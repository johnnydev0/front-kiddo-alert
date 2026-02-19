# Guia do Simulador iOS - KidoAlert

## 🎯 Como Testar o App no Simulador

### Passo 1: Executar o App
1. Abra o Xcode
2. Selecione um simulador (ex: iPhone 17)
3. Pressione `Cmd + R` ou clique no botão ▶️ "Play"

---

### Passo 2: Tela de Permissões

Após o splash screen, você verá a tela de permissões:

```
┌─────────────────────────────┐
│   🔵  (ícone de localização) │
│                              │
│      Localização             │
│                              │
│  ✓ Receba alertas quando...  │
│  ✓ Dados privados e seguros  │
│  ✓ Não gasta bateria         │
│                              │
│  [Permitir Localização] 🔵   │
│                              │
│      Agora não               │
└─────────────────────────────┘
```

**Clique em "Permitir Localização"**

---

### Passo 3: Dialog do iOS	

O iOS mostrará um dialog perguntando sobre permissões. Você terá 3 opções:

```
┌─────────────────────────────────────┐
│ "alert" Would Like to Use Your      │
│ Current Location                     │
│                                      │
│ O KidoAlert precisa da sua          │
│ localização para...                  │
│                                      │
│  [Allow While Using App]             │
│  [Allow Once]                        │
│  [Don't Allow]                       │
└─────────────────────────────────────┘
```

**Escolha: "Allow While Using App"**

---

### Passo 4: Segunda Permissão (Always)

Logo após, aparecerá outro dialog:

```
┌─────────────────────────────────────┐
│ Change to "Always Allow"?            │
│                                      │
│ O KidoAlert precisa acessar sua     │
│ localização em segundo plano...      │
│                                      │
│  [Change to "Always Allow"]          │
│  [Keep "While Using"]                │
└─────────────────────────────────────┘
```

**Escolha: "Change to Always Allow"**

---

### Passo 5: Você deve ver a Home Screen

Após aceitar as permissões, você verá:

```
┌─────────────────────────────┐
│  Suas Crianças     👤       │
│  Toque para ver detalhes    │
│                              │
│  ┌───────────────────────┐  │
│  │ João                  │  │
│  │ 🔵 Na escola          │  │
│  │ 🔋 87%  há 3 min      │  │
│  │                       │  │
│  │ [Ver Mapa]            │  │
│  └───────────────────────┘  │
│                              │
│  ┌───────────────────────┐  │
│  │ Maria                 │  │
│  │ 🟢 Em casa           │  │
│  │ 🔋 45%  há 15 min     │  │
│  │                       │  │
│  │ [Ver Mapa]            │  │
│  └───────────────────────┘  │
│                              │
│  ─────────────────────────  │
│  + Adicionar Criança        │
│  📍 Alertas                  │
│  🕐 Ver Histórico            │
│  👥 Convidar Responsável     │
└─────────────────────────────┘
```

---

## 📍 Como Definir Localização no Simulador

### Opção 1: Usar o Menu do Simulador

Com o simulador aberto, na **barra de menu do macOS** (no topo da tela):

1. Clique em **Simulador** (ou **Simulator** se estiver em inglês)
2. Vá em **Features** (ou **Recursos**)
3. Vá em **Location** (ou **Localização**)
4. Escolha uma opção:

```
Simulador
  ├── File
  ├── Edit
  ├── Device
  ├── Features ← AQUI
  │   ├── Location ← AQUI
  │   │   ├── None
  │   │   ├── Apple (Cupertino)
  │   │   ├── City Run
  │   │   ├── Custom Location... ← ESCOLHA ESTA
  │   │   └── ...
  │   ├── Shake Gesture
  │   └── ...
  └── ...
```

### Opção 2: Localizações Úteis

Clique em **Custom Location...** e use estas coordenadas:

| Local | Latitude | Longitude |
|-------|----------|-----------|
| São Paulo (Centro) | -23.5505 | -46.6333 |
| Escola (exemplo) | -23.5489 | -46.6388 |
| Casa (exemplo) | -23.5520 | -46.6350 |

---

## ✅ Como Testar Funcionalidades

### 1. Ver Localização no Mapa
1. Na home, clique em uma criança (ex: João)
2. Você verá o mapa com a localização
3. Se não aparecer nada, defina uma localização no simulador (ver acima)

### 2. Criar um Alerta (Geofence)
1. Na home, clique em "📍 Alertas"
2. Clique no botão "+ Novo Alerta"
3. Preencha:
   - Nome: "Escola"
   - Endereço: "Rua das Flores, 123"
4. Clique em "Salvar Alerta"
5. ✅ Geofence criado!

### 3. Testar Geofencing
1. Crie um alerta com localização próxima à atual
2. No simulador, mude a localização para dentro da área
3. Depois mude para fora
4. Vá em "🕐 Ver Histórico"
5. ✅ Você deve ver eventos de "Chegou" e "Saiu"

### 4. Pausar Compartilhamento (Modo Criança)
1. Clique no ícone 👤 no topo direito
2. Você entra no modo criança
3. Clique em "Pausar Compartilhamento"
4. ✅ Status muda e evento é criado no histórico
5. Clique novamente para retomar

---

## 🐛 Troubleshooting

### Não vejo nada após aceitar permissões
**Solução:** O app deve redirecionar automaticamente. Se não funcionar:
1. Feche o app no simulador (swipe up)
2. Abra novamente
3. Deve ir direto para a home

### Mapa não mostra localização
**Causas possíveis:**
1. Você não definiu uma localização no simulador
2. O app não tem permissões

**Solução:**
1. Vá em: Simulador > Features > Location > Custom Location
2. Defina: -23.5505, -46.6333
3. Volte ao app e clique em "Atualizar Agora"

### Como resetar permissões
1. Feche o simulador
2. No Xcode: `Product` > `Clean Build Folder` (Shift+Cmd+K)
3. Delete o app do simulador
4. Execute novamente

### Onde vejo os logs
No Xcode, no painel inferior (Console), você verá mensagens como:
```
📍 Status de permissão mudou: notDetermined -> authorizedWhenInUse
✅ Permissão concedida!
📍 Localização atualizada: -23.5505, -46.6333
✅ Geofence criada: Escola em (-23.5489, -46.6388)
```

---

## 🎨 Atalhos Úteis do Simulador

| Ação | Atalho |
|------|--------|
| Home button | Cmd + Shift + H |
| Lock screen | Cmd + L |
| Rotate left | Cmd + ← |
| Rotate right | Cmd + → |
| Screenshot | Cmd + S |
| Open/Close keyboard | Cmd + K |

---

Agora teste o app! Qualquer dúvida, me avise. 🚀
