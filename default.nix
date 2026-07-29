# This file defines an overlay for NixOS
# When imported, it extends nixpkgs with the packages from this repository
final: prev:
{
  # Firmware packages
  esos-elf-firmware = final.callPackage ./pkgs/firmware/esos-elf-firmware.nix { };
  orangepi-firmware = final.callPackage ./pkgs/firmware/orangepi-firmware.nix { };
  # Kernel packages
  linux-orangepi-ky = final.callPackage ./pkgs/linux/linux-orangepi-ky.nix { };
  linuxPackages_orangepi_ky = final.linuxPackagesFor final.linux-orangepi-ky;
  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877
  makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

  # Temporary fix: xtask (used for doc generation) is built for the build platform
  # but pkg-config returns the target's pcre2 during cross-compilation, causing
  # linker errors. Disable docs when cross-compiling.
  fish = prev.fish.overrideAttrs (old: {
    cmakeFlags =
      old.cmakeFlags
      ++ final.lib.optionals (final.stdenv.hostPlatform != final.stdenv.buildPlatform) [
        (final.lib.cmakeBool "WITH_DOCS" false)
      ];
  });
}
