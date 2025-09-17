FROM ghcr.io/b521f771d8991e6f1d8e65ae05a8d783/base-tools/debian-tools:main AS development
RUN cargo install wasm-bindgen-cli@0.2.100

FROM development AS build
ARG VARIANT=release

WORKDIR /buildroot
COPY . . 
RUN VARIANT=${VARIANT} TARGET=$(python3 Development/Scripts/get-host-target-triple.py | sed 's/gnu/musl/') \
    make init && npx dotenvx run -- make installer android-apk

FROM ghcr.io/b521f771d8991e6f1d8e65ae05a8d783/base-tools/debian-tools-runtime:main AS run-build

WORKDIR /
COPY --from=build /buildroot/output /tmp
RUN dpkg -i /tmp/*.deb && rm -rf /tmp/*

ENTRYPOINT [ "/bin/backend" ]
