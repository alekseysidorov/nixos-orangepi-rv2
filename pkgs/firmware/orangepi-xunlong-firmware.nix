{ stdenv
, fetchFromGitHub
, lib
}:

stdenv.mkDerivation {
  pname = "orangepi-xunlong-firmware";
  version = "master-2025-03-19"; # updated to last commit date

  src = fetchFromGitHub {
    owner = "orangepi-xunlong";
    repo = "firmware";
    rev = "master";
    sha256 = "sha256-v+4dv4U1vIF0kNCzbX8iZsGNkKWUDWdMmQOwuoFKWRo=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/firmware
    cp -a * $out/lib/firmware/
    rm -f $out/lib/firmware/README.md

    # Copy CLM file for 43456 from brcmfmac43455.
    cp $out/lib/firmware/brcm/brcmfmac43455-sdio.clm_blob $out/lib/firmware/clm_bcm43456c5_ag.blob
    cp $out/lib/firmware/brcm/brcmfmac43455-sdio.clm_blob $out/lib/firmware/brcm/brcmfmac43456-sdio.clm_blob

    runHook postInstall
  '';

  meta = with lib; {
    description = "All Orange Pi specific firmware files from orangepi-xunlong/firmware";
    homepage = "https://github.com/orangepi-xunlong/firmware";
    license = licenses.unfreeRedistributable; # most firmwares are not open source
    platforms = platforms.linux;
    maintainers = [ maintainers.alekseysidorov ];
  };
}
