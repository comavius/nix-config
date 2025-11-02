{
  pkgs,
  unfree-pkgs,
  inputs,
  ...
}: {
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
    wl-clipboard
    (unfree-pkgs "core/utilities/utilities.nix").unityhub
    inputs.firefox.packages."${pkgs.system}".firefox-nightly-bin
  ];
}
