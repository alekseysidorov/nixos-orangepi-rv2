{ pkgs, ... }:

{
  hardware.graphics.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true; # recommended for most users
    xwayland.enable = false; # optimize compilation time
  };

  environment.systemPackages = with pkgs; [
    kmscube
  ];
}
