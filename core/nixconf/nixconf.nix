{conf, ...}: {
  system.stateVersion = "25.05";
  nix.extraOptions = (builtins.readFile ./nix.conf)
    + "trusted-users = ${conf.username}\n";
}
