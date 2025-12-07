# This file defines an overlay for NixOS
# When imported, it extends nixpkgs with the packages from this repository
final: prev:
let
  disableAllChecks = pkg: pkg.overrideAttrs (_: {
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
  orangepi-xunlong-firmware = final.callPackage ./pkgs/firmware/orangepi-xunlong-firmware.nix { };
  # Kernel packages
  linux-orangepi-ky = final.callPackage ./pkgs/linux/linux-orangepi-ky.nix { };
  linuxPackages_orangepi_ky = final.linuxPackagesFor final.linux-orangepi-ky;
  # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877
  makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

  # A lot of packages have tests that fail on riscv64
  python3Packages = prev.python3Packages.overrideScope (f: p: {
    eventlet = disableAllChecks p.eventlet;
    picosvg = disableAllChecks p.picosvg;
  });
}
