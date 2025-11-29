# Erik's Dotfiles

A fully reproducible and portable macOS development environment using:

- 🧰 [Homebrew](https://brew.sh) for native apps and system-level CLI tools
- ❄️ [Nix + flakes](https://nixos.org/) for isolated, versioned dev environments
- 📂 Symbolic dotfile syncing with backup safety
- 🔁 `bootstrap.sh` for clean setup on new machines
- 🧠 Designed for Go, Rust, Zig, Odin, C/C++, JS/TS, and Python development
  


## Setup Steps  
  
```bash
git clone git@github.com:erikolson/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```


## 🧪 Global Dev Environment (Nix + direnv)
  
This project includes a flake-based development environment in `dotfiles/dev-env`.  
  
The script will automatically 'direnv allow' /dotfiles/dev-env/flake.nix in the home directory.  
This configuration will be available to any directory in '~'.    
  
To manually perform this step:  
  
```bash
echo 'use flake ~/dotfiles/dev-env' > ~/.envrc
direnv allow ~
```




