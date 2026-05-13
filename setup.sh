#!/usr/bin/env bash
# setup.sh — Idempotent environment setup for Ararat
# Skips any step that is already satisfied.
set -euo pipefail

# ── Colours ─────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}[setup]${NC} $*"; }
ok()    { echo -e "${GREEN}[setup] ✓${NC} $*"; }
skip()  { echo -e "${YELLOW}[setup] ↷${NC} $* (already present, skipping)"; }

# ── 1. Pixi ─────────────────────────────────────────────────────────────────
if command -v pixi &>/dev/null; then
    skip "pixi $(pixi --version 2>/dev/null | head -1)"
else
    info "Installing pixi..."
    curl -fsSL https://pixi.sh/install.sh | bash
    # Make pixi available in the current shell without restarting the terminal
    export PATH="$HOME/.pixi/bin:$PATH"
    ok "pixi installed. PATH updated for this session."
    echo ""
    echo "  NOTE: Add the following to your shell profile (~/.bashrc / ~/.zshrc)"
    echo "  so pixi is available in future sessions:"
    echo ""
    echo '    export PATH="$HOME/.pixi/bin:$PATH"'
    echo ""
fi

# ── 2. Project dependencies (Mojo, PyYAML, …) ───────────────────────────────
if pixi run mojo --version &>/dev/null; then
    skip "pixi environment already solved ($(pixi run mojo --version 2>/dev/null | head -1))"
else
    info "Installing project dependencies via pixi..."
    pixi install
    ok "Dependencies installed."
fi

# ── 3. Docker image: kathiravelulab/neuromod-pm ──────────────────────────────
if docker image inspect kathiravelulab/neuromod-pm:latest &>/dev/null 2>&1; then
    skip "Docker image kathiravelulab/neuromod-pm:latest"
else
    if command -v docker &>/dev/null; then
        info "Building Docker image kathiravelulab/neuromod-pm:latest..."
        docker build -t kathiravelulab/neuromod-pm:latest scripts/neuromod-pm/
        ok "Docker image built."
    else
        echo -e "${YELLOW}[setup] ⚠${NC}  docker not found — skipping image build."
        echo "         Install Docker to enable container-based node execution."
    fi
fi

# ── 4. Verify ────────────────────────────────────────────────────────────────
echo ""
info "Verifying installation..."
pixi run mojo --version
ok "Ararat environment is ready. Run the simulation with:"
echo ""
echo "    pixi run mojo main.mojo"
echo ""
