{
  pkgs,
  system,
  hostPlatform ? "riscv64-linux",
  extraModules ? [ ],
}:

let
  configuration = pkgs.nixos {
    imports = [
      (pkgs.path + "/nixos/modules/profiles/nix-builder-vm.nix")
      {
        # Build the RISC-V guest from whichever Linux system evaluates this
        # package. The builder is deliberately target-specific, while its
        # build platform remains the current package system.
        nixpkgs.buildPlatform = system;
        nixpkgs.hostPlatform = hostPlatform;

        # This is a guest image, not a bootable physical installation.
        virtualisation.useBootLoader = false;
        boot.loader.grub.enable = false;
      }
    ]
    ++ extraModules;
  };
in
configuration.config.system.build.vm.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    nixosConfiguration = configuration;
  };
})
