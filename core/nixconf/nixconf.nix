{username, ...}: {
  system.stateVersion = "25.05";
  nix.extraOptions = (builtins.readFile ./nix.conf)
    + "trusted-users = ${username}\n";
}
