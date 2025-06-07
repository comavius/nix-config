{
  description = "Nix flakes for my NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    home-manager,
  } @ input:
  let
    conf = import ./conf.nix;
  in
    {
      nixosConfigurations.my-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # ./hosts/vm/core.nix
          # ./hosts/vm/hardware-configuration.nix
          ./core/docker/docker.nix
          ./core/utilities/utilities.nix
          ./core/user/user.nix
          ./core/nixconf/nixconf.nix
          ./core/desktop/desktop.nix
          ./core/i18n/i18n.nix
          ./hosts/note/network.nix
          ./hosts/note/boot.nix
          ./hardware-configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.comavius = {
              imports = [
                ./home/hyprland/hyprland.nix
                ./home/home.nix
                ./home/kitty/kitty.nix
                ./home/waybar/waybar.nix
                ./home/zsh/zsh.nix
              ];
              _module.args = {
                inherit conf;
              };
            };
          }
        ];
        specialArgs = {
          inherit self;
          inherit input;
          inherit conf;
        };
      };
    };
}
