# Anthaathi Rust Actions

Prebuilt Rust CI environment for Anthaathi projects. Instead of downloading Rust,
GStreamer development packages, and cross-compilers in every job, workflows run
inside `ghcr.io/anthaathi/rust-actions:latest`.

The image contains:

- Rust with native, ARM64 Linux, MinGW Windows, Intel macOS, and Apple Silicon targets
- native and extracted ARM64 GStreamer/XKB development files
- ARM64 and MinGW cross-compilers
- osxcross prerequisites
- common build tools such as Clang, CMake, pkg-config, Python, and msitools

## Workflow usage

Set the container on the job and then use the companion action to verify and
configure the selected target:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/anthaathi/rust-actions:latest
    steps:
      - uses: actions/checkout@v4
      - uses: anthaathi/rust-actions@v1
        with:
          crate: apps/client
          target: aarch64-unknown-linux-gnu
```

For osxcross:

```yaml
- uses: anthaathi/rust-actions@v1
  with:
    mode: osxcross
```

The action intentionally does not run `apt-get` or install Rust. Missing tools
cause an immediate failure so the container definition remains the single source
of truth. The image is rebuilt automatically when its Dockerfile or provisioning
scripts change.
