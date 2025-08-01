{unfree-pkgs, ...}: let
  pkgs = unfree-pkgs;
in {
  environment.systemPackages = with pkgs; [
    vscode
    discord
    steam
  ];
}
