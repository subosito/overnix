{pkgs}: let
  version = "262.1817.0";
  system = pkgs.stdenv.hostPlatform.system;

  sources = {
    "x86_64-linux" = {
      url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-linux-x64.zip";
      hash = "sha256-BsjmllnZsB5i9NJBf8mb47aw6PoeZZbtp0OX8VV0VOA=";
    };
    "aarch64-linux" = {
      url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-linux-aarch64.zip";
      hash = "sha256-4JxkCX2GHz8Ld6ilVuNlPMl/YvwCBH0JivR/lukcb88=";
    };
    "x86_64-darwin" = {
      url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-mac-x64.zip";
      hash = "sha256-M/bNUdL9Ctq1ZC1bczKQPD3Pyv6Tpiy1QBsjuX1rSXA=";
    };
    "aarch64-darwin" = {
      url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-mac-aarch64.zip";
      hash = "sha256-OFPQ7MfGjq6rB1y13aIF09Ij296AMg1PCCZn1pwjoQA=";
    };
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

    nativeBuildInputs =
      [pkgs.makeWrapper]
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux [pkgs.autoPatchelfHook];

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
      chmod u+w,+x $out/libexec/kotlin-lsp.sh
      chmod +x $out/libexec/jre/bin/java
      patchShebangs $out/libexec/kotlin-lsp.sh
      sed -i '/chmod.*bin\/java/d' $out/libexec/kotlin-lsp.sh
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
