{pkgs, conf, ...}: {
  services.xserver.enable = false;
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = conf.username;
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${pkgs.hyprland}/bin/hyprland";
      };
    };
  };
  programs.hyprland.xwayland.enable = true;
  programs.virt-manager.enable = true;
  /*
  environment.etc."greetd/sessions/hyprland.desktop" = {
    text = ''
      [Desktop Entry]
      Name=Hyprland
      Comment=Hyprland Window Manager
      Type=Application
      DesktopNames=Hyprland
      Exec=${pkgs.hyprland}/bin/hyprland
    '';
  };
  */
}
