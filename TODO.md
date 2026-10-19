# TODO

- Trim `export-sysroot.sh`. It copies `/bin`, `/lib`, `/usr`, `/etc`, `/var`, `/home`, and `/sbin` out of the image on purpose: native compiles link against that Debian userland, and a smaller set that still links has not been proven. Do that reduction before publishing a binary package.
- Publish the image to `ghcr.io/daemonarium/reflection-toolchain`. A local `docker build` is the supported compile-in-Docker path until then.
- Attach a `sysroot` archive to a GitHub Release, after the export is small enough to be worth downloading.
- An `EM_CONFIG` that points at some other Emscripten install is unlikely to see this Clang or this libc++. Leave it unsupported unless a concrete consumer needs it.
- Confirm the Emscripten pin. The working export said `4.0.21-git` and did not keep `.git`, so `upstream-commits.txt` uses tag `4.0.21`. Run `./run-smoke.sh` on a sysroot built from that tag. If it fails, bisect between `4.0.21` and the next tag.
