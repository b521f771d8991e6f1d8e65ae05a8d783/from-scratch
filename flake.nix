# for good documentation, see here: https://nixos.org/manual/nixpkgs/stable/

{
  inputs = {
    nixpkgs.url = "github:b521f771d8991e6f1d8e65ae05a8d783/nixpkgs/stable";
    flake-utils.url = "github:b521f771d8991e6f1d8e65ae05a8d783/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
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
              cargo
              rustc
              lld
              wasm-pack
              wasm-bindgen-cli_0_2_100
              bacon
              nodejs
              python3
            ]
            ++ lib.optionals pkgs.stdenv.isLinux [
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
              cp -r ${npm-deps}/node_modules .
              chmod -R 777 node_modules # to prevent Error: EACCES: permission denied, mkdir '/build/s4bnqnz1prnhv383fpn2hqm29m7ifn3g-source/node_modules/react-native-css-interop/.cache'
              make all
            '';

            checkPhase = "make test";

            installPhase = ''
              mkdir -p $out
              DESTDIR=$out make install
            '';
          };

          docker-image = pkgs.dockerTools.buildLayeredImage {
            name = backend.name;

            config = {
              EntryPoint = [ "${backend}/bin/backend" ];
            };
          };
        in
        {
          packages = {
            backend = backend;
            default = backend;
            docker-image = docker-image;
          };

          formatter = pkgs.nixfmt-tree;
        }
      );

  #templates = {
  #  defaultTemplate = {
  #    path = ./.;
  #    description = "A simple, very opinionated template for all sorts of AI projects!";
  #    welcomeText = ''
  #      # Getting Started
  #      - run `nix develop` to enter the development environment
  #      - run `pnpm install` to install the packaged
  #      - run `pnpm start` to open a live reloading website
  #    '';
  #  };
  #};
}
