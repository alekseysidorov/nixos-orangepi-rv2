# treefmt.nix
{ ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;
  programs.beautysh.enable = true;
  programs.deno.enable = true;
}
