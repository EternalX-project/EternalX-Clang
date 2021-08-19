#!/usr/bin/env bash
#
# Pushing Prebuilt
#

set -eo pipefail

# Helper function to perform a GitHub API call
function gh_call() {
    local req="$1"
    local server="$2"
    local endpoint="$3"
    shift
    shift
    shift

    resp="$(curl -Lfu "$GH_USER:$GH_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -X "$req" \
        "https://$server.github.com/repos/$GH_REL_REPO/$endpoint" \
        "$@")" || \
        { ret="$?"; echo "Request failed with exit code $ret:"; cat <<< "$resp"; return $ret; }

    cat <<< "$resp"
}

# Generate build info
rel_date="$(date "+%Y%m%d")" # ISO 8601 format
rel_friendly_date="$(date "+%B %-d, %Y")" # "Month day, year" format
clang_version="$(install/bin/clang --version | head -n1 | cut -d' ' -f4)"

# Generate release info
builder_commit="$(git rev-parse HEAD)"
pushd llvm-project
llvm_commit="$(git rev-parse HEAD)"
short_llvm_commit="$(cut -c-8 <<< $llvm_commit)"
popd

llvm_commit_url="https://github.com/llvm/llvm-project/commit/$llvm_commit"
binutils_ver="$(ls | grep "^binutils-" | sed "s/binutils-//g")"

# Update Git repository
git clone "https://$GH_USER:$GH_TOKEN@github.com/$GH_REL_REPO" rel_repo
pushd rel_repo
rm -fr *
cp -r ../install/* .
# Keep files that aren't part of the toolchain itself
git checkout README.md LICENSE
git add .
git commit -am "Update to $rel_date build
LLVM commit: $llvm_commit_url
binutils version: $binutils_ver
Builder commit: https://github.com/$GH_BUILD_REPO/commit/$builder_commit"
git push
popd
