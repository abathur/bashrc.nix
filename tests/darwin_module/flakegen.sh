cat <<EOF
{
  description = "SIGH";

  inputs = {
    nixpkgs = {
      # url = "github:nixos/nixpkgs/nixpkgs-unstable";
      #TODO: only use this until lilgit can unpin
      url = "github:nixos/nixpkgs/260eb420a2e55e3a0411e731b933c3a8bf6b778e";
    };
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bashrc.url = "github:abathur/bashrc.nix/$GITHUB_SHA";
  };

  outputs = { self, nixpkgs, bashrc, ... }@inputs: {
    darwinConfigurations.ci = let
      system = "x86_64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ bashrc.overlays.default ];
      };
    in inputs.darwin.lib.darwinSystem rec {
      system = "x86_64-darwin";
      inherit inputs;
      specialArgs = {
        inherit pkgs;
      };
      modules = [
        bashrc.darwinModules.bashrc
        (
          { config, pkgs, bashrc, ... }:

          {
            programs.bash.enable = true;
            programs.bashrc = {
              user = "$USER";
              enable = true;
            };

            users.users."$USER".home = "/Users/runner";

            system.stateVersion = 4;
            nix.useDaemon = true;
          }
        )
      ];
    };
  };
}
EOF
