#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$project_root"

if ! command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
  echo "Missing aarch64-linux-gnu-gcc. Run: sudo runtime/scripts/install-debian-runtime-deps.sh"
  exit 1
fi

# external/shadps4 was vendored as a flat file copy, so its own .gitmodules
# (sdl3, dear_imgui, etc.) were never checked out — see init-shadps4-externals.sh
# and PORTING_PLAN.md. build-shadps4-arm64.sh requires these to be populated.
bash runtime/scripts/init-shadps4-externals.sh

# runtime/sources/box64 is required by build-box64-host.sh (pinned revision
# check) but nothing checked it out before — components.lock.json has the
# pinned url/revision, checkout-component.sh does the actual clone.
box64_component=$(node -e '
  const c = require("./runtime/locks/components.lock.json");
  const box64 = c.components.find(x => x.name === "box64");
  if (!box64) throw new Error("box64 missing from components.lock.json");
  process.stdout.write(box64.url + " " + box64.revision);
')
read -r box64_url box64_revision <<<"$box64_component"
bash runtime/scripts/checkout-component.sh box64 "$box64_url" "$box64_revision"

bash runtime/scripts/build-shadps4-x86_64.sh
bash runtime/scripts/build-box64-host.sh
bash runtime/scripts/build-shadps4-arm64.sh
bash runtime/scripts/vendor-winlator.sh
bash runtime/scripts/vendor-vortek.sh
bash runtime/scripts/build-vortek-client.sh
node runtime/scripts/stage-debian-runtime.mjs
node runtime/scripts/package-runtime.mjs
