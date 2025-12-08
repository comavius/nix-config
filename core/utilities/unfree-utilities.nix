{unfree-pkgs, ...}: let
  pkgs = unfree-pkgs "core/utilities/unfree-utilities.nix";
in {
  environment.systemPackages = with pkgs; [
    vscode
    discord
    unityhub
    google-chrome
  ];
  programs.steam = {
    enable = true;
    package = pkgs.steam;
  };
}
