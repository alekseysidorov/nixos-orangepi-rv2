# This file defines an overlay for NixOS
# When imported, it extends nixpkgs with the packages from this repository
final: prev: {
  makeFlashCommand = final.callPackage ./makeFlashCommand.nix { };

  linux-builder-riscv64 = final.callPackage ./linux-builder.nix { hostPlatform = "riscv64-linux"; };

  # The Orange Pi image only needs sing-box's VLESS/Reality functionality.
  # Naive outbound pulls Chromium/Cronet into the riscv64 closure and is not
  # currently cross-compilable, while Gwaihir uses the same reduced package.
  sing-box = prev.sing-box.override {
    withNaiveOutbound = false;
  };

  # Temporary fix: xtask (used for doc generation) is built for the build platform
  # but pkg-config returns the target's pcre2 during cross-compilation, causing
  # linker errors. Disable docs when cross-compiling.
  fish = prev.fish.overrideAttrs (old: {
    cmakeFlags =
      old.cmakeFlags
      ++ final.lib.optionals (final.stdenv.hostPlatform != final.stdenv.buildPlatform) [
        (final.lib.cmakeBool "WITH_DOCS" false)
      ];
  });
}
