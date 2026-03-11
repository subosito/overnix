{
  description = "Personal collection of Nix packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { pkgs, system, ... }:
        let
          kotlin-lsp = import ./packages/kotlin-lsp { inherit pkgs; };
        in
        {
          devShells.default = import ./shell.nix { inherit pkgs; };

          packages = {
            kotlin-lsp = kotlin-lsp;
          };
        };

      flake = {
        overlays.default = final: _: {
          kotlin-lsp = self.packages.${final.system}.kotlin-lsp;
        };
      };
    };
}
