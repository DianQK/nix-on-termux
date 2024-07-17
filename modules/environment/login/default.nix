# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, targetSystem, ... }:

with lib;

let
  cfg = config.environment.files;

  nixLogin = pkgs.callPackage ./login.nix { inherit config; };

  loginInner = pkgs.callPackage ./login-inner.nix {
    inherit config targetSystem;
  };
in

{

  ###### interface

  options = {

    environment.files = {
      nixLogin = mkOption {
        type = types.package;
        readOnly = true;
        internal = true;
        description = "Login script.";
      };

      loginInner = mkOption {
        type = types.package;
        readOnly = true;
        internal = true;
        description = "Login-inner script.";
      };
    };

  };


  ###### implementation

  config = {

    build.activation = {
      installNixLogin = ''
        if ! diff /usr/bin/nix-login ${nixLogin} > /dev/null; then
          $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /bin
          $DRY_RUN_CMD cp $VERBOSE_ARG ${nixLogin} /usr/bin/.login.tmp
          $DRY_RUN_CMD chmod $VERBOSE_ARG u+w /usr/bin/.login.tmp
          $DRY_RUN_CMD mv $VERBOSE_ARG /usr/bin/.login.tmp /usr/bin/nix-login
        fi
      '';

      installLoginInner = ''
        if (test -e /usr/lib/.login-inner.new && ! diff /usr/lib/.login-inner.new ${loginInner} > /dev/null) || \
            (! test -e /usr/lib/.login-inner.new && ! diff /usr/lib/login-inner ${loginInner} > /dev/null); then
          $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /usr/lib
          $DRY_RUN_CMD cp $VERBOSE_ARG ${loginInner} /usr/lib/.login-inner.tmp
          $DRY_RUN_CMD chmod $VERBOSE_ARG u+w /usr/lib/.login-inner.tmp
          $DRY_RUN_CMD mv $VERBOSE_ARG /usr/lib/.login-inner.tmp /usr/lib/.login-inner.new
        fi
      '';
    };

    environment.files = {
      inherit nixLogin loginInner;
    };

  };

}
