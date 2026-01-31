{unfreePkgs, ...}: let
in {
  environment.systemPackages = with unfreePkgs; [
    vscode
    discord
    unityhub
    google-chrome
    unityhub
  ];
  programs.steam = {
    enable = true;
    package = unfreePkgs.steam;
  };
}
