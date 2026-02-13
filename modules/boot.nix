{ lib, pkgs, ... }:

{
  # Some common tweaks for nix packages
  nixpkgs = {
    overlays = [ (import ./..) ];
  };

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    consoleLogLevel = lib.mkDefault 7;

    kernelParams = [
      "console=tty0"
      "console=ttyS0,115200"
      "earlycon=sbi"
      "boot.shell_on_fail"
    ];

    kernelPackages = pkgs.linuxPackages_orangepi_ky;
    kernelModules = [ "bcmdhd" ]; # wifi
    blacklistedKernelModules = [ "onboard_usb_hub" ]; # breaks usb boot

    initrd = {
      availableKernelModules = [
        "dw_mmc-starfive"
        "motorcomm"
        "dwmac-starfive"
        "cdns3-starfive"
        "jh7110-trng"
        "phy-jh7110-usb"
        "clk-starfive-jh7110-aon"
        "clk-starfive-jh7110-stg"
        "clk-starfive-jh7110-vout"
        "clk-starfive-jh7110-isp"
        "clk-starfive-jh7100-audio"
        "phy-jh7110-pcie"
        "pcie-starfive"
        "nvme"
      ];
      extraFirmwarePaths = [ "esos.elf" ];
    };

    supportedFilesystems.zfs = lib.mkForce false;
  };

  # Wifi driver doesn't support custom MAC addresses.
  networking.networkmanager.wifi.scanRandMacAddress = lib.mkDefault false;
  networking.networkmanager.wifi.macAddress = lib.mkDefault "preserve";

  hardware = {
    enableRedistributableFirmware = lib.mkDefault true;
    firmware = with pkgs; [
      esos-elf-firmware
      orangepi-firmware
    ];
    deviceTree.name = "ky/x1_orangepi-rv2.dtb";
  };
}
