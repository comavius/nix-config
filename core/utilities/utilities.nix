{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    coreutils-full
    bottom
    gping
    dive
    fastfetch
    zellij
    git
  ];
}
