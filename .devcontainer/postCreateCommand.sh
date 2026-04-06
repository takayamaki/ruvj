#!/usr/bin/env bash
set -euo pipefail

echo "==> Trusting mise.toml..."
mise trust --yes

echo "==> Installing tools via mise..."
mise install

echo "==> Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash

echo "==> Activating mise in shell..."
if ! grep -q 'mise activate' "$HOME/.bashrc" 2>/dev/null; then
  echo 'eval "$(mise activate bash)"' >> "$HOME/.bashrc"
fi

echo "==> Linking dotfiles..."
ln -sf /workspaces/workspace/.devcontainer/dotfiles/tmux.conf "$HOME/.tmux.conf"

echo ""
echo "Setup complete!"
