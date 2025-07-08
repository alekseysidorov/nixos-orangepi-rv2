final: prev: {
  esos-elf-firmware = final.callPackage ./firmware/esos-elf-firmware.nix { };
  ap6256-firmware = final.callPackage ./firmware/ap6256-firmware.nix { };
  linux-orangepi-ky = final.callPackage ./linux/linux-orangepi-ky.nix { };
  linuxPackages_orangepi_ky = final.linuxPackagesFor final.linux-orangepi-ky;
}
