{
  description = "NixOS installer for Orange Pi RV2";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Nix configuration is passed via CLI arguments
  # to avoid security and trust issues
  outputs =
    {
      self,
      flake-parts,
      ...
    }@inputs:
    let
      localOverlay = import ./pkgs;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Declared systems that your flake supports. These will be enumerated in perSystem
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        {
          config,
          system,
          ...
        }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              localOverlay
            ];
          };
        in
        {
          # Use the common overlay in all per-system modules.
          _module.args.pkgs = pkgs;

          # Expose build artifacts and project commands through `nix build` / `nix run`.
          packages = {
            sd-image-installer =
              (pkgs.nixos {
                imports = [
                  ./sd-image-installer.nix
                ];
              }).config.system.build.sdImage;

            flash-sd-image = pkgs.makeFlashCommand { sdImage = config.packages.sd-image-installer; };
          };

          checks = config.packages // {
            # Curated list of cross-compiled packages.
            inherit (pkgs.pkgsCross.riscv64)
              fish
              nftables
              tcpdump
              ethtool
              nmap
              nushell
              git
              tmux
              vim-full
              ;
            amneziawg = pkgs.linuxPackages_testing.amneziawg;
          };

          # Share formatting rules between `nix fmt` and CI.
          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt = {
                enable = true;
                package = pkgs.nixfmt-rs;
              };
              taplo.enable = true;
            };
          };
        };
    };
}
