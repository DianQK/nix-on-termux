{ lib
, stdenv
}:

stdenv.mkDerivation {
  pname = "rish";
  version = "13.5.4";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    substitute ${./rish} $out/bin/rish \
      --subst-var-by rish_shizuku.dex ${./rish_shizuku.dex}
    chmod 0755 $out/bin/rish
  '';

  meta = with lib; {
    homepage = "https://github.com/RikkaApps/Shizuku";
    description = "rish command-line";
    mainProgram = "rish";
    platforms = platforms.linux;
    license = licenses.asl20;
    maintainers = with maintainers; [ DianQK ];
  };
}
