# Hunter Life — Etapa 7: Batalhas narrativas

Continuação do projeto existente, Godot 4.7.2 e GDScript. As quatro abas e o tema foram mantidos. Há 35 acontecimentos, incluindo dois novos encontros opcionais. As duas aventuras anteriores continuam sem batalhas obrigatórias.

## Como experimentar
Abra project.godot e pressione F5. Uma ameaça na estrada ou Um treino na praça podem aparecer entre as oportunidades. A primeira opção inicia o confronto; a segunda evita a luta. A luta permanece na aba Aventura. Você pode consultar Personagem e Registro; neste último é possível salvar no meio do confronto. Distribuição de atributos e desvios para aprendizado/final de jornada ficam bloqueados durante a luta. Criar outro personagem continua sendo um reinício explícito da sessão.

## Ações e cálculo
Cada botão resolve uma ação e a resposta do inimigo de forma atômica. O turno seguinte só existe após essa resolução. Um token com o número do turno impede reaplicar cliques de controles antigos. Probabilidades usam a mesma função Progress.chance e os 20 valores possíveis de d20 + atributo >= dificuldade. A execução sorteia apenas o d20 do RNG persistente.
- Atacar: Força ou Agilidade. Dano 3, mais 1 se a margem do teste alcançar 6. Sem sucesso, não há dano.
- Defender: proteção 2 no primeiro uso consecutivo. Repetir a mesma defesa elimina essa proteção base. Segurar uma investida/golpe direto pode criar abertura.
- Esquivar: Agilidade, com a dificuldade-base do adversário. Sucesso evita a reação daquele turno e cria abertura; fracasso aumenta o dano recebido em 1.
- Fugir: Agilidade 12 contra o assaltante ou 10 no treino. Sucesso encerra sem vitória; fracasso admite a resposta anunciada.
- Render-se: encerra sem vitória. O assaltante toma até 25 Jenny; a lutadora aceita interromper o treino sem cobrança.

Guarda inimiga aumenta a dificuldade ofensiva em 3. Abertura/hesitação reduz em 2. Acertar um ataque durante preparação interrompe a resposta do turno. O lutador aumenta em 3 a dificuldade se reconhecer a repetição imediata da mesma ação e acrescenta 1 à reação nessa circunstância. Isso incentiva alternar abordagens em vez de atacar sempre com o mesmo atributo.
Reação-base do inimigo: golpe 2, investida 3, guarda 1, preparação/hesitação 0. A partir do sexto turno a pressão cresce (mínimo 3 e máximo 4 antes de vulnerabilidade/repetição), impedindo alternância defensiva perfeita indefinida. Não há regeneração por turno. Saúde do personagem continua 0–10. Saúde zero recebe a política anterior de socorro e encerramento por incapacidade, sem morte automática.

## Adversários
Assaltante: Saúde 6 e dificuldade-base 12. Começa anunciando investida, alterna golpe e investida e hesita ao ficar com até 2 de Saúde. Nessa faixa tem chance de desistir (35% após uma reação sobrevivida). Não concede Jenny por ser derrotado.
Lutadora experiente: Saúde 7 e dificuldade-base 14. Começa em preparação; depois alterna golpe, preparação e guarda. Reconhece ações consecutivas repetidas. Aceita rendição. O treino é consensual, sem exigir desfecho fatal.
O balanceamento inicial com Saúde 8 para a lutadora foi reduzido para 7 para aproximar a duração da meta de 2–5 turnos. Não houve mudança na fórmula d20.

## Nen e Hatsus
Uma ação especial exige uma ação comum antes do próximo uso especial: special_until=turno+2. É concentração contextual, não consumo detalhado de aura. Zetsu é uma ação exclusiva de saída: não pode compartilhar o turno com emissão ativa e não oculta o corpo.
- Ten: defesa com +1 de proteção, sem imunidade geral.
- Zetsu: fuga com dificuldade reduzida em 2; usa a rota de saída, não invisibilidade.
- Ren: ação ofensiva de Presença, dificuldade-base +1, dano +1 quando acerta.
- Corpo Temperado/Potência: ataque físico, dano +2 em sucesso.
- Corpo Temperado/Resistência: defesa com +2 de proteção adicional.
- Projétil/Potência: Intelecto, dano +2 por impacto.
- Projétil/Alcance: Agilidade; sucesso durante investida/preparação impede a resposta pela distância contextual.
- Projétil/Precisão: Intelecto; dificuldade -3 contra abertura/preparação ou -1 em outros casos; abertura também concede dano +1.
Só aparecem técnicas aprendidas e o Hatsu/especialização existentes. As regras também bloqueiam chamadas pela lógica. Os atributos e especializações não podem ser redistribuídos no meio da batalha. Personagens sem Nen mantêm ataques, defesa, esquiva, fuga e rendição.

## Resultados e recompensas
Vitória e desistência do adversário são resultados distintos; fuga e rendição nunca são contadas como vitória. As recompensas vêm do campo battle_rewards do acontecimento JSON, por outcome. Assaltante: vitória/desistência 22 XP e nenhum dinheiro. Lutadora: vitória 30 XP e 20 Jenny pelo treino combinado. Fuga/rendição concedem 3 XP, sem prêmio de vitória. Rendição ao assaltante desconta até 25 Jenny. Incapacidade não concede XP. Os efeitos são aplicados uma única vez, antes de gravar o resultado final; o sinalizador rewarded persiste.
Todo turno e o encerramento ficam em Registro. A tela mostra resultado anterior, Saúde, intenção, abertura e ações com probabilidades. No encerramento mostra também a ação final e o desfecho, sem esconder a última rolagem.

## Salvamento v7
Mantém nome, atributos, nível, XP, Saúde, Jenny, Nen, Hatsu, visitas, flags, história e RNG. Adiciona battle: enemy, hp, turn, intent, opening, last, repeat, special_until, outcome, log e rewarded. A Saúde do personagem continua no campo principal.
O carregamento valida tipos, intervalos, inimigo, intenção, resultado, vínculo com a escolha narrativa que iniciou o confronto e coerência de incapacidade/vitória/recompensa. Campos numéricos de combate são normalizados. Não executa rolagens, respostas ou recompensas ao carregar.
Saves v6 recebem battle vazio: não inventa confrontos nem muda categoria/especialização. Migrações v2–v5 continuam preservadas. O slot manual user://hunter_life.json não foi apagado ou substituído pelos testes; arquivos de teste têm nomes próprios.

## Arquivos
Novos: scripts/battle.gd; scripts/ui/battle_view.gd; tests/battle_driver.gd; tests/test_battle.gd; tests/test_battle_visual.gd; tests/battle_results.json; STAGE_7.md.
Modificados: scripts/game_state.gd; scripts/progression.gd; scripts/storage.gd; scripts/main.gd; data/events.json; project.godot; tests/test_foundation.gd; tests/test_narrative.gd; tests/test_visual.gd; tests/test_journeys.gd; tests/test_progression.gd; tests/test_nen.gd; tests/test_hatsu.gd; README.md.
O auxiliar de testes resolve batalhas nas simulações de jornadas anteriores para que elas continuem avaliando partidas completas. Não atua na lógica do produto. Nenhum arquivo One Piece Life foi alterado.

## Testes e simulações
Suítes finais: foundation 41; narrative 1280; story_ui 26; journeys 237; progression 430; progression_ui 4; nen 1239; hatsu 218; visual 348; nen_visual 34; hatsu_visual 180; battle 7793; battle_visual 68. Total: **11898 verificações, zero falhas**.
75 capturas, incluindo dez novas de confrontos em 320×480, 390×844, 480×860, 768×1024 e 1100×720. O encontro com o assaltante foi inspecionado visualmente. O teste visual inicia encontros por sinais reais, resolve um turno, rende-se e retorna à narrativa.

Foram simulados 2120 confrontos: 1600 sem Nen (200 por combinação de dois inimigos e quatro estratégias), 120 variando atributos 3/5/8 e Saúde 3/10 e 400 com técnicas/especializações (50 por habilidade). Os dados estão em tests/battle_results.json.

| Estratégia | Assaltante: média de turnos / êxitos | Lutadora: média / vitórias |
|---|---|---|
| Atacar sempre | 2,365 / 96% | 4,52 / 66,5% |
| Tática contextual | 3,52 / 96% | 4,085 / 87,5% |
| Defender sempre | 4,98 / 0% | 6 / 0% |
| Tentar fugir sempre | 1,4 / 99,5% fugas | 1,325 / 100% fugas |

Êxito contra o assaltante inclui sua desistência. A política tática defende investidas, esquiva guardas e alterna Força/Agilidade nos demais turnos. Ela não é um algoritmo ótimo. Houve casos excepcionais de nove turnos contra a lutadora. Defender continuamente levou à incapacidade, sem ciclos infinitos; fuga permaneceu viável. Nenhum ataque comum derrota um personagem saudável de Saúde 10 em uma única resposta.
Nas 50 simulações por habilidade contra a lutadora, Potência de ambos os Hatsus venceu 49, Alcance/Precisão e Ren venceram 48, Ten e Resistência venceram 36, enquanto Zetsu resultou em 50 fugas. Todas as habilidades ofensivas tiveram pelo menos um fracasso. Esses resultados mostram vantagem contextual forte de personagens treinados, não uma prova de balanceamento universal; a pausa entre especiais permanece necessária.
Também foram verificadas rendição, incapacidade, migração v6, save encerrado, rejeição de Saúde inimiga inválida, bloqueio de token antigo e equivalência integral do próximo turno após salvar/carregar (incluindo RNG). Regressões mantêm as aventuras anteriores e categorias/Hatsus persistentes.

Com Godot no PATH: `godot --headless --path . --script res://tests/test_battle.gd`. Para imagens: `godot --path . --script res://tests/test_battle_visual.gd`, sem headless. Logs em tests/stage7_*.log.

## Limitações
Dois adversários fixos, sem armas/equipamentos, posicionamento, aliados, regeneração ou aura detalhada. Distância é uma oportunidade sugerida pela intenção, não um mapa ou estado espacial. Dano inimigo usa intenção e resposta do jogador, sem uma segunda rolagem ofensiva inimiga. A pressão crescente encerra estratégias de estagnação; não há empate automático. O treino pode terminar em incapacidade se o jogador insistir apesar da Saúde baixa, mas rendição está sempre disponível e não implica morte. Fuga é propositalmente acessível em confrontos opcionais. As amostras iniciais indicam que Nen ofensivo é muito eficaz e poderá exigir ajustes futuros. A Etapa 8 não foi iniciada.
