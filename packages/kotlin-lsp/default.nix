{ pkgs }:

let
  version = "261.13587.0";
  system = pkgs.stdenv.hostPlatform.system;

  sources = {
    "x86_64-linux"   = { url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-linux-x64.zip";      hash = "sha256-EweSqy30NJuxvlJup78O+e+JOkzvUdb6DshqAy1j9jE="; };
    "aarch64-linux"  = { url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-linux-aarch64.zip";   hash = "sha256-MhHEYHBctaDH9JVkN/guDCG1if9Bip1aP3n+JkvHCvA="; };
    "x86_64-darwin"  = { url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-mac-x64.zip";         hash = "sha256-zMuUcahT1IiCT1NTrMCIzUNM0U6U3zaBkJtbGrzF7I8="; };
    "aarch64-darwin" = { url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-mac-aarch64.zip";     hash = "sha256-zwlzVt3KYN0OXKr6sI9XSijXSbTImomSTGRGa+3zCK8="; };
  };

  srcData = sources.${system} or (throw "Unsupported system: ${system}");
in
pkgs.stdenv.mkDerivation {
  pname = "kotlin-lsp";
  inherit version;

  src = pkgs.fetchzip {
    inherit (srcData) url hash;
    stripRoot = false;
  };

  nativeBuildInputs = [ pkgs.makeWrapper ]
    ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.autoPatchelfHook ];

  buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
  ];

  # The bundled JRE ships GUI libs (X11, Wayland, etc.) that a headless
  # LSP server never uses. Ignore all missing deps from autoPatchelf.
  autoPatchelfIgnoreMissingDeps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec
    cp -r ./* $out/libexec
    chmod +x $out/libexec/kotlin-lsp.sh
    makeWrapper $out/libexec/kotlin-lsp.sh $out/bin/kotlin-lsp

    runHook postInstall
  '';

  meta = {
    description = "Kotlin Language Server by JetBrains";
    homepage = "https://github.com/Kotlin/kotlin-lsp";
    license = pkgs.lib.licenses.asl20;
    mainProgram = "kotlin-lsp";
    platforms = builtins.attrNames sources;
  };
}
