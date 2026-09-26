{
  stdenv,
  writeShellScriptBin,
  caligula,
  runtimeShell,
  lib,
}:

{ sdImage }:
let
  sdImageArchive = stdenv.mkDerivation {
    name = "sd-image-orangepi-rv2.img.zst";
    version = "1.0.0";
    src = sdImage;

    phases = [ "installPhase" ];
    noAuditTmpdir = true;
    preferLocalBuild = true;

    installPhase = "ln -s $src/sd-image/*.img.zst $out";
  };
in
writeShellScriptBin "flash-sd-image-cross" ''
  #!/${runtimeShell}
  set -euo pipefail
  "${lib.getExe caligula}" burn -z zst -s none "${sdImageArchive}"
''
