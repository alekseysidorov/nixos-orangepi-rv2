{ pkgs, ... }:

{
  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    mesa-demos
  ];
}
