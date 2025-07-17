{ ... }:

{
  nix.settings = {
    # Enable commonly used experimental features.
    experimental-features = [ "nix-command" "flakes" ];
    # Add more caches for faster builds and package retrieval.
    substituters = [
      "https://cache.nichi.co"
      "https://cache.ztier.in"
    ];
    trusted-public-keys = [
      "hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk="
      "cache.ztier.link-1:3P5j2ZB9dNgFFFVkCQWT3mh0E+S3rIWtZvoql64UaXM="
    ];
  };
}
