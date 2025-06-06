{conf, ...}:
let
  hyprlandConfFiles = [
    "keybindings.conf"
    "devices.conf"
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
  home.file = builtins.listToAttrs (builtins.map (confFile: {
    name = "${hyprlandConfDirFromHomeDir}/${confFile}";
    value = { text = builtins.readFile ./${confFile}; };
  }) hyprlandConfFiles);

  programs.wofi.enable = true;

  # screen locker
  programs.hyprlock.enable = true;

  # Logout Menu
  programs.wlogout.enable = true;

  # Hyprland idle daemon
  services.hypridle.enable = true;

  # notification daemon, the same as dunst
  services.mako.enable = true;
}
