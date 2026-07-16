#!/usr/bin/env bash
# install.sh — instala o bw-connect no computador atual
# Uso: bash install.sh
#
# O que ele faz (e nada além disso):
#   1. Verifica se o Bitwarden CLI (bw) está instalado; se não, mostra como instalar
#   2. Copia o script bw-connect para ~/.local/bin
#   3. Garante que ~/.local/bin está no PATH
#
# Este instalador NÃO contém nem pede nenhuma senha ou segredo.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.local/bin"

echo "═══ Instalador do bw-connect ═══"
echo

# ── 1. Bitwarden CLI presente? ───────────────────────────────────────────────
if command -v bw >/dev/null 2>&1; then
  echo "✅ Bitwarden CLI encontrado: $(bw --version 2>/dev/null || echo 'versão desconhecida')"
else
  echo "⚠️  O Bitwarden CLI (bw) ainda não está instalado."
  echo
  echo "   Instale com UMA das opções oficiais abaixo e rode este script de novo:"
  echo
  echo "   • Via npm (recomendado se você usa Node.js):"
  echo "       npm install -g @bitwarden/cli"
  echo
  echo "   • Via snap (Ubuntu):"
  echo "       sudo snap install bw"
  echo
  echo "   • Binário oficial: https://bitwarden.com/help/cli/#download-and-install"
  echo
  exit 1
fi

# ── 2. python3 presente? (usado pelo bw-connect para ler o status) ──────────
if ! command -v python3 >/dev/null 2>&1; then
  echo "⚠️  python3 não encontrado — o bw-connect precisa dele."
  echo "   Instale com:  sudo apt install python3"
  exit 1
fi

# ── 3. Copia o script ────────────────────────────────────────────────────────
mkdir -p "$DEST"
install -m 755 "$HERE/bw-connect" "$DEST/bw-connect"
echo "✅ Script instalado em: $DEST/bw-connect"

# ── 4. Garante ~/.local/bin no PATH ──────────────────────────────────────────
case ":$PATH:" in
  *":$DEST:"*)
    echo "✅ $DEST já está no PATH"
    ;;
  *)
    SHELL_RC="$HOME/.bashrc"
    [ -n "${ZSH_VERSION:-}" ] && SHELL_RC="$HOME/.zshrc"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_RC"
    echo "✅ PATH atualizado em $SHELL_RC (abra um novo terminal para valer)"
    ;;
esac

echo
echo "═══ Instalação concluída! ═══"
echo
echo "Próximos passos (só na primeira vez neste computador):"
echo "  1. bw login          → entre com seu e-mail e senha master do Bitwarden"
echo "  2. bw-connect        → desbloqueia o cofre e salva a sessão"
echo
echo "No dia a dia, basta rodar:  bw-connect"
