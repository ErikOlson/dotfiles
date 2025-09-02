{
  description = "Global dev environment with Go, Rust, Zig, Odin, Python, JS/TS, C/C++";

  # ⚠️ This uses the nixpkgs-unstable branch (latest, but may break occasionally).
  # For more stability, consider:
  # - A fixed release like "github:nixos/nixpkgs/23.11"
  # - Pinning to a specific commit using a 'rev'
  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    in {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            name = "global-dev-env";

            buildInputs = [
              # Go
              pkgs.go pkgs.gopls

              # Rust
              pkgs.rustc pkgs.cargo pkgs.rust-analyzer pkgs.clippy pkgs.rustfmt

              # Zig & Odin
              pkgs.zig pkgs.odin pkgs.zls

              # JavaScript / TypeScript
              pkgs.nodejs pkgs.nodePackages.eslint pkgs.nodePackages.prettier pkgs.typescript-language-server

              # Python
              pkgs.python3 pkgs.pyright pkgs.black

              # C/C++
              pkgs.gcc pkgs.clang

              # Nix LSP
              pkgs.nil
            ];

            shellHook = ''
              echo "🧪 Entered global dev shell for system: ${system}"
              export GOPATH="$HOME/.gopath"
              export GOBIN="$GOPATH/bin"
              mkdir -p "$GOBIN"
              export PATH="$GOBIN:$PATH"
            '';
          };
        });
    };
}

