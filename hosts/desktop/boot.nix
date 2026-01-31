{unfreePkgs, ...}: let
in {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.xserver.videoDrivers = ["nvidia"];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = unfreePkgs.linuxPackages_6_12.nvidiaPackages.stable;
  };
}
