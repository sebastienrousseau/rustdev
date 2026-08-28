<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

## Summary

<!-- What does this change and why? One or two sentences. -->

## Related issue

<!-- e.g. "Closes #123". Use "N/A" if none. -->

## Type of change

- [ ] Bug fix (non-breaking)
- [ ] New feature (non-breaking)
- [ ] Breaking change (behaviour, template shape, or security posture)
- [ ] Docs / CI / tooling only

## Affected scope

- [ ] Shared core (`common/`) or templates — needs `make sync-common` downstream
- [ ] A single `<language>dev` image only
- [ ] Docs / meta only

## Checklist

- [ ] `make lint` is clean (hadolint + shellcheck)
- [ ] `make build` succeeds (where a built image is affected)
- [ ] `make scan` reports no HIGH/CRITICAL findings (where an image is affected)
- [ ] No new un-pinned input (base by digest, downloads checksum-verified, deps hash-locked)
- [ ] No secret committed or baked into an image layer
- [ ] SPDX headers present on new files (`Apache-2.0 OR MIT`)
- [ ] Docs / `CHANGELOG.md` updated where behaviour changed
- [ ] Commits are signed (CI verifies this)
