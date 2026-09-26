{
  callPackage,
  stdenv,
}:

{
  buildPlatform ? stdenv.buildPlatform.system,
  hostPlatform ? "riscv64-linux",
  extraModules ? [ ],
}:
callPackage ./linux-builder.nix {
  system = buildPlatform;
  inherit hostPlatform extraModules;
}
