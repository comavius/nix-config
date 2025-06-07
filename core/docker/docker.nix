{pkgs, ...}: {
  virtualisation.docker = {
    enable = true;
    logDriver = "journald";
    enableOnBoot = true;
  };
}
