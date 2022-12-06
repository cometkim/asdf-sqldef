#!/bin/bash

set -eo pipefail

GITHUB_REPO="https://github.com/k0kubun/sqldef"

cmd="curl -fsSL"
if [ -n "$GITHUB_API_TOKEN" ]; then
 cmd="$cmd -H 'Authorization: token $GITHUB_API_TOKEN'"
fi

# stolen from https://github.com/rbenv/ruby-build/pull/631/files#diff-fdcfb8a18714b33b07529b7d02b54f1dR942
function sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

function list_github_tags() {
  git ls-remote --tags --refs "$GITHUB_REPO" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

function get_platform() {
  case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
    "darwin") echo -n "darwin";;
    "linux") echo -n "linux";;
    *) fail "Unsupported platform";;
  esac
}

function get_arch() {
  case "$(uname -m)" in
    "arm64") echo -n "arm64";;
    "x86_64") echo -n "amd64";;
    "i386") echo -n "386";;
    *) fail "Unsupported architecture";;
  esac
}

function get_ext() {
  case "$(get_platform)" in
    "darwin") echo -n "zip";;
    "linux") echo -n "tar.gz";;
  esac
}

function extract() {
  local src=$1
  local dst=$2

  case "$(get_platform)" in
    "darwin") unzip "$src" -d "$dst";;
    "linux") tar xf "$src" -C "$dst";;
  esac
}

function get_bin_url() {
  local name=$1
  local version=$2

  local platform
  platform="$(get_platform)"

  local arch
  arch="$(get_arch)"

  local ext
  ext="$(get_ext)"

  local url="$GITHUB_REPO/releases/download/v$version/${name}_${platform}_${arch}.${ext}"

  echo -n "$url"
}

function get_temp_dir() {
  local tmpdir
  tmpdir=$(mktemp -d asdf-sqldef.XXXX)

  echo -n "$tmpdir"
}

function fail() {
  echo -e "\e[31mFail:\e[m $*" 1>&2
  exit 1
}
