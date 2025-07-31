{conf, ...}: {
  home = {
    username = conf.username;
    homeDirectory = conf.homeDirectory;
    stateVersion = conf.nixVersion;
  };
}
