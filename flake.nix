# for good documentation, see here: https://nixos.org/manual/nixpkgs/stable/

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.05";
    flake-utils.url = "github:numtide/flake-utils";
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
              #swift
              #swiftpm
              gnustep-base
              gnustep-make
              gnustep-gui
              gnustep-libobjc
              clang
            ]
            ++ lib.optionals stdenv.isDarwin [
              apple-sdk # clang and swift is included here
            ];

          environment = {
            VARIANT = "release";
            CC = if pkgs.stdenv.isLinux
              then "${pkgs.clang}/bin/clang"
              else "";
            CXX = if pkgs.stdenv.isLinux
              then "${pkgs.clang}/bin/clang++"
              else "";
            OBJC = if pkgs.stdenv.isLinux
              then "${pkgs.clang}/bin/clang"
              else "";
            OBJCXX = if pkgs.stdenv.isLinux
              then "${pkgs.clang}/bin/clang++"
              else "";

            OBJCFLAGS = if pkgs.stdenv.isLinux
              then "-isystem${pkgs.gnustep-gui}/include -isystem${pkgs.gnustep-base.dev}/include -isystem${pkgs.gnustep-libobjc}/include"
              else "";
            OBJCXXFLAGS = if pkgs.stdenv.isLinux
              then "-isystem${pkgs.gnustep-gui}/include -isystem${pkgs.gnustep-base.dev}/include -isystem${pkgs.gnustep-libobjc}/include"
              else "";
            LDFLAGS = if pkgs.stdenv.isLinux
              then "-L${pkgs.gnustep-libobjc}/lib"
              else "";
          };

          backend = pkgs.rustPlatform.buildRustPackage {
            name = "backend";
            src = ./.;
            stdenv = pkgs.clangStdenv;

            cargoLock = {
              lockFile = ./Cargo.lock;
            };

            env = environment;
            HOME = "./home";

            npmDeps = pkgs.importNpmLock { npmRoot = ./.; };

            nativeBuildInputs = global-packages ++ (with pkgs; [
              pkgs.importNpmLock.npmConfigHook
            ]);

            buildPhase = ''
              mkdir -p ${backend.HOME}
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
