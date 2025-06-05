{conf, ...}:
let
  hyprlandConfFiles = [
    "keybindings.conf"
  ];
  hyprlandConfDirFromHomeDir = ".config/hypr";
  hyprlandConfDir = "${conf.homeDirectory}/${hyprlandConfDirFromHomeDir}";
in
 {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      source = builtins.map(confFile: "${hyprlandConfDir}/${confFile}") hyprlandConfFiles;
    };
  };
  home.file."${hyprlandConfDirFromHomeDir}" = builtins.listToAttrs (builtins.map (confFile: {
    name = confFile;
    value = { text = builtins.readFile ./${confFile}; };
  }) hyprlandConfFiles);

  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  # screen locker
  programs.hyprlock.enable = true;

  # Logout Menu
  programs.wlogout.enable = true;

  # Hyprland idle daemon
  services.hypridle.enable = true;

  # notification daemon, the same as dunst
  services.mako.enable = true;
}
