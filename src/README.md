# auto-app

Sample C++ application for AutoSD. Prints a greeting and exits.

## Building

The recommended way is through the top-level Makefile (runs inside a Podman container, no local toolchain needed):

```shell
make build       # compile → bin/auto-app
make build-rpm   # build RPM → bin/*.rpm
```

To build locally with CMake:

```shell
cmake -B build .
cmake --build build
```

## Packaging

The RPM spec is `auto-app.spec`. It uses CMake macros (`%cmake` / `%cmake_build` / `%cmake_install`) and installs the binary to `/usr/bin/auto-app`.