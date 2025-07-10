# This file defines an overlay for NixOS
# When imported, it extends nixpkgs with the packages from this repository
final: prev: {
  # Firmware packages
  esos-elf-firmware = final.callPackage ./pkgs/firmware/esos-elf-firmware.nix { };
  ap6256-firmware = final.callPackage ./pkgs/firmware/ap6256-firmware.nix { };

  # Kernel packages
  linux-orangepi-ky = final.callPackage ./pkgs/linux/linux-orangepi-ky.nix { };
  linuxPackages_orangepi_ky = final.linuxPackagesFor final.linux-orangepi-ky;

  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877
  makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
}
