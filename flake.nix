{
  description = "A template for Nix based C++ project setup.";

  inputs = {
    # Pointing to the current stable release of nixpkgs. You can
    # customize this to point to an older version or unstable if you
    # like everything shining.
    #
    # E.g.
    #
    # nixpkgs.url = "github:NixOS/nixpkgs/unstable";

    nixpkgs.url = "github:NixOS/nixpkgs/master";

    utils.url = "github:numtide/flake-utils";

  };

  outputs = { self, nixpkgs, ... }@inputs:
    inputs.utils.lib.eachSystem [
      # Add the system/architecture you would like to support here. Note that not
      # all packages in the official nixpkgs support all platforms.
      "x86_64-linux"
      "i686-linux"
      "aarch64-linux"
      "x86_64-darwin"
    ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;

          # Add overlays here if you need to override the nixpkgs
          # official packages.
          overlays = [
            (final: prev: { llvmPackages = prev.llvmPackages_18; })

          ];

          # Uncomment this if you need unfree software (e.g. cuda) for
          # your project.
          #
          config.allowUnfree = true;
        };
      in {
        devShells.default = pkgs.llvmPackages_18.libcxxStdenv.mkDerivation

          rec {
            # Update the name to something that suites your project.
            name = "wonkyhonky_therac_sim_shell";
            stdenv = pkgs.llvmPackages_18.libcxxStdenv;
            packages = with pkgs; [
              haskell.compiler.ghc98
              # Development Tools
              #            llvmPackages_18.clang
              (clang-tools.override { llvmPackages = llvmPackages_18; })
              llvmPackages_18.bintools
              python3
              git
              #            llvmPackages_18.libraries.libcxx
              llvmPackages_18.libcxx
              llvmPackages_18.compiler-rt
              cmake
              cmakeCurses
              ninja
              # Development time dependencies
              #            gtest
              # Build time and Run time dependencies
            ];
            nativeBuildInputs = packages;

          };

        packages.default = pkgs.callPackage ./default.nix {

        };
      });
}
