{pkgs, conf, ...}: {
  users.users."${conf.username}" = {
    isNormalUser = true;
    description = conf.username;
    extraGroups = ["networkmanager" "wheel" "vboxsf" "docker"];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
}