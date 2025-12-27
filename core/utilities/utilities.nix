{
  pkgs,
  unfree-pkgs,
  inputs,
  rust-toolchain,
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
    rust-toolchain
    (unfree-pkgs "core/utilities/utilities.nix").unityhub
    inputs.firefox.packages."${pkgs.system}".firefox-nightly-bin
  ];
}
