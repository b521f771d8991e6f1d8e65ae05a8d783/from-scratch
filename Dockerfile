ARG TRIXIE_TOOLS_SRC=ghcr.io/b521f771d8991e6f1d8e65ae05a8d783/base-tools/debian-tools
ARG TRIXIE_TOOLS_VERSION=main

FROM ${TRIXIE_TOOLS_SRC}:${TRIXIE_TOOLS_VERSION} AS development

FROM development AS buildroot

WORKDIR /buildroot
COPY . . 
RUN make init

FROM --platform=x86_64 buildroot AS build-android

ARG VARIANT=release
WORKDIR /buildroot
RUN VARIANT=${VARIANT} npx dotenvx run -- make android-apk

FROM buildroot AS build

ARG VARIANT=release
WORKDIR /buildroot
RUN VARIANT=${VARIANT} TARGET=$(python3 Development/Scripts/get-host-target-triple.py | sed 's/gnu/musl/') npx dotenvx run -- make rootfs test
RUN chmod +x /buildroot/output/rootfs/bin/*
WORKDIR /buildroot/output/rootfs/opt
# in its own stage so that it may be built in parallel
COPY --from=build-android /buildroot/output/app-release.apk .

FROM scratch AS run

WORKDIR / 
COPY --from=build /buildroot/output/rootfs .
CMD [ "/bin/from-scratch" ]
