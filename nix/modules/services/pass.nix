{ pkgs, ... }:

{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-tty;
  };

  environment.systemPackages = with pkgs; [
    gnupg
    (pass.withExtensions (extensions: [ extensions.pass-otp ]))
    github-cli
  ];

  environment.extraInit = ''
    export GPG_TTY=$(tty)
  '';
}
