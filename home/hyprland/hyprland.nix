{
  pkgs,
  conf,
  wayggle-bg,
  ...
}: let
  hyprlandConfFiles = [
    "keybindings.conf"
    "devices.conf"
    "cursor-nvidia.conf"
  ];
  hyprlandConfDirFromHomeDir = ".config/hypr";
  hyprlandConfDir = "${conf.homeDirectory}/${hyprlandConfDirFromHomeDir}";
in {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      source =
        (builtins.map (confFile: "${hyprlandConfDir}/${confFile}") hyprlandConfFiles)
        ++ [
          "${hyprlandConfDir}/background.conf"
        ];
    };
    systemd = {
      enable = true;
    };
    xwayland.enable = true;
  };
  home.file = builtins.listToAttrs (builtins.map (confFile: {
      name = "${hyprlandConfDirFromHomeDir}/${confFile}";
      value = {text = builtins.readFile ./${confFile};};
    })
    hyprlandConfFiles
    ++ [
      {
        name = "${hyprlandConfDirFromHomeDir}/background.conf";
        value = {text = "exec = ${wayggle-bg}/bin/wayggle-bg\n";};
      }
    ]);

  programs.wofi.enable = true;

  # screen locker
  programs.hyprlock.enable = true;

  # Logout Menu
  programs.wlogout.enable = true;

  # Hyprland idle daemon
  services.hypridle.enable = true;

  # notification daemon, the same as dunst
  services.mako.enable = true;

  # https://wiki.hypr.land/Useful-Utilities/Screen-Sharing/
  # https://wiki.hypr.land/FAQ/#screenshare--obs-no-worky
  home.packages = with pkgs; [
    pipewire
    wireplumber
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    kdePackages.qtwayland
  ];

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = [
        pkgs.fcitx5-mozc
      ];
      waylandFrontend = true;
    };
  };
}
