{
  # This file re-exports the overlay and individual packages
  # to make them easily importable from other parts of the project

  # Re-export the overlay function
  overlay ? import ./overlay.nix
, # The nixpkgs to apply the overlay to
  pkgs ? import <nixpkgs> { overlays = [ overlay ]; }
}:

{
  inherit overlay pkgs;

  # Re-export all the packages from the overlay
  inherit (pkgs)
    esos-elf-firmware
    ap6256-firmware
    linux-orangepi-ky
    linuxPackages_orangepi_ky;
}
