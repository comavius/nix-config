{lib, ...}: {
  options.comavius.hyprland = {
    enable = lib.mkEnableOption "Enable comavius.hyprland module";
    confFiles = lib.types.listOf (
      lib.types.submodule
    );
  };
}