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

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.consoleLogLevel = lib.mkDefault 7;

  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0,115200"
    "earlycon=sbi"
    "boot.shell_on_fail"
  ];

  boot.kernelPackages = pkgs.linuxPackages_orangepi_ky;

  boot.kernelModules = [ "bcmdhd" ]; # wifi
  boot.blacklistedKernelModules = [ "onboard_usb_hub" ]; # breaks usb boot

  boot.initrd.availableKernelModules = [ "nvme" ];

  boot.initrd.extraFirmwarePaths = [ "esos.elf" ];

  hardware.firmware = [ pkgs.esos-elf-firmware pkgs.ap6256-firmware ];

  hardware.deviceTree.name = "ky/x1_orangepi-rv2.dtb";

  nixpkgs.overlays = [
    (self: super: {
      # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });

      esos-elf-firmware = self.callPackage ./esos-elf-firmware.nix { };

      ap6256-firmware = self.callPackage ./ap6256-firmware.nix { };

      linuxPackages_orangepi_ky = self.linuxPackagesFor (self.callPackage ./linux-orangepi-ky.nix { });
    })
  ];

  system.stateVersion = lib.mkDefault lib.trivial.release;

  sdImage = {
    populateFirmwareCommands = "";
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
