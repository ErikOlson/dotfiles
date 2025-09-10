{
  description = "Global dev environment with Go, Rust, Zig, Odin, Python, JS/TS, C/C++";

  # ⚠️ Uses nixpkgs latest (unstable). Consider pinning for stability.
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
              pkgs.nodejs
              pkgs.nodePackages.eslint
              pkgs.nodePackages.prettier
              pkgs.typescript-language-server

              # Python
              pkgs.python3 pkgs.pyright pkgs.black

              # C/C++
              pkgs.gcc pkgs.clang

              # Nix LSP
              pkgs.nil

              # Nice-to-have for Claude Code project search, etc.
              pkgs.ripgrep
            ];

            shellHook = ''
              echo "🧪 Entered global dev shell (${system})"

              # Global, brew-style GOPATH for cache
              export GOPATH="$HOME/.gopath"
              mkdir -p "$GOPATH/pkg/mod"

              # Temporary shim bin dir (project-local, not committed)
              if [ -n "$XDG_CACHE_HOME" ]; then
                AI_CACHE="$XDG_CACHE_HOME"
              else
                AI_CACHE="$HOME/.cache"
              fi
              export AI_TOOLS_BIN="$AI_CACHE/ai-tools/bin"
              mkdir -p "$AI_TOOLS_BIN"
              export PATH="$AI_TOOLS_BIN:$PATH"

              # --- Gemini CLI wrapper (npx, no global install) ---
              cat > "$AI_TOOLS_BIN/gemini" <<'EOF'
              #!/usr/bin/env bash
              # Use @latest for convenience, or pin a version for reproducibility:
              #   exec npx -y @google/gemini-cli@0.1.9 "$@"
              exec npx -y @google/gemini-cli@latest "$@"
              EOF
              chmod +x "$AI_TOOLS_BIN/gemini"

              # --- Claude Code wrapper (npx, no global install) ---
              cat > "$AI_TOOLS_BIN/claude" <<'EOF'
              #!/usr/bin/env bash
              # Use @latest for convenience, or pin a version for reproducibility:
              #   exec npx -y @anthropic-ai/claude-code@1.0.83 "$@"
              exec npx -y @anthropic-ai/claude-code@latest "$@"
              EOF
              chmod +x "$AI_TOOLS_BIN/claude"

              # --- Codex CLI wrapper (npx, no global install) ---
              cat > "$AI_TOOLS_BIN/codex" <<'EOF'
              #!/usr/bin/env bash
              # Pin a version for reproducibility (recommended), or use @latest:
              # exec npx -y @openai/codex@0.31.0 "$@"
              exec npx -y @openai/codex@latest "$@"
              EOF
              chmod +x "$AI_TOOLS_BIN/codex"

              # Quick tip on first entry
              if command -v gemini >/dev/null && command -v claude >/dev/null; then
                echo "🤖 AI CLIs ready: 'gemini' and 'claude' (first run will prompt login)"
              fi
            '';
          };
        });
    };
}

