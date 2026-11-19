# Hunter Life — Etapa 6: Hatsus e personalização

Projeto existente preservado. Godot 4.7.2, quatro abas, tema de diário, curva de XP e RNG anteriores mantidos. Há 33 acontecimentos: 29 anteriores e quatro novos, sem batalhas ou nova campanha extensa.

## Como acessar
Crie ou continue uma jornada. Aprenda os fundamentos com Mira e revele a categoria na água. Sem requisitos de nível ou Exame Hunter, uma oportunidade prática pode aparecer entre os acontecimentos normais se a afinidade for Reforço ou Emissão. Categoria não é alterada nem favorecida pelo novo sistema. Nas outras quatro categorias, a seção Nen informa discretamente que ainda não há Hatsu implementado.
Escolher uma especialização realiza uma prova prática supervisionada. Sucesso executa a tarefa completa e concede 12 XP. No fracasso Mira simplifica o exercício: o personagem aprende a forma básica escolhida, recebe 4 XP e a prova não é concluída integralmente. Não há repetição obrigatória. O Hatsu não é concedido pelo teste da água.
A especialização é permanente nesta etapa. Reabrir o acontecimento, carregar o save ou clicar outra vez não permite trocá-la nem receber novamente os ganhos. Recusar a oportunidade única de desenvolvimento significa seguir sem esse Hatsu nesta jornada.

## Habilidades e aplicações
| Hatsu | Especialização | Aplicação |
|---|---|---|
| Corpo Temperado | Potência | Mover a viga: Força, dificuldade 12, comparada à opção comum com dificuldade 15 |
| Corpo Temperado | Resistência | Proteger a retirada: Agilidade 15, com dano de fracasso reduzido a 1 nessa situação; a opção comum pode causar 3 |
| Projétil de Aura | Potência | Romper um apoio preso: Intelecto 13, impacto sem atingir pessoas |
| Projétil de Aura | Alcance | Tocar uma bandeira distante: Agilidade 13 |
| Projétil de Aura | Precisão | Liberar uma trava pequena: Intelecto 12 |

Os efeitos são escolhas JSON específicas. Não há bônus global nem modificação da fórmula. A interface usa a dificuldade real daquela escolha e a chance é enumerada com o mesmo d20 + atributo >= dificuldade. Atributo 5 tem 70% contra dificuldade 12, 65% contra 13 e 55% contra 15. Todos esses testes ainda podem falhar.
As consequências narrativas explicam impacto, distância, precisão ou amortecimento. Resistência não protege universalmente; efeitos de Saúde fora dessa escolha continuam normais. Nenhum Hatsu concede imunidade, projéteis em tempo real ou vitória automática.

## Acontecimentos
Novos: develop_reinforce (caixa pesada e apoio acolchoado), develop_emission (três alvos supervisionados), blocked_passage (viga no armazém) e signal_roof (bandeira e trava). Os dois últimos têm alternativas sem Nen: coordenar trabalhadores, chamar o encarregado, segurar uma escada ou seguir viagem. As duas aventuras anteriores não foram reescritas e não exigem Hatsu.
Alterado: nen_zetsu. Agora permite realizar uma prova de Intelecto 13 ou pedir acompanhamento. Sucesso concede 8 XP, aprende a técnica e conclui a prova independente; fracasso concede 3 XP e aprende de forma assistida, com a flag zetsu_guided. Pedir orientação desde o início concede 4 XP e também segue para Ren. A falha não cria um ciclo de tentativas. Essa flag registra a experiência; não é uma árvore de treino ou penalidade permanente.

## Persistência v6
Adiciona hatsu={id,specialization,learned}. O evento atual e selected_choice representam a prova ainda não resolvida ou já concluída. Não há estado intermediário de treinamento nem coleção de habilidades.
IDs: reinforce/emission. Especializações: power/resistance/range/precision, limitadas ao conjunto apropriado de cada Hatsu. Validação exige categoria revelada, os três fundamentos e compatibilidade da especialização. Save com Hatsu incompatível é recusado.
V5 migra para Hatsu não desenvolvido, sem mudar afinidade, RNG, atributos, XP ou histórico. Migrações v2–v4 continuam funcionando. Carregar não grava ou exclui o slot manual. O próximo salvamento explícito passa a usar v6. A afinidade oculta criada na Etapa 5 não é sorteada novamente.

## Arquivos
Criados: scripts/hatsu.gd; tests/test_hatsu.gd; tests/test_hatsu_visual.gd; STAGE_6.md.
Modificados: scripts/game_state.gd; scripts/catalog.gd; scripts/storage.gd; scripts/main.gd; scripts/ui/adventure_view.gd; data/events.json; project.godot; tests/test_foundation.gd; tests/test_narrative.gd; tests/test_journeys.gd; README.md.
A view recebeu quebra de linha em legendas longas para preservar a largura de janelas compactas. O tema, a cena principal, os ícones e as abas não foram redesenhados. Nenhum arquivo de One Piece Life foi alterado.

## Testes
Godot 4.7.2: foundation 41, narrative 1280, story_ui 26, journeys 237, progression 430, progression_ui 4, nen 1239, visual 348, nen_visual 34, hatsu 218 e hatsu_visual 180: **4037 verificações, zero falhas**.
65 capturas: 35 das telas anteriores, cinco de Nen e 25 de Hatsus, cobrindo as cinco especializações em 320×480, 390×844, 480×860, 768×1024 e 1100×720. A seção Emissão/Precisão foi inspecionada visualmente. Os testes visuais acionam as escolhas reais de desenvolvimento, conferem largura das escolhas e posição da navegação.
Foram testados os cinco desbloqueios, bloqueio antes de requisitos, categorias não suportadas, prova antes da revelação, imutabilidade da especialização, probabilidades, fracasso e sucesso, redução contextual de dano, save v6 resolvido, rejeição de Hatsu incompatível e migração v5 preservando a afinidade. Regressões continuam cobrindo as duas aventuras nas duas ordens e a água sem rerrolagem.
Simulações específicas completaram 50 jornadas com Hatsu desenvolvido e 50 sem Hatsu, sempre com fundamentos e categoria de Reforço/Emissão preparados como fixtures. Sem Hatsu: níveis finais 1/2/3 em 8/33/9 casos; com Hatsu: 9/30/11. As opções são sorteadas entre escolhas elegíveis, portanto essa amostra não é uma comparação causal de força. Os 100 percursos chegaram a encerramentos sem bloqueios. Testes dirigidos demonstraram tanto sucesso quanto fracasso nas aplicações e no novo aprendizado de Zetsu.
Também foram repetidas as simulações anteriores de 100 jornadas gerais e 100 com/sem Nen. Seus dados completos estão nos logs tests/stage6_*.log.

Execute com Godot no PATH: `godot --headless --path . --script res://tests/test_hatsu.gd`. Para imagens, execute `godot --path . --script res://tests/test_hatsu_visual.gd` sem headless. As demais suítes existentes também foram executadas.

## Limitações
Uma especialização fixa por personagem; não há oportunidade de redistribuição nesta etapa. Desenvolvimento compacto de uma cena por categoria e duas situações de aplicação. Um fracasso no desenvolvimento ensina uma versão básica por orientação assistida, sem graduação adicional de domínio. As outras quatro categorias não têm Hatsus. Sem batalhas, aura consumível, animações físicas, equipamentos, inventário funcional, NPCs autônomos, calendário, mundo aberto ou arquitetura antecipada da Etapa 7. O save continua local, manual e em um slot.
