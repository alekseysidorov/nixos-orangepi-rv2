{ stdenv
, fetchFromGitHub
, lib
}:

stdenv.mkDerivation {
  pname = "orangepi-firmware";
  version = "unstable-2025-03-19"; # updated to last commit date

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

    # Create symlinks for Orange Pi 5 specific firmware names
    mkdir -p $out/lib/firmware/brcm
    ln -sf ../SYN43711A0.hcd $out/lib/firmware/brcm/SYN43711A0.hcd
    ln -sf ../SYN43711A0.hcd $out/lib/firmware/brcm/BCM.xunlong,orangepi-5-max.hcd
    ln -sf ../SYN43711A0.hcd $out/lib/firmware/brcm/BCM.xunlong,orangepi-5-ultra.hcd

    runHook postInstall
  '';

  meta = with lib; {
    description = "All Orange Pi specific firmware files from orangepi-xunlong/firmware";
    homepage = "https://github.com/orangepi-xunlong/firmware";
    license = licenses.unfreeRedistributable;

    platforms = platforms.linux;
    maintainers = [ maintainers.alekseysidorov ];
  };
}
