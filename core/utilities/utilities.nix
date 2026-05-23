{
  pkgs,
  unfree-pkgs,
  inputs,
  rust-toolchain,
  ...
}:
let
  canon-capt = import ./canon-capt.nix {
    pkgs = unfree-pkgs "core/utilities/canon-capt.nix";
  };
in
{
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
      canon-capt
    ];
  };

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
