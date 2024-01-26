{ resholve
, lib
, callPackage
, hag
, coreutils
, gnugrep
, git
, lilgit
}:

# TODO: this could be a writeScript
resholve.mkDerivation rec {
  version = "unset";
  pname = "bashrc";

  src = ./.;

  installPhase = ''
    install -Dv bashrc $out/bin/bashrc
  '';

  solutions = {
    profile = {
      interpreter = "none";
      inputs = [ hag lilgit ];
      scripts = [ "bin/bashrc" ];
      keep = {
        source = [ "$HOME" ];
      };
    };
  };
  # Could in theory use bash syntax check (-n) flag here
  # Waste of time unless it catches things shellcheck doesn't.
  # bash -n ./bashrc
  # Could also in theory actually run the script, but I'm not sure how to do this pragmatically; there are two big concerns:
  # - this is a profile script for an interactive shell; it has features that fall over without a TTY, job control, history, etc.
  # - Nix neuters our access to the home directory without giving us a safe sandbox to make files in...
  # this was in below: -P ${makeBinPath buildInputs}
  doInstallCheck = false;
  doCheck = false;

  # TODO: below likely needs fixing
  passthru.tests = callPackage ./test.nix { };

  meta = with lib; {
    description = "bashrc as a Nix flake";
    homepage = https://github.com/abathur/bashrc.nix;
    license = licenses.mit;
    maintainers = with maintainers; [ abathur ];
    platforms = platforms.all;
  };
}
