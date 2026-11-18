{
  coredns,
}:

coredns.override {
  externalPlugins = [
    {
      name = "nftsync";
      repo = "github.com/MelsRoughSketch/nftsync";
      version = "ef3e3a0c336fed006f39ecb3d3f53fcf700c3aca";
      position.after = "cache";
    }
  ];

  # Keep the package pinned to the vendored modules for the followed nixpkgs.
  vendorHash = "sha256-aYYWg+CqjQ+wsopucderNFMosFpMrLfYX+dYJJH+0b8=";
}
