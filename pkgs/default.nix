# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs
, system
, nixOnDroidChannelURL ? null
, nixpkgsChannelURL ? null
, nixOnDroidFlakeURL ? null
}:

let
  urlOptionValue = url: envVar:
    let
      envValue = builtins.getEnv envVar;
    in
    pkgs.lib.mkIf
      (envValue != "" || url != null)
      (if url == null then envValue else url);

  modules = import ../modules {
    inherit pkgs;
    targetSystem = system;

    isFlake = true;

    config = {

      system.stateVersion = "24.05";

      build = {
        channel = {
          nixpkgs = urlOptionValue nixpkgsChannelURL "NIXPKGS_CHANNEL_URL";
          nix-on-droid = urlOptionValue nixOnDroidChannelURL "NIX_ON_DROID_CHANNEL_URL";
        };

        flake.nix-on-droid = urlOptionValue nixOnDroidFlakeURL "NIX_ON_DROID_FLAKE_URL";
      };
    };
  };

  callPackage = pkgs.lib.callPackageWith (
    pkgs // customPkgs // {
      inherit (modules) config;
      inherit callPackage;
      targetSystem = system;
    }
  );

  customPkgs = {
    rish = callPackage ./rish { };
    # bootstrap = callPackage ./bootstrap.nix { };
    # bootstrapZip = callPackage ./bootstrap-zip.nix { };
    # prootTermux = callPackage ./cross-compiling/proot-termux.nix { };
    # tallocStatic = callPackage ./cross-compiling/talloc-static.nix { };
  };
in

{
  inherit (modules) config;
  inherit customPkgs;
}
