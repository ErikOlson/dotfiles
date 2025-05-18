{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "dev-environment";

  buildInputs = [
    pkgs.go
    pkgs.rustc
    pkgs.cargo
    pkgs.zig
    pkgs.odin

    pkgs.nodejs
    pkgs.prettier
    pkgs.eslint

    pkgs.gopls
    pkgs.rust-analyzer
    pkgs.zls
    pkgs.nil  # nix lsp
  ];

  shellHook = ''
    echo "🧪 Entered Nix Dev Shell"
    export GOPATH=$PWD/.gopath
    export PATH=$GOPATH/bin:$PATH
  '';
}

