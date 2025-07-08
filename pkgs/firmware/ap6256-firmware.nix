{ stdenvNoCC
, lib
, fetchFromGitHub
,
}:
stdenvNoCC.mkDerivation {
  pname = "ap6256-firmware";
  version = "0-unstable-2025-03-19";

  compressFirmware = false;
  dontFixup = true;
  dontBuild = true;

  src = fetchFromGitHub {
    owner = "orangepi-xunlong";
    repo = "firmware";
    rev = "db5e86200ae592c467c4cfa50ec0c66cbc40b158";
    hash = "sha256-v+4dv4U1vIF0kNCzbX8iZsGNkKWUDWdMmQOwuoFKWRo=";
  };

  installPhase = ''
    install -D -t $out/lib/firmware nvram_ap6256.txt-orangepirv2
    install -D -t $out/lib/firmware fw_bcm43456c5_*.bin
    install -D -t $out/lib/firmware BCM4345C5.hcd

    cd $out/lib/firmware
    ln -s nvram_ap6256.txt-orangepirv2 nvram_ap6256.txt
  '';

  meta = {
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = [ "riscv64-linux" ];
  };
}
