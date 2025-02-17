# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, writeScript, writeText }:

let
  inherit (config.build) installationDir extraProotOptions;
  fakeProcStat = writeText "fakeProcStat" ''
    btime 0
  '';
  fakeProcUptime = writeText "fakeProcUptime" ''
    0.00 0.00
  '';
in

writeScript "nix-login" ''
  #!/data/data/com.termux/files/usr/bin/bash

  # This file is generated by Nix-on-Termux. DO NOT EDIT.
  set -eu -o pipefail

  if [[ -d "/nix" ]]; then
      echo "IN_PROOT_NIX is set. Exiting script."
      exit 1
  fi

  unset LD_LIBRARY_PATH
  unset LD_PRELOAD

  export GC_NPROCS=4
  export IN_PROOT_NIX=1

  export USER="${config.user.userName}"
  export HOME="${config.user.home}"
  export PROOT_TMP_DIR=${installationDir}/tmp
  export PROOT_L2S_DIR=${installationDir}/.l2s

  if test -e ${installationDir}/lib/.login-inner.new; then
    echo "Installing new login-inner..."
    /system/bin/mv ${installationDir}/lib/.login-inner.new ${installationDir}/lib/nix-login-inner
  fi

  if [ ! -r /proc/stat ] && [ -e ${installationDir}${fakeProcStat} ]; then
    BIND_PROC_STAT="-b ${installationDir}${fakeProcStat}:/proc/stat"
  else
    BIND_PROC_STAT=""
  fi

  if [ ! -r /proc/uptime ] && [ -e ${installationDir}${fakeProcUptime} ]; then
    BIND_PROC_UPTIME="-b ${installationDir}${fakeProcUptime}:/proc/uptime"
  else
    BIND_PROC_UPTIME=""
  fi

  exec ${installationDir}/bin/proot \
    -b /dev \
    -b /dev/urandom:/dev/random \
    -b /sys \
    -b ${installationDir}/nix:/nix \
    -b ${installationDir}/var:/var \
    -b ${installationDir}/run:/run \
    -b ${installationDir}/etc:/etc! \
    -b ${installationDir}/tmp:/tmp \
    -b ${installationDir}:/usr \
    -b ${installationDir}/dev/shm:/dev/shm \
    $BIND_PROC_STAT \
    $BIND_PROC_UPTIME \
    --kill-on-exit \
    --link2symlink \
    --sysvipc \
    ${builtins.concatStringsSep " " extraProotOptions} \
    ${installationDir}/bin/bash ${installationDir}/lib/nix-login-inner "$@"
''
