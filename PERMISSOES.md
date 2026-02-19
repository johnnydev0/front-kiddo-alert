# Configuração de Permissões - Fase 2

## Permissões de Localização Necessárias

Para que o app funcione corretamente na Fase 2, você precisa adicionar as seguintes permissões no arquivo `Info.plist` do projeto no Xcode:

### Como Configurar no Xcode:

1. Abra o projeto `alert.xcodeproj` no Xcode
2. Selecione o target "alert" no Project Navigator
3. Vá para a aba "Info"
4. Adicione as seguintes chaves (Custom iOS Target Properties):

### Chaves Obrigatórias:

| Key | Type | Value |
|-----|------|-------|
| `Privacy - Location When In Use Usage Description` | String | "O KidoAlert precisa da sua localização para enviar alertas de chegada e saída aos seus responsáveis." |
| `Privacy - Location Always and When In Use Usage Description` | String | "O KidoAlert precisa acessar sua localização em segundo plano para monitorar chegadas e saídas mesmo quando o app não estiver aberto. Seus dados são privados e seguros." |
| `Privacy - Location Always Usage Description` | String | "O KidoAlert precisa acessar sua localização em segundo plano para monitorar chegadas e saídas." |

### Background Modes (Opcional - Para Produção):

⚠️ **IMPORTANTE**: Esta configuração é opcional durante desenvolvimento. O app funciona no simulador sem ela.

Para habilitar atualizações de localização em background (necessário para produção):

1. Selecione o target "alert" no Project Navigator
2. Vá para a aba "Signing & Capabilities"
3. Clique em "+ Capability"
4. Adicione "Background Modes"
5. Marque a checkbox "Location updates"

**Nota**: Sem esta configuração:
- ✅ O app funciona normalmente no simulador
- ✅ Geofencing funciona
- ✅ Todas as funcionalidades da Fase 2 funcionam
- ❌ Atualizações em background não funcionarão em dispositivo real quando app estiver fechado

## Como Testar:

### No Simulador:

1. Execute o app no simulador
2. Quando solicitado, aceite as permissões de localização
3. No simulador, vá em: Features > Location > Custom Location
4. Defina uma localização (ex: São Paulo: -23.5505, -46.6333)
5. O app deve mostrar essa localização no mapa

### Simular Geofence:

1. Crie um alerta em uma localização próxima
2. No simulador, altere a localização para dentro/fora da geofence
3. Verifique se os eventos aparecem no histórico

### No Dispositivo Real:

Para testar em dispositivo real:
1. Configure um Development Team no Xcode
2. Habilite Developer Mode no dispositivo (Settings > Privacy & Security > Developer Mode)
3. Execute o app
4. Caminhe fisicamente para dentro/fora das geofences criadas
5. Verifique se os eventos são registrados

## Observações:

- **Always Authorization**: É necessária para geofencing funcionar em segundo plano
- **Background Location**: Permite que o app monitore geofences mesmo quando fechado
- **Bateria**: O sistema usa geofencing, que é otimizado para bateria (não rastreamento contínuo)

## Troubleshooting:

### Erro: "Invalid parameter not satisfying: !stayUp || CLClientIsBackgroundable..."
**Causa**: Tentativa de usar background location updates sem a capability configurada.
**Solução**: Já está corrigido! O LocationManager detecta automaticamente se está no simulador e desabilita background updates. O app funciona normalmente.

### Permissões negadas:
- Vá em: Settings > KidoAlert > Location
- Altere para "Always"

### Geofencing não funciona em background (dispositivo real):
- Certifique-se de que "Background Modes" está habilitado (ver seção acima)
- Verifique se a permissão é "Always" (não apenas "When In Use")
- Reinicie o app após conceder permissões

### Simulador não atualiza localização:
- Reset Location: Features > Location > None, depois Custom Location novamente
- Verifique se o LocationManager está recebendo updates nos logs
- No simulador: Features > Location > Apple (ou qualquer preset)
- Depois: Features > Location > Custom Location (-23.5505, -46.6333)
