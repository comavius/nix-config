{unfree-pkgs, ...}: let
  pkgs = unfree-pkgs "core/utilities/unfree-utilities.nix";
in {
  environment.systemPackages = with pkgs; [
    vscode
    discord
    steam
  ];
}
