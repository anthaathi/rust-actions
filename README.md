# Anthaathi Rust Actions

Reusable setup for Anthaathi Rust CI and release builds. The action installs:

- Rust using the minimal rustup profile (when it is not already available)
- the requested Rust compilation target
- native Linux GStreamer and XKB development packages for the client
- ARM64 or MinGW cross-compilers
- extracted ARM64 GStreamer development files for client cross-builds
- osxcross prerequisites when requested

## Usage

```yaml
- uses: anthaathi/rust-actions@v1
  with:
    crate: apps/client
    target: aarch64-unknown-linux-gnu
```

For osxcross prerequisites:

```yaml
- uses: anthaathi/rust-actions@v1
  with:
    mode: osxcross
```

Supported standard targets are the native host (an empty target),
`aarch64-unknown-linux-gnu`, and `x86_64-pc-windows-gnu`.
