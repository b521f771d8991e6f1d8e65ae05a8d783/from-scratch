# for good documentation, see here: https://nixos.org/manual/nixpkgs/stable/

{
  inputs = {
    nixpkgs.url = "github:b521f771d8991e6f1d8e65ae05a8d783/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
    }:
    flake-utils.lib.eachSystem
      [
        flake-utils.lib.system.x86_64-linux
        flake-utils.lib.system.aarch64-linux
        flake-utils.lib.system.x86_64-darwin
        flake-utils.lib.system.aarch64-darwin
      ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = false;
            overlays = [ rust-overlay.overlays.default ];
          };

          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            extensions = [ "rust-src" ];
            targets = [
              "x86_64-apple-darwin"
              "aarch64-apple-darwin"
              "x86_64-unknown-linux-musl"
              "aarch64-unknown-linux-musl"
              "x86_64-unknown-linux-gnu"
              "aarch64-unknown-linux-gnu"
              "wasm32-unknown-unknown"
            ];
          };

          global-packages =
            with pkgs;
            [
              zsh
              git
              gnumake
              pkg-config
              cmake
              radicle-node
              rpm
              ninja
              jq # tools
              lld # (Objective) C/++ toolchain
              rustToolchain
              wasm-pack
              wasm-bindgen-cli
              bacon
              swift
              swiftpm
              nodejs
            ]
            ++ lib.optionals pkgs.stdenv.isLinux [
              gcc
              gnustep-base
              gnustep-gui
              gnustep-make
              gnustep-libobjc
              dpkg
              pkg-config
              clang
              clang-tools
            ]
            ++ lib.optionals stdenv.isDarwin [
              libcxx
              apple-sdk # clang is included here
            ];

          npm-deps = pkgs.buildNpmPackage {
            # used only to create the node_modules folder
            name = "npm-deps";
            src = ./.;

            npmDeps = pkgs.importNpmLock {
              npmRoot = ./.;
            };

            npmConfigHook = pkgs.importNpmLock.npmConfigHook;

            buildPhase = ":";

            installPhase = ''
              mkdir -p $out
              cp --no-preserve=mode,ownership -r node_modules $out
            '';

            fixupPhase = ":";
            checkPhase = ":";
          };

          environment = {
            VARIANT = "release";
            # use clang as much as possible
            CC = if pkgs.stdenv.isLinux then "${pkgs.gcc}/bin/gcc" else "${pkgs.clang}/bin/clang";
            CXX = if pkgs.stdenv.isLinux then "${pkgs.gcc}/bin/gcc" else "${pkgs.clang}/bin/clang++";
            OBJC = if pkgs.stdenv.isLinux then "${pkgs.gcc}/bin/gcc" else "${pkgs.clang}/bin/clang";
            OBJCXX = if pkgs.stdenv.isLinux then "${pkgs.gcc}/bin/gcc" else "${pkgs.clang}/bin/clang";

            OBJCFLAGS =
              if pkgs.stdenv.isLinux then
                "-isystem${pkgs.gnustep-gui}/include -isystem${pkgs.gnustep-base.dev}/include -isystem${pkgs.gnustep-libobjc}/include"
              else
                "";
            OBJCXXFLAGS =
              if pkgs.stdenv.isLinux then
                "-isystem${pkgs.gnustep-gui}/include -isystem${pkgs.gnustep-base.dev}/include -isystem${pkgs.gnustep-libobjc}/include"
              else
                "";
            LDFLAGS =
              if pkgs.stdenv.isLinux then
                "-L${pkgs.gnustep-gui}/lib -L${pkgs.gnustep-base.lib}/lib -L${pkgs.gnustep-libobjc}/lib -lgnustep-gui -lgnustep-base -lobjc -lm"
              else
                "";

            CPLUS_INCLUDE_PATH = if pkgs.stdenv.isDarwin then "${pkgs.libcxx.dev}/include/c++/v1" else "";
          };

          backend = pkgs.rustPlatform.buildRustPackage {
            name = "backend";
            src = ./.;

            cargoLock = {
              lockFile = ./Cargo.lock;
            };

            env = environment;
            nativeBuildInputs = global-packages;
            HOME = "./home";

            buildPhase = ''
              mkdir -p ${backend.HOME}            
              cp -r --no-preserve=mode,ownership ${npm-deps}/node_modules .
              chmod -R 777 node_modules # to prevent Error: EACCES: permission denied, mkdir '/build/s4bnqnz1prnhv383fpn2hqm29m7ifn3g-source/node_modules/react-native-css-interop/.cache'
              make rootfs
            '';

            checkPhase = "make test";

            installPhase = ''
              mkdir -p $out
              cp --no-preserve=mode,ownership -r output/rootfs/* $out
            '';
          };
        in
        {
          devShells = {
            default =
              pkgs.mkShell.override
                {
                }
                {
                  packages =
                    with pkgs;
                    global-packages
                    ++ [
                      prefetch-npm-deps

                      (vscode-with-extensions.override {
                        vscode = vscodium;
                        vscodeExtensions =
                          with vscode-extensions;
                          [
                            bbenoist.nix
                            streetsidesoftware.code-spell-checker
                            vscode-extensions.rust-lang.rust-analyzer
                            vscode-extensions.dbaeumer.vscode-eslint
                            vscode-extensions.esbenp.prettier-vscode
                            vscode-extensions.rust-lang.rust-analyzer
                            vscode-extensions.ms-azuretools.vscode-docker
                            vscode-extensions.ms-vscode.makefile-tools
                            vscode-extensions.sswg.swift-lang
                          ]
                          ++ vscode-utils.extensionsFromVscodeMarketplace [
                            # {
                            #   name = "swift-lang";
                            #   publisher = "sswg";
                            #   version = "1.10.4";
                            #   sha256 = "sha256-5NrWBuaNdDNF0ON0HUwdwPFsRO3Hfe0UW4AooJbjiA0=";
                            # }
                          ];
                      })
                    ]
                    ++ lib.optionals stdenv.isLinux [
                      pkgs.projectcenter
                      pkgs.podman
                    ];
                  DONT_PROMPT_WSL_INSTALL = true; # to supress warnings issued by vscode on wsl
                };
          };

          packages = {
            backend = backend;
            default = backend;
          };

          formatter = pkgs.nixfmt-tree;
        }
      );
}
