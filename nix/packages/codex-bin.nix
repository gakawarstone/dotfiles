{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  installShellFiles,
  gnutar,
  gzip,
  bubblewrap,
  installShellCompletions ? stdenv.buildPlatform.canExecute stdenv.hostPlatform,
}:

assert
  stdenv.hostPlatform.system == "x86_64-linux"
  || throw "codex-bin currently supports only x86_64-linux";

stdenv.mkDerivation (finalAttrs: {
  # Use the upstream release package until nixpkgs catches up.
  pname = "codex";
  version = "0.165.0";

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-package-x86_64-unknown-linux-musl.tar.gz";
    hash = "sha256-6XxEY9fxRmkqlV17DhyM9I+XzU1hbNRcXcqy6Nl0MxY=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontPatchELF = true;
  dontStrip = true;
  doCheck = false;

  nativeBuildInputs = [
    gnutar
    gzip
    makeWrapper
  ]
  ++ lib.optionals installShellCompletions [ installShellFiles ];

  buildPhase = ''
    runHook preBuild
    mkdir -p build
    tar -xzf "$src" -C build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/lib/codex"
    cp -R build/. "$out/lib/codex/"
    ln -s "$out/lib/codex/bin/codex-code-mode-host" "$out/bin/codex-code-mode-host"
    makeWrapper "$out/lib/codex/bin/codex" "$out/bin/codex" \
      --set DISABLE_AUTOUPDATER 1 \
      --prefix PATH : "${lib.makeBinPath [ bubblewrap ]}"
    runHook postInstall
  '';

  postInstall = lib.optionalString installShellCompletions ''
    installShellCompletion --cmd codex \
      --bash <("$out/bin/codex" completion bash) \
      --fish <("$out/bin/codex" completion fish) \
      --zsh <("$out/bin/codex" completion zsh)
  '';

  meta = {
    description = "OpenAI Codex CLI coding agent";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = [ "x86_64-linux" ];
  };
})
