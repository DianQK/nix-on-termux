{ callPackage
, lib
, stdenv
, libglvnd
, fetchurl
, fetchpatch
, vulkan-loader
, nixos
, libxml2
, testers
, hello
, mesa
, llvmPackages_18
,
}:
with lib; let
  commit = "23ef65ea3b859368c6ba4fcc66ba4d251b3f5afd";
in
(mesa.override {
  galliumDrivers = [ "llvmpipe" "zink" ];
  vulkanDrivers = [ "freedreno" ];
  eglPlatforms = [ "x11" ];
  llvmPackages = llvmPackages_18;
}).overrideAttrs (oldAttrs: rec {
  pname = "mesa-termux";
  version = "24.2.0-unstable-2024-07-19";

  src = fetchurl {
    url = "https://gitlab.freedesktop.org/mesa/mesa/-/archive/${commit}/mesa-${commit}.tar.gz";
    hash = "sha256-o4vY9tcZMlJHXJMMQ16EAU1FXkAHSq33+Ev1Asi1g2E=";
  };
  patches = oldAttrs.patches ++ [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/MastaG/mesa-turnip-ppa/1a69eb6d09ba1eca2f22b4760d68e27e298102d5/turnip-patches/fix-for-anon-file.patch";
      hash = "sha256-QE0qyBjoCBBhZytHX9FwUJ67XCg+zntY2or6aBq8eNQ=";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/MastaG/mesa-turnip-ppa/1a69eb6d09ba1eca2f22b4760d68e27e298102d5/turnip-patches/fix-for-getprogname.patch";
      hash = "sha256-av//Yavq1Re9Fk0psm7kiWZzpDJEdG3jxV0yjcBbYhU=";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/MastaG/mesa-turnip-ppa/1a69eb6d09ba1eca2f22b4760d68e27e298102d5/turnip-patches/zink_fixes.patch";
      hash = "sha256-ZxRgw/Q+krS4lKgvhOUS0I5xVQOrOlh/QTwbWfiY+n8=";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/MastaG/mesa-turnip-ppa/1a69eb6d09ba1eca2f22b4760d68e27e298102d5/turnip-patches/dri3.patch";
      hash = "sha256-0xR36Nqre2tkrJeUnu7F7/GIS7QTS3cy2K6xvyd3svI=";
    })
  ];
  buildInputs = oldAttrs.buildInputs ++ [
    libxml2
  ];
  mesonFlags = [
    "-Dgbm=disabled"
    "-Dopengl=true"
    "-Degl=enabled"
    "-Degl-native-platform=x11"
    "-Dgles1=disabled"
    "-Dgles2=enabled"
    "-Dglx=dri"
    "-Dllvm=enabled"
    "-Dshared-llvm=disabled"
    "-Dplatforms=x11"
    "-Dgallium-drivers=llvmpipe,zink"
    "-Dxmlconfig=disabled"
    "-Dvulkan-drivers=freedreno"
    "-Dfreedreno-kmds=msm,kgsl"
    "-Dgallium-vdpau=disabled"
    "-Dgallium-va=disabled"
    "-Dgallium-xa=disabled"
    "-Dintel-rt=disabled"
    "-Ddri3=enabled"
    "-Dosmesa=false"
    "-Dvalgrind=disabled"
    "-Dlibunwind=disabled"

    "--sysconfdir=/etc"
    "--datadir=${placeholder "drivers"}/share"
    # Make sure we know where to find all the drivers
    (lib.mesonOption "dri-drivers-path" "${placeholder "drivers"}/lib/dri")
    (lib.mesonOption "vdpau-libs-path" "${placeholder "drivers"}/lib/vdpau")
    (lib.mesonOption "omx-libs-path" "${placeholder "drivers"}/lib/bellagio")
    (lib.mesonOption "va-libs-path" "${placeholder "drivers"}/lib/dri")
    (lib.mesonOption "d3d-drivers-path" "${placeholder "drivers"}/lib/d3d")
    # Enable glvnd for dynamic libGL dispatch
    (lib.mesonEnable "glvnd" true)

    (lib.mesonBool "gallium-nine" true) # Direct3D in Wine
    (lib.mesonBool "osmesa" true) # used by wine

    (lib.mesonOption "clang-libdir" "${llvmPackages_18.clang-unwrapped.lib}/lib")
    # meson auto_features enables this, but we do not want it
    "-Dandroid-libbacktrace=disabled"
    "-Dmicrosoft-clc=disabled"
  ];

  postFixup = ''
    # set the default search path for DRI drivers; used e.g. by X server
    for pc in lib/pkgconfig/{dri,d3d}.pc; do
      [ -f "$dev/$pc" ] && substituteInPlace "$dev/$pc" --replace "$drivers" "${libglvnd.driverLink}"
    done

    # remove pkgconfig files for GL/EGL; they are provided by libGL.
    rm -f $dev/lib/pkgconfig/{gl,egl}.pc

    # Move development files for libraries in $drivers to $driversdev
    mkdir -p $driversdev/include
    mv $dev/include/xa_* $dev/include/d3d* -t $driversdev/include || true
    mkdir -p $driversdev/lib/pkgconfig
    for pc in lib/pkgconfig/{xatracker,d3d}.pc; do
      if [ -f "$dev/$pc" ]; then
        substituteInPlace "$dev/$pc" --replace $out $drivers
        mv $dev/$pc $driversdev/$pc
      fi
    done

    # Don't depend on build python
    patchShebangs --host --update $out/bin/*

    # NAR doesn't support hard links, so convert them to symlinks to save space.
    jdupes --hard-links --link-soft --recurse "$drivers"

    # add RPATH so the drivers can find the moved libgallium and libdricore9
    # moved here to avoid problems with stripping patchelfed files
    for lib in $drivers/lib/*.so* $drivers/lib/*/*.so*; do
      if [[ ! -L "$lib" ]]; then
        patchelf --set-rpath "$(patchelf --print-rpath $lib):$drivers/lib" "$lib"
      fi
    done

    # add RPATH here so Zink can find libvulkan.so
    patchelf --add-rpath ${vulkan-loader}/lib $drivers/lib/dri/libgallium.so
  '';

  outputs = [ "out" "dev" "drivers" "driversdev" "opencl" "osmesa" ];
})
