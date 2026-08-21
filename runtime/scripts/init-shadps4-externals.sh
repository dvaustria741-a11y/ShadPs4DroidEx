#!/usr/bin/env bash
# Populates external/shadps4's own submodules (declared in its .gitmodules).
#
# Context: external/shadps4 was vendored into this repo as a plain file copy
# (from dev-Ali2008/onRps4-runtime, which itself had squashed shadPS4's history),
# not via `git submodule add`. That means .gitmodules is present but none of the
# ~44 submodules it declares were ever actually checked out — their directories
# are simply missing, which is why CMake fails with "which is not an existing
# directory" for externals/winlator-app and externals/libdeflate (see CI run
# 87931460154). This script is the manual equivalent of
# `git submodule update --init --recursive` for a tree that isn't a real
# submodule-linked checkout.
#
# Three of the 44 are fork-specific (not present in vanilla shadPS4):
#   externals/winlator-app, externals/libdeflate, runtime/sources/box64
# The other ~41 are shadPS4's normal build dependencies (fmt, glslang, ffmpeg,
# etc.) and are fetched at HEAD, same as a fresh shadPS4 checkout would.
set -euo pipefail

shadps4_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../external/shadps4" && pwd)
gitmodules="$shadps4_root/.gitmodules"

if [[ ! -f "$gitmodules" ]]; then
  echo "no .gitmodules at $gitmodules, nothing to do"
  exit 0
fi

# name -> pinned revision, where we have one (see runtime/locks/components.lock.json)
declare -A pinned_revision=(
  ["runtime/sources/box64"]="50c8b90b09b433ab0767de44af2d0731cb0748b7"
)

names=$(git config -f "$gitmodules" --get-regexp '\.path$' | awk '{print $1}' | sed 's/\.path$//')

for name in $names; do
  path=$(git config -f "$gitmodules" --get "$name.path")
  url=$(git config -f "$gitmodules" --get "$name.url")
  branch=$(git config -f "$gitmodules" --get "$name.branch" 2>/dev/null || true)
  dest="$shadps4_root/$path"

  if [[ -d "$dest" && -n "$(ls -A "$dest" 2>/dev/null)" ]]; then
    echo "skip $path (already populated)"
    continue
  fi

  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"

  revision="${pinned_revision[$path]:-}"
  if [[ -n "$revision" ]]; then
    git clone --filter=blob:none --no-checkout "$url" "$dest"
    git -C "$dest" fetch --depth 1 origin "$revision"
    git -C "$dest" checkout --detach --force "$revision"
    echo "fetched $path @ $revision (pinned)"
  else
    # .gitmodules pins a non-default branch for a handful of these (dear_imgui
    # -> docking, ext-wepoll -> dist, sdl3 -> main, libusb -> shadps4, spdlog
    # -> v2.x). Cloning without --branch silently grabs each repo's actual
    # default branch instead, which for at least externals/libusb doesn't even
    # have a CMakeLists.txt at its root (see CI run 87989520516: "does not
    # contain a CMakeLists.txt file"). Also recurse: some of these have their
    # own nested submodules (e.g. externals/sirit needs its own
    # externals/SPIRV-Headers), which a flat non-recursive clone leaves empty.
    if [[ -n "$branch" ]]; then
      git clone --depth 1 --recurse-submodules --shallow-submodules --branch "$branch" "$url" "$dest" 2>&1 | tail -1
      echo "fetched $path @ $branch (unpinned, pinned branch, recursive)"
    else
      git clone --depth 1 --recurse-submodules --shallow-submodules "$url" "$dest" 2>&1 | tail -1
      echo "fetched $path @ HEAD (unpinned, recursive)"
    fi
  fi
  # Deliberately NOT stripping .git here (a `rm -rf "$dest/.git"` used to run
  # at this point). At least externals/ffmpeg-core's own CMakeLists.txt does
  # `git rev-parse --short HEAD` inside itself to pick which prebuilt FFmpeg
  # binary to download; strip .git and that command walks up to the outer
  # fork's .git instead, returning the fork's own commit SHA -- which has no
  # matching FFmpeg prebuilt and fails CMake configure with "No FFMPEG
  # prebuilt found with corresponding commit SHA" (see CI run 87985485956).
  # None of these directories are committed to this repo (only
  # CMakeLists.txt/aacdec/cmake-modules/gcn/renderdoc/stb are, at
  # external/shadps4/externals/), so there's no git-hygiene reason to strip
  # nested .git dirs -- they only exist for the lifetime of a CI checkout.
done
