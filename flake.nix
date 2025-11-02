{
  description = "Nix flakes for my NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    firefox.url = "github:nix-community/flake-firefox-nightly";
    firefox.inputs.nixpkgs.follows = "nixpkgs";
    wayggle-bg = {
      url = "github:comavius/wayggle-bg";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    home-manager,
    wayggle-bg,
    ...
  } @ inputs: let
    conf = import ./conf.nix;
    coreModules = [
      ./core/docker/docker.nix
      ./core/utilities/utilities.nix
      ./core/utilities/unfree-utilities.nix
      ./core/user/user.nix
      ./core/nixconf/nixconf.nix
      ./core/desktop/desktop.nix
      ./core/i18n/i18n.nix
      ./core/utilities/bluetooth.nix
      ./core/ld/ld.nix
      ./core/font/font.nix
    ];
    homeModules = {
      useWayggleBg,
      system,
      withNvidiaGpu,
    }: [
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
            ./home/direnv/direnv.nix
          ];
          _module.args = {
            inherit conf;
            wayggle-bg = wayggle-bg.packages."${system}".default;
            inherit useWayggleBg withNvidiaGpu;
          };
        };
      }
    ];
    desktopHostModules = [
      ./hosts/desktop/network.nix
      ./hosts/desktop/boot.nix
      ./hosts/desktop/hardware-configuration.nix
    ];
    noteHostModules = [
      ./hosts/note/network.nix
      ./hosts/note/boot.nix
      ./hosts/note/hardware-configuration.nix
    ];
  in
    {
      nixosConfigurations = {
        "desktop" = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules =
            coreModules
            ++ (homeModules {
              useWayggleBg = true;
              withNvidiaGpu = true;
              inherit system;
            })
            ++ desktopHostModules;
          specialArgs = {
            inherit self;
            inherit inputs;
            inherit conf;
            unfree-pkgs = source-rel-path:
              builtins.warn "Using UNFREE-pkgs in ${source-rel-path}" (import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              });
          };
        };
        "note" = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules =
            coreModules
            ++ (homeModules {
              useWayggleBg = false;
              withNvidiaGpu = false;
              inherit system;
            })
            ++ noteHostModules;
          specialArgs = {
            inherit self;
            inherit inputs;
            inherit conf;
            unfree-pkgs = source-rel-path:
              builtins.warn "Using UNFREE-pkgs in ${source-rel-path}" (import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              });
          };
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      packages.default = pkgs.rustPlatform.buildRustPackage {
        pname = "my-wl-background";
        version = "0.1.0";
        src = ./.;
        nativeBuildInputs = with pkgs; [
          pkg-config
        ];
        buildInputs = with pkgs; [
          libglvnd
          wayland
        ];
        cargoLock = {
          lockFile = ./Cargo.lock;
        };
      };
      formatter = pkgs.alejandra;
    });
}
