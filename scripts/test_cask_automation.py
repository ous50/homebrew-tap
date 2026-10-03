"""Regression tests for the boundaries of unattended cask merging."""

import copy
import hashlib
import io
import json
import os
import tempfile
import unittest
from unittest.mock import patch

import cask_automation as automation


class CaskAutomationTests(unittest.TestCase):
    def setUp(self):
        self.before = (automation.ROOT / 'Casks/maaend.rb').read_text(encoding='utf-8')
        version, _ = automation.metadata(self.before)
        self.after = self.before.replace(f'version "{version}"', 'version "999.0.0"')

    def test_forward_bump_allowed(self):
        self.assertTrue(automation.bump_only(self.before, self.after))

    def test_manual_code_changes_blocked(self):
        for change in [self.after.replace('auto_updates true', 'auto_updates false'),
                       self.after + '\nsystem "untrusted"\n']:
            self.assertFalse(automation.bump_only(self.before, change))

    def test_checksum_only_and_downgrade_blocked(self):
        self.assertFalse(automation.bump_only(self.before, self.before))
        self.assertFalse(automation.bump_only(self.after, self.before))

    def test_all_platforms_required(self):
        with self.assertRaises(ValueError):
            automation.metadata(self.before.replace('arm64_linux:', 'unsupported:'))

    def test_beta_ordering(self):
        versions = ['2.1.0-beta.2', '2.1.0-beta.10', '2.1.0', '2.2.0-beta.1']
        self.assertEqual(sorted(versions, key=automation.version_key), versions)

    def test_downloads_are_hashed_for_all_four_targets(self):
        digest = hashlib.sha256(b'asset').hexdigest()
        text = automation.HASH.sub(lambda m: m[1] + f'"{digest}"', self.before)
        with patch.object(automation, 'urlopen', side_effect=lambda *a, **k: io.BytesIO(b'asset')) as fetch:
            automation.verify(text)
        self.assertEqual(fetch.call_count, 4)
        urls = [call.args[0].full_url for call in fetch.call_args_list]
        self.assertEqual(len(set(urls)), 4)

    def test_bad_download_blocks_validation(self):
        with patch.object(automation, 'urlopen', return_value=io.BytesIO(b'bad asset')):
            with self.assertRaisesRegex(ValueError, 'Checksum mismatch'):
                automation.verify(self.before)

    def test_only_current_same_repo_success_is_eligible(self):
        repo = {'full_name': 'ous50/homebrew-tap'}
        pr = {'state': 'open', 'draft': False, 'base': {'ref': 'main', 'repo': repo},
              'head': {'ref': 'automation/maaend', 'repo': repo, 'sha': 'tested'}}
        run = {'head_branch': 'automation/maaend', 'head_sha': 'tested',
               'head_repository': repo, 'event': 'pull_request', 'conclusion': 'success',
               'path': '.github/workflows/tests.yml'}
        self.assertTrue(automation.eligible(pr, run, repo['full_name']))
        for key, value in [('head_sha', 'stale'), ('conclusion', 'failure'),
                           ('event', 'push'), ('path', '.github/workflows/other.yml')]:
            changed = dict(run, **{key: value})
            self.assertFalse(automation.eligible(pr, changed, repo['full_name']))
        for key, value in [('sha', 'new'), ('ref', 'manual'),
                           ('repo', {'full_name': 'fork/homebrew-tap'})]:
            changed = copy.deepcopy(pr)
            changed['head'][key] = value
            self.assertFalse(automation.eligible(changed, run, repo['full_name']))
        self.assertFalse(automation.eligible(dict(pr, draft=True), run, repo['full_name']))

    def merge_fixture(self, behind=0, cask_result='success', changed_head=False):
        repository = 'ous50/homebrew-tap'
        repo = {'full_name': repository}
        run = {'id': 1, 'run_attempt': 1, 'head_branch': 'automation/maaend',
               'head_sha': 'tested', 'head_repository': repo, 'event': 'pull_request',
               'conclusion': 'success', 'path': '.github/workflows/tests.yml'}
        pr = {'number': 2, 'state': 'open', 'draft': False, 'changed_files': 1,
              'base': {'ref': 'main', 'repo': repo},
              'head': {'ref': 'automation/maaend', 'repo': repo, 'sha': 'tested'},
              'mergeable_state': 'clean', 'rebaseable': True}
        pr_reads = 0

        def fake_api(path, method='GET', data=None):
            nonlocal pr_reads
            if method == 'PUT':
                self.assertEqual(path, 'pulls/2/merge')
                self.assertEqual(data, {'sha': 'tested', 'merge_method': 'rebase'})
                return {'merged': True}
            if path == 'actions/runs/1':
                return run
            if path.startswith('pulls?'):
                return [pr]
            if path == 'pulls/2':
                pr_reads += 1
                result = copy.deepcopy(pr)
                if changed_head and pr_reads > 1:
                    result['head']['sha'] = 'untested'
                return result
            if '/jobs?' in path:
                return {'jobs': [{'name': 'test-bot (macos-26)', 'conclusion': 'success'},
                                 {'name': 'test-bot (ubuntu-latest)', 'conclusion': 'success'},
                                 {'name': 'cask-checks', 'conclusion': cask_result}]}
            if '/files?' in path:
                return [{'filename': 'Casks/maaend.rb', 'status': 'modified'}]
            if path == 'git/ref/heads/main':
                return {'object': {'sha': 'base'}}
            if path == 'compare/base...tested':
                return {'behind_by': behind}
            self.fail(f'Unexpected API call: {path}')

        with tempfile.TemporaryDirectory() as directory:
            event = automation.Path(directory) / 'event.json'
            event.write_text(json.dumps({'workflow_run': {'id': 1}}))
            with patch.dict(os.environ, GITHUB_EVENT_PATH=str(event), GITHUB_REPOSITORY=repository), \
                    patch.object(automation, 'api', side_effect=fake_api) as calls, \
                    patch.object(automation, 'read_file', side_effect=[self.before, self.after]):
                if cask_result != 'success':
                    with self.assertRaisesRegex(ValueError, 'Missing successful'):
                        automation.merge()
                else:
                    automation.merge()
        return [call for call in calls.call_args_list if len(call.args) > 1 and call.args[1] == 'PUT']

    def test_successful_workflow_merges_exact_tested_sha(self):
        self.assertEqual(len(self.merge_fixture()), 1)

    def test_advanced_base_or_head_never_merges(self):
        self.assertFalse(self.merge_fixture(behind=1))
        self.assertFalse(self.merge_fixture(changed_head=True))

    def test_skipped_download_job_never_merges(self):
        self.assertFalse(self.merge_fixture(cask_result='skipped'))


if __name__ == '__main__':
    unittest.main()
