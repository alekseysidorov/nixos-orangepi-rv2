# This file defines an overlay for NixOS
# When imported, it extends nixpkgs with the packages from this repository
final: prev: {
  makeFlashCommand = final.callPackage ./makeFlashCommand.nix { };

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

  # Force remove unsupported bcachefs-tools
  bcachefs-tools = final.hello;
}
