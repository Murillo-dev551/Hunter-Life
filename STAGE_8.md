# Hunter Life — Etapa 8: Inventário funcional

Projeto existente, Godot 4.7.2 e GDScript. As quatro abas e o diário foram preservados; Inventário agora permite consultar, usar, equipar e desequipar. Catálogo separado em data/items.json. São 39 acontecimentos: os 35 anteriores e quatro oportunidades novas, mantendo as duas aventuras, Nen, Hatsus e batalhas.

## Catálogo completo
| Objeto | Categoria | Limite | Efeito |
|---|---|---:|---|
| Bandagem | Consumível | 5 | Cura até 3 de Saúde |
| Remédio simples | Consumível | 2 | Cura até 5 de Saúde; oferta escassa |
| Faca de viagem | Equipamento | 1 | Dificuldade -1 em ataques comuns contra o assaltante |
| Colete reforçado | Equipamento | 1 | Reduz em 1 o dano de investidas anunciadas, se ainda causariam pelo menos 2 após outras defesas |
| Corda resistente | Objeto de aventura | 1 | Abre uma travessia específica, sem consumo |
| Lanterna | Objeto de aventura | 1 | Permite investigar uma passagem escura |
| Mapa regional | Objeto de aventura | 1 | Abre uma opção de orientação na entrega |
| Lembrança de viagem | Lembrança | 1 | Registro da entrega concluída, sem bônus |

Itens de limite 1 são únicos. Não há descarte, venda, fabricação, durabilidade ou peso. Os limites são capacidade de acúmulo, não promessa de que todas as quantidades sejam obtidas em uma jornada. Categorias, descrições, efeitos, cura, limite e espaço de equipamento estão no JSON; não há scripts arbitrários de efeitos.

## Obtenção e escolhas
- Suprimentos na feira: uma compra nessa visita única. Bandagem 15, remédio 35, corda 25, lanterna 20, mapa 15, faca 45 e colete 60 Jenny. Saldo insuficiente ou excesso de quantidade bloqueia a opção antes de aplicar custo. É possível recusar compras.
- Ajuda na oficina: um teste de Intelecto 12 pode render colete; serviço de carregamento rende faca; organização de bancada rende lanterna. Há alternativa de recusa. A banca e a oficina permitem obter ambos os equipamentos em eventos diferentes, conforme as escolhas.
- Um embrulho na trilha: guardar o embrulho de um viajante permite aceitar bandagem, corda ou mapa; também se pode recusar o presente.
- Uma passagem escura: lanterna permite investigar por 12 Jenny e 6 XP. Esperar o responsável continua disponível. Uma opção explicitamente rotulada permite ceder uma bandagem a um trabalhador, consumindo uma unidade por 3 XP.
- Antes da subida: possuir mapa permite escolher a rota indicada, sem consumi-lo nem alterar atributos.
- A ponte danificada: possuir corda abre uma travessia cuidadosa; a ferramenta é recolhida ao fim. Desvio preparado, barqueira e alternativas anteriores continuam disponíveis.
- O abrigo da serra: a entrega concluída também rende uma lembrança única.

Efeitos narrativos usam somente items_add/items_take; condições usam items com quantidades mínimas. Operações são verificadas antes da resolução e aparecem no resultado com nomes em português. As novas fontes são únicas por jornada. Além disso, retornos de eventos repetíveis não concedem novamente items_add. Nenhum item é concedido retroativamente por eventos antigos já resolvidos.

## Consumíveis e equipamentos
Usar exige posse, Saúde entre 1 e 9, jornada em andamento e ausência de confronto ativo. A cura respeita 10, remove uma unidade e registra o ganho efetivo. Saúde cheia não consome nada; incapacidade não é revertida. Cura não avança acontecimentos ou altera RNG.
Cada botão captura a revisão do inventário. Uma operação bem-sucedida altera essa revisão; um segundo sinal do controle antigo é recusado, inclusive após carregar. Usar outra unidade por um novo controle é uma ação legítima, se ainda houver ferimento.
Arma e Proteção são espaços independentes. Equipar e desequipar atualiza o histórico e a interface imediatamente. A compra também atualiza a aba Inventário sem exigir avançar a narrativa. Durante batalha é possível consultar objetos, mas botões de uso e troca ficam bloqueados pela interface e pela lógica.

## Integração com combate
A faca só reduz a dificuldade dos ataques comuns attack/quick contra o assaltante. Não altera dano, atributos globais, treino amistoso, Ren ou ações de Hatsu. A chance exibida usa a dificuldade efetiva e a função d20 existente.
O colete reduz em 1 somente uma investida anunciada que, após defesa/esquiva/Nen, ainda causaria pelo menos 2. Não transforma dano positivo em zero. Não atua contra golpes comuns ou os ataques do treino amistoso. Nen e Hatsus mantêm suas regras. Essa restrição foi escolhida após a primeira simulação apontar proteção ampla demais.
Os equipamentos ficam fixos durante o confronto e são persistidos com ele. Vitória, fuga, rendição, incapacidade e recompensas anteriores permanecem.

## Salvamento v8
Adiciona inventory={items,equipment,revision}. items associa ID a quantidade; equipment tem weapon/protection, com ID ou string vazia. Revisão é um inteiro monotônico para operações da interface.
Validação verifica IDs conhecidos, quantidades inteiras positivas, limites de acúmulo, objetos únicos, espaços corretos e posse dos itens equipados. Um item ausente não pode estar equipado. Quantidades e revisão são normalizadas ao carregar.
V7 e versões anteriores recebem inventário vazio; nada é inventado a partir do histórico. Todos os campos anteriores, Nen, categoria oculta/revelada, Hatsu, RNG e batalha permanecem. Carregar não modifica o arquivo anterior. O próximo salvamento manual grava v8. Testes usam arquivos próprios, sem substituir o slot do usuário.

## Arquivos
Novos: data/items.json; scripts/inventory.gd; scripts/ui/inventory_view.gd; tests/test_inventory.gd; tests/test_inventory_visual.gd; STAGE_8.md.
Modificados: scripts/game_state.gd; scripts/catalog.gd; scripts/storage.gd; scripts/main.gd; scripts/battle.gd; data/events.json; project.godot; tests/test_foundation.gd; tests/test_narrative.gd; tests/test_nen.gd; tests/test_hatsu.gd; README.md.
O teste de Nen passou a procurar a escolha pela condição da técnica, em vez de assumir que ela seria sempre a última depois da nova opção de corda. O fixture de Hatsus foi corrigido para não carregar uma aventura anterior artificialmente ativa ao preparar personagens treinados. Não houve alteração correspondente nas regras do produto.
Nenhum arquivo de One Piece Life foi alterado.

## Testes e simulações
Resultados finais: **12539 verificações, zero falhas**, incluindo 528 da suíte de inventário e 35 da interface nova. Importação e inicialização normal também terminaram sem erros ou avisos. Contadores estão em tests/stage8_*.log. A suíte nova verifica catálogo, saldo, compra, duplicação, limite de cura, quantidades, itens únicos, consumo por escolha, equipamentos, restrições em combate, bônus reais, Nen, save no confronto, RNG, migração v7 e saves inválidos. O teste visual verifica compra e atualização imediata, uso pelo botão, token antigo, equipamento e bloqueio em batalha, além das cinco resoluções anteriores.
Foram repetidas todas as suítes anteriores, incluindo as duas aventuras, Hatsus, água sem rerrolagem, batalhas e os textos corrigidos. Foram produzidas 80 capturas (75 de regressão e cinco novas inventory_*.png). A aba Inventário em 390×844 foi inspecionada visualmente.

Simulação controlada com 200 sementes por grupo, contra o assaltante, sempre atacando:
- Sem equipamentos: 191 êxitos e Saúde média final 5,475.
- Com faca e colete: 199 êxitos e Saúde média final 7,06.
Ainda houve derrota e dano; a proteção não é imunidade. Não se pretende que essa amostra prove equilíbrio para todas as situações. As regressões de combate sem equipamentos mantiveram os resultados anteriores.
Também foram simuladas 50 jornadas completas sem equipamento ativo e 50 com equipamento inicial. Sem: 45 finais narrativos e cinco incapacidades. Com: 42 finais narrativos e oito incapacidades. Escolhas e caminhos divergem após os efeitos iniciais, então esse segundo ensaio verifica continuidade e riscos, não uma comparação causal da eficácia dos equipamentos. Os percursos chegaram a encerramentos sem bloqueios. A cura manual não foi automatizada nessas simulações.

Com Godot no PATH: `godot --headless --path . --script res://tests/test_inventory.gd`. Para imagens: `godot --path . --script res://tests/test_inventory_visual.gd`, sem headless. Abra project.godot e pressione F5 para experimentar.

## Limitações
Oferta finita e uma compra por visita à banca, sem comércio dinâmico. O remédio tem somente uma oportunidade de compra nesta amostra; nem todos os objetos precisam ser obtidos na mesma jornada. Não há cura em batalha, reviver uma jornada encerrada, venda, descarte, peso, durabilidade, raridades, fabricação, melhorias, equipamentos de NPCs ou novos inimigos. Ferramentas desbloqueiam apenas as escolhas declaradas, sem vantagens globais. A Etapa 9 não foi iniciada.
