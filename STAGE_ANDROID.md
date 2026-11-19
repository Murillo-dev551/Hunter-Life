# Hunter Life — Preparação Android v0.1.0

> Registro da preparação inicial. O desenvolvedor confirmou posteriormente instalação e execução no Galaxy A15 5G e relatou falhas de arrasto e ausência de modo imersivo. O APK atual é o **test2**; veja [Revisão Android 1](STAGE_ANDROID_REVISION_1.md). Os resultados e a configuração descritos abaixo registram a primeira entrega.

## Situação da entrega

**APK de testes gerado, assinado e verificado. A execução no Samsung Galaxy A15 5G ainda não foi validada. A v0.1.0 não está declarada pronta para lançamento público.**

Artefato: `builds/android/Hunter-Life-0.1.0-test.apk`.

Caminho neste computador:

```text
C:\Users\muril\Downloads\Hunter life\Hunter_Life\builds\android\Hunter-Life-0.1.0-test.apk
```

O arquivo `.apk.sha256` ao lado contém a soma de verificação da compilação final. O APK e ferramentas privadas de assinatura não são versionados. A v0.1.1 não foi iniciada.

SHA-256 desta entrega: `3a08db683abc048fe87ac0539e1772a131c5d46fe52e339b6a7c254e3d8ef60b`.

## Configuração e ambiente

| Componente | Configuração validada |
|---|---|
| Motor e templates | Godot 4.7.2 stable, `ed1daf0bf`, templates padrões oficiais |
| JDK | Eclipse Temurin OpenJDK 17.0.21+9, Windows x64 |
| SDK | Platform 36, Build-Tools 36.0.0 e Platform-Tools |
| Modalidade | APK de depuração, exportação nativa sem Gradle |
| Pacote | `org.hunterlife.prototype` |
| Nome | Hunter Life |
| Versão | `0.1.0-test`, código 1 |
| ABI | Somente `arm64-v8a`, adequada ao Galaxy A15 5G |
| Android mínimo | API 24, herdada do template e conferida no manifesto |
| Target/compile SDK | API 36, conferida no manifesto |
| Orientação | Retrato |
| Permissões | Nenhuma permissão `uses-permission` encontrada; sem Internet |
| Assinatura | Debug local, esquemas v2 e v3 válidos |
| Alinhamento | Verificado com `zipalign`, incluindo alinhamento de páginas de 16 KB |

A documentação geral consultada lista API/Build-Tools 35. A implementação da versão exata 4.7.2 define target SDK 36, portanto o ambiente foi preparado com 36. A exportação nativa não aceita substituir min/target SDK pelas opções de Gradle: esses overrides foram removidos e os valores reais foram inspecionados no APK. NDK, CMake e Gradle não foram necessários para esta exportação de GDScript com template pronto.

Ferramentas foram instaladas em `%LOCALAPPDATA%\HunterLifeBuild\`, fora do repositório:

- `java\jdk-17.0.21+9\`.
- `sdk\`.
- Arquivos de instalação em cache.

Templates Android ficam em `%APPDATA%\Godot\export_templates\4.7.2.stable\`. Foram verificados os checksums oficiais: SHA-256 para JDK/Command-line Tools e SHA-512 para o pacote completo de templates. A compilação final utiliza os templates **padrões**, sem Perfetto. Os caminhos de JDK/SDK foram configurados nas preferências locais do editor.

O keystore de depuração é gerenciado localmente pelo Godot. Não há senhas, chaves privadas ou caminhos de keystore no preset versionado. O `.gitignore` exclui APK/AAB, keystores, credenciais de exportação e artefatos de build. Esta assinatura serve para testes locais, não para publicação na loja.

## Interface e ciclo de vida

- A configuração Windows continua em 480×860 e permanece redimensionável.
- Overrides somente para Android usam base lógica 360×780, `canvas_items` e aspecto `expand`. Essa base corresponde à proporção 1080×2340 informada pela Samsung, mantendo textos e botões em dimensões úteis.
- Retrato, barras do sistema visíveis e edge-to-edge configurados. `DisplayServer.get_display_safe_area()` é convertido para coordenadas lógicas pelo inverso da transformação de tela. As margens consideram recortes/barras sem somar duas vezes uma área já excluída pelo viewport.
- O manifesto confirma `adjustResize` para o teclado virtual. Voltar primeiro pode ocultar o teclado; a validação real do teclado Samsung continua pendente.
- Toque é tratado pelos controles nativos, com emulação de mouse a partir de toque habilitada. No PC, a injeção de `InputEventScreenTouch` acionou o botão de configurações uma única vez.
- Limite Android de 60 FPS configurado; não foi feita medição de FPS ou consumo no telefone.
- A música pausa ao perder foco/suspender e retoma o mesmo reprodutor e posição. Efeitos pendentes são descartados; não há fila sonora ao voltar. Foco e suspensão são considerados separadamente, evitando retomar enquanto o aplicativo ainda está suspenso.

### Botão Voltar

O encerramento automático por Voltar foi desabilitado. O tratamento segue contexto:

1. Oculta o teclado, quando informado como aberto pelo Android.
2. Fecha configurações ou cancela um diálogo aberto.
3. Sai do formulário de criação sem sobrescrever outra jornada.
4. Retorna de outra aba para Aventura ou de uma categoria de combate ao menu de ações.
5. No nível principal, apresenta confirmação de saída.

Em uma jornada vinculada a slot, há **Salvar e sair**, **Sair sem salvar** e **Continuar**. Salvar usa os métodos atômicos existentes; erro mantém a jornada aberta. Animações não acionam gravação ou exclusão. A confirmação foi organizada verticalmente para caber em telas estreitas.

O salvamento manual permanece. **Não foi introduzido autosave ao suspender.** Salve antes de alternar aplicativos ou bloquear a tela por longos períodos: o Android pode finalizar processos suspensos sem dar oportunidade de gravação. Os checkpoints da Especialização continuam seguindo as regras anteriores.

## Ícones e recursos

Quatro variantes SVG foram derivadas do emblema original: ícone principal de 192×192, camadas adaptativas e ícone monocromático de 432×432 para temas do Android 13 ou superior. A parte essencial do emblema fica centralizada na região segura do ícone adaptativo. A origem/CC0 está registrada em `assets/ASSET_LICENSES.md`; não foi usada arte oficial da Licença Hunter.

Importação ETC2/ASTC foi habilitada conforme exigência do exportador Android, preservando o renderizador de compatibilidade e a importação desktop. Todos os recursos necessários são locais. Testes, ferramentas, relatórios e diretórios de build são excluídos do APK.

## Preservação e arquivos

O save continua **v9**, sem migração nova ou alteração de regras. `user://` no Android aponta para o armazenamento privado do próprio aplicativo. Atualizar com o mesmo pacote e assinatura mantém os arquivos; desinstalar remove os dados locais. Dados Windows não são copiados automaticamente para o telefone.

Não foram alterados os 92 acontecimentos, dificuldade, recompensas, atributos, RNG, Nen, cinco Hatsus/11 especializações, inventário, Exame Hunter, motor de combate, três slots ou checkpoints. Música, efeitos e a apresentação da 10H foram preservados.

| Arquivo | Alteração |
|---|---|
| `project.godot` | Identificação de teste, overrides Android, retrato, toque, limite de FPS e importação ETC2/ASTC |
| `export_presets.cfg` | Preset Android Test; preservação do Windows e exclusão de builds |
| `scripts/ui/mobile_layout.gd` | Conversão de área segura para margens lógicas |
| `scripts/main.gd` | Voltar contextual, confirmação/salvamento na saída e margens Android |
| `scripts/audio_manager.gd` | Suspensão/retomada por ciclo de vida Android |
| `assets/icons/app_*.svg` | Quatro variantes do emblema para launcher |
| `assets/ASSET_LICENSES.md` | Proveniência das variantes |
| `tools/configure_android.gd` | Configuração de caminhos locais do editor sem segredos versionados |
| `tools/export_android.ps1` | Exportação, assinatura, alinhamento e SHA-256 reproduzíveis |
| `tests/test_android.gd` | Layout, toque simulado, Voltar, persistência e ciclo de vida |
| `tests/check_android_apk.ps1` | Integridade do catálogo, recursos importados e ABI |
| `.gitignore` | Exclusão de artefatos e materiais de assinatura |
| `README.md`, `STAGE_ANDROID.md` | Procedimentos e resultados |
| `tests/captures/android_*.png` | Sete capturas de layout feitas no PC |

## Validação realizada no computador

**35 suítes GDScript executadas: 37.237 verificações, zero falhas de asserção.** Incluem todas as anteriores e a nova suíte Android de 40 verificações. Os testes de layout Windows anteriores continuaram passando.

- Criação, carregamento e exclusão de slots; migrações históricas; isolamento dos checkpoints.
- Narrativa, d20, progressão, duas expansões, Nen, cinco Hatsus, Especialista, Exame Hunter, inventário e equipamentos.
- Navegação e Voltar sem modificar RNG, recursos ou turnos; cancelamento de exclusão; falha de salvamento impedindo saída.
- “Salvar e sair” preservando estado de batalha e RNG na reabertura do slot.
- Áudio suspenso/retomado por notificações simuladas; mesmo reprodutor, posição mantida e sem efeitos acumulados.
- Layouts 320×480, 390×844, 480×860, 768×1024 e 1100×720 das suítes anteriores. Novos testes em 360×780, 390×845, 480×1040 e escala física 540×1170 mantendo base lógica 360×780.
- Insets matemáticos com barras simuladas e viewport já recortado, sem margens duplicadas.
- Manifesto inspecionado com `aapt`; assinatura v2/v3 validada por `apksigner`; alinhamento validado por `zipalign`.
- **26 verificações adicionais de integridade do APK:** catálogo com 92 acontecimentos idêntico ao arquivo local, ARM64, ausência de ferramentas/testes e presença de todos os streams/ícones importados necessários.

O ADB foi executado e **não detectou dispositivos conectados**. Não foram realizadas instalação, execução Android, medição de memória/bateria ou captura de `logcat` no aparelho. Os avisos de áudio ao encerramento imediato de alguns testes antigos permanecem conhecidos desde a 10G; não são falhas de asserção ou mudanças nas regras. O helper de configuração foi ajustado para rodar sem iniciar o editor inteiro, eliminando avisos de descarte de recursos dessa ferramenta.

Logs locais: `tests/android_*.log`. Os testes usam `HUNTER_LIFE_DATA_ROOT` para isolar slots/preferências e não substituir jornadas do usuário.

## Como gerar novamente

No computador já configurado, execute na pasta do projeto:

```powershell
./tools/export_android.ps1
./tests/check_android_apk.ps1
```

Em outro computador:

1. Instale Godot 4.7.2 standard e seus templates da mesma versão. Abra o editor uma vez para criar as preferências locais.
2. Instale OpenJDK 17 e Android Command-line Tools pelos fornecedores oficiais.
3. Usando o SDK Manager, instale `platform-tools`, `build-tools;36.0.0` e `platforms;android-36`, aceitando os termos aplicáveis. Não é necessário instalar NDK/CMake para esta exportação nativa.
4. Execute o script informando os caminhos:

```powershell
./tools/export_android.ps1 `
  -GodotPath 'C:\caminho\Godot_v4.7.2-stable_win64_console.exe' `
  -JavaSdk 'C:\caminho\jdk-17' `
  -AndroidSdk 'C:\caminho\Android\Sdk'
```

Alternativamente, configure Java SDK Path/Android SDK Path em Editor Settings > Export > Android e exporte **Android Test** como APK de depuração. Não use uma chave de produção para este teste. Preserve o keystore local utilizado se quiser instalar futuras compilações por cima sem perder os dados; uma assinatura diferente impede a atualização normal. O script não baixa ferramentas ou solicita senhas.

Para repetir a suíte Android no PC:

```powershell
$env:HUNTER_LIFE_DATA_ROOT = 'user://android_validation_' + [DateTime]::UtcNow.Ticks
godot --path . --script res://tests/test_android.gd
Remove-Item Env:HUNTER_LIFE_DATA_ROOT
```

## Instalar no Galaxy A15 5G

### Por arquivo, sem ADB

1. Copie `Hunter-Life-0.1.0-test.apk` para Downloads do telefone por USB.
2. Abra **Meus Arquivos > Downloads** e toque no APK.
3. Se solicitado, permita a instalação por essa origem e siga as confirmações da One UI. Os nomes/opções podem variar com a versão do Android e políticas do aparelho.
4. Abra **Hunter Life** e execute o checklist abaixo.

### Por USB/ADB

Ative as opções de desenvolvedor e a depuração USB no aparelho e autorize o computador. No PowerShell, na pasta do projeto:

```powershell
$adb = "$env:LOCALAPPDATA\HunterLifeBuild\sdk\platform-tools\adb.exe"
& $adb devices
& $adb install -r '.\builds\android\Hunter-Life-0.1.0-test.apk'
& $adb shell am start -n org.hunterlife.prototype/com.godot.game.GodotAppLauncher
```

Se o computador não detectar o telefone, confira cabo, autorização e [driver USB oficial Samsung](https://developer.samsung.com/android-usb-driver). Não desinstale para corrigir diferença de assinatura sem antes preservar os dados que deseja manter: a desinstalação apaga os slots.

Para investigar uma falha, capture o processo do aplicativo com Android Studio/ADB e registre versão do Android/One UI, ação realizada e imagem da tela. Um log completo pode conter informações de outros aplicativos; prefira filtrar o processo Hunter Life.

## Checklist curto de testes físicos — pendente

- [ ] Instalar e abrir em retrato; conferir ícone, emblema, recorte da câmera, barra de status e navegação por gestos/três botões. Girar o aparelho e confirmar que o jogo permanece em retrato.
- [ ] Criar três jornadas com nomes diferentes usando o teclado Samsung; salvar, fechar/reabrir e carregar cada slot. Cancelar uma exclusão e depois excluir somente o slot escolhido.
- [ ] Percorrer quatro abas, textos longos e configurações; usar toque e rolagem; testar Voltar com teclado, configurações, diálogo e categoria de combate abertos.
- [ ] Escolher acontecimentos e verificar d20, XP, Jenny, Saúde, itens e animações. Ativar Reduzir animações, ajustar volumes/silenciamento e confirmar persistência após reabrir.
- [ ] Entrar em combate, salvar durante um turno, fechar/carregar e confirmar Saúde, turno, equipamentos e continuidade; testar Nen/Hatsu quando disponíveis.
- [ ] Prosseguir pelo Exame Hunter e pela avaliação de Especialização quando disponíveis; conferir retomada e ausência de recompensas/rolagens repetidas.
- [ ] Alternar para outro aplicativo/bloquear a tela: áudio deve pausar e retomar sem sobreposição. Salvar e usar Voltar > Salvar e sair; reabrir e confirmar o progresso.
- [ ] Jogar uma sessão prolongada e observar travamentos, aquecimento, consumo e legibilidade. Registrar qualquer problema antes de considerar uma versão pública.

## Referências oficiais consultadas

- [Godot: Exporting for Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).
- [Godot 4.7.2, exportador Android](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/export/export_plugin.cpp), para defaults e validações da versão exata.
- [Downloads Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/).
- [Godot: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html).
- [Godot: DisplayServer, área segura](https://docs.godotengine.org/en/stable/classes/class_displayserver.html#class-displayserver-method-get-display-safe-area).
- [Godot: SceneTree, quit_on_go_back](https://docs.godotengine.org/en/stable/classes/class_scenetree.html#class-scenetree-property-quit-on-go-back).
- [Android SDK e Command-line Tools](https://developer.android.com/studio#command-tools).
- [Eclipse Adoptium, OpenJDK](https://adoptium.net/temurin/releases/?version=17).
- [Samsung Galaxy A15 5G: resolução 1080×2340](https://www.samsung.com/ie/business/smartphones/galaxy-a/galaxy-a15-5g-blue-128gb-sm-a156bzbdeub/).

As capturas em `tests/captures/android_*.png` são do computador e não constituem evidência de execução no telefone.
