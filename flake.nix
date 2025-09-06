# for good documentation, see here: https://nixos.org/manual/nixpkgs/stable/

{
  inputs = {
    nixpkgs.url = "github:b521f771d8991e6f1d8e65ae05a8d783/nixpkgs";
    flake-utils.url = "github:b521f771d8991e6f1d8e65ae05a8d783/flake-utils";

    rust-overlay = {
      url = "github:b521f771d8991e6f1d8e65ae05a8d783/rust-overlay";
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
              git
              zsh
              gnumake
              pkg-config
              cmake
              ninja
              jq # tools
              clang-tools
              rustToolchain
              wasm-pack
              wasm-bindgen-cli
              bacon
              nodejs
              python3
            ]
            ++ lib.optionals pkgs.stdenv.isLinux [ 
              # do not add rpm and dpkg here so that they are not built - we do not need them
              swift
              swiftpm
              clang 
              gobjc
              gnustep-base-gcc
              gnustep-gui-gcc
              gnustep-make-gcc
              pkg-config
            ]
            ++ lib.optionals stdenv.isDarwin [
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
              cp -r node_modules $out
            '';

            fixupPhase = ":";
            checkPhase = ":";
          };

          environment = {
            VARIANT = "release";
            CC = if pkgs.stdenv.isLinux then "${pkgs.gobjc}/bin/gcc" else "${pkgs.clang}/bin/clang";
            CXX = if pkgs.stdenv.isLinux then "${pkgs.gobjc}/bin/g++" else "${pkgs.clang}/bin/clang++";
            OBJC = if pkgs.stdenv.isLinux then "${pkgs.gobjc}/bin/gcc" else "${pkgs.clang}/bin/clang";
            OBJCXX = if pkgs.stdenv.isLinux then "${pkgs.gobjc}/bin/g++" else "${pkgs.clang}/bin/clang";

            OBJCFLAGS =
              if pkgs.stdenv.isLinux then
                "-isystem${pkgs.gnustep-gui-gcc}/include -isystem${pkgs.gnustep-base-gcc.dev}/include"
              else
                "";
            OBJCXXFLAGS =
              if pkgs.stdenv.isLinux then
                "-isystem${pkgs.gnustep-gui-gcc}/include -isystem${pkgs.gnustep-base-gcc.dev}/include"
              else
                "";
            LDFLAGS =
              if pkgs.stdenv.isLinux then
                "-L${pkgs.gnustep-gui-gcc}/lib -L${pkgs.gnustep-base-gcc.lib}/lib -lgnustep-gui -lgnustep-base -lm"
              else
                "";

            CPLUS_INCLUDE_PATH =
              if pkgs.stdenv.isDarwin then
                "${pkgs.libcxx.dev}/include/c++/v1"
                else
                  "";
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
              cp -r ${npm-deps}/node_modules .
              chmod -R 777 node_modules # to prevent Error: EACCES: permission denied, mkdir '/build/s4bnqnz1prnhv383fpn2hqm29m7ifn3g-source/node_modules/react-native-css-interop/.cache'
              make rootfs
            '';

            checkPhase = "make test";

            installPhase = ''
              mkdir -p $out
              cp -r output/rootfs/* $out
              chmod +x $out/bin/* #  TODO remove this hack
            '';
          };

          # https://nix.dev/tutorials/nixos/building-and-running-docker-images.html
          # https://ryantm.github.io/nixpkgs/builders/images/dockertools/
          # https://nixos.org/manual/nixpkgs/stable/#ssec-pkgs-dockerTools-buildLayeredImage-examples
          docker-image = pkgs.dockerTools.buildLayeredImage {
            name = backend.name;
            contents = [ backend ];

            config = {
                Cmd = [ "${backend}/bin/backend" ];
            };
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
            docker-image = docker-image;
          };

          formatter = pkgs.nixfmt-tree;
        }
      );
}
