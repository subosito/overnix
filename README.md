# overnix

Personal collection of Nix packages.

## Packages

### kotlin-lsp

An unofficial Nix wrapper for the official [Kotlin Language Server](https://github.com/Kotlin/kotlin-lsp) by JetBrains.

#### Usage

Run directly:

```sh
nix run github:subosito/overnix#kotlin-lsp
```

Add to your flake inputs:

```nix
{
  inputs.overnix.url = "github:subosito/overnix";

  # Use the overlay
  nixpkgs.overlays = [ overnix.overlays.default ];
}
```
