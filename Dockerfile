FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG RUST_TOOLCHAIN=stable

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
      bash ca-certificates clang cmake curl file g++-aarch64-linux-gnu \
      gcc-aarch64-linux-gnu gcc-mingw-w64-x86-64 git libfontconfig1-dev \
      libfreetype-dev libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev \
      libssl-dev libxkbcommon-dev libxkbcommon-x11-dev libxml2-dev llvm-dev \
      lzma-dev msitools nodejs patch pkg-config python3 tar unzip xz-utils zip zlib1g-dev \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --profile minimal --default-toolchain "$RUST_TOOLCHAIN" \
    && rustup target add \
      aarch64-unknown-linux-gnu \
      x86_64-pc-windows-gnu \
      x86_64-apple-darwin \
      aarch64-apple-darwin \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/install-arm64-dev-packages.sh /usr/local/bin/install-arm64-dev-packages
RUN chmod +x /usr/local/bin/install-arm64-dev-packages \
    && install-arm64-dev-packages \
      libgstreamer1.0-dev:arm64 \
      libgstreamer-plugins-base1.0-dev:arm64 \
      libxkbcommon-dev:arm64 \
      libxkbcommon-x11-dev:arm64 \
      libfontconfig1-dev:arm64 \
      libfreetype-dev:arm64 \
    && rm -f /usr/local/bin/install-arm64-dev-packages \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/*

RUN node --version \
    && cargo --version \
    && rustc --version \
    && pkg-config --exists gstreamer-1.0 \
    && test -f /usr/lib/aarch64-linux-gnu/pkgconfig/gstreamer-1.0.pc \
    && command -v aarch64-linux-gnu-gcc \
    && command -v x86_64-w64-mingw32-gcc

LABEL org.opencontainers.image.source="https://github.com/anthaathi/rust-actions" \
      org.opencontainers.image.description="Prebuilt Rust cross-compilation environment for Anthaathi"
