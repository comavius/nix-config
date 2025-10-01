{
  pkgs,
  conf,
  wayggle-bg,
  useWayggleBg,
  withNvidiaGpu,
  ...
}: let
  commonConfFiles = [
    "keybindings.conf"
    "devices.conf"
    "cursor.conf"
  ];
  nvidiaSpecificConfFiles = [
    "cursor-nvidia.conf"
  ];
  hyprlandConfFiles =
    commonConfFiles
    ++ (
      if withNvidiaGpu
      then nvidiaSpecificConfFiles
      else []
    );
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
    ++ (
      if useWayggleBg
      then [
        {
          name = "${hyprlandConfDirFromHomeDir}/background.conf";
          value = {text = "exec = ${wayggle-bg}/bin/wayggle-bg shadertoy\n";};
        }
      ]
      else []
    ));

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
