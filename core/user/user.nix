{username, ...}: {
  users.users.comavius = {
    isNormalUser = true;
    description = username;
    extraGroups = ["networkmanager" "wheel" "vboxsf" "docker"];
  };
}