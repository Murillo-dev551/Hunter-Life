# Hunter Life — Revisão Android 1: rolagem e tela cheia

## Escopo

Revisão exclusiva da interação Android. A primeira compilação foi instalada e executada no Galaxy A15 5G pelo desenvolvedor, que identificou ausência de arrasto e barras do sistema visíveis. Não foram modificados acontecimentos, combate, balanceamento, salvamentos v9, áudio ou animações.

O novo APK é **0.1.0-test2**, versionCode **2**, mesmo pacote `org.hunterlife.prototype`. O APK anterior foi preservado.

```text
C:\Users\muril\Downloads\Hunter life\Hunter_Life\builds\android\Hunter-Life-0.1.0-test2.apk
```

SHA-256: `2cdcd3e5a672a06e9aae94c9e7bf89d3c5d8d5dc6d285bfb1064a2b3e045750b`.

## Causa e correção da rolagem

Os botões usavam o filtro padrão `MOUSE_FILTER_STOP`. Na versão 4.7.2, esse filtro interrompe a propagação de eventos de mouse, `ScreenTouch` e `ScreenDrag` na árvore da GUI. Um arrasto iniciado sobre um botão não chegava ao `ScrollContainer`. A propagação forçada de eventos de roda não resolve isso: roda e arrasto são caminhos distintos no motor.

Uma fixture automatizada reproduziu a falha antes de habilitar a correção: o conteúdo não rolava e o gesto podia terminar como clique. Portanto, não se tratava apenas da ausência de barra de rolagem ou de um tamanho insuficiente do conteúdo.

`scripts/ui/touch_scroll.gd` estende o controle nativo e configura somente a rota de eventos:

- No Android, botões, containers e indicadores passivos dentro da área rolável deixam o ponteiro chegar ao ancestral ScrollContainer.
- `scroll_deadzone=12`, em unidades lógicas, distingue pequenos movimentos de um arrasto.
- `follow_focus=false` no Android evita que tocar um botão parcialmente visível reposicione a página antes do gesto. No Windows, o comportamento anterior é preservado, incluindo `follow_focus=true` nas páginas principais.
- O motor continua calculando deslocamento/inércia e emitindo `NOTIFICATION_SCROLL_BEGIN`. O `BaseButton` nativo cancela sua tentativa de clique ao receber essa notificação.
- Sliders, edição de texto, seletores de popup e barras de rolagem mantêm seu tratamento nativo. Por exemplo, arrastar o controle de volume continua ajustando o volume.
- A configuração acompanha controles adicionados posteriormente. Não há reconhecimento próprio de gestos, cálculo manual de velocidade ou processamento contínuo por quadro.

O componente é usado pelas quatro páginas, telas de criação/slots e pelo painel de configurações. Cabeçalho e navegação inferior não são transformados em áreas de arrasto. No Windows, a classe não habilita a configuração de toque: os filtros e a roda continuam como antes.

## Causa e correção da tela cheia

O preset anterior tinha `screen/immersive_mode=false`, mantendo as barras visíveis por configuração explícita.

A revisão ativa:

- `screen/immersive_mode=true` no preset Android.
- `window/size/mode.android=3`, modo fullscreen somente para Android.
- Solicitação nativa de fullscreen na inicialização e ao retomar foco/aplicativo, com recalculagem das margens existentes.

O código Java/Kotlin da versão exata do Godot usa `WindowInsetsControllerCompat` e `BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE`. Assim, o comportamento solicitado é ocultar status/navegação e permitir revelação temporária por gesto. Não há ocultação repetida a cada quadro que impeça consultar o sistema.

Retrato, edge-to-edge e conversão da área segura foram preservados. O recorte da câmera continua sendo considerado por `DisplayServer.get_display_safe_area()`. Não foi acrescentada uma margem fixa para uma barra que passa a estar oculta. O Windows não recebe fullscreen ou mudança de layout.

O argumento `--fullscreen` foi encontrado no arquivo de argumentos do APK gerado. A efetiva ocultação e retomada na One UI precisa ser conferida no aparelho; um teste Windows não comprova esse comportamento Android.

## Arquivos alterados

| Arquivo | Alteração |
|---|---|
| `scripts/ui/touch_scroll.gd` | Novo componente de configuração da rolagem nativa |
| `scripts/main.gd` | Uso do componente e solicitação de imersão no ciclo de vida |
| `scripts/ui/audio_settings.gd` | Troca do ScrollContainer pelo componente, sem alterar áudio ou preferências |
| `scripts/ui/mobile_layout.gd` | Solicitação de fullscreen protegida por plataforma |
| `project.godot` | Override fullscreen Android |
| `export_presets.cfg` | Modo imersivo, versionCode 2 e caminho test2 |
| `tools/export_android.ps1` | Novo nome de saída e parâmetro opcional OutputPath |
| `tests/check_android_apk.ps1` | Artefato padrão atualizado para test2 |
| `tests/test_touch_scroll.gd` | Reprodução da falha e regressões de toque/roda |
| `README.md`, `STAGE_ANDROID.md`, este relatório | Estado atual e instruções |

## Testes

Nova suíte: **25 verificações, zero falhas**, com renderização real no PC e emulação do caminho nativo de toque. Exercita:

- Reprodução com filtro STOP e comparação com a configuração corrigida.
- Arrasto para cima e para baixo, inclusive iniciado dentro de botão.
- Cancelamento nativo de clique; toque simples executado uma única vez.
- Eventos `ScreenTouch`/`ScreenDrag` e ausência de dupla seleção pela emulação de mouse.
- Movimento abaixo da zona morta tratado como toque pelo motor.
- Roda do mouse e controles inseridos dinamicamente.
- Aventura, Personagem, Inventário, Registro, slots e combate; sem mudanças em RNG, recursos ou turnos por arrasto.
- Preservação do controle de volume e ausência de fullscreen na janela Windows.

Todas as suítes anteriores foram executadas novamente: **36 suítes, 37.262 verificações, zero falhas de asserção**. O resumo acompanha os logs `tests/android_r1_*.log`. A verificação de integridade do novo APK passou nas **28 verificações**, preservando os 92 acontecimentos e recursos locais e confirmando o argumento fullscreen e o componente de rolagem compilado. Assinatura debug v2/v3 e alinhamento foram verificados pelo processo de exportação. O certificado público foi comparado com o APK anterior e permaneceu idêntico, permitindo atualizar sem desinstalar.

Para reproduzir o teste de interação:

```powershell
$env:HUNTER_LIFE_DATA_ROOT = 'user://touch_scroll_' + [DateTime]::UtcNow.Ticks
godot --path . --script res://tests/test_touch_scroll.gd
Remove-Item Env:HUNTER_LIFE_DATA_ROOT
```

`Input.emulate_touch_from_mouse` é habilitado apenas dentro da suíte para exercitar o caminho de touchscreen no PC. Não foi ativado globalmente no jogo Windows. Algumas suítes antigas continuam emitindo os avisos de descarte de áudio no encerramento abrupto já documentados na 10G; não são erros de regras ou scripts durante as ações.

## Instalar por cima e validar no A15 5G

Antes da atualização, salve a jornada pelo Registro: instalar uma atualização pode encerrar o processo atual. Instale `Hunter-Life-0.1.0-test2.apk` **por cima da versão anterior**, mantendo o aplicativo e seus dados. O pacote é o mesmo e a versão aumentou. Não é necessário desinstalar.

Por arquivo, copie para Downloads e abra em Meus Arquivos. Por ADB:

```powershell
$adb = "$env:LOCALAPPDATA\HunterLifeBuild\sdk\platform-tools\adb.exe"
& $adb install -r '.\builds\android\Hunter-Life-0.1.0-test2.apk'
```

Checklist da revisão:

1. Deslizar para cima/baixo sobre texto, cartão e botão nas quatro abas e no combate. O arrasto não deve escolher, atacar, consumir ou salvar.
2. Tocar rapidamente em uma opção: executar uma vez. Conferir também botões desabilitados, configurações e slots.
3. Conferir barras de status/navegação ocultas, retrato e ausência de conteúdo sob a câmera.
4. Deslizar a partir da borda para revelar temporariamente as barras do sistema.
5. Minimizar/reabrir, bloquear/desbloquear e abrir/fechar o teclado: confirmar retorno à tela cheia e rolagem normal.
6. Conferir que os slots e as preferências anteriores continuam presentes.

Nenhum aparelho estava conectado ao ADB durante esta revisão. Os testes no computador verificam o encaminhamento dos eventos, as regras e a configuração exportada; não substituem essa validação física. A v0.1.1 não foi iniciada.

## Referências oficiais

- [Godot: ScrollContainer](https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html), zona morta e acompanhamento de foco.
- [Viewport 4.7.2: propagação da GUI](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/main/viewport.cpp).
- [ScrollContainer 4.7.2: arrasto nativo](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/gui/scroll_container.cpp).
- [BaseButton 4.7.2: cancelamento no início da rolagem](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/gui/base_button.cpp).
- [Godot Android 4.7.2: implementação do modo imersivo](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/java/lib/src/main/java/org/godotengine/godot/Godot.kt).
- [Android: Hide system bars for immersive mode](https://developer.android.com/develop/ui/views/layout/immersive).
