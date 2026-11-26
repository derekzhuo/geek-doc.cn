FROM ubuntu:24.04 AS openroad-build

ARG OPENROAD_COMMIT=6f3f28cc85
ARG GITHUB_BASE_URL=https://github.com
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /OpenROAD
RUN git clone "${GITHUB_BASE_URL}/The-OpenROAD-Project/OpenROAD.git" . \
 && git checkout "${OPENROAD_COMMIT}"
RUN git submodule update --init --recursive
RUN if [ "${GITHUB_BASE_URL}" != "https://github.com" ]; then \
      sed -i "s|https://github.com|${GITHUB_BASE_URL}|g" MODULE.bazel etc/DependencyInstaller.sh; \
    fi
RUN ./etc/DependencyInstaller.sh
RUN ./etc/Build.sh

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    iverilog python3 make ca-certificates \
    libx11-6 libx11-xcb1 libsm6 libice6 \
    libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 \
    libxcb-render-util0 libxcb-shape0 libxcb-shm0 libxcb-sync1 libxcb-util1 \
    libxcb-xfixes0 libxcb-xkb1 libdbus-1-3 libfontconfig1 \
    libxkbcommon0 libxkbcommon-x11-0 libuuid1 libbsd0 libsystemd0 \
    libfreetype6 libexpat1 libmd0 liblzma5 libzstd1 liblz4-1 libcap2 \
    libgcrypt20 libpng16-16 zlib1g libbz2-1.0 libbrotli1 libgpg-error0 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=openroad-build /OpenROAD/install /OpenROAD/install
RUN ln -s /OpenROAD/install/bin/openroad /usr/local/bin/openroad \
 && openroad -version | grep -F '26Q4-1108-g6f3f28cc85' \
 && iverilog -V 2>/dev/null | grep -F 'Icarus Verilog version 12.0' \
 && python3 --version | grep -F 'Python 3.12.3'

WORKDIR /work
CMD ["bash"]
