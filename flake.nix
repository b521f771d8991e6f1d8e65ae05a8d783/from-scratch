# for good documentation, see here: https://nixos.org/manual/nixpkgs/stable/

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    base-tools.url = "github:b521f771d8991e6f1d8e65ae05a8d783/base-tools";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      base-tools,
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
          };

          globalPackages = base-tools.outputs.global-packages."${system}";

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
              cp -a node_modules $out
            '';

            fixupPhase = ":";
            checkPhase = ":";
          };

          environment = {
            VARIANT = "release";

            CC = "${pkgs.clang}/bin/clang";
            CXX = "${pkgs.clang}/bin/clang++";
            OBJC = "${pkgs.clang}/bin/clang";
            OBJCXX = "${pkgs.clang}/bin/clang++";

            OBJCFLAGS =
              if pkgs.stdenv.isLinux then
                " -isystem${pkgs.gnustep-gui}/include -isystem${pkgs.gnustep-base.dev}/include -isystem${pkgs.gnustep-libobjc}/include"
              else
                "";
            OBJCXXFLAGS = backend.OBJCFLAGS;
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

            nativeBuildInputs = globalPackages;

            HOME = "./home";

            buildPhase = ''
              mkdir -p ${backend.HOME}            
              cp -a ${npm-deps}/node_modules .
              chmod -R 777 node_modules # to prevent Error: EACCES: permission denied, mkdir '/build/s4bnqnz1prnhv383fpn2hqm29m7ifn3g-source/node_modules/react-native-css-interop/.cache'
              make rootfs
            '';

            checkPhase = "make test";

            installPhase = ''
              mkdir -p $out
              cp -a output/rootfs/* $out
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
                    globalPackages
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
