# Hunter Life — Etapa 10H: Animações e Refinamento dos Menus

## Resultado e preservação

A interface recebeu feedback visual curto, transições interrompíveis e configurações compactas. O texto inteiro e os controles ficam disponíveis imediatamente. Não há digitação gradual, espera obrigatória, bloqueio de entrada ou callbacks de animação que executem ações do jogo.

Validação no Godot **4.7.2.stable.official.ed1daf0bf**, Windows/OpenGL. Os 92 acontecimentos e seus textos, personagens, itens, cinco Hatsus/11 especializações, atributos, recompensas, probabilidades, batalhas, slots e checkpoints não foram modificados. O save dos personagens continua **v9**. Nenhum sistema ou etapa posterior foi iniciado.

## Animações e estados visuais

| Interação | Apresentação | Duração |
|---|---|---:|
| Pressionar botão | Luminosidade suave, além do estado pressionado do tema | 0,10 s |
| Trocar aba | Opacidade de 88% até 100%; conteúdo já legível | 0,14 s |
| Novo acontecimento | Entrada suave da apresentação existente | 0,14 s |
| Categorias de combate | Entrada do menu/submenu escolhido | 0,14 s |
| Resultado e recompensa | Entrada breve e borda/tom semântico | 0,14 s |

Não foram usados deslocamentos, mudanças de escala, partículas ou animações de personagens. Bordas semânticas permanecem como informação estática até a atualização do conteúdo. Foco por teclado usa a borda dourada do tema; pressão por mouse, teclado e toque passa pelo sinal nativo `button_down`. Botões desabilitados continuam com estilo próprio. A opção narrativa escolhida tem borda dourada e mantém a indicação textual **Sua escolha**.

`scripts/ui/motion.gd` centraliza os efeitos. Um novo tween substitui o anterior do mesmo controle. Os tweens ficam vinculados aos controles, e o registro usa referências fracas; não há processamento contínuo de animações ociosas. Ao sair de uma aba, sua transição é encerrada. Foram exercitadas 100 trocas consecutivas sem modificar estado/RNG ou acumular transições em abas ocultas.

## Resultados, recompensas e combate

`interaction_feedback.gd` captura uma fotografia pequena antes de uma ação e compara somente dados já resolvidos. Não concede XP, Jenny, itens, cura, flags ou recompensas. `main.gd` chama o feedback somente depois de uma ação aceita, incluindo a abertura do resultado do Exame Hunter, onde a licença é realmente concedida pelo sistema existente.

- Sucesso d20 recebe borda verde; fracasso recebe vermelho discreto. A rolagem e o texto **sucesso/fracasso** continuam visíveis.
- Ganhos de XP/Jenny destacam as informações do cabeçalho. Nível e Licença Hunter podem destacar o cartão em dourado; isso não mascara um fracasso.
- Aquisições de itens destacam brevemente o acesso ao Inventário; a descrição e a quantidade recebida continuam no resultado narrativo existente.
- Dano em batalha destaca em vermelho o cartão que contém a Saúde. O resultado da ação fica separado: defender pode reduzir dano e criar abertura mesmo recebendo um ferimento, exatamente como antes.
- Defesa, esquiva, execução e encerramento usam o resultado já registrado. As quatro categorias, ações, testes, cooldowns e intenções permanecem intactos.

Nenhum texto de recompensa adicional é inserido. Reconstrução de tela e carregamento limpam o recibo visual; cliques rejeitados não renovam o feedback. A música e os efeitos da 10G são preservados, e animações não disparam sons.

## Movimento reduzido e configurações

**Reduzir animações** é uma preferência global booleana, padrão `false`. A infraestrutura de preferências da 10G é reutilizada: o arquivo continua `user://audio.cfg`, com uma seção separada `[accessibility]`, chave `reduce_motion`. Os valores de áudio permanecem em `[audio]`. Os personagens e slots não recebem campos novos.

Ativar a opção interrompe os tweens visuais registrados, restaura opacidade/luminosidade e torna as próximas atualizações imediatas. Bordas, foco e textos de resultado permanecem. O áudio não é silenciado ou reiniciado por essa preferência. Preferências antigas sem a chave recebem o padrão; tipos inválidos são descartados. A restauração foi testada tanto pelo arquivo quanto em outro processo.

A janela de configurações é reutilizada ao reabrir e sincroniza controles sem emitir alterações artificiais. Música, efeitos e movimento reduzido cabem em um painel compacto com Concluir acessível. A rolagem permanece disponível para mensagens excepcionais, mas não aparece desnecessariamente no conteúdo normal nas cinco resoluções verificadas.

## Refinamentos dos menus e comparação com a 10G

| Área | 10G | 10H |
|---|---|---|
| Configurações | Título longo, silenciar em linhas separadas, janela solicitada de 360×390 | Título curto, silenciar alinhado ao volume, janela solicitada de 340×340 e preferência de acessibilidade |
| Rolagem compacta | Barra evidente em 320×480 | Conteúdo normal sem rolagem nas cinco resoluções |
| Slots | Nome e resumo | Estados explícitos Vazio/Jornada salva/Arquivo inválido/Jornada em uso; destaque do slot ativo e erro |
| Combate | Quatro categorias com ícones | Mesmas categorias; separador dos comandos, ícones também nos títulos de submenus e resultados visualmente separados da Saúde |
| Escolhas | Indisponibilidade após decisão | Opção escolhida reconhecível mesmo desabilitada |
| Cabeçalho/navegação | Emblema e ícones | Estrutura preservada, foco/seleção consistentes e transição curta; botão geral Configurações |

A descrição narrativa não foi reescrita. O espaçamento interno do cartão foi ajustado pontualmente, sem aumentar a altura dos menus de forma geral. As novas capturas identificadas por `10h_` mostram o estado atual. As suítes visuais antigas regeneram seus próprios arquivos, portanto os nomes antigos de capturas não devem ser usados como uma cópia imutável da 10G.

## Arquivos desta etapa

| Arquivo | Mudança |
|---|---|
| `scripts/ui/motion.gd` | Novo utilitário de tweens interrompíveis e realces estáticos |
| `scripts/ui/interaction_feedback.gd` | Novo comparador de resultados já aplicados |
| `scripts/ui/styles.gd` | Resposta visual ao pressionar botões |
| `scripts/main.gd` | Transições, feedback após ações, slots, sincronização/reutilização das configurações |
| `scripts/ui/adventure_view.gd` | Cartão narrativo, espaçamento e escolha selecionada |
| `scripts/ui/battle_view.gd` | Realces de Saúde/resultado, separador e cabeçalhos dos submenus |
| `scripts/ui/audio_settings.gd` | Configurações compactas e movimento reduzido |
| `scripts/audio_manager.gd` | Persistência tipada da acessibilidade e notificação de preferências |
| `tests/test_polish.gd` | Nova suíte funcional/visual e capturas |
| `tests/captures/10h_*.png` | 20 capturas de slots, configurações, resultados e combate |
| `README.md`, `STAGE_10H.md` | Estado atual e relatório |

Não foram alterados recursos de música/efeitos, SVGs, catálogo, motor narrativo, fórmulas de combate ou migrações dos personagens. Alterações anteriores que já existiam na pasta foram preservadas.

## Testes executados

**34 suítes distintas: 33 anteriores e a nova suíte de polimento.** A rodada das 33 anteriores somou **37.093 verificações sem falhas de asserção**. A versão final da nova suíte passou em **104 verificações**, e sua repetição em outro processo passou em **105**, incluindo restauração de movimento reduzido. A execução da 10G em outro processo também passou em 55 verificações.

As verificações de UI de slots, menu de combate, continuidade e áudio foram reexecutadas após ajustes. Um novo PCK foi gerado e aberto em pasta vazia: os 23 testes de recursos exportados passaram, incluindo a janela atual de configurações.

| Área | Evidência |
|---|---|
| Botões | Pressão imediata, foco real e borda de foco, estilo de indisponibilidade |
| Navegação | 100 trocas rápidas; última aba correta; música mantida; dados/RNG iguais |
| Resultados | Sucesso e fracasso reais, XP/Jenny, nível, aquisição de bandagem e concessão da Licença Hunter |
| Repetição/carregamento | Clique já resolvido não muda dados/feedback; reconstrução não reapresenta conquistas |
| Combate | Defesa, esquiva, ataque e rendição; dano, abertura e encerramento; navegação sem turno/RNG |
| Acessibilidade | Cancelamento dos tweens ativos, resultados estáticos, arquivo e restauração entre processos |
| Menus | Slot ocupado/vazio/inválido, janela reutilizada, cancelamento de exclusão, cabeçalho e navegação dentro da janela |
| Layout | 320×480, 390×844, 480×860, 768×1024 e 1100×720; configurações sem rolagem normal |
| Regressões | Narrativa, duas expansões, Nen, cinco Hatsus, Especialista, inventário, Exame, persistência/slots/checkpoints, progressão e todas as suítes visuais anteriores |

Falhas encontradas durante o desenvolvimento: acesso a metadado inexistente antes do primeiro tween (corrigido com `has_meta`); fixture de teste que podia visitar um acontecimento duas vezes antes da asserção de XP (corrigida sem alterar a progressão); teste de defesa que confundia defesa bem-sucedida com ausência total de dano (corrigido para verificar a abertura produzida pela regra existente). Nenhuma fórmula ou recompensa foi alterada para satisfazer testes.

### Executar a suíte nova

```powershell
$env:HUNTER_LIFE_DATA_ROOT = 'user://test_polish_' + [DateTime]::UtcNow.Ticks
godot --path . --script res://tests/test_polish.gd
$env:HUNTER_LIFE_MOTION_EXPECT_RESTORED = '1'
godot --path . --script res://tests/test_polish.gd
Remove-Item Env:HUNTER_LIFE_MOTION_EXPECT_RESTORED
Remove-Item Env:HUNTER_LIFE_DATA_ROOT
```

Use renderização real, sem `--headless`. A suíte mantém os slots de teste em subdiretórios próprios; o ambiente indicado também isola preferências. Logs: `tests/stage10h_*.log`. Para as demais suítes, consulte o README; para reprodução da exportação PCK, o procedimento da 10G continua aplicável.

## Capturas

- [Configurações compactas, 320×480](tests/captures/10h_settings_320.png).
- [Configurações, 390×844](tests/captures/10h_settings_390.png).
- [Slots, 480×860](tests/captures/10h_slots_480.png).
- [Resultado, 320×480](tests/captures/10h_result_320.png).
- [Combate após defesa, 480×860](tests/captures/10h_combat_480.png).
- [Configurações, 1100×720](tests/captures/10h_settings_1100.png).

## Limitações e referências

Os testes foram realizados no PC, com tamanhos de janela simulando telas compactas. Não houve teste em celular físico, leitor de tela ou diferentes escalas de texto do sistema. O toque usa o comportamento nativo de Button, mas não foi validado em hardware de toque. O feedback foi implementado somente sobre os resultados existentes, sem novos sistemas de notificação.

Permanece o aviso do motor identificado na 10G quando testes antigos chamam `SceneTree.quit()` com áudio ainda em reprodução. Isso aparece no encerramento, não como falha de regras ou scripts durante a partida. A saída normal e as novas suítes permitem liberar o áudio gradualmente.

Foi consultada a [documentação oficial de Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html), especialmente vinculação ao nó e substituição de animações anteriores com `kill()`. As APIs foram verificadas no executável instalado. Não foram adicionados recursos de terceiros ou dependências. Os relatórios históricos foram preservados.
