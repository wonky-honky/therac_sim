{ lib, llvmPackages_18, cmake, pkgs }:

llvmPackages_18.libcxxStdenv.mkDerivation rec {
  pname = "therac_sim";
  version = "0.1.0";

  src = ./.;
  stdenv = llvmPackages_18.libcxxStdenv;
  nativeBuildInputs = [ cmake ];
  buildInputs = with pkgs; [

    llvmPackages_18.bintools # why the fuck is this not in stdenv but other shit is
    #    llvmPackages_18.clang
    #    llvmPackages_18.clang-tools

    cmake
    cmakeCurses
    ninja
    python3
    git
    # Development time dependencies
    #    gtest
    vulkan-validation-layers
    # Build time and Run time dependencies
    vulkan-loader
    vulkan-headers
    vulkan-tools
    pkg-config
    xorg.libX11
    libdrm
    libxkbcommon
    xorg.libXext
    xorg.libXv
    xorg.libXrandr
    xorg.libxcb
    zlib
    libuuid
    wayland
    pulseaudio
  ];
  cmakeFlags = [ "-DCMAKE_BUILD_TYPE=Release" ];

  meta = with lib; {
    homepage = "https://github.com/pillowtrucker/retarded_sisyphus";
    description = ''
      Fourth rewrite";
    '';
    license = licenses.agpl3Plus;
    platforms = with platforms; linux ++ darwin;
    maintainers = [ maintainers.breakds ];
  };
}
