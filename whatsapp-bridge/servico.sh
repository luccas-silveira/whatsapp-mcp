#!/bin/bash
# Liga a ponte como serviço do macOS: sobe no login e volta sozinha quando cai.
# Compila e religa: rode de novo depois de mudar o código. QR e erros: tail -f ~/Library/Logs/whatsapp-bridge.log
set -eu
PASTA="$(cd "$(dirname "$0")" && pwd -P)"
ROTULO=com.whatsapp-mcp.bridge
PLIST="$HOME/Library/LaunchAgents/$ROTULO.plist"
LOG="$HOME/Library/Logs/whatsapp-bridge.log"

# o módulo se chama whatsapp-client; sem -o o binário sairia com esse nome
(cd "$PASTA" && go build -o whatsapp-bridge .)

launchctl bootout "gui/$(id -u)/$ROTULO" 2>/dev/null || true
# o bootout volta antes de o serviço sair; o bootstrap falha se ele ainda estiver lá
for _ in $(seq 50); do
  launchctl print "gui/$(id -u)/$ROTULO" >/dev/null 2>&1 || break
  sleep 0.2
done
# duas pontes com a mesma sessão derrubam uma à outra
pkill -x whatsapp-bridge 2>/dev/null || true

mkdir -p "$(dirname "$PLIST")" "$(dirname "$LOG")"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$ROTULO</string>
  <key>ProgramArguments</key><array><string>$PASTA/whatsapp-bridge</string></array>
  <key>WorkingDirectory</key><string>$PASTA</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>10</integer>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
EOF
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "ponte ligada como serviço ($ROTULO). Log: $LOG"
