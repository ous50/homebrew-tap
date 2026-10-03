# Cask update automation

The `brew bump` workflow runs every 30 minutes, on pushes to main, and manually.
It starts from current main, uses each cask's existing livecheck definition, and
lets `brew bump-cask-pr --write-only` generate versions and all four checksums.
Beta channel selection is unchanged (the existing livecheck also accepts stable releases).

The fixed branches `automation/maaend` and `automation/maaend-beta` each have at
most one pending PR. New releases replace the proposed update in that same PR.
Base changes refresh the generated branch too. These branches are bot-owned;
put manual changes on another branch. After merging, the next release opens a
new PR. Unchanged checks do not create commits or PRs.

## One-time setup

Create a fine-grained personal access token restricted to `ous50/homebrew-tap`:

- Contents: read and write (branches and merges).
- Pull requests: read and write (PR creation and metadata).
- Actions: read (verify the test run and its jobs).

Save it as the repository Actions **secret** `TAP_BOT_TOKEN`. Do not paste it in
an issue, PR, or chat. Set an expiry and replace the secret when rotating it.
The built-in GITHUB_TOKEN is used for read-only testing. The custom token makes
PR changes trigger CI without the workflow-approval prompt, and merged updates
trigger the main-branch tests and existing README updater.

Enable **Allow rebase merging** in repository Settings > General. This uses the
merge API after checking CI, so GitHub's **Allow auto-merge** setting is not required.
Recommended branch protection: require `test-bot (macos-26)`,
`test-bot (ubuntu-latest)`, and `cask-checks`, and require branches to be up to date.
Keep bypass disabled for the token's owner. This also enforces the base/check
requirements atomically if main advances during the merge API request.

Merge the automation setup PR, then run **Actions > brew bump > Run workflow**.
No update is published without the token; the updater explains the missing secret.

## Merge conditions

The `Merge tested cask updates` workflow uses only the script checked out from
main. It never checks out or executes PR code with the write token. It requires:

- A successful `brew test-bot` PR workflow for the current PR head, with both
  Homebrew jobs and `cask-checks` successful (not skipped).
- A same-repository PR to main from exactly one of the two automation branches.
- Exactly one modified cask file, changing only version and four SHA-256 values,
  with a strictly newer version.
- Current main already included in the branch and a clean, rebaseable PR.

The merge API is given the tested head SHA, so a concurrent head change rejects
the merge. If main advances, the updater refreshes the pending branch and CI runs
again. Failed checks, changed app definitions, drafts, or blocked reviews never
auto-merge. Checks verify downloaded bytes for all four targets; they do not
install or launch the app. GitHub branch rules still apply.
