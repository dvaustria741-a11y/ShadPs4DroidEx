# Porting Plan — shadPS4 on Android

## Why this is hard
shadPS4 emulates a PS4, which runs x86-64 (AMD Jaguan) code. On PC, shadPS4 runs that
game code **directly on the host x86-64 CPU** — there is no CPU JIT in shadPS4 itself,
it only intercepts PS4 syscalls/libraries. Android devices are ARM64, so PS4 game code
cannot execute natively; it must be dynamically translated.

## Why we're not using FEX-Emu as-is
[FEX-Emu](https://github.com/FEX-Emu/FEX) is a full **Linux userspace x86 emulator**:
it hooks `binfmt_misc`, requires an x86-64 rootfs, and assumes glibc syscalls end-to-end.
Android is Bionic-based and has no user-accessible `binfmt_misc` without root — FEX's
normal install/execution model does not function in a standard APK sandbox.

## Chosen approach: embed FEXCore only
shadPS4 already implements its own PS4 syscall/library/linker layer (that's how any PS4
emulator works on any host OS — it does not rely on the host kernel to service PS4
syscalls). So the plan is:

- Pull in **FEXCore** (the x86-64→ARM64 block JIT, not the Linux-emulation frontend) as
  a library dependency, built for `arm64-v8a` only.
- shadPS4's existing linker/memory manager stays in control of PS4 process state.
- Instead of executing translated code on a real x86-64 CPU, hand code blocks to FEXCore
  for translation+execution, with syscalls trapped back into shadPS4's existing
  `core/libraries` implementations rather than passed to FEXCore's Linux syscall path.
- No `binfmt_misc`, no x86-64 rootfs, no glibc dependency at runtime.

## Current status
- [x] Confirmed shadPS4 has no built-in CPU translation (checked `src/core`, `externals/`)
- [x] Confirmed FEX's standard integration model is unusable on stock Android
- [ ] FEXCore standalone (non-Linux-frontend) build for arm64-v8a — **not yet attempted**
- [ ] Syscall trap plumbing between shadPS4 and FEXCore — **not started**
- [ ] Vulkan/audio/input Android backends for shadPS4 — **not started**
- [ ] Anything resembling a bootable game — **not started, likely a multi-month effort**

## Repo layout
- `external/shadps4/` — shadPS4 source (submodule)
- `external/FEX/` — FEX-Emu source (submodule, only FEXCore is built)
- `app/` — Android app module (JNI bridge + Activity shell)
- `cpp/toolchain/` — CMake toolchain glue for NDK cross-compilation
- `.github/workflows/` — CI: builds APK on every push, reports build status
