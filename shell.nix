# shell.nix
let
  flake = builtins.getFlake (toString ./dev-env);
  sys = builtins.currentSystem;
in flake.devShells.${sys}.default

