{...}: {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      source = [
        # "./exec.conf"
        "./keybindings.conf"
      ];
    };
  };
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
