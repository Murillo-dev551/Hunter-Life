# Hunter Life — Etapa 2

Continuação do projeto existente: tema, criação, atributos e quatro abas preservados.

## Executar
Importe project.godot no Godot 4.7.2 e pressione F5. Crie um personagem, escolha uma opção e pressione Continuar jornada. Visite Registro para salvar. A tela inicial oferece Continuar partida salva. O botão Criar outro personagem mantém o save anterior até que você salve uma nova sessão.

## Implementado
12 acontecimentos originais em data/events.json: cinco situações independentes, uma oportunidade, três continuações e três finais. Seleção ponderada sem repetição; continuações obrigatórias precedem novos sorteios. Escolhas respeitam flags, atributos mínimos e Jenny. A aventura da entrega tem preparação de rota, travessia com alternativas e decisão de vida no desfecho. Não obriga o Exame Hunter nem usa personagens canônicos.

Testes usam 1d20 + atributo >= dificuldade. A interface mostra rolagem, soma, dificuldade e sucesso/fracasso junto da consequência. Atributos ficam entre 1 e 10; Jenny nunca é negativo. Escolhas resolvidas são bloqueadas e o RNG é persistido.

## Estrutura JSON
Cada evento contém id, title, chapter, kind (independent/opportunity/continuation/ending), weight, conditions, paragraphs e choices. Todos são únicos por partida, controlados por seen. Continuações e finais têm peso zero e só são acessados por encadeamento. Se o catálogo elegível se esgotar, há encerramento seguro.

Exemplo de escolha:
```json
{"label":"Tentar a passagem","test":{"attribute":"agility","difficulty":16},"result":"Você atravessa.","jenny":0,"flags":{"crossed":true},"next":"delivery","failure":{"result":"Você procura ajuda.","jenny":0,"next":"delivery"}}
```
Effects suportados: result, jenny, attributes (deltas), flags (booleanos), next. O bloco failure substitui os efeitos de sucesso, sem aplicar ambos. Conditions suporta flags com valores esperados, attributes com mínimos e jenny mínimo. Capacidades futuras podem ser representadas por flags, sem implementar Nen. Não há linguagem genérica de scripts.

## Arquivos
Novos: scripts/catalog.gd, scripts/storage.gd, data/events.json, tests/test_narrative.gd e tests/test_story_ui.gd.
Modificados: scripts/game_state.gd, scripts/main.gd, scripts/ui/adventure_view.gd, scripts/ui/creation_view.gd, project.godot, tests/test_foundation.gd, tests/test_visual.gd, README.md. Tema, ícones e cena principal preservados. data/demo_event.json permanece como referência antiga, sem ser usado pelo motor.

## Saves
Arquivo manual user://hunter_life.json no diretório Hunter Life Prototype. Gravação temporária e substituição após sucesso. Preserva nome, atributos, Jenny, flags, eventos visitados, evento atual, escolha resolvida, resultado, continuação pendente, aventura ativa, registro e RNG. Carregar valida tipos, intervalos, IDs e continuidade básica antes de substituir a sessão. Saves inválidos mostram erro no formulário. Etapa 1 não tinha saves persistentes.

## Testes
Executados no Godot 4.7.2: test_foundation.gd (41), test_narrative.gd (1277), test_visual.gd (348) e test_story_ui.gd (24): 1690 verificações, nenhuma falha. Foram produzidas 35 capturas em cinco resoluções (320x480 até 1100x720). A suíte narrativa cobre 1000 seleções ponderadas, condições de flags/Jenny, encadeamento prioritário, três finais, save de finais, 50 sementes antes/depois de salvar, rejeição de duplicação e arquivos inválidos. Regressões da Etapa 1 foram adaptadas aos resultados reais, mantendo as verificações de navegação, formulário e layout.

Com o executável do Godot no PATH:
```powershell
godot --headless --path . --script res://tests/test_foundation.gd
godot --headless --path . --script res://tests/test_narrative.gd
godot --path . --script res://tests/test_visual.gd
```

## Limitações
Uma aventura curta, saves manuais em um slot e todos os eventos sem repetição. Os finais resultam de decisões explícitas no abrigo ou da opção de permanecer na cidade; não são sorteados. O inventário continua indisponível. Não há calendário, NPCs autônomos, combate, Nen, mundo aberto ou economia complexa. Fontes têm fallback local. Não há compatibilidade prometida com alterações manuais arbitrárias do catálogo após salvar. Não foi iniciada a Etapa 3.

