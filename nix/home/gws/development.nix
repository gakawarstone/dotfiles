{ pkgs, ... }:
{
  programs.java = {
    enable = true;
    package = pkgs.jdk25;
  };

  # Stable paths for IDE SDKs and Gradle's local toolchain discovery.
  home.file.".jdks/java-24".source = "${pkgs.jdk24.home}";
  home.file.".jdks/java-25".source = "${pkgs.jdk25.home}";
  home.sessionVariables = {
    JAVA_24_HOME = "${pkgs.jdk24.home}";
    JAVA_25_HOME = "${pkgs.jdk25.home}";
  };

  home.packages = with pkgs; [
    python314
    uv
    typst
    elmPackages.elm
    elmPackages.elm-format
    elmPackages.elm-language-server
    elmPackages.elm-test
    jetbrains.idea
    opencode
    codex-bin
    herdr
    lazygit
    t3code
  ];
}
