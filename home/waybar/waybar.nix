{pkgs, ...}: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = ''
      @import url("${./waybar.css}");
    '';
    settings = builtins.fromJSON (builtins.readFile ./waybar.json);
  };
}
