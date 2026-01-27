# Prompt de Integracao - KidoAlert Frontend

## Contexto

Desenvolver o frontend do aplicativo KidoAlert, um app iOS nativo (Swift/SwiftUI) para monitoramento de localizacao de criancas com sistema de geofencing. O backend ja esta pronto e documentado abaixo.

## Requisitos do App

### Visao Geral

KidoAlert permite que responsaveis monitorem a localizacao de criancas e recebam alertas quando elas chegam ou saem de locais predefinidos (escola, casa, etc).

### Dois Modos de Uso

1. **Modo Responsavel (Guardian)**
   - Cadastra criancas no sistema
   - Define alertas de localizacao (geofences)
   - Visualiza localizacao em tempo real
   - Recebe notificacoes de chegada/saida
   - Visualiza historico de eventos
   - Pode convidar outros responsaveis

2. **Modo Crianca (Child)**
   - Aceita convite de vinculacao
   - Compartilha localizacao em background
   - Pode pausar/retomar compartilhamento
   - Interface minimalista

## API Backend

**Base URL**: `http://localhost:3000/api/v1` (dev) ou producao

### Autenticacao

Todas as rotas protegidas requerem header:
```
Authorization: Bearer <access_token>
```

#### Fluxo de Auth

1. **Primeiro acesso** - Criar usuario anonimo:
```http
POST /auth/device
Content-Type: application/json

{
  "deviceId": "UUID-DO-DISPOSITIVO",
  "mode": "guardian" | "child"
}

Response 200:
{
  "accessToken": "jwt...",
  "refreshToken": "refresh...",
  "user": {
    "id": "uuid",
    "deviceId": "...",
    "email": null,
    "name": null,
    "mode": "guardian",
    "plan": "free",
    "planExpiresAt": null
  }
}
```

2. **Criar conta** (opcional, requer auth):
```http
POST /auth/register
Authorization: Bearer <access_token>

{
  "email": "usuario@email.com",
  "password": "senha123",
  "name": "Nome do Usuario"
}
```

3. **Login**:
```http
POST /auth/login

{
  "email": "usuario@email.com",
  "password": "senha123",
  "deviceId": "UUID-DO-DISPOSITIVO"
}
```

4. **Refresh token**:
```http
POST /auth/refresh

{
  "refreshToken": "refresh..."
}
```

5. **Logout** (requer auth):
```http
POST /auth/logout
```

### Usuarios

```http
# Dados do usuario atual
GET /users/me

Response:
{
  "user": { ... }
}

# Limites do plano
GET /users/me/limits

Response:
{
  "plan": "free",
  "limits": {
    "maxAlerts": 3,
    "maxChildren": 2,
    "maxGuardians": 1,
    "historyDays": 7
  },
  "current": {
    "children": 1,
    "alerts": 2,
    "guardians": 0
  }
}

# Atualizar usuario
PATCH /users/me

{
  "name": "Novo Nome"
}
```

### Criancas (Modo Guardian)

```http
# Listar criancas
GET /children

Response:
{
  "children": [
    {
      "id": "uuid",
      "name": "Maria",
      "isSharing": true,
      "lastLatitude": -23.5505,
      "lastLongitude": -46.6333,
      "lastUpdateTime": "2024-01-15T10:30:00Z",
      "batteryLevel": 85,
      "owner": { "id": "...", "name": "..." }
    }
  ]
}

# Detalhes da crianca (com alertas e historico recente)
GET /children/:id

Response:
{
  "child": {
    "id": "uuid",
    "name": "Maria",
    "isSharing": true,
    "lastLatitude": -23.5505,
    "lastLongitude": -46.6333,
    "lastUpdateTime": "2024-01-15T10:30:00Z",
    "batteryLevel": 85,
    "alerts": [...],
    "historyEvents": [...],
    "guardians": [...]
  }
}

# Criar crianca
POST /children

{
  "name": "Maria"
}

Response 201:
{
  "child": { ... },
  "inviteToken": "ABC123",
  "inviteExpiresAt": "2024-01-22T..."
}

# Atualizar crianca
PATCH /children/:id

{
  "name": "Maria Silva"
}

# Deletar crianca
DELETE /children/:id

# Criar novo convite para crianca
POST /children/:id/invite

Response:
{
  "inviteToken": "XYZ789",
  "expiresAt": "2024-01-22T..."
}
```

### Alertas (Geofences)

```http
# Listar alertas (opcionalmente por crianca)
GET /alerts?childId=uuid

Response:
{
  "alerts": [
    {
      "id": "uuid",
      "name": "Escola",
      "address": "Rua das Flores, 123",
      "latitude": -23.5505,
      "longitude": -46.6333,
      "radius": 100,
      "isActive": true,
      "child": { "id": "...", "name": "Maria" }
    }
  ]
}

# Criar alerta
POST /alerts

{
  "childId": "uuid-da-crianca",
  "name": "Escola",
  "address": "Rua das Flores, 123",
  "latitude": -23.5505,
  "longitude": -46.6333,
  "radius": 150
}

# Atualizar alerta
PATCH /alerts/:id

{
  "name": "Escola Nova",
  "isActive": false
}

# Deletar alerta
DELETE /alerts/:id
```

### Localizacao (Modo Child)

```http
# Enviar atualizacao de localizacao
POST /location/update

{
  "latitude": -23.5505,
  "longitude": -46.6333,
  "batteryLevel": 85
}

Response:
{
  "success": true,
  "events": 1,
  "triggeredAlerts": ["uuid-do-alerta"]
}

# Pausar compartilhamento
POST /location/pause

# Retomar compartilhamento
POST /location/resume
```

### Convites

```http
# Criar convite (para adicionar responsavel)
POST /invites

{
  "type": "add_guardian",
  "childId": "uuid-da-crianca"
}

Response:
{
  "token": "ABC123",
  "expiresAt": "2024-01-22T..."
}

# Ver detalhes do convite (sem auth)
GET /invites/:token

Response:
{
  "invite": {
    "token": "ABC123",
    "type": "add_child" | "add_guardian",
    "expiresAt": "..."
  },
  "createdByName": "Joao",
  "childName": "Maria"
}

# Aceitar convite
POST /invites/:token/accept
```

### Historico

```http
# Listar eventos
GET /history?childId=uuid&days=7

Response:
{
  "events": [
    {
      "id": "uuid",
      "type": "arrived" | "left" | "paused" | "resumed",
      "location": "Escola",
      "latitude": -23.5505,
      "longitude": -46.6333,
      "timestamp": "2024-01-15T10:30:00Z",
      "child": { "id": "...", "name": "Maria" },
      "alert": { "id": "...", "name": "Escola" }
    }
  ],
  "limit": {
    "days": 7,
    "isPremium": false
  }
}
```

### Dispositivos (Push Notifications)

```http
# Registrar token APNs
POST /devices/token

{
  "pushToken": "apns-token-here",
  "platform": "ios"
}

# Remover token
DELETE /devices/token

{
  "pushToken": "apns-token-here"
}
```

### Assinaturas

```http
# Verificar recibo Apple e ativar premium
POST /subscriptions/verify

{
  "appleReceiptData": "base64-receipt-data"
}

# Status da assinatura
GET /subscriptions/status

Response:
{
  "isPremium": false,
  "subscription": null | {
    "plan": "monthly" | "annual",
    "status": "active",
    "expiresAt": "..."
  }
}
```

## Telas Sugeridas

### Modo Guardian

1. **Onboarding**
   - Splash screen
   - Selecao de modo (Guardian/Child)
   - Permissoes (notificacoes)

2. **Home/Dashboard**
   - Lista de criancas com localizacao atual
   - Status de cada crianca (compartilhando, pausado, offline)
   - Acesso rapido a adicionar crianca/alerta

3. **Mapa**
   - Mapa com localizacao das criancas
   - Geofences visiveis como circulos
   - Cluster quando varias criancas

4. **Detalhes da Crianca**
   - Localizacao atual no mapa
   - Lista de alertas ativos
   - Historico de eventos recentes
   - Bateria do dispositivo
   - Botao para criar novo alerta

5. **Criar/Editar Alerta**
   - Selecao de local no mapa
   - Busca de endereco
   - Ajuste de raio (slider)
   - Nome do local

6. **Historico**
   - Timeline de eventos
   - Filtro por crianca
   - Filtro por data (limitado no free)

7. **Convites**
   - Gerar convite (codigo/QR)
   - Compartilhar convite

8. **Configuracoes**
   - Perfil do usuario
   - Gerenciar criancas
   - Gerenciar responsaveis
   - Assinatura premium
   - Logout

### Modo Child

1. **Onboarding**
   - Aceitar convite (inserir codigo)
   - Permissoes (localizacao always)

2. **Home**
   - Status de compartilhamento
   - Botao pausar/retomar
   - Nome do responsavel vinculado

3. **Configuracoes**
   - Perfil simples
   - Logout

## Consideracoes Tecnicas

### iOS

- **Localizacao**: Usar `CLLocationManager` com `allowsBackgroundLocationUpdates`
- **Push**: APNs com `UNUserNotificationCenter`
- **StoreKit**: Para compras in-app (premium)
- **Keychain**: Armazenar tokens de forma segura
- **Background Fetch**: Manter localizacao atualizada

### Tratamento de Erros

Todas as respostas de erro seguem o formato:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Dados invalidos",
    "details": { ... }
  }
}
```

Codigos de erro:
- `VALIDATION_ERROR` (400) - Dados invalidos
- `UNAUTHORIZED` (401) - Token invalido/expirado
- `FORBIDDEN` (403) - Sem permissao
- `NOT_FOUND` (404) - Recurso nao encontrado
- `CONFLICT` (409) - Conflito (ex: email ja existe)
- `LIMIT_EXCEEDED` (403) - Limite do plano atingido

### Refresh Token Flow

Quando receber 401, tentar refresh:
1. Chamar `POST /auth/refresh` com refreshToken
2. Se sucesso, atualizar tokens e repetir requisicao original
3. Se falha, redirecionar para login

## Limites por Plano

| Recurso | Free | Premium |
|---------|------|---------|
| Criancas | 2 | 50 |
| Alertas | 3 | Ilimitado |
| Responsaveis adicionais | 1 | 10 |
| Historico | 7 dias | Ilimitado |
| Intervalo de atualizacao | 5 min | 2 min |

## Fluxo de Vinculacao

### Guardian cria crianca:
1. `POST /children` -> recebe `inviteToken`
2. Compartilha codigo com a crianca

### Child aceita convite:
1. `POST /auth/device` com `mode: "child"`
2. `GET /invites/:token` para ver detalhes
3. `POST /invites/:token/accept` para vincular

### Guardian adiciona outro responsavel:
1. `POST /invites` com `type: "add_guardian"`
2. Novo guardian faz `POST /auth/device` com `mode: "guardian"`
3. `POST /invites/:token/accept` para vincular
