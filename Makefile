#! /usr/bin/env /usr/bin/make -f

.DEFAULT_GOAL := all
VARIANT ?= debug
SHELL := zsh
TARGET ?= $(shell python3 -c 'import subprocess; output=subprocess.check_output(["rustc", "-vV"]).decode("utf-8"); print(output.splitlines()[output.splitlines().index([line for line in output.splitlines() if line.startswith("host: ")][0])].strip().replace("host: ", ""))')
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
	npm install

.PHONY: all
all:
    # ------------------------------------------------------------------------------
	@echo Building frontend
	# ------------------------------------------------------------------------------

	PATH="/opt/homebrew/opt/llvm/bin:${PATH}" npx dotenvx run -- wasm-pack build --out-dir ../../generated/npm-pkgs/from-scratch Sources/Core --mode no-install
	npx dotenvx run -- npm run build --workspaces
	
	# ------------------------------------------------------------------------------
	@echo Building backend
	# ------------------------------------------------------------------------------
	
	@echo Recognized cmake dirs: ${CMAKE_DIRS}
	@for i in $(CMAKE_DIRS); do \
		echo "Running cmake in $$i"; \
		TARGET=${TARGET} VARIANT=${VARIANT} npx dotenvx run -- cmake -G ${CMAKE_BUILDER} -S $$i -B .cmake/$$i --preset ${VARIANT}; \
		TARGET=${TARGET} VARIANT=${VARIANT} npx dotenvx run -- cmake --build .cmake/$$i; \
	done
	jq -s add .cmake/${SOURCES_DIR}/**/compile_commands.json  > .cmake/compile_commands.json

	# TODO enable this
	# npx dotenvx run -- swift build --package-path Sources/Core/swift --configuration ${VARIANT}
	npx dotenvx run -- cargo build ${CARGO_TARGET_FLAG} ${CARGO_VARIANT_FLAG} --features backend

.PHONY: test
test: all
	npx dotenvx run -- ctest --test-dir .cmake
	npx dotenvx run -- swift test --package-path Sources/Core/swift
	npx dotenvx run -- cargo test
	npx dotenvx run -- npm run test --workspaces

.PHONY: lint
lint: all
	npx dotenvx run -- npm run lint --workspaces
	#TODO

.PHONY: clean
clean:
	cargo clean
	npx shx rm -rf .build .cmake target generated node_modules result output

.PHONY: run
run: all
	npx dotenvx run -- bacon run --bin backend --features="backend"

.PHONY: format
format:
	nix fmt
	cargo fmt
	clang-format -i $(shell find $(CMAKE_DIRS) -type f \
                    \( -name '*.c'  -o -name '*.cc' -o -name '*.cpp' -o -name '*.c++' -o -name '*.h' -o \
                      -name '*.h++' -o -name '*.cxx' -o -name '*.m'   -o -name '*.mm' \) )
	npx prettier --write Sources

.PHONY: install
install: all
	mkdir -p ${DESTDIR}/bin
	cp ./target/${TARGET}/${VARIANT}/backend ${DESTDIR}/bin # TODO find a way to make this work for other targets
	chmod +x ${DESTDIR}/bin/*
	echo "Installed to ${DESTDIR}/bin"
