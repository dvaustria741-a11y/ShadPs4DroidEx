# ShadPs4DroidEx

Android port effort for [shadPS4](https://github.com/shadps4-emu/shadPS4) (PS4 emulator).

**Status: does not run games yet — see [PORTING_PLAN.md](PORTING_PLAN.md).**

Vendors a further-along shadPS4 Android runtime (from
[dev-Ali2008/onRps4-runtime](https://github.com/dev-Ali2008/onRps4-runtime))
combining a FEXCore-based x86-64→ARM64 JIT bridge with a Box64/Winlator-based
Linux userland path. Both translation approaches are present; which one (or
both) ends up load-bearing is still open — see the porting plan for exact
status, what's actually wired into the build, and what's still orphaned
source.

The buildable Android project lives at
`external/shadps4/android/BachataS4/` (kept at that depth on purpose — its
native build computes paths via a fixed number of `../` hops).

See [NOTICE.android-runtime.md](NOTICE.android-runtime.md) for third-party
attribution (Winlator, Vortek, Box64, glibc, Mesa/Turnip — LGPL-2.1/MIT/mixed)
and `runtime/locks/components.lock.json` for pinned revisions.
