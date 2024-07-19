# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ bash, coreutils, lib, nix, runCommand }:

runCommand
  "nix-on-termux"
{
  preferLocalBuild = true;
  allowSubstitutes = false;
}
  ''
    install -D -m755  ${./nix-on-droid.sh} $out/bin/nix-on-termux

    substituteInPlace $out/bin/nix-on-termux \
      --subst-var-by bash "${bash}" \
      --subst-var-by coreutils "${coreutils}" \
      --subst-var-by nix "${nix}"
  ''
