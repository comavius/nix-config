{ config, pkgs, ... }:
let
  tpLinkTx1uNano = pkgs.callPackage ./tp-link-aic8800.nix {
    kernel = config.boot.kernelPackages.kernel;
  };
in {
  # TP-Link's current Linux beta driver for this adapter targets kernels up to 6.14.
  boot.kernelPackages = pkgs.linuxPackages_6_12;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModulePackages = [ tpLinkTx1uNano ];

  hardware.enableRedistributableFirmware = true;
  # The vendor AIC driver opens firmware files by exact path and does not
  # tolerate NixOS's default .zst firmware compression.
  hardware.firmwareCompression = "none";
  hardware.firmware = [ tpLinkTx1uNano ];
  # This vendor driver bypasses firmware_class and opens /lib/firmware directly.
  # Provide a compatibility symlink to the NixOS firmware tree.
  system.activationScripts.aic8800FirmwareCompat.text = ''
    mkdir -p /lib
    ln -sfn ${config.hardware.firmware}/lib/firmware /lib/firmware
  '';
  services.udev.extraRules = ''
    # Switch the TX1U Nano/A out of its fake USB mass-storage mode.
    KERNEL=="sd*", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="5721", RUN+="${pkgs.util-linux}/bin/eject /dev/%k"
  '';
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
