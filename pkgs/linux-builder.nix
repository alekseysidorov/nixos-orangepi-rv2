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
        # Use the cross package set as the guest package universe. Without
        # this, qemu-vm sees the evaluator's x86_64 package set and selects
        # qemu-system-x86_64 even though hostPlatform is RISC-V.
        nixpkgs.pkgs = pkgs.pkgsCross.riscv64;
        nixpkgs.buildPlatform = system;
        nixpkgs.hostPlatform = hostPlatform;

        # QEMU runs on the evaluator/VM host, not inside the RISC-V guest.
        # Keep its package native to the build platform instead of
        # cross-compiling qemu itself for RISC-V.
        virtualisation.host.pkgs = pkgs;

        # This is a guest image, not a bootable physical installation.
        virtualisation.useBootLoader = false;
        boot.loader.grub.enable = false;
      }
    ]
    ++ extraModules;
  };
in
# Keep the upstream VM derivation and add the small public API needed by
# callers that run this builder outside nix-darwin. `nixosConfiguration`
# exposes the evaluated guest configuration, while `run-builder` is the
# launch wrapper from nix-builder-vm (it prepares its SSH-key directory and
# runtime environment before starting QEMU).
#
# The `macos-builder-installer` name is inherited from nixpkgs: this profile
# was originally introduced for macOS's Linux builder, but the contained
# `run-builder` wrapper is platform-neutral and is also correct on Linux.
configuration.config.system.build.vm.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    nixosConfiguration = configuration;
    run-builder = configuration.config.system.build.macos-builder-installer.passthru.run-builder;
  };
})
