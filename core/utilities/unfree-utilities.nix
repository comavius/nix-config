{unfree-pkgs, ...}: {
  environment.systemPackages = with unfree-pkgs; [
    vscode
    discord
  ];
}
