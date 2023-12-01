{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/release-23.05";
    };
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    hag = {
      url = "github:abathur/shell-hag/flaky-breaky-heart";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };
    lilgit = {
      url = "github:abathur/lilgit";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };
    bats-require = {
      url = "github:abathur/bats-require";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };
  };

  # description = "Bash library for neighborly signal sharing";

  outputs = { self, nixpkgs, flake-utils, flake-compat, hag, lilgit, bats-require }:
  let
    # TODO: drop userHome if I don't end up obviously needing it
    sharedOptions = userHome: pkgs: with nixpkgs.lib; {
      enable = mkOption {
        description = "Whether to enable bashrc.";
        default = false;
        type = types.bool;
      };

      package = mkOption {
        description = "bashrc package to use.";
        default = pkgs.bashrc;
        defaultText = "pkgs.bashrc";
        type = types.package;
      };

      # TODO: IDK; avoid if possible?
      user = mkOption {
        type = types.str;
        default = "root";
        description = ''
          User to aggregate history for.
        '';
      };
    };
    testUser = "user1";
    testPassword = "password1234";
  in
    {
      overlays.default = nixpkgs.lib.composeManyExtensions [ hag.overlays.default lilgit.overlays.default (final: prev: {
        bashrc = final.callPackage ./bashrc.nix { };
      })];
      nixosModules = {
        hag = hag.nixosModules.hag;
        bashrc = { config, pkgs, lib, ... }:
        let
          cfg = config.programs.bashrc;
          userHome = config.users.users.${cfg.user}.home;
        in {
          imports = [ hag.nixosModules.hag ];
          options.programs.bashrc = (sharedOptions userHome pkgs);
          config = lib.mkIf cfg.enable {
            programs.hag = {
              enable = true;
              init = false;
              user = "${cfg.user}";
            };
            system.userActivationScripts.bashrc.text = ''
              ln -fs ${cfg.package}/bin/bashrc ${userHome}/.bashrc
            '';
          };
        };
      };
      darwinModules = {
        hag = hag.darwinModules.hag;
        bashrc = { config, pkgs, lib, ... }:
        let
          cfg = config.programs.bashrc;
          userHome = config.users.users.${cfg.user}.home;
        in {
          imports = [ hag.darwinModules.hag ];
          options.programs.bashrc = (sharedOptions userHome pkgs);
          config = lib.mkIf cfg.enable {
            programs.hag = {
              enable = true;
              init = false;
              user = "${cfg.user}";
            };
            system.activationScripts.postUserActivation.text = ''
              ln -fs ${cfg.package}/bin/bashrc ${userHome}/.bashrc
            '';
          };
        };
      };
      # nixosModules.default = self.nixosModules.${system}.bashrc;
      # darwinModules.default = self.darwinModules.${system}.bashrc;

      # DOING: relevant?
      # checks.upstream = pkgs.callPackage ./tests/upstream.nix {
      #       inherit (packages) bashrc;
      #     };
      checks.x86_64-linux.integration = let
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in pkgs.nixosTest {
        name = "bashrc-integration";

        nodes.system1 = { config, pkgs, ... }: {

          imports = [
            self.nixosModules.bashrc
          ];

          programs.bashrc = {
            user = "${testUser}";
            enable = true;
          };

          programs.bash.interactiveShellInit = ''
           source ~/.bashrc
          '';

          users = {
            mutableUsers = false;

            users = {
              "${testUser}" = {
                isNormalUser = true;
                password = "${testPassword}";
              };
            };
          };
        };

        testScript = ''
          import base64, shlex
          from typing import Optional, Tuple

          system1.wait_for_unit("multi-user.target")
          system1.wait_until_succeeds("pgrep -f 'agetty.*tty1'")

          with subtest("open virtual console"):
              # system1.fail("pgrep -f 'agetty.*tty2'")
              system1.send_key("alt-f2")
              system1.wait_until_succeeds("[ $(fgconsole) = 2 ]")
              system1.wait_for_unit("getty@tty2.service")
              system1.wait_until_succeeds("pgrep -f 'agetty.*tty2'")

          with subtest("Log in as ${testUser} on new virtual console"):
              system1.wait_until_tty_matches("2", "login: ")
              system1.send_chars("${testUser}\n")
              system1.wait_until_tty_matches("2", "login: ${testUser}")
              system1.wait_until_succeeds("pgrep login")
              system1.wait_until_tty_matches("2", "Password: ")
              system1.send_chars("${testPassword}\n")
              system1.wait_until_tty_matches("2", "$")

          with subtest("Set up hag purpose & track"):
              system1.wait_until_tty_matches("2", "hag doesn't have a purpose")
              system1.send_chars("porpoise\n")
              system1.wait_until_tty_matches("2", "Should hag track the history for purpose")
              system1.send_chars("y\n")

          # override to work around output encoding error (ansi format?)
          def execute(
              self, command: str, check_return: bool = True, timeout: Optional[int] = 900
          ) -> Tuple[int, str]:
              self.run_callbacks()
              self.connect()

              # Always run command with shell opts
              command = f"set -euo pipefail; {command}"

              timeout_str = ""
              if timeout is not None:
                  timeout_str = f"timeout {timeout}"

              out_command = (
                  f"{timeout_str} sh -c {shlex.quote(command)} | (base64 --wrap 0; echo)\n"
              )

              assert self.shell
              self.shell.send(out_command.encode())

              # Get the output
              output = base64.b64decode(self._next_newline_closed_block_from_shell())

              if not check_return:
                  return (-1, output.decode(errors='ignore'))

              # Get the return code
              self.shell.send("echo ''${PIPESTATUS[0]}\n".encode())
              rc = int(self._next_newline_closed_block_from_shell().strip())

              return (rc, output.decode(errors='ignore'))

          def get_tty_text(self, tty: str) -> str:
              status, output = execute(self,
                  "fold -w$(stty -F /dev/tty{0} size | "
                  "awk '{{print $2}}') /dev/vcs{0}".format(tty)
              )
              return output

          # custom logic because wait_until_tty_matches fails on unicode errors
          # todo: open an issue on the bove
          with subtest("Verify my prompt shows up"):
              while True:
                  try:
                      output = get_tty_text(system1, "2")
                      if "porpoise" in output and "user1 on system1" in output:
                          print("bashrc.nix prompt worked")
                          break
                      else:
                          print("bashrc.nix awaiting correct prompt; current output:")
                          print(output)
                  except:
                      print("output caused exception")
                      print(output)
                      raise
        '';
      };
      # shell = ./shell.nix;
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            bats-require.overlays.default
            hag.overlays.default
            lilgit.overlays.default
            self.overlays.default
          ];
        };
      in
        {
          packages = {
            inherit (pkgs) bashrc;
            default = pkgs.bashrc;
          };
        }
    );
}
