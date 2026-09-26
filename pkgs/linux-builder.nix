{
  lib,
  pkgs,
  system,
  hostPlatform ? "riscv64-linux",
  extraModules ? [ ],
}:

let
  # Keep the guest package universe derived from the requested target instead
  # of selecting a hard-coded pkgsCross alias such as `riscv64`. This keeps
  # `hostPlatform` authoritative when another target is added later.
  guestPkgs = import pkgs.path {
    localSystem = system;
    crossSystem = hostPlatform;
  };

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
        nixpkgs = {
          buildPlatform = system;
          hostPlatform = hostPlatform;
          pkgs = guestPkgs;
        };

        # The builder guest has no hardware to manage. Keep the cross-compiled
        # closure focused on SSH, Nix and the build toolchain.
        networking = {
          modemmanager.enable = false;
          networkmanager.enable = false;
        };
        hardware = {
          bluetooth.enable = false;
          graphics.enable = false;
        };
        services.pipewire.enable = false;

        virtualisation = {
          # QEMU runs on the evaluator/VM host, not inside the RISC-V guest.
          # Keep its package native to the build platform instead of
          # cross-compiling qemu itself for RISC-V.
          host.pkgs = pkgs;
          # The RISC-V `virt` machine exposes virtio devices through MMIO. The
          # qemu-vm default uses legacy `-net nic,model=virtio`, which leaves
          # this guest without a DHCP-capable network interface.
          qemu.networkingOptions = pkgs.lib.mkForce [
            "-device virtio-net-device,netdev=user.0"
            "-netdev user,id=user.0\${QEMU_NET_OPTS:+,$QEMU_NET_OPTS}"
          ];
          # This is a guest image, not a bootable physical installation.
          useBootLoader = false;
          # The guest has its own CA bundle; Host certificate path
          # is not valid inside the RISC-V VM.
          useHostCerts = lib.mkForce false;
        };

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
