{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    coreutils-full
    bottom
    gping
    dive
    fastfetch
    zellij
    git
    firefox
    cargo
    gcc
    clang
    nixd
    obs-studio
    libreoffice
    go
    go-tools
    clang-tools
    poppler-utils
  ];
}
