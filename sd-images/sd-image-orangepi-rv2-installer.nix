{ config
, lib
, pkgs
, modulesPath
, ...
}:
{
  imports = [
    (modulesPath + "/profiles/base.nix")
    (modulesPath + "/profiles/installation-device.nix")
    (modulesPath + "/installer/sd-card/sd-image.nix")
  ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    consoleLogLevel = lib.mkDefault 6;

    kernelParams = [
      "console=tty1"
      "console=ttyS0,115200"
      "earlycon=sbi"
      "boot.shell_on_fail"
    ];

    kernelPackages = pkgs.linuxPackages_orangepi_ky;
    kernelModules = [ "bcmdhd" ]; # wifi
    blacklistedKernelModules = [ "onboard_usb_hub" ]; # breaks usb boot

    initrd = {
      availableKernelModules = [ "nvme" ];
      extraFirmwarePaths = [ "esos.elf" ];
    };
  };

  hardware.firmware = with pkgs; [ esos-elf-firmware ap6256-firmware ];
  hardware.deviceTree.name = "ky/x1_orangepi-rv2.dtb";

  # Enable installation of redistributable firmware packages
  hardware.enableRedistributableFirmware = true;

  system.stateVersion = lib.mkDefault lib.trivial.release;

  networking.networkmanager = {
    enable = true;
    plugins = lib.mkForce [ ]; # Disable all plugins
  };
  networking.wireless.enable = false;

  sdImage = {
    populateFirmwareCommands = "";
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
