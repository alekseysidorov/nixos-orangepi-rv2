{
  description = "NixOS installer for Orange Pi RV2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  # Конфигурация Nix для этого flake
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://cache.ztier.in" # cache from hydra-riscv64 project
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.ztier.link-1:3P5j2ZB9dNgFFFVkCQWT3mh0E+S3rIWtZvoql64UaXM="
    ];
    keep-outputs = true;
    keep-derivations = true;
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "riscv64-linux" ] (system:
      let
        isCross = system != "riscv64-linux";
        localSystem = if isCross then { system = "x86_64-linux"; } else { system = "riscv64-linux"; };
        crossSystem = if isCross then { system = "riscv64-linux"; } else null;

        pkgs = import nixpkgs {
          inherit localSystem;
          crossSystem = crossSystem;
          config = {
            allowUnfree = true;
            # Оптимизации для сборки
            permittedInsecurePackages = [ "openssl-1.1.1w" ];
          };
        };

        lib = pkgs.lib;
      in
      {
        packages = {
          installer = (pkgs.nixos ({
            imports = [
              ./sd-image-orangepi-rv2-installer.nix
            ];

            # Конфигурации специфичные для сборки
            nixpkgs.config.allowUnfree = true;
            nix.settings = {
              max-jobs = "auto";
              cores = 0;
              sandbox = true;
              extra-sandbox-paths = [ "/bin/sh=/bin/sh" ];
              substituters = [ "https://cache.nixos.org" "https://cache.ztier.in" ];
              trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "cache.ztier.link-1:3P5j2ZB9dNgFFFVkCQWT3mh0E+S3rIWtZvoql64UaXM="
              ];
            };
          })).config.system.build.sdImage;

          default = self.packages.${system}.installer;
        };
      }
    );
}
