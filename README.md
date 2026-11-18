# Hunter Life — Etapa 3

Projeto existente preservado: tema de diário, criação, quatro abas, testes d20 e salvamento local. Abra project.godot no Godot 4.7.2 e pressione F5. Escolha nome e inclinação, participe das oportunidades e pressione Continuar jornada após cada decisão. Salve em Registro; retome pela tela inicial.

## Conteúdo e continuidade
23 acontecimentos: os 12 originais revisados e 11 novos. Duas pequenas aventuras: Entrega da Serra e Levantamento da Trilha. Ambas podem ocorrer na mesma jornada, em ordens diferentes. A composição é: oito independentes, duas oportunidades, cinco continuações, quatro conclusões de aventura, uma pausa de encerramento e três finais. A contagem inclui continuações, conclusões, a pausa de encerramento e três finais definitivos.

Acontecimentos são cenas; aventuras são sequências com identidade (delivery/survey); a jornada inclui todas elas. Concluir uma aventura limpa a aventura ativa e permite voltar ao sorteio. As conclusões possuem uma opção explícita de encerrar a jornada. Personagem também oferece Escolher o final da jornada, indisponível durante aventuras ativas. Se as oportunidades se esgotarem, Uma pausa na jornada oferece três encerramentos sem impor um contador obrigatório.

Nenhuma continuação aleatória é inserida no meio de uma aventura: next tem prioridade; o seletor também respeita a aventura ativa. Os antigos end_path/end_home/end_duty agora são conclusões da entrega. journey_path/journey_home/journey_duty são finais definitivos.

## Escolhas
Os cinco acontecimentos antigos foram revisados individualmente: dificuldades variadas, atributos distintos em opções diferentes, alternativas pagas e decisões sem rolagem. O botão mostra ◇ Atributo · Dificuldade antes de escolher; o resultado mantém d20 + atributo >= dificuldade.

Exemplos:
- Carroça: empurrar usa Força 14; improvisar uma alavanca usa Intelecto 13 e pode ensinar um ponto de Intelecto; pagar animais custa 15 Jenny, sem rolagem.
- Mercado: ajudar honestamente abre Uma indicação merecida; uma dica falsa paga pouco, mas a flag dishonest fecha essa indicação.
- Levantamento: alugar equipamentos abre o desvio seguro e a conferência com corda. Sem equipamento, observação e leitura do relevo são caminhos com testes. Relatórios falsos pagam mais, mas fecham a indicação comercial.
- Entrega: preparar o mapa continua permitindo evitar o teste na ponte. Ao concluir, é possível buscar outra aventura, em vez de terminar automaticamente.

Não há reputação global ou relações complexas. Flags booleanas e condições existentes são suficientes. Os equipamentos são flags narrativas de empréstimo, sem inventário funcional; o aluguel de 20 Jenny vale para essa vistoria, sem sistema de inventário.

## Repetição e progresso
A política JSON repeat contém max (participações totais) e gap (quantidade mínima de transições narrativas desde a última visita). Não são dias; não há calendário. Cada evento é único por padrão.

A prova da praça pode aparecer duas vezes, com intervalo 5; o turno no cais, três vezes, com intervalo 4. O pagamento positivo de retorno é multiplicado por repeat_reward_scale=0.5 e arredondado para baixo. Não há ganhos de atributos no retorno. A escolha continua resolvida uma só vez por visita, inclusive após salvar/carregar. O catálogo tem um número finito de retornos: não há fonte ilimitada de renda.

Perfis iniciais opcionais mantêm soma 20: equilibrado (5 em tudo), vigor (Força 6/Intelecto 4), destreza (Agilidade 6/Presença 4), curiosidade (Intelecto 6/Força 4). A prévia muda com a seleção; atributos não citados permanecem 5. Limites gerais continuam 1–10. A única recompensa nova de atributo no catálogo é o aprendizado da alavanca, +1 Intelecto em evento único. Testar um atributo não gera progressão automática.

## Arquivos criados e modificados
Novo: tests/test_journeys.gd, com jornadas completas, ordens de aventuras, retornos, flags, perfis, migração e simulações.
Modificados: data/events.json; scripts/catalog.gd; scripts/game_state.gd; scripts/storage.gd; scripts/main.gd; scripts/ui/adventure_view.gd; scripts/ui/creation_view.gd; project.godot; tests/test_foundation.gd; tests/test_narrative.gd; tests/test_story_ui.gd; README.md.
A cena, tema e ícones foram preservados. Capturas e logs atualizados ficam em tests/. Nenhum arquivo One Piece Life foi alterado.

## Estrutura JSON
Mantém id/title/chapter/kind/weight/conditions/paragraphs/choices. Ampliações:
- kind: adventure_end separa conclusão de ending; hub é a pausa de encerramento.
- adventure: identifica delivery ou survey.
- repeat: {"max":3,"gap":4}; repeat_reward_scale opcional.
- Uma escolha pode usar finish_adventure:true para voltar às oportunidades sem continuação obrigatória.
- Flags delivery_completed/survey_completed identificam sucesso da aventura; desistências não são registradas como trabalhos concluídos.
- Conditions segue suportando flags esperadas, mínimos de atributos e Jenny. As capacidades futuras continuam possíveis por flags, sem sistemas antecipados.

## Salvamento
Mantém user://hunter_life.json e o diretório Hunter Life Prototype. Formato agora é versão 3, adicionando adventure, completed, step, visits e last_visit. Atributos, dinheiro, histórico, escolhas resolvidas, continuações e RNG permanecem persistidos.
Saves válidos da versão 2 são migrados em memória: visitas anteriores contam uma vez e recebem um intervalo conservador; aventura ativa antiga é identificada como entrega. Finais antigos e continuações antigas para finais são mapeados para journey_*, preservando a decisão anterior de encerrar. Não são inventadas aventuras concluídas a partir de registros ambíguos. O histórico e os resultados antigos são mantidos; o rótulo da escolha resolvida é lido do registro para não atribuir retroativamente a nova opção ao jogador. Arquivos não são apagados ou regravados automaticamente ao carregar. O próximo salvamento manual usa v3.

## Testes realizados
Godot 4.7.2: foundation 41; narrative 1280; story_ui 25; journeys 237; visual 348. Total: 1931 verificações, zero falhas nas execuções finais. As regressões antigas foram adaptadas para os 23 eventos e para a separação entre conclusão e final.
100 partidas simuladas, com sementes de 0 a 99 e escolhas aleatórias entre alternativas elegíveis, chegaram a finais sem bloqueios: 33 journey_home, 49 journey_duty, 18 journey_path; máximo 21 escolhas. É uma amostra, não uma garantia universal de duração. Testes dirigidos completaram as duas aventuras nas duas ordens, salvaram entre aventuras, verificaram intervalos, limite de retornos, recompensa reduzida e persistência de escolha resolvida, além de migrações v2 em aventura e em final.
35 capturas foram produzidas em 320x480, 390x844, 480x860, 768x1024 e 1100x720. Prévia de testes foi verificada antes da escolha; navegação e retorno da rolagem ao início foram exercitados depois de vários eventos.

Com Godot no PATH:
```powershell
godot --headless --path . --script res://tests/test_foundation.gd
godot --headless --path . --script res://tests/test_narrative.gd
godot --headless --path . --script res://tests/test_story_ui.gd
godot --headless --path . --script res://tests/test_journeys.gd
godot --path . --script res://tests/test_visual.gd
```

## Limitações
Catálogo compacto e finito; a jornada pode ser encerrada cedo por decisão explícita. Repetíveis usam texto base reaproveitado, com pagamentos variáveis mostrados na consequência. Não há salvamento automático nem múltiplos slots. Informações de migração não recuperam feitos que o formato antigo não distinguia. Não há batalhas, Nen, Hatsus, calendário, mundo aberto, NPCs autônomos, inventário funcional ou economia complexa. Etapa seguinte não iniciada.

