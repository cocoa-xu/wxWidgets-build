# wxWidgets-build

Precompiled wxWidgets archives for CI builds.

This repository publishes release assets named:

```text
wxWidgets-<shared|static>-<triplet>.tar.gz
```

The Linux and macOS archives are installed under `usr/local` and include
`wx-config`. The Windows archives contain the prebuilt MSVC library directory
contents for the matching wxWidgets build.

## GitHub Action

Install a precompiled wxWidgets build in one step:

```yaml
steps:
  - uses: actions/checkout@v6

  - name: Install wxWidgets
    id: wx
    uses: cocoa-xu/wxWidgets-build@main
    with:
      wxwidgets_version: '3.3.3'
      library: shared

  - run: wx-config --version
```

`wxwidgets_version` accepts an exact version or an Elixir-style requirement.
The action resolves requirements to the newest release that satisfies the
requirement and has a build for the runner's platform and selected library:

| `wxwidgets_version` | resolves to |
|---|---|
| `3.3.3.1` | exactly `3.3.3.1` |
| `~> 3.3` | newest `>= 3.3` and `< 4` |
| `~> 3.3.3` | newest `>= 3.3.3` and `< 3.4` |
| `>= 3.2.8` | newest `>= 3.2.8` |
| `< 3.4` | newest `< 3.4` |

Patch-level rebuilds can be published for only one platform. For example,
`3.3.3.1` is intended for the Windows MSVC artifacts rebuilt from upstream
wxWidgets `3.3.3`.

The current runner platform is detected automatically. Supported triplets are:

- Linux glibc: `x86_64-linux-gnu`, `aarch64-linux-gnu`,
  `armv7l-linux-gnueabihf`, `riscv64-linux-gnu`, `ppc64le-linux-gnu`,
  `s390x-linux-gnu`
- Linux musl: `x86_64-linux-musl`, `i686-linux-musl`,
  `aarch64-linux-musl`, `armv7l-linux-musleabihf`,
  `riscv64-linux-musl`, `ppc64le-linux-musl`, `s390x-linux-musl`
- macOS: `arm64-apple-darwin`, `x86_64-apple-darwin`
- Windows MSVC: `aarch64-windows-msvc`, `x86_64-windows-msvc`,
  `i686-windows-msvc`

### Inputs

| input | default | description |
|---|---|---|
| `wxwidgets_version` | - | exact version or requirement (required) |
| `library` | `shared` | `shared` or `static` |
| `install-dir` | `.wxwidgets` | directory to extract into |
| `add-to-path` | `true` | append `bin` to `PATH` when present |
| `repository` | `cocoa-xu/wxWidgets-build` | release source |
| `token` | `${{ github.token }}` | used to list releases when resolving a requirement |

`wxwidgets-version` is also accepted as an alias for `wxwidgets_version`.

### Outputs

| output | description |
|---|---|
| `wxwidgets-version` | resolved wxWidgets version |
| `triplet` | detected platform triplet |
| `library` | installed library type |
| `install-dir` | absolute extraction directory |
| `prefix` | `usr/local` prefix when present, otherwise `install-dir` |
| `bindir` | absolute `bin` directory when present |
| `includedir` | absolute include directory when present |
| `libdir` | absolute library directory |
| `wx-config` | absolute `wx-config` path when present |

The action exports `WXWIDGETS_ROOT` and `WXWIDGETS_PREFIX` through
`GITHUB_ENV`. On Linux and macOS it also exports `WX_CONFIG` and adds the
directory containing `wx-config` to `PATH` by default.

## Manual Download

Choose the matching triplet and library type from a release:

```bash
VERSION=3.3.3
LIBRARY=shared
TRIPLET=x86_64-linux-gnu

mkdir -p .wxwidgets
curl -fSL "https://github.com/cocoa-xu/wxWidgets-build/releases/download/v${VERSION}/wxWidgets-${LIBRARY}-${TRIPLET}.tar.gz" \
  -o ".wxwidgets/wxWidgets-${LIBRARY}-${TRIPLET}.tar.gz"
tar -xzf ".wxwidgets/wxWidgets-${LIBRARY}-${TRIPLET}.tar.gz" -C .wxwidgets
```
