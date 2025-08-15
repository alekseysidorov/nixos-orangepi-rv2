# This file defines an overlay for NixOS
# When imported, it extends nixpkgs with the packages from this repository
final: prev:
let
  dontCheck = drv: drv.overrideAttrs (old: {
    doCheck = false;
  });
  dontInstallCheck = drv: drv.overrideAttrs (old: {
    doInstallCheck = false;
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

  # Utilities to create SD images.
  sdImageUtils = {
    makeImage = configuration:
      let
        sdImage = (prev.nixos {
          imports = [
            configuration
          ];
        }).config.system.build.sdImage;
      in
      prev.pkgsBuildBuild.stdenv.mkDerivation {
        name = "sd-image-orangepi-rv2.img.zst";
        version = "1.0.0";
        src = sdImage;

        phases = [ "installPhase" ];
        noAuditTmpdir = true;
        preferLocalBuild = true;

        installPhase = "ln -s $src/sd-image/*.img.zst $out";
      };
    # Utilites to flash SD images to devices.
    makeFlashCommand = sdImage:
      prev.writeShellScriptBin "flash-sd-image-cross" ''
        #!/${prev.pkgsBuildBuild.runtimeShell}
        set -euo pipefail
        "${prev.pkgsBuildBuild.caligula}/bin/caligula" burn -z zst -s none "${sdImage}"
      '';
  };

  # Fixes for packages
  git = dontInstallCheck prev.git;
  nix = dontCheck prev.nix;

}
