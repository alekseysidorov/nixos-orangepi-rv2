# This file defines an overlay for NixOS
# When imported, it extends nixpkgs with the packages from this repository
final: prev:
let
  disableAllChecks =
    pkg:
    pkg.overrideAttrs (_: {
      doCheck = false;
      doInstallCheck = false;
      checkPhase = "true"; # replace test command with a no-op stub
      installCheckPhase = "true"; # replace install-time tests with a no-op stub
      pythonImportsCheck = [ ];
    });
in
{
  # Firmware packages
  esos-elf-firmware = final.callPackage ./pkgs/firmware/esos-elf-firmware.nix { };
  orangepi-firmware = final.callPackage ./pkgs/firmware/orangepi-firmware.nix { };
  # Kernel packages
  linux-orangepi-ky = final.callPackage ./pkgs/linux/linux-orangepi-ky.nix { };
  linuxPackages_orangepi_ky = final.linuxPackagesFor final.linux-orangepi-ky;
  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877
  makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

  # A lot of packages have tests that fail on riscv64
  python3Packages = prev.python3Packages.overrideScope (
    f: p: {
      eventlet = disableAllChecks p.eventlet;
      picosvg = disableAllChecks p.picosvg;
    }
  );

  # Workaround for a nixpkgs bug: https://github.com/NixOS/nixpkgs/issues/FIXME
  #
  # libqmi conflates two distinct features under a single `withIntrospection` flag:
  #   1. GObject introspection (g-ir-scanner/compiler) — can work in cross builds
  #      when an emulator (QEMU) is available to run host binaries.
  #   2. API documentation via gi-docgen — requires build-machine `pkg-config`
  #      (i.e. plain `pkg-config`, not the cross-prefixed wrapper) to locate
  #      the gi-docgen package at meson configure time.
  #
  # In a nixpkgs cross build only the cross-prefixed pkg-config is in PATH, so
  # meson fails with:
  #   "Pkg-config for machine build machine not found. Giving up."
  #
  # The upstream fix should split withIntrospection into two parameters:
  #   withIntrospection — keep the current emulatorAvailable condition
  #   withDoc (defaulting to withIntrospection && buildPlatform == hostPlatform)
  #             — gates gi-docgen / gtk_doc only when native pkg-config is present
  #
  # Until that is fixed upstream we force withIntrospection=false for the whole
  # cross-compiled package set, which also disables gtk_doc.
  libqmi = prev.libqmi.override { withIntrospection = false; };
}
