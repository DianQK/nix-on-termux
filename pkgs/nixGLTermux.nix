# From https://github.com/nix-community/nixGL/blob/main/nixGL.nix.
{ stdenv
, writeTextFile
, shellcheck
, pcre
, runCommand
, linuxPackages
, fetchurl
, lib
, runtimeShell
, libglvnd
, vulkan-validation-layers
, mesa
, libvdpau-va-gl
, zlib
, libdrm
, xorg
}:

let
  writeExecutable = { name, text }:
    writeTextFile {
      inherit name text;

      executable = true;
      destination = "/bin/${name}";

      checkPhase = ''
        ${shellcheck}/bin/shellcheck "$out/bin/${name}"

        # Check that all the files listed in the output binary exists
        for i in $(${pcre}/bin/pcregrep  -o0 '/nix/store/.*?/[^ ":]+' $out/bin/${name})
        do
          ls $i > /dev/null || (echo "File $i, referenced in $out/bin/${name} does not exists."; exit -1)
        done
      '';
    };

  writeNixGL = name: vadrivers: writeExecutable {
    inherit name;
    # add the 32 bits drivers if needed
    text =
      let
        mesa-drivers = [ mesa.drivers ];
        libvdpau = [ libvdpau-va-gl ];
        glxindirect = runCommand "mesa_glxindirect" { } (
          ''
            mkdir -p $out/lib
            ln -s ${mesa.drivers}/lib/libGLX_mesa.so.0 $out/lib/libGLX_indirect.so.0
          ''
        );
      in
      ''
        #!${runtimeShell}
        export LIBVA_DRIVERS_PATH=${lib.makeSearchPathOutput "out" "lib/dri" (mesa-drivers ++ vadrivers)}
        ${''export __EGL_VENDOR_LIBRARY_FILENAMES=${mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json"''${__EGL_VENDOR_LIBRARY_FILENAMES:+:$__EGL_VENDOR_LIBRARY_FILENAMES}"''
        }
        export LD_LIBRARY_PATH=${lib.makeLibraryPath mesa-drivers}:${lib.makeLibraryPath mesa-drivers}/dri:${lib.makeSearchPathOutput "lib" "lib/vdpau" libvdpau}:${glxindirect}/lib:${lib.makeLibraryPath [libglvnd]}"''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        exec "$@"
      '';
  };
in
{
  nixGLTermuxMesa = writeNixGL "nixGLTermuxMesa" [ ];
}
