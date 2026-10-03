#!/usr/bin/env python3
"""Prepare/verify cask updates and merge only tested version/checksum changes."""

import base64
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import urlencode
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent.parent
CASKS = ('maaend', 'maaend-beta')
VERSION = re.compile(r'^(  version )"(\d+\.\d+\.\d+(?:-beta\.\d+)?)"$', re.M)
HASH = re.compile(r'((?:sha256\s+)?\b(arm|intel|arm64_linux|x86_64_linux):\s*)"([0-9a-f]{64})"')
TARGETS = {
    'arm': ('macos', 'aarch64', 'dmg'),
    'intel': ('macos', 'x86_64', 'dmg'),
    'arm64_linux': ('linux', 'aarch64', 'tar.gz'),
    'x86_64_linux': ('linux', 'x86_64', 'tar.gz'),
}
URL_TEMPLATE = 'https://github.com/MaaEnd/MaaEnd/releases/download/v#{version}/MaaEnd-#{os}-#{arch}-v#{version}.#{downloaded_file_format}'


def metadata(text):
    versions = VERSION.findall(text)
    hashes = HASH.findall(text)
    if len(versions) != 1 or len(hashes) != 4 or {h[1] for h in hashes} != set(TARGETS):
        raise ValueError('Expected one version and exactly four platform checksums')
    if f'url "{URL_TEMPLATE}"' not in text:
        raise ValueError('Unexpected release URL; update the verifier before enabling automation')
    return versions[0][1], {key: value for _, key, value in hashes}


def version_key(version):
    main, _, beta = version.partition('-beta.')
    return (*map(int, main.split('.')), 0 if beta else 1, int(beta or 0))


def bump_only(before, after):
    old, _ = metadata(before)
    new, _ = metadata(after)

    def normalized(text):
        return HASH.sub(lambda m: m[1] + '"HASH"', VERSION.sub(r'\1"VERSION"', text))

    return version_key(new) > version_key(old) and normalized(before) == normalized(after)


def verify(text):
    version, hashes = metadata(text)
    for key, (platform, arch, suffix) in TARGETS.items():
        url = f'https://github.com/MaaEnd/MaaEnd/releases/download/v{version}/MaaEnd-{platform}-{arch}-v{version}.{suffix}'
        digest = hashlib.sha256()
        # Public downloads: never forward credentials to release asset hosts.
        with urlopen(Request(url, headers={'User-Agent': 'homebrew-tap-ci'}), timeout=120) as response:
            while chunk := response.read(1024 * 1024):
                digest.update(chunk)
        if digest.hexdigest() != hashes[key]:
            raise ValueError(f'Checksum mismatch: {key} {version}')
        print(f'Verified {key} {version}', flush=True)


def prepare(cask, tap):
    if cask not in CASKS:
        raise ValueError('Unsupported cask')
    path = ROOT / 'Casks' / f'{cask}.rb'
    before = path.read_text(encoding='utf-8')
    current, _ = metadata(before)
    result = subprocess.check_output(
        ['brew', 'livecheck', '--cask', '--json', f'{tap}/{cask}'], text=True,
    )
    entries = json.loads(result)
    if len(entries) != 1 or 'version' not in entries[0]:
        raise ValueError(f'Livecheck did not return a version: {result}')
    latest = entries[0]['version']['latest']
    if not re.fullmatch(r'\d+\.\d+\.\d+(?:-beta\.\d+)?', latest):
        raise ValueError('Unsupported upstream version')
    if version_key(latest) > version_key(current):
        subprocess.run(
            ['brew', 'bump-cask-pr', '--write-only', f'--version={latest}', f'{tap}/{cask}'],
            check=True,
        )
        after = path.read_text(encoding='utf-8')
        if not bump_only(before, after):
            raise ValueError('Bump changed more than version/checksums')
        # Homebrew downloads assets to generate hashes. Independent verification runs in PR CI.
        current, _ = metadata(after)
    with open(os.environ['GITHUB_OUTPUT'], 'a', encoding='utf-8') as output:
        output.write(f'version={current}\n')


def api(path, method='GET', data=None):
    token = os.environ.get('GH_TOKEN')
    if not token:
        raise ValueError('TAP_BOT_TOKEN is required; see docs/automation.md')
    request = Request(
        f'https://api.github.com/repos/{os.environ["GITHUB_REPOSITORY"]}/{path}',
        method=method,
        data=json.dumps(data).encode() if data is not None else None,
        headers={'Authorization': f'Bearer {token}', 'Accept': 'application/vnd.github+json',
                 'Content-Type': 'application/json', 'X-GitHub-Api-Version': '2022-11-28'},
    )
    with urlopen(request, timeout=60) as response:
        return json.load(response)


def read_file(path, sha):
    result = api(f'contents/{path}?ref={sha}')
    return base64.b64decode(result['content']).decode('utf-8')


def eligible(pr, run, repository):
    return (
        pr['state'] == 'open' and not pr['draft']
        and pr['base']['ref'] == 'main'
        and pr['base']['repo']['full_name'] == repository
        and pr['head']['repo']['full_name'] == repository
        and run['head_repository']['full_name'] == repository
        and pr['head']['ref'] in {f'automation/{c}' for c in CASKS}
        and pr['head']['ref'] == run['head_branch']
        and pr['head']['sha'] == run['head_sha']
        and run['event'] == 'pull_request' and run['conclusion'] == 'success'
        and run['path'] == '.github/workflows/tests.yml'
    )


def merge_run(run):
    repository = os.environ['GITHUB_REPOSITORY']
    owner = repository.split('/')[0]
    query = urlencode({'state': 'open', 'base': 'main', 'head': f'{owner}:{run["head_branch"]}'})
    prs = api(f'pulls?{query}')
    if len(prs) != 1:
        print('No unique open automation PR; nothing to merge.')
        return
    number = prs[0]['number']
    pr = api(f'pulls/{number}')
    if not eligible(pr, run, repository):
        print('PR or test run is no longer eligible; leaving it open.')
        return
    jobs = api(f'actions/runs/{run["id"]}/attempts/{run["run_attempt"]}/jobs?per_page=100')['jobs']
    required = {'test-bot (macos-26)', 'test-bot (ubuntu-latest)', 'cask-checks'}
    successful = {job['name'] for job in jobs if job['conclusion'] == 'success'}
    if not required <= successful:
        raise ValueError('Missing successful Homebrew or cask validation jobs')
    cask = pr['head']['ref'].split('/')[1]
    path = f'Casks/{cask}.rb'
    files = api(f'pulls/{number}/files?per_page=100')
    if pr['changed_files'] != 1 or len(files) != 1 or files[0]['filename'] != path or files[0]['status'] != 'modified':
        raise ValueError('Only a single cask version/checksum update may auto-merge')
    head = pr['head']['sha']
    base = api('git/ref/heads/main')['object']['sha']
    comparison = api(f'compare/{base}...{head}')
    if comparison['behind_by'] != 0:
        print('main advanced; the updater will refresh this PR and run new checks.')
        return
    if not bump_only(read_file(path, base), read_file(path, head)):
        raise ValueError('PR includes changes beyond a forward version/checksum bump')
    # Respect pending checks and review requirements, including for an admin-owned PAT.
    pr = api(f'pulls/{number}')
    if pr['head']['sha'] != head or pr['mergeable_state'] != 'clean' or not pr['rebaseable']:
        print('PR changed or is not cleanly rebaseable; leaving it open.')
        return
    if api('git/ref/heads/main')['object']['sha'] != base:
        print('main changed during verification; leaving this PR for the next refresh.')
        return
    result = api(f'pulls/{number}/merge', 'PUT', {'sha': head, 'merge_method': 'rebase'})
    if not result.get('merged'):
        raise ValueError(f'Merge refused: {result}')
    print(f'Rebased and merged #{number} at tested head {head}')


def merge():
    event = json.loads(Path(os.environ['GITHUB_EVENT_PATH']).read_text())
    if 'workflow_run' in event:
        # An old successful event must not approve a failed/in-progress rerun.
        merge_run(api(f'actions/runs/{event["workflow_run"]["id"]}'))
        return
    # Reconcile after transient merge blockers, without creating new commits or PRs.
    owner = os.environ['GITHUB_REPOSITORY'].split('/')[0]
    for cask in CASKS:
        query = urlencode({'state': 'open', 'base': 'main', 'head': f'{owner}:automation/{cask}'})
        prs = api(f'pulls?{query}')
        if len(prs) != 1:
            continue
        query = urlencode({'event': 'pull_request', 'head_sha': prs[0]['head']['sha'], 'per_page': 1})
        runs = api(f'actions/workflows/tests.yml/runs?{query}')['workflow_runs']
        if runs:
            merge_run(api(f'actions/runs/{runs[0]["id"]}'))


if __name__ == '__main__':
    command = sys.argv[1]
    if command == 'prepare':
        prepare(*sys.argv[2:])
    elif command == 'verify':
        for filename in sys.argv[2:]:
            verify(Path(filename).read_text(encoding='utf-8'))
    elif command == 'merge':
        merge()
    else:
        raise ValueError(f'Unknown command: {command}')
