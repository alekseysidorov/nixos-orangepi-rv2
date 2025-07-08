{ stdenvNoCC
, lib
, fetchurl
, ...
}:
stdenvNoCC.mkDerivation {
  pname = "esos-elf";
  version = "0-unstable-2025-03-12";

  compressFirmware = false;
  dontUnpack = true;
  dontFixup = true;
  dontBuild = true;

  src = fetchurl {
    url = "https://github.com/orangepi-xunlong/orangepi-build/raw/c5b3b1df7029ddb4adb63d63d0f093c24e0180cf/external/packages/bsp/ky/usr/lib/firmware/esos.elf";
    hash = "sha256-58sNeiCzgO4UXsaFENJihfdLcNU3/cGRP/7HrY21y1c=";
  };

  installPhase = ''
    mkdir -p $out/lib/firmware
    cp -r $src $out/lib/firmware/esos.elf
  '';

  meta = {
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = [ "riscv64-linux" ];
  };
}
