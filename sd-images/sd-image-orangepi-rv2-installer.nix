{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/profiles/installation-device.nix")
    (modulesPath + "/installer/sd-card/sd-image.nix")
    ../modules/boot.nix
  ];

  system.stateVersion = lib.mkDefault lib.trivial.release;

  # Network manager more useful than the wpa_supplicant.
  networking.wireless.enable = false;
  networking.networkmanager = {
    enable = true;
    # A lot of plugins are not supported on riscv64. Disable all plugins to avoid errors.
    plugins = lib.mkForce [ ];
  };

  sdImage = {
    populateFirmwareCommands = "";
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
