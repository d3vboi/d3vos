{ pkgs }:
pkgs.writeShellScriptBin "wb-mediaplayer" (
  builtins.readFile ./wb-mediaplayer.sh
)
