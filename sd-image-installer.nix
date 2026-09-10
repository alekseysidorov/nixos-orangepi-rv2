{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/profiles/installation-device.nix")
    (modulesPath + "/installer/sd-card/sd-image.nix")
  ];

  boot = {
    loader.grub.enable = false;
    loader = {
      generic-extlinux-compatible.enable = true;
    };

    kernelPackages = pkgs.linuxPackages_testing;
    supportedFilesystems = {
      zfs = lib.mkForce false;
      bcachefs = lib.mkForce false;
    };

    consoleLogLevel = lib.mkDefault 7;

    kernelParams = [
      "console=tty1"
      "console=ttyS0,115200"
      "earlycon=sbi"
      "boot.shell_on_fail"
    ];

    # TODO updage curated list of needed modules.
    initrd.availableKernelModules = [
    ];
  };

  system.stateVersion = lib.mkDefault lib.trivial.release;

  sdImage = {
    populateFirmwareCommands = "";
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
