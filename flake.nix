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
            (final: prev: {
              inherit (rec {
                llvmPackages_18 = prev.recurseIntoAttrs (prev.callPackage
                  "${inputs.nixpkgs}/pkgs/development/compilers/llvm/18" ({
                    inherit (prev.stdenvAdapters) overrideCC;
                    officialRelease = {
                      version = "18.1.8";
                      sha256 =
                        "sha256-iiZKMRo/WxJaBXct9GdAcAT3cz9d9pnAcO1mmR6oPNE=";
                    };
                    buildLlvmTools = prev.buildPackages.llvmPackages_18.tools;
                    targetLlvmLibraries =
                      prev.targetPackages.llvmPackages_18.libraries or llvmPackages_18.libraries;
                    targetLlvm =
                      prev.targetPackages.llvmPackages_18.llvm or llvmPackages_18.llvm;
                  }));

                clang_18 = llvmPackages_18.clang;
                lld_18 = llvmPackages_18.lld;
                lldb_18 = llvmPackages_18.lldb;
                llvm_18 = llvmPackages_18.llvm;

                clang-tools_18 = prev.callPackage
                  "${inputs.nixpkgs}/pkgs/development/tools/clang-tools" {
                    llvmPackages = llvmPackages_18;
                  };
              })
                llvmPackages_18 clang_18 lld_18 lldb_18 llvm_18 clang-tools_18;

              llvmPackages = final.llvmPackages_18;
            })

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
