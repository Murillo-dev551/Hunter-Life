# Hunter Life — Etapa 4: Progressão, XP e recursos

Projeto existente, com os mesmos 23 acontecimentos, duas aventuras e quatro abas. Abra project.godot no Godot 4.7.2 e pressione F5. Escolhas relevantes concedem XP; em Personagem distribua pontos quando disponíveis. Salve em Registro e continue pela tela inicial.

## Regras
- Nível inicial 1, saldo de XP 0, Saúde 10/10 e pontos 0.
- XP necessário para o próximo nível: 80 + 40 × (nível atual − 1). Custos: 80, 120, 160, 200... O saldo consumido é descontado, com excedente preservado. Totais para níveis 2/3/4: 80/200/360 XP.
- Cada nível concede um ponto, limitado às vagas restantes até atributos 10. Pontos guardados persistem. Se todos estiverem no teto, níveis podem continuar, mas não geram pontos inutilizáveis. A distribuição é atômica e registrada no histórico.
- Força, Agilidade, Intelecto e Presença continuam entre 1 e 10. Perfis iniciais preservados. Não há ganho de atributo em todo sucesso; a descoberta única da alavanca mantém a recompensa excepcional da etapa anterior.
- A probabilidade enumera os 20 resultados de 1d20 + atributo >= dificuldade; exibe de 0% a 100%, em passos de 5. Atributo 5 com dificuldade 15 resulta em 55%; dificuldade 16, 50%. O resultado usa a rolagem d20 existente, não um sorteio percentual adicional.
- Saúde é independente: 0–10, sem perda pelo avanço de acontecimentos. Fracassos físicos específicos podem causar dano. As escolhas de abrigo na chuva recuperam 3 ou 1, sem ultrapassar 10.
- Saúde zero termina a jornada: o personagem recebe socorro e abandona a vida de aventuras. Não há morte automática. Continuações, novas escolhas e distribuição de pontos ficam bloqueadas; registro, salvamento e criação de outro personagem continuam disponíveis. Nenhum evento novo foi criado para esse encerramento.

## Conteúdo alterado
Recompensas estão nos efeitos JSON xp e health, inclusive nos blocos failure. Sucesso e fracasso não são somados.

| Acontecimento | XP e recursos principais |
|---|---|
| Contas no mercado | 8 XP ao conferir; 3 no fracasso |
| A prova da praça | 18/6 XP na prova; fracasso -1 Saúde; equipe 12/4 XP |
| Uma carroça atolada | Força 15/5 XP, fracasso -1 Saúde; alavanca 20/5 XP |
| Um viajante perdido | Negociação 10/4 XP |
| Um mural de oportunidades | Verificação 12/3 XP |
| Antes da subida | Preparar o mapa: 8 XP |
| A ponte danificada | Teste 20/8 XP, fracasso -2 Saúde; desvio 12; travessia paga 8 |
| O abrigo da serra | Concluir a entrega: 40 XP |
| Uma bifurcação apagada | Leitura 18/6 XP; mapa 10; subida 20/7 e fracasso -2 Saúde |
| O marco e o riacho | Relato honesto 25; relato falso 8; conferência com corda 30 |
| Um turno no cais | Conferência 5; carregamento 10/4 XP |
| Um abrigo na chuva | Recuperação +3 ou +1 Saúde, sem XP |

Escolhas triviais não concedem XP por padrão; terminar a aventura não concede XP novamente ao sair da tela de conclusão. Retornos usam o mesmo fator 0,5 já aplicado ao pagamento positivo, arredondado para baixo, também para XP. Não recebem atributo extra. Intervalos e limites de visitas permanecem. Dano e custos não são reduzidos para evitar recuperar ou gastar recursos indevidamente.

Após a escolha são mostrados somente ganhos efetivos: XP, níveis, Jenny, Saúde e alterações de atributos. Recuperação no teto não mostra um ganho inexistente. O resultado e o histórico são salvos como texto resolvido e não reconstruídos com recompensas ao carregar.

## Arquivos
Novos: scripts/progression.gd; tests/test_progression.gd; tests/test_progression_ui.gd; STAGE_4.md.
Modificados: scripts/game_state.gd; scripts/storage.gd; scripts/main.gd; scripts/ui/adventure_view.gd; data/events.json; project.godot; tests/test_foundation.gd; tests/test_visual.gd; README.md.
Tema, ícones, quatro abas e ramificações preservados. Nenhum arquivo One Piece Life foi alterado.

## Salvamento v4
Adiciona level, xp (saldo), points e health. Mantém todo o estado narrativo, RNG, decisões resolvidas, visitas e intervalos. Validação verifica intervalos, saldo menor que o custo do próximo nível, pontos compatíveis com nível e espaço disponível e consistência da jornada em Saúde zero.
Saves v3 válidos são migrados em memória: nível 1, 0 XP, Saúde 10 e 0 pontos. Atributos, dinheiro, flags, aventuras, histórico e sorteios não são modificados para inventar recompensas passadas. V2 continua com a migração anterior. Carregar não grava nem apaga arquivos; somente salvar manualmente substitui o slot com v4.

## Validação
Godot 4.7.2, testes funcionais e renderização real. Suítes: foundation (41), narrative (1280), story_ui (25), journeys (237), progression (430), progression_ui (4), visual (348): 2365 verificações, zero falhas. As 35 capturas foram atualizadas nas cinco resoluções já utilizadas, de 320×480 a 1100×720.
Progressão verifica 310 combinações atributo/dificuldade, níveis múltiplos, limites, pontos, cura, dano, Saúde zero, retornos, saves resolvidos, migração v3 e rejeição de campos inválidos. O teste UI aciona os botões reais de distribuição e confirma aba preservada, bloqueio sem pontos, percentual visível e bloqueio por Saúde zero.
100 jornadas completas com escolhas variadas produziram 71 personagens de nível 1 e 29 de nível 2, sem níveis superiores. Muitas trajetórias são encerradas cedo por escolha explícita; essa amostra não representa uma busca por XP máximo. As regressões também verificam duas aventuras na mesma partida e nas duas ordens. Não houve mudança nos finais narrativos anteriores.

Com Godot no PATH, execute os scripts res://tests/test_foundation.gd, test_narrative.gd, test_story_ui.gd, test_journeys.gd, test_progression.gd e test_progression_ui.gd usando --headless --path . --script. Execute test_visual.gd sem --headless. Logs finais estão em tests/stage4_*.log; imagens em tests/captures/.

## Limitações
Catálogo curto e finito, um slot manual e pouco conteúdo de recuperação (o evento de chuva é único). Saúde zero é terminal para a jornada atual, não um sistema de hospital, ressurreição ou cura contínua. XP não é aplicado retroativamente a escolhas antigas. Não há Nen, Hatsus, batalhas, equipamentos, inventário funcional, calendário ou outros sistemas novos. A próxima etapa não foi iniciada.
