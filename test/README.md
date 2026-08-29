<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

# langdev test suite

Unit tests for the shared shell core — `common/bootstrap-dotfiles.sh`,
`common/entrypoint.sh`, and `bin/langdev-sync` — written with
[bats-core](https://github.com/bats-core/bats-core) and measured with
[kcov](https://github.com/SimonKagstrom/kcov). The gate fails the build
below **95 %** line coverage.

## Running

```sh
make test        # bats under kcov, fail if coverage < 95%
make coverage    # same, then open coverage/ (HTML report)
test/run.sh --no-coverage   # just the bats suite, no kcov
```

CI runs the same gate in `.github/workflows/ci.yml` (the `coverage`
job), so a coverage regression fails the pull request.

## How the tests stay hermetic

The scripts shell out to `git`, `chezmoi`, `nvim`, `tmux`, and `rsync`.
The suite never touches the network or a container. Instead:

- **Test doubles** for each of those tools live in
  [`helpers/bin/`](helpers/bin/). They record their argv to `$STUB_LOG`
  and simulate just enough behaviour (a `clone` that populates a
  directory, a `rev-parse` that prints a fixed sha) to drive every
  branch. Their responses are steered by env vars — e.g.
  `STUB_GIT_BRANCH_FAIL=1` forces the shallow `clone --branch` to fail so
  the fallback full-clone path runs.
- **A closed PATH.** [`helpers/common.bash`](helpers/common.bash)'s
  `hermetic_path` builds a PATH containing only a whitelist of real
  coreutils plus the stubs a test opts into. Because the PATH is closed,
  tool *presence* is deterministic: include `rsync` to exercise
  langdev-sync's rsync branch, omit it for the `cp` fallback; include
  `tmux` for the entrypoint's tmux branch, omit it for the login-shell
  fallback.
- **A private `$HOME`** per test, under bats' `$BATS_TEST_TMPDIR`, so the
  dotfiles clone/apply and the chezmoi config write land in a sandbox.

## Test seams in the scripts

The scripts carry a small, documented seam that is **inert in
production** (it activates only when `LANGDEV_TEST` is exported, which
only the test runner does):

| Seam | Script | Purpose |
| :--- | :--- | :--- |
| `exec` shadow | `entrypoint.sh` | Under `LANGDEV_TEST`, `exec` is a function that records its argv and exits instead of replacing the process — so the arg-vs-shell, tmux, and login-shell branches are each observable. |
| `LANGDEV_FAKE_TTY` | `entrypoint.sh` | Forces the stdout-TTY probe (`_is_tty`) true/false without a real PTY. |
| `LANGDEV_WORKDIR` | `entrypoint.sh` | Overrides the `/work` project dir (defaults to `/work`). |
| `LANGDEV_RUNTIME_HOOK` | `entrypoint.sh` | Overrides the `/usr/local/lib/langdev/runtime-hook.sh` path (defaults to it). |

With `LANGDEV_TEST` unset, every seam resolves to its production value,
so runtime behaviour is byte-identical.

## Layout

```
test/
├── bootstrap-dotfiles.bats   # clone/ref/fallback/chezmoi-config/apply
├── entrypoint.bats           # arg-vs-shell, tmux, no-tty/no-tmux, hook
├── langdev-sync.bats         # local-path vs git-URL, rsync vs cp, errors
├── run.sh                    # bats-under-kcov coverage gate (>=95%)
└── helpers/
    ├── common.bash           # sandbox + hermetic PATH + assertions
    └── bin/                  # git / chezmoi / nvim / tmux / rsync doubles
```
