# Porting Plan — shadPS4 on Android

## Where this stands
This repo now vendors a much further-along shadPS4 Android runtime (internally
named "BachataS4") pulled from `dev-Ali2008/onRps4-runtime`, combining two CPU
translation paths rather than picking one:

- **FEXCore bridge** — `external/shadps4/src/core/fex/` +
  `external/shadps4/src/core/guest_cpu/`. Translates x86-64 PS4 game code to
  ARM64 in-process, with syscalls trapped back into shadPS4's own PS4
  library/linker layer instead of FEX's Linux syscall path — this is why FEX
  can't just be used "as installed" (see below).
- **Box64 path** — `runtime/patches/box64-*.patch`, a Kotlin
  `Box64EmulatorRuntime`, and a Winlator-style glibc userland (via a vendored,
  pinned Winlator/Vortek stack for X11/GPU/audio plumbing). This is the same
  general approach Winlator itself uses to run x86 Windows software on Android.

Both are present because they solve different halves of the problem — FEXCore
for direct in-process JIT translation, Box64+Winlator's userland for a fuller
Linux-compatible environment (glibc, X11, ALSA) some PS4 library shims may
depend on. Which one (or both) ends up load-bearing is still open.

## Why not just install FEX/Box64 the normal way
Both are built as full Linux-userspace x86 emulators (binfmt_misc hooks, a
glibc x86-64 rootfs). Stock Android has no user-accessible binfmt_misc without
root and is Bionic-based, not glibc — neither tool's normal execution model
works in an APK sandbox as-is.

## Honest status (verified by inspection, not by building)
- [x] shadPS4 confirmed to have no native CPU JIT (source-level check)
- [x] `fex_guest_engine.{h,cpp}` and the `guest_cpu/` bridge exist and compile
      against real FEXCore APIs (ExecuteThread, HandleCallback, signal
      delivery, XMM/AVX reconstruction) — this is real, substantial code
- [x] Another contributor pushed a real two-job CI pipeline (`native-runtime`
      building box64 + FEXCore + shadPS4 for both x86_64 and arm64 in a Debian
      container, `build` assembling the APK from its output) and a FEXCore
      smoke-test build (`build-fexcore-smoke-aarch64.sh`) that genuinely
      compiles `core/fex/fex_guest_engine.cpp` and `core/guest_cpu/*` against
      real FEXCore — so the "orphaned, not wired into any build" status above
      is now outdated for that specific build path (still not wired into the
      *Android* CMake target BachataS4 ships, which is the one that matters
      for a real APK — see below).
- [x] Found and fixed the actual cause of that CI run's failure (run
      87949737412): not the patch-apply noise (those failures are expected
      and handled — the vendored shadPS4 source already contains these
      changes, so `git apply --check`/`--reverse --check` correctly detects
      that and skips; the printed "error: patch failed" lines are normal
      `--check` diagnostic noise, not a fatal error). The real fatal error was
      two levels down: `build-fexcore-smoke-aarch64.sh` needs
      `runtime/probes/fexcore-smoke.cpp` and `fexcore-guest-harness.cpp`,
      which I never vendored in the original merge — only `patches/`,
      `scripts/`, `vendor-overrides/`, `vortek-protocol/`, `settings/`,
      `locks/` came over, not `probes/`. Copied it over; `kotlin/` and
      `qualification/` (also present upstream, not vendored) are confirmed
      unreferenced by anything on the build path, so left out on purpose.
- [ ] Still true: the CMake target BachataS4's Android app actually builds
      (`core:runtime` in `android/BachataS4/core/runtime/src/main/cpp/
      CMakeLists.txt`) does not reference `core/fex` or `core/guest_cpu` —
      the smoke-test build above is a separate, standalone verification path,
      not the app itself linking against it yet.
- [ ] `externals/winlator-app` (needed by the native runtime CMake for
      `libadrenotools`) is not vendored in git — it's fetched at setup time by
      `runtime/scripts/vendor-winlator.sh` from a pinned upstream revision
      (see `runtime/locks/components.lock.json`)
- [x] `externals/winlator-app` fetched correctly by `runtime/scripts/vendor-winlator.sh`
      — my earlier worry about a path mismatch there didn't materialize (verified
      against real CI run 87931460154)
- [x] Root cause of the actual CMake failure found and fixed: `external/shadps4`
      was vendored as a flat file copy, so its own `.gitmodules` (~44 entries —
      shadPS4's normal build deps, plus fork-specific `externals/winlator-app`,
      `externals/libdeflate`, `runtime/sources/box64`) were never checked out.
      `runtime/scripts/init-shadps4-externals.sh` now does the manual equivalent
      of `git submodule update --init --recursive` for that tree, run in CI
      before the CMake configure step. Verified locally against the real repo —
      all three fork-specific paths land where CMake expects them.
- [ ] No evidence I've generated or verified that any of this boots a game.
      The upstream repo's own `runtime/evidence/sm8650/` logs (phase0/phase1
      FEX instrumentation, an audio gate doc) suggest active device testing
      in progress there, not a finished result.
- [ ] Nothing in this session was actually built — no Android SDK/NDK
      toolchain available here to verify compilation.

## Attribution
See `NOTICE.android-runtime.md` and `external/shadps4/LICENSES/` — Winlator
and Vortek components are LGPL-2.1, Box64 is MIT, shadPS4 itself is
GPL-2.0-or-later. Pinned revisions for every vendored component are in
`runtime/locks/components.lock.json`.

## Repo layout
- `external/shadps4/` — vendored shadPS4 fork, including `src/core/fex`,
  `src/core/guest_cpu`, and the nested `android/BachataS4` Gradle project
  (the actual buildable app — kept at its original relative depth because its
  CMake computes paths via a fixed number of `../` hops)
- `runtime/` — patches, setup scripts, license/attribution locks for the
  Box64/Winlator/Vortek/glibc/Mesa stack
- `settings.gradle.kts` at repo root — points at
  `external/shadps4/android/BachataS4` via `includeBuild` rather than
  flattening it, for the same relative-path reason

## Next real steps, in order
1. Fix the vendoring scripts' path mismatch (or vendor `winlator-app` directly
   instead of fetching it) so a clean checkout can actually produce a build.
2. Wire `core/fex` + `core/guest_cpu` into an actual CMake target — they
   compile as source but aren't linked into anything yet.
3. Get one clean CI build (even if non-functional) to establish a baseline.
4. Only then: attempt to actually execute PS4 code through the bridge.
