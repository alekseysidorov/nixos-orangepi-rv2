# This file defines an overlay for NixOS
# When imported, it extends nixpkgs with the packages from this repository
final: prev: {
  # Firmware packages
  esos-elf-firmware = final.callPackage ./pkgs/firmware/esos-elf-firmware.nix { };
  orangepi-xunlong-firmware = final.callPackage ./pkgs/firmware/orangepi-xunlong-firmware.nix { };

  # Kernel packages
  linux-orangepi-ky = final.callPackage ./pkgs/linux/linux-orangepi-ky.nix { };
  linuxPackages_orangepi_ky = final.linuxPackagesFor final.linux-orangepi-ky;

  # Mesa override to include PowerVR (imagination) driver
  mesa = prev.mesa.override {
    vulkanDrivers = prev.mesa.vulkanDrivers ++ [ "imagination-experimental" ];
  };

  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877
  makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
}
