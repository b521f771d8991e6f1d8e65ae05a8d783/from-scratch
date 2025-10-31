#! /usr/bin/env /usr/bin/make -f

.DEFAULT_GOAL := all
VARIANT ?= debug
SHELL := zsh
TARGET ?= $(shell python3 Development/Scripts/get-host-target-triple.py)
OUT_DIR ?= ./output

SWIFT_SDK_CMD := --swift-sdk $(shell echo $(TARGET) | sed 's/unknown/swift/')
CARGO_TARGET_FLAG := --target ${TARGET}
CMAKE_BUILDER := Ninja

SOURCES_DIR := Sources/Core
CMAKE_DIRS := $(shell find $(SOURCES_DIR) -maxdepth 2 -type f -name 'CMakeLists.txt' -exec dirname {} \;)

ifneq (, $(shell command -v gnustep-config))
	# Store the new flags in temporary variables
	TEMP_OBJCFLAGS := $(shell gnustep-config --gui-libs --objc-flags) \
		-isystem/usr/include/x86_64-linux-gnu/GNUstep/ -isystem/usr/lib/gcc/x86_64-linux-gnu/14/include/ \
		-isystem/usr/include/aarch64-linux-gnu/GNUstep/ -isystem/usr/lib/gcc/aarch64-linux-gnu/14/include/ \
		-fconstant-string-class=NSConstantString

	# Append the temporary variables to OBJCFLAGS and OBJCXXFLAGS
	export OBJCFLAGS := $(TEMP_OBJCFLAGS) $(OBJCFLAGS)
	export OBJCXXFLAGS := $(TEMP_OBJCFLAGS) $(OBJCXXFLAGS)
endif

ifeq ($(shell uname), Darwin)
	TMP_LDFLAGS := -framework Foundation -framework Cocoa \
	               -framework AppKit -framework CoreData \
	               -framework Security -framework CoreGraphics \
	               -framework CoreAudio -framework CoreLocation \
	               -framework AVFoundation -framework QuartzCore \
	               -framework MediaPlayer
	export LDFLAGS := $(TMP_LDFLAGS) $(LDFLAGS)
endif

# some tools like Cargo require special treatment 🦄
ifeq ($(VARIANT),release)
CARGO_VARIANT_FLAG := --release
else
CARGO_VARIANT_FLAG :=
endif

.PHONY: init
init:
	git submodule update --init --recursive
	cargo fetch
	npm install --before="$(date -v -1d)" --workspaces
	npm install --before="$(date -v -1d)"
	#swift package resolve

.PHONY: trixie-tools-static-offline
trixie-tools-offline:
	docker build -f Dependencies/base-tools/trixie-tools.dockerfile . -t trixie-tools:main

.PHONY: cmake-projects
cmake-projects:
	@echo Recognized cmake dirs: ${CMAKE_DIRS}

	@for i in $(CMAKE_DIRS); do \
		echo "Running cmake in $$i"; \
		TARGET=${TARGET} VARIANT=${VARIANT} npx dotenvx run -- cmake -G ${CMAKE_BUILDER} -S $$i -B .cmake/$$i --preset ${VARIANT}; \
		TARGET=${TARGET} VARIANT=${VARIANT} npx dotenvx run -- cmake --build .cmake/$$i; \
	done

	jq -s add .cmake/${SOURCES_DIR}/**/compile_commands.json  > .cmake/compile_commands.json

	npx dotenvx run -- cmake -G ${CMAKE_BUILDER} -DTARGET=${TARGET} -DVARIANT=${VARIANT}  -S . -B .cmake/root;
	npx dotenvx run -- cmake --build .cmake/root;

# apple clang does not have a webassembly target, so we need the one shipped by e.g. homebrew. Do not do this in other parts, because we do not need wasm there and want to use Apple Clang there.
.PHONY: shared-frontend-and-backend-parts
shared-frontend-and-backend-parts:
	PATH="/opt/homebrew/opt/llvm/bin:${PATH}" npx dotenvx run -- wasm-pack build --out-dir ../../generated/npm-pkgs/from-scratch Sources/Core --mode no-install

.PHONY: frontend
frontend: shared-frontend-and-backend-parts
	npx dotenvx run -- npm run build:web --workspaces

.PHONY: backend
backend: cmake-projects
	npx dotenvx run -- cargo build ${CARGO_TARGET_FLAG} ${CARGO_VARIANT_FLAG} --features backend
	#CC=clang CXX=clang++ swift build --configuration ${VARIANT} # ${SWIFT_SDK_CMD}

.PHONY: all
all: shared-frontend-and-backend-parts frontend backend

.PHONY: test
test:
	npx dotenvx run -- ctest --test-dir .cmake
	npx dotenvx run -- cargo test
	#swift test

.PHONY: clean
clean:
	cargo clean
	npx shx rm -rf .build .cmake target generated node_modules result output

.PHONY: installer
installer: all
	cd .cmake/root && npx dotenvx run -- cpack
	npx shx rm -rf ${OUT_DIR}
	npx shx mkdir -p ${OUT_DIR}
	npx shx mv .cmake/root/* $(OUT_DIR)

.PHONY: android-apk
android-apk:
	cd Sources/UI && ANDROID_HOME=${ANDROID_HOME} PATH="${PATH}:${ANDROID_HOME}/tools/:${ANDROID_HOME}/platform-tools/" npm run build:android:${VARIANT}
	mkdir -p ${OUT_DIR}
	cp Sources/UI/android/app/build/outputs/apk/release/app-release.apk ${OUT_DIR}/

.PHONY: ios-ipa
ios-ipa:
	cd Sources/UI && npm run build:ios:${VARIANT}
	mkdir -p ${OUT}

.PHONY: rootfs
rootfs: installer
	mkdir -p ${OUT_DIR}/rootfs
	sh ${OUT_DIR}/*.sh -- --skip-license --prefix=${OUT_DIR}/rootfs

.PHONY: run
run: all
	npx dotenvx run --  cargo run --bin backend --features="backend"

.PHONY: run-dev
run-dev: all
	tmux new-session -d -s dev \
		"cd Development && npm run dev-proxy" \; \
		split-window -h "BROWSER=none npx dotenvx run -- npm run web --workspaces" \; \
		split-window -v -t dev:0.0 "npx dotenvx run -- bacon run --features=\"backend\"" \; \
		select-layout tiled \; \
		attach-session -t dev

.PHONY: format
format:
	nix fmt
	cargo fmt
	clang-format -i $(shell find $(CMAKE_DIRS) -type f \
                    \( -name '*.c'  -o -name '*.cc' -o -name '*.cpp' -o -name '*.c++' -o -name '*.h' -o \
                      -name '*.h++' -o -name '*.cxx' -o -name '*.m'   -o -name '*.mm' \) )
	npx prettier --write Sources
