# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.environment;
in

{

  ###### interface

  options = {

    environment = {
      binSh = mkOption {
        type = types.str;
        readOnly = true;
        description = "Path to <filename>/bin/sh</filename> executable.";
      };

      usrBinEnv = mkOption {
        type = types.str;
        readOnly = true;
        description = "Path to <filename>/usr/bin/env</filename> executable.";
      };
    };

  };


  ###### implementation

  config = {

    build.activationBefore = {
      linkBinSh = ''
        
      '';

      linkUsrBinEnv = ''
       
      '';
    };

    environment = {
      binSh = "${pkgs.bashInteractive}/bin/sh";
      usrBinEnv = "${pkgs.coreutils}/bin/env";
    };

  };

}
