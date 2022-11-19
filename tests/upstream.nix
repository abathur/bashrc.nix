{ bashrc
, shellcheck
, bats
, bats-require
, bashInteractive
, expect
}:

bashrc.unresholved.overrideAttrs (old: {
  name = "${bashrc.name}-tests";
  dontInstall = true; # just need the build directory
  installCheckInputs = [
    bashrc
    shellcheck
    (bats.withLibraries (p: [ bats-require ]))
    bashInteractive
    expect
  ];
  prePatch = ''
    patchShebangs tests
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    shellcheck -x ${bashrc}/bin/bashrc
    bats --timing tests
    touch $out
  '';
})
