#!/usr/bin/env bash
# Resolve a wxWidgets version requirement and install the matching precompiled
# build from the cocoa-xu/wxWidgets-build releases.
set -euo pipefail

req="${INPUT_WXWIDGETS_VERSION:-}"
library="${INPUT_LIBRARY:-shared}"
triplet="${INPUT_TRIPLET:-}"
repo="${INPUT_REPOSITORY:-cocoa-xu/wxWidgets-build}"
install_dir="${INPUT_INSTALL_DIR:-.wxwidgets}"
add_to_path="${INPUT_ADD_TO_PATH:-true}"
token="${INPUT_TOKEN:-${GH_TOKEN:-${GITHUB_TOKEN:-}}}"
resolve_only="${RESOLVE_ONLY:-}"

err() { echo "::error::$*" >&2; exit 1; }
log() { echo "$*" >&2; }

[ -n "$req" ] || err "wxwidgets_version input is required"
case "$library" in
  shared|static) ;;
  *) err "library must be 'shared' or 'static', got '$library'" ;;
esac

detect_triplet() {
  local os arch a libc
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Linux)
      case "$arch" in
        x86_64|amd64) a=x86_64 ;;
        aarch64|arm64) a=aarch64 ;;
        armv7l|armv7*) a=armv7l ;;
        i?86) a=i686 ;;
        riscv64) a=riscv64 ;;
        ppc64le|powerpc64le) a=ppc64le ;;
        s390x) a=s390x ;;
        *) err "unsupported Linux architecture: $arch" ;;
      esac

      if [ -f /etc/alpine-release ] || (command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl); then
        libc=musl
      else
        libc=gnu
      fi

      if [ "$libc" = musl ]; then
        if [ "$a" = armv7l ]; then
          printf 'armv7l-linux-musleabihf'
        else
          printf '%s-linux-musl' "$a"
        fi
      elif [ "$a" = armv7l ]; then
        printf 'armv7l-linux-gnueabihf'
      else
        printf '%s-linux-gnu' "$a"
      fi
      ;;
    Darwin)
      case "$arch" in
        arm64) printf 'arm64-apple-darwin' ;;
        x86_64) printf 'x86_64-apple-darwin' ;;
        *) err "unsupported macOS architecture: $arch" ;;
      esac
      ;;
    MINGW*|MSYS*|CYGWIN*)
      case "$arch" in
        x86_64|amd64) a=x86_64 ;;
        aarch64|arm64) a=aarch64 ;;
        i?86) a=i686 ;;
        *) err "unsupported Windows architecture: $arch" ;;
      esac
      printf '%s-windows-msvc' "$a"
      ;;
    *) err "unsupported OS: $os" ;;
  esac
}

strip() { echo "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'; }

version_valid() {
  echo "$1" | grep -Eq '^[0-9]+(\.[0-9]+)+$'
}

ver_cmp() {
  local IFS=. i max ai bi
  local -a av bv
  read -ra av <<<"$1"
  read -ra bv <<<"$2"
  max=${#av[@]}
  [ "${#bv[@]}" -gt "$max" ] && max=${#bv[@]}

  for ((i = 0; i < max; i++)); do
    ai="${av[i]:-0}"
    bi="${bv[i]:-0}"
    if ((10#$ai < 10#$bi)); then echo -1; return; fi
    if ((10#$ai > 10#$bi)); then echo 1; return; fi
  done
  echo 0
}

ver_le() { [ "$(ver_cmp "$1" "$2")" != 1 ]; }
ver_lt() { [ "$(ver_cmp "$1" "$2")" = -1 ]; }

tilde_upper() {
  local IFS=.
  local -a p
  local n
  read -ra p <<<"$1"
  n=${#p[@]}
  if [ "$n" -le 1 ]; then
    echo "$((p[0] + 1))"
  else
    p[n-2]=$((p[n-2] + 1))
    unset 'p[n-1]'
    echo "${p[*]}"
  fi
}

list_versions() {
  local auth=() page=1 body
  [ -n "$token" ] && auth=(-H "Authorization: Bearer $token")
  while :; do
    body="$(curl -fsSL "${auth[@]}" -H 'Accept: application/vnd.github+json' \
      "https://api.github.com/repos/$repo/releases?per_page=100&page=$page" 2>/dev/null)" || break
    [ "$body" = "[]" ] || [ -z "$body" ] && break
    printf '%s' "$body" | grep -oE '"tag_name":[[:space:]]*"v?[^"]+"' \
      | sed -E 's/.*"v?([^"]+)"/\1/'
    page=$((page + 1))
    [ "$page" -gt 10 ] && break
  done | grep -E '^[0-9]+(\.[0-9]+)+$'
}

req="$(strip "$req")"
case "$req" in
  "~>"*) op="~>"; ver="$(strip "${req#\~>}")" ;;
  ">="*) op=">="; ver="$(strip "${req#>=}")" ;;
  "<="*) op="<="; ver="$(strip "${req#<=}")" ;;
  "=="*) op="=="; ver="$(strip "${req#==}")" ;;
  ">"*) op=">"; ver="$(strip "${req#>}")" ;;
  "<"*) op="<"; ver="$(strip "${req#<}")" ;;
  v[0-9]*) op="=="; ver="${req#v}" ;;
  *) op="=="; ver="$req" ;;
esac

[ -n "$ver" ] || err "could not parse version requirement: '$req'"
version_valid "$ver" || err "invalid wxWidgets version: '$ver'"

if [ -z "$triplet" ]; then
  triplet="$(detect_triplet)"
fi
log "Platform: $triplet  |  library: $library  |  requirement: ${op} ${ver}"

asset_ok() {
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' -I -L \
    "https://github.com/$repo/releases/download/v$1/wxWidgets-$library-$triplet.tar.gz" 2>/dev/null || echo 000)"
  [ "$code" = 200 ]
}

constraint_matches() {
  local candidate="$1"
  case "$op" in
    "~>") ver_le "$ver" "$candidate" && ver_lt "$candidate" "$upper" ;;
    ">=") ver_le "$ver" "$candidate" ;;
    ">") ver_lt "$ver" "$candidate" ;;
    "<=") ver_le "$candidate" "$ver" ;;
    "<") ver_lt "$candidate" "$ver" ;;
    *) false ;;
  esac
}

resolved=""
if [ "$op" = "==" ]; then
  if asset_ok "$ver"; then
    resolved="$ver"
  else
    err "wxWidgets $ver has no $library build for $triplet (exact match)"
  fi
else
  upper=""
  if [ "$op" = "~>" ]; then upper="$(tilde_upper "$ver")"; fi

  while read -r candidate; do
    [ -n "$candidate" ] || continue
    constraint_matches "$candidate" || continue
    if asset_ok "$candidate"; then
      if [ -z "$resolved" ] || ver_lt "$resolved" "$candidate"; then
        resolved="$candidate"
      fi
    else
      log "  (skipping $candidate - no $library $triplet build)"
    fi
  done < <(list_versions)

  [ -n "$resolved" ] || err "no wxWidgets release satisfying '${op} ${ver}' has a $library $triplet build"
fi

log "Resolved '${req}' -> wxWidgets ${resolved}"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "wxwidgets-version=$resolved"
    echo "triplet=$triplet"
    echo "library=$library"
  } >> "$GITHUB_OUTPUT"
fi

[ -n "$resolve_only" ] && { echo "$resolved"; exit 0; }

mkdir -p "$install_dir"
install_dir="$(cd "$install_dir" && pwd)"
archive="wxWidgets-$library-$triplet.tar.gz"
url="https://github.com/$repo/releases/download/v$resolved/$archive"

log "Downloading $url"
curl -fSL --retry 3 --retry-all-errors "$url" -o "$install_dir/$archive" \
  || err "failed to download $url"
tar -xzf "$install_dir/$archive" -C "$install_dir"
rm -f "$install_dir/$archive"

if [ -d "$install_dir/usr/local" ]; then
  prefix="$install_dir/usr/local"
else
  prefix="$install_dir"
fi

if [ -L "$prefix/bin/wx-config" ] && [ ! -e "$prefix/bin/wx-config" ]; then
  wx_config_target="$(readlink "$prefix/bin/wx-config")"
  wx_config_name="$(basename "$wx_config_target")"
  if [ -x "$prefix/lib/wx/config/$wx_config_name" ]; then
    ln -sf "../lib/wx/config/$wx_config_name" "$prefix/bin/wx-config"
  fi
fi

bindir=""
includedir=""
libdir="$prefix"
wx_config=""

[ -d "$prefix/bin" ] && bindir="$prefix/bin"
[ -d "$prefix/include" ] && includedir="$prefix/include"
[ -d "$prefix/lib" ] && libdir="$prefix/lib"
[ -x "$prefix/bin/wx-config" ] && wx_config="$prefix/bin/wx-config"

if [ "$add_to_path" = "true" ] && [ -n "$bindir" ] && [ -n "${GITHUB_PATH:-}" ]; then
  echo "$bindir" >> "$GITHUB_PATH"
fi

if [ -n "${GITHUB_ENV:-}" ]; then
  {
    echo "WXWIDGETS_ROOT=$install_dir"
    echo "WXWIDGETS_PREFIX=$prefix"
    [ -n "$wx_config" ] && echo "WX_CONFIG=$wx_config"
  } >> "$GITHUB_ENV"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "install-dir=$install_dir"
    echo "prefix=$prefix"
    echo "bindir=$bindir"
    echo "includedir=$includedir"
    echo "libdir=$libdir"
    echo "wx-config=$wx_config"
  } >> "$GITHUB_OUTPUT"
fi

log "wxWidgets ${resolved} ($library, $triplet) installed to ${install_dir}"
if [ -n "$wx_config" ]; then
  "$wx_config" --version || log "(note: could not run wx-config)"
fi
