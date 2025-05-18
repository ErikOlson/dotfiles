# Erik's Dotfiles  
  
Portable macOS development setup with Homebrew + Nix.

## Setup Steps  
  
```bash
git clone git@github.com:yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh



## 🧪 Global Dev Environment (Nix + direnv)
  
This project includes a flake-based development environment in `dotfiles/dev-env`.  
  
The script will automatically 'direnv allow' /dotfiles/dev-env/flake.nix in the home directory.  
This configuration will be available to any directory in '~'.    
  
To manually perform this step:  
  
```bash
echo 'use flake ~/dotfiles/dev-env' > ~/.envrc
direnv allow ~





