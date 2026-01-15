#!/bin/bash
# Script to reset all app data in the simulator
# Run this when you want to clear UserDefaults and start fresh

echo "🧹 Limpando dados do app no simulador..."
xcrun simctl uninstall booted kiddo.alert
echo "✅ Dados limpos com sucesso!"
echo ""
echo "Agora execute o app novamente no Xcode (Cmd+R)"
echo "O app será instalado sem nenhum dado antigo."
