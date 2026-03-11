{ pkgs }:

pkgs.mkShell {
  packages = with pkgs; [
    curl
    jq
    nix
  ];
}
