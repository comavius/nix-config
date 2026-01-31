{...}: let
in {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
