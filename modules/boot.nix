{ lib, pkgs, ... }:

{
  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    consoleLogLevel = lib.mkDefault 5;

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

  # Wifi driver doesn't support custom MAC addresses.
  networking.networkmanager.wifi.scanRandMacAddress = lib.mkDefault false;
  networking.networkmanager.wifi.macAddress = lib.mkDefault "preserve";

  hardware = {
    enableRedistributableFirmware = lib.mkDefault true;
    firmware = with pkgs; [
      esos-elf-firmware
      orangepi-xunlong-firmware
    ];
    deviceTree.name = "ky/x1_orangepi-rv2.dtb";
  };
}
