# Hunter Life — Etapa 10G: Áudio e Identidade Visual

## Entrega

Implementação validada no Godot **4.7.2.stable.official.ed1daf0bf**, Windows, renderização OpenGL de compatibilidade. A Etapa 10H não foi iniciada.

Os 92 acontecimentos, identificadores, textos, condições e recompensas foram preservados. Não houve alterações em `game_state.gd`, `battle.gd`, Nen, Hatsus, inventário, catálogo narrativo, formato v9, migrações ou checkpoints. Os projetos One Piece Life não foram modificados.

## Áudio

O autoload `Audio` mantém somente dois `AudioStreamPlayer`: música ambiente contínua e uma voz para efeitos. Os canais `Music` e `Effects` são criados uma única vez e encaminhados ao Master. A navegação não recria os reprodutores.

**Caderno de campo**, `assets/audio/music/field_notes.wav`, é uma composição original de 64 segundos, instrumental, sem vocais, com arpejos e timbres sintetizados suaves. O gerador distribui as caudas das notas circularmente. O loop usa a duração em amostras, independentemente do formato de compressão. Há entrada gradual de 1,2 segundo e saída pela janela com redução gradual e liberação dos reprodutores.

| Efeito | Duração | Uso |
|---|---:|---|
| click | 0,12 s | Confirmação comum |
| select | 0,42 s | Escolha narrativa ou ação resolvida |
| tab | 0,42 s | Abas e categorias de combate |
| back | 0,42 s | Voltar, cancelar e concluir configurações |
| success | 0,42 s | Sucesso d20 já resolvido |
| failure | 0,42 s | Fracasso d20 já resolvido |
| reward | 0,42 s | XP ou Jenny recebidos |
| level | 0,80 s | Subida de nível |

No mesmo quadro, o aviso de maior prioridade substitui os demais: nível > recompensa > resultado de teste > seleção > navegação > clique. Portanto, uma escolha com sucesso e recompensa toca um único aviso de recompensa. Novas interações substituem o efeito anterior; não há fila longa nem vozes sobrepostas. Não são usados sons de hover ou atualização de textos, esperas na resolução, variações aleatórias de pitch ou chamadas ao RNG.

A interface compara nível, XP e Jenny antes/depois de uma ação aceita. Para o resultado d20, lê o texto de resultado já calculado em português; não realiza testes adicionais. Essa dependência de apresentação está isolada em `main.gd::result_sound` e coberta por testes.

## Preferências globais

`user://audio.cfg`, formato ConfigFile, separado de `saves/`. Os volumes padrão são **22% para música e 50% para efeitos**; ambos inicialmente não silenciados. A faixa musical tem pico PCM de aproximadamente 0,179 e RMS 0,044 antes do volume do canal, deixando margem ampla contra clipping. Todos os arquivos foram analisados pelo gerador, com resultados em `assets/audio/analysis.json`.

As preferências incluem `music`, `effects`, `mute_music` e `mute_effects`. Sliders e checkboxes aplicam os valores imediatamente; a gravação usa arquivo temporário e renomeação. Silenciar preserva a posição da música. Valores são limitados a 0–1; tipos incompatíveis, NaN e infinito são descartados. Arquivos ausentes ou malformados usam padrões seguros. Falhas de gravação têm mensagem contextual.

O botão acessível **Configurações de áudio** fica no cabeçalho, disponível também nos slots e na criação. A janela usa o tema existente, controles nativos, rolagem para telas compactas e botão Concluir. Não foi criada outra aba. `HUNTER_LIFE_DATA_ROOT` também isola as preferências nos testes.

## Emblema e ícones

Recursos originais SVG: dez ícones de traço uniforme para Aventura, Personagem, Inventário, Registro, ajustes, salvamentos e quatro categorias de combate. O emblema colorido combina cartão, bússola, marfim, verde e dourado. Não reproduz a arte oficial da licença e não altera o status do personagem.

O mesmo cabeçalho apresenta o emblema no menu inicial e durante a jornada. Textos, quatro abas, informações do combate e áreas de interação foram mantidos. Os ícones de combate usam os mesmos botões e identificadores existentes.

## Recursos, licenças e referências consultadas

Todos os nove WAV e onze SVG foram criados para o projeto, sem samples, melodias, bibliotecas gráficas, fontes novas ou imagens de terceiros. Os recursos e geradores originais são disponibilizados sob CC0 1.0, conforme [ASSET_LICENSES.md](assets/ASSET_LICENSES.md); não há atribuição obrigatória. Isso não concede direitos sobre a franquia Hunter × Hunter. Node.js é usado somente para reproduzir os geradores em desenvolvimento.

Fontes técnicas efetivamente consultadas:

- [Godot: AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html): reprodutores não posicionais, canais e polifonia.
- [Godot: AudioStreamWAV](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html): loop e duração em amostras.
- [Godot: Audio buses](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html): roteamento e controle de volume.
- [Godot: ConfigFile](https://docs.godotengine.org/en/stable/classes/class_configfile.html): persistência de preferências.
- [Godot: Window](https://docs.godotengine.org/en/stable/classes/class_window.html): comportamento e apresentação de diálogos.
- [Godot, ocorrência #76745](https://github.com/godotengine/godot/issues/76745): referências de áudio retidas durante encerramento imediato e necessidade de permitir liberação assíncrona.

A documentação consultada está no canal stable; as APIs utilizadas foram verificadas executando o motor instalado. Nenhum exemplo foi copiado como recurso de áudio ou arte. Não foi necessário obter material oficial da Licença Hunter.

## Arquivos criados e modificados nesta etapa

| Arquivo/grupo | Alteração |
|---|---|
| `scripts/audio_manager.gd` | Autoload, reprodutores, preferências, arbitragem de efeitos e encerramento |
| `scripts/ui/audio_settings.gd` | Painel de configurações |
| `scripts/main.gd` | Cabeçalho, emblema, ajustes, avisos de resultado e ícone de salvamento |
| `scripts/ui/styles.gd` | Som comum dos botões e aplicação consistente de ícones |
| `scripts/ui/line_icon.gd` | SVGs preservando a API existente de cor e tipo |
| `scripts/ui/battle_view.gd` | Ícones e sons de navegação das categorias |
| `project.godot` | Registro do autoload de áudio |
| `export_presets.cfg` | Pacote Windows Desktop incluindo JSONs e licença dos recursos; testes e geradores excluídos |
| `assets/audio/music/`, `assets/audio/sfx/` | Uma música e oito efeitos WAV, com metadados de importação |
| `assets/icons/` | Dez ícones e emblema SVG, com metadados de importação |
| `assets/ASSET_LICENSES.md`, `assets/audio/analysis.json` | Proveniência, licença e análise de amplitude |
| `tools/create_audio.cjs`, `tools/create_icons.cjs` | Geradores originais, determinísticos e sem dependências |
| `tests/test_audio_identity.gd` | Testes de áudio, configurações, integridade e capturas |
| `tests/test_export_assets.gd` | Verificação dos recursos no pacote exportado |
| `tests/captures/10g_*.png` | Sete novas capturas |
| `README.md`, `STAGE_10G.md` | Documentação atualizada |

As suítes visuais anteriores também regeneraram suas imagens e resultados de simulação durante a execução. Modificações anteriores da 10F já existentes no diretório foram preservadas.

## Validação executada

**33 suítes distintas**, incluindo 31 anteriores e duas novas. A suíte de áudio foi executada outra vez em um segundo processo para verificar restauração. A rodada principal e o teste de restauração somam **37.148 verificações, zero falhas de asserção**: 37.016 anteriores + 54 de áudio/interface + 55 na segunda sessão + 23 de recursos exportados. Após os ajustes finais, slots/interface e menu de combate foram reexecutados: outras 55 e 203 verificações sem falhas.

| Área | Resultado |
|---|---|
| Importação, scripts e recursos | Importação concluída no editor; execução real do projeto |
| Áudio | Uma música e uma voz; oito efeitos; prioridade; loop atravessando o fim; troca de abas sem reinício |
| Configurações | Volumes imediatos; mute independente; arquivo ausente, malformado, tipos inválidos, NaN/infinito; restauração em outro processo |
| Integridade | Serialização e RNG idênticos antes/depois de navegação e áudio; combate sem consumo de turnos por categorias |
| Slots e afinidade | Suítes de slots, interface e avaliação completas; isolamento e checkpoints preservados |
| Sistemas anteriores | Fundação, narrativa, jornadas, progressão, textos, Nen, cinco Hatsus, Especialista, inventário, Exame e expansões passaram |
| Renderização | Suítes anteriores em 320×480, 390×844, 480×860, 768×1024 e 1100×720; novas capturas em 320×480, 480×860 e 960×720 |
| Exportação | PCK gerado e aberto em diretório vazio; música, oito efeitos, onze SVGs, licença e painel de configurações disponíveis |

As simulações anteriores mantiveram seus resultados: 16 combinações do exame; 249 aprovações/51 reprovações na amostra; inventário com 191 vitórias sem equipamento e 199 equipado; distribuição de níveis das 100 jornadas: nível 1 = 10, nível 2 = 35, nível 3 = 42 e nível 4 = 13. O áudio não modificou essas mecânicas.

Falhas encontradas e corrigidas durante o desenvolvimento: cálculo do loop baseado incorretamente nos bytes de áudio comprimido; diálogo de configurações excedendo a janela compacta; contraste dos checkboxes; decoração do título do diálogo. A suíte final de áudio e o teste do pacote encerraram sem erros ou avisos de recursos retidos.

### Reprodução dos testes novos

Na pasta do projeto, com `godot` apontando para o executável 4.7.2:

```powershell
$env:HUNTER_LIFE_DATA_ROOT = 'user://test_audio_' + [DateTime]::UtcNow.Ticks
godot --path . --script res://tests/test_audio_identity.gd
$env:HUNTER_LIFE_AUDIO_EXPECT_RESTORED = '1'
godot --path . --script res://tests/test_audio_identity.gd
Remove-Item Env:HUNTER_LIFE_AUDIO_EXPECT_RESTORED

$projectRoot = (Get-Location).Path
$packPath = Join-Path $env:TEMP 'hunter-life-10g.pck'
$emptyPath = Join-Path $env:TEMP 'hunter-life-10g-empty'
New-Item -ItemType Directory -Force -Path $emptyPath | Out-Null
godot --headless --path . --export-pack 'Windows Desktop' $packPath
godot --path $emptyPath --main-pack $packPath --script (Join-Path $projectRoot 'tests/test_export_assets.gd')
Remove-Item Env:HUNTER_LIFE_DATA_ROOT
```

Os testes não devem ser executados sem o isolamento indicado. Logs locais: `tests/stage10g_*.log`.

## Capturas inspecionadas

- [Menu de slots e emblema, 480×860](tests/captures/10g_slots_480.png).
- [Configurações compactas, 320×480](tests/captures/10g_settings_320.png).
- [Configurações, 480×860](tests/captures/10g_settings_480.png).
- [Configurações, 960×720](tests/captures/10g_settings_960.png).
- [Combate com ícones](tests/captures/10g_combat.png).

## Compatibilidade e limitações

O salvamento continua **v9**, sem migração nova. Não são adicionadas preferências aos personagens. Slots, identidade de jornada, checkpoints e arquivos antigos permanecem como estavam. Os testes utilizaram dados separados.

Algumas suítes antigas usam `SceneTree.quit()` enquanto o áudio está tocando: o motor ainda pode emitir `ObjectDB instances leaked at exit` e `resources still in use at exit`. A investigação encontrou o comportamento de liberação assíncrona documentado na ocorrência oficial citada. Não são falhas de asserção nem erros de scripts durante a jornada. O fechamento normal pela janela e os novos testes interrompem os reprodutores e permitem sua liberação antes de sair. Interromper pelo editor ou forçar o processo pode continuar mostrando o aviso.

A reprodução e os sinais de áudio foram verificados pelo motor, mas não houve avaliação humana com fones/alto-falantes da qualidade musical. Ajustes de timbre e volume podem ser feitos após essa avaliação. Não foram testados dispositivos móveis físicos, exportação web ou um executável Windows independente; foi validado o pacote PCK executado pelo Godot instalado. Não há trilha dinâmica, gravações acústicas, ícones oficiais, animações ou outros recursos da 10H.
