brew "neovim"
brew "lua-language-server"
brew "eslint"
brew "prettier"
brew "fzf"
brew "fd"
brew "starship"
brew "direnv"
brew "zsh"

cask "google-chrome"
cask "ghostty"
cask "rectangle"
cask "font-jetbrains-mono"
cask "raycast"
cask "stats"
cask "1password"
cask "intellij-idea"
cask "obsidian"
cask "lens"
cask "sublime-text"

# Docker CLI tools (keep these even if you switch backends)
brew "docker"
brew "docker-buildx"
brew "docker-compose"

# Docker Backends
cask "docker"     # Docker Desktop (GUI, built-in k8s option)
brew "colima"     # Lightweight VM backend (runs Docker daemon via Lima)

# Kubernetes core CLIs
brew "kubernetes-cli"   # kubectl
brew "helm"
brew "kustomize"
brew "kubectx"          # includes kubens
brew "k9s"              # nice TUI (optional)
brew "stern"            # logs tailing (optional)

# Choose ONE local cluster path (comment out the others)

# 1) Kind: upstream K8s-in-Docker; great for CI and ephemeral clusters
# brew "kind"

# 2) k3d: runs lightweight K3s inside Docker/Colima; great when your project uses K3s
brew "k3d"
brew "k3sup"            # optional helper to create K3s clusters on VMs/servers

# 3) Minikube: full-featured but heavier, uses a VM
# brew "minikube"

