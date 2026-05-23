# iPad as sub-monitor
{
  pkgs,
  conf,
  ...
}: 
let weylus = pkgs.callPackage ./weylus.nix {};
in
{
networking.firewall.trustedInterfaces = [ "wlan0" "wlp0s20f3" ];
networking.firewall.interfaces.wlp0s20f3.allowedUDPPorts = [ 9000 ];
  services.usbmuxd.enable = true;
  programs.weylus = {
    enable = true;
    openFirewall = true;
    users = [conf.username];
    package = weylus;
  };
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "*";
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
}
