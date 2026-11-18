# This file defines an overlay for NixOS
# When imported, it extends nixpkgs with the packages from this repository
final: prev: {
  mkFlashCommand = final.callPackage ./mk-flash-command.nix { };
  # Go generators such as CoreDNS's need the build-platform compiler for
  # runtime/cgo during cross compilation.
  coredns = prev.coredns.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ final.buildPackages.stdenv.cc ];
    preBuild = (old.preBuild or "") + ''
      export PATH=${final.buildPackages.stdenv.cc}/bin:$PATH
    '';
  });
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
  # `go generate` builds a native Go helper during cross compilation. It
  # needs the build-platform compiler available on PATH for runtime/cgo.
  git-lfs = prev.git-lfs.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ final.buildPackages.stdenv.cc ];
    preBuild = (old.preBuild or "") + ''
      export PATH=${final.buildPackages.stdenv.cc}/bin:$PATH
    '';
  });
}
