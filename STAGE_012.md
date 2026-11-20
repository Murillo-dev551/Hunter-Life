# v0.1.2 — Identidade Visual

## Resultado e referência estável

Hunter Life recebeu uma interface de diário de campo contemporâneo, seguindo a composição do protótipo aprovado: cabeçalho ilustrado, documentos recortados, faixas diagonais, tipografia editorial e navegação inferior marinho/vinho. O catálogo passou de **174 para 182 acontecimentos**, com oito encontros novos e oito cenários originais. Apenas **16 acontecimentos, aproximadamente 8,8%, têm ilustração narrativa**.

O complemento da ordem foi integrado nesta mesma versão: acontecimentos comuns não se repetem; o Exame Hunter admite novas tentativas elegíveis depois de reprovação. Não foram criadas versões intermediárias, novas mecânicas de combate ou expansões de sistemas.

O repositório estava limpo ao iniciar. A tag anotada **`v0.1.1`** conserva `1c79df6`; o desenvolvimento está em **`feature/v0.1.2-identidade-visual`**. A tag v0.1.0, relatórios históricos e APKs anteriores foram preservados. Nenhum projeto One Piece Life foi modificado.

## Fidelidade ao protótipo: comparação e correções

A imagem anexada foi inspecionada e comparada diretamente com capturas reais do Godot, especialmente `012_after_escort_offer.png` e `012_after_escort_offer_choices.png`. A primeira apresentação, que mudava principalmente cores e fontes, foi substituída por componentes redesenhados.

| Elemento do protótipo | Implementação e correção realizada |
|---|---|
| Marca inclinada, subtítulo e paisagem no cabeçalho | Barlow Condensed Bold Italic, subtítulo serifado, emblema próprio e vinheta em tinta recortada diagonalmente; botões auxiliares passaram à faixa de contexto |
| Papel de caderno e marcações laterais | Fundo claro com linha de margem e pequenos furos gráficos; sem textura pesada ou imagens de pergaminho |
| Painéis com cantos cortados e contornos internos | StyleBox próprio desenha polígonos, contornos duplos e detalhes editoriais; substitui os cartões arredondados genéricos |
| Faixa de acontecimento e traços vinho | Faixa marinho inclinada com duas faixas vinho, bússola e identificador discreto; corrigida quebra vertical indevida do número |
| Título forte e sublinhado irregular | Source Sans 3 Bold, 29 px, com traço vinho afilado |
| Ilustração integrada ao texto | Panorama compacto abaixo do título, sem moldura de fotografia; carregamento opcional e contextual |
| Hierarquia dentro da narrativa | Nomes cadastrados em negrito marinho e valores em Jenny em negrito vinho; o texto integral permanece idêntico |
| Botões editoriais com ícones | Contorno recortado, escolha principal marinho com acento vinho, Source Serif 4 e ícones originais de aceitação, conversa e retorno; quebra de linhas nativa e probabilidades preservadas |
| Navegação inferior contínua | Base marinho, seleção vinho com contorno claro duplo, ícones e nomes serifados das quatro abas |

Também foram inspecionadas as capturas de **Personagem, Inventário e Registro**. Credencial, progressão, atributos, Nen, agrupamento de itens, estados equipados e entradas extensas compartilham a mesma linguagem. O combate mantém seus quatro grupos, com os novos painéis e contraste.

As diferenças intencionais são proporções responsivas, texto narrativo maior para leitura no celular, ilustrações menos altas e decoração leve. O símbolo oficial da licença não foi copiado. A composição foi aproximada do protótipo sem transformá-lo em imagem de fundo, reduzir a leitura a fontes minúsculas ou exigir que todas as opções caibam sem rolagem. A aprovação estética final permanece com o desenvolvedor/tester no aparelho; não se declara equivalência pixel a pixel.

## Paleta, tipografia e componentes

| Função | Recurso |
|---|---|
| Papel / painéis | `#F1E8D7` / `#F9F5EC` |
| Marinho / vinho | `#243B5A` / `#963D49` |
| Tinta / secundário | `#343C43` / `#59616A` |
| Dourado / divisórias | `#806230` / `#B9B6AE` |
| Narrativa | Source Sans 3 Regular, 18 px lógicos |
| Títulos de acontecimentos | Source Sans 3 Bold, 29 px |
| Marca / seções | Barlow Condensed Bold Italic / SemiBold |
| Escolhas / detalhes editoriais | Source Serif 4 Semibold / Italic |

São seis arquivos de fonte locais, com suas licenças OFL. O dourado foi escurecido em relação ao ponto de partida para manter contraste em mensagens pequenas. Testes verificam texto principal ≥7:1 e texto secundário, dourado e seleção vinho ≥4,5:1 nos pares utilizados; isso não equivale a uma certificação completa de acessibilidade.

`styles.gd` centraliza o tema; `document_style.gd` usa o desenho nativo de StyleBox/RenderingServer, sem texturas pesadas ou processamento contínuo. `notebook.gd`, `masthead.gd` e `editorial_rule.gd` desenham os detalhes. A implementação inicial herdava StyleBoxFlat e seu desenho nativo impedia o recorte; a versão final herda StyleBox e foi conferida nas capturas reais.

O realce narrativo usa RichTextLabel e `data/editorial_names.json`, sem alterar as palavras. A suíte compara o texto renderizado com todos os parágrafos de suas amostras. As escolhas usam a quebra automática do Button, em vez de inserir quebras artificiais a cada quantidade fixa de caracteres.

Botões continuam com áreas de toque de pelo menos 44–52 px conforme o componente. Preferência de movimento reduzido, áudio, foco, gestos e rolagem foram preservados. O identificador legado `UI.GREEN` é alias do novo marinho, para manter as chamadas existentes.

## Biblioteca de cenários e exibição seletiva

| ID | Arte local |
|---|---|
| `city` | [Cidade](assets/scenery/city.webp) |
| `forest` | [Floresta](assets/scenery/forest.webp) |
| `road` | [Estrada](assets/scenery/road.webp) |
| `inn` | [Hospedaria](assets/scenery/inn.webp) |
| `port` | [Porto](assets/scenery/port.webp) |
| `ruins` | [Ruínas de um antigo canal](assets/scenery/ruins.webp) |
| `office` | [Escritório de investigação](assets/scenery/office.webp) |
| `market` | [Mercado](assets/scenery/market.webp) |

As oito ilustrações originais foram produzidas com **imagegen**, inspecionadas e convertidas para WebP. Usam tinta preta, hachuras e retículas moderadas; não há retratos ou personagens em destaque. Sete medem 960×320 e a floresta 960×327. Total: **2.773.770 bytes**. Houve redução Lanczos e codificação WebP sem perdas depois da redução. [SOURCES.md](assets/scenery/SOURCES.md) registra prompts, assuntos e nomes dos arquivos originais.

`data/scenery.json` cadastra nomes/caminhos; `scenery_assignments.json` associa explicitamente treze cenas anteriores; três encontros novos têm `scenery` no próprio JSON. As apresentações escolhidas incluem início de entrega, escolta, levantamento, ruínas, missões Hunter, travessia para a oficina, busca do caderno, feira e chegada ao exame.

`scripts/scenery.gd` carrega texturas sob demanda. A imagem narrativa usa largura disponível e altura limitada a 76–164 px lógicos; sem imagem, não cria espaço vazio. Arquivo conhecido ausente mantém texto e escolhas. Referência desconhecida ou associação a acontecimento inexistente é rejeitada na validação. A suíte verifica que uma continuação direta não repete a mesma arte.

A pequena paisagem fixa do cabeçalho é parte da marca, reaproveitando `city`, **não uma ilustração atribuída automaticamente a cada acontecimento**. Ela é distinta dos 16 cartões narrativos ilustrados.

## Oito acontecimentos novos

Todos têm peso 2, são únicos e oferecem alternativas sem licença ou Nen. Não foram alterados os pesos anteriores.

| ID | Situação e decisões |
|---|---|
| `012_inn` | Duas reservas na hospedaria: mediar, contribuir para o acerto ou deixar a responsável negociar |
| `012_markers` | Sinalização depois da chuva: conferir, usar mapa ou pedir informação sem mover setas por palpite |
| `012_mooring` | Amarra no cais: alcançar a corda, sustentar a carga ou afastar pedestres |
| `012_window` | Janela antes da chuva: conserto, ajuda do vizinho ou cobertura provisória paga |
| `012_receipt` | Recibo no casaco: devolução, conferência na oficina ou apropriação desonesta |
| `012_mending` | Mochila rasgada: reparo, material ou indicação de oficina; um erro pode exigir ressarcimento |
| `012_observation` | Estação de observação: organizar registros, liberar acesso ou alcançar folhas deslocadas |
| `012_scales` | Peso da banca: comparar balanças, mediar o conflito ou aguardar a conferência |

Os quatro atributos têm aplicações; há escolhas sem teste, custos opcionais e ferimentos proporcionais. XP é pequeno e contextual, sem recompensas automáticas de atributos ou fontes ilimitadas de recursos.

## Regra de acontecimentos únicos e nova tentativa do Exame

### Acontecimentos comuns

`Catalog.available()` exclui qualquer ID já presente em `seen` ou com visitas positivas, independentemente do orçamento repetível legado. `open_event()` também impede reabrir uma oportunidade comum vivida. Os dados históricos de visitas **não são apagados** ao carregar.

Continuações obrigatórias seguem `pending_next` e não entram no sorteio global. Cenas distintas da mesma missão não são consideradas repetições. Retomar uma aprendizagem de Nen adiada segue a cena pendente, sem sortear novamente o convite ou criar outra visita/sessão da mesma cena. Duplo clique continua bloqueado pela resolução já existente.

Quando não há candidatos elegíveis, o seletor retorna o encontro de decisão `crossroads`, com alternativas naturais de conclusão. Esse ponto de navegação não distribui encontros já vividos ou tenta sortear indefinidamente. A redução de oportunidades é tratada como catálogo finito.

### Exame Hunter: única exceção narrativa

Somente **reprovação** pode abrir outra candidatura. Os parâmetros centralizados em `exam_journal.gd` exigem:

- **Saúde mínima 5**, representando condições de viajar.
- **Seis acontecimentos distintos vividos fora do exame** desde a reprovação.
- Uma oferta adiada exige outras seis experiências distintas antes de reaparecer.
- Aprovação, desistência e recusa definitiva impedem novas participações. Não há limite arbitrário de tentativas; cada retorno depende das oportunidades finitas ainda disponíveis.

A aba Personagem informa a elegibilidade e permite buscar outra inscrição. O convite também pode voltar ao sorteio quando elegível. Não há calendário ou simulação de exames anuais. Os textos de entrada e informações foram adequados a essas regras.

Cada tentativa conserva sequência de quatro provas, etapa, advertências, resultado e flags próprias. Nova inscrição arquiva a anterior e limpa apenas flags específicas daquela participação, sem apagar o histórico global. A sequência da nova seleção usa o RNG existente uma única vez. Carregar mantém exatamente a sequência e o RNG; não inicia outra tentativa nem reaplica recompensas. Uma cena já aberta na tentativa corrente não pode ser reaberta como outra recompensa.

Nenhuma fórmula de combate, Hatsu, d20, XP ou Saúde foi alterada. A licença continua única, concedida somente na aprovação. Recursos legitimamente recebidos antes de uma reprovação são conservados.

## Salvamento e preservação

O formato permanece **v10**, com a extensão opcional **`exam_history`**. Cada registro contém `status`, `started`, `ended`, `outside`, `offered`, `offer_step`, `sequence`, `stage`, `setbacks` e `flags`. São passos/experiências do motor, não datas inventadas. Os campos são validados e normalizados como inteiros após ler JSON.

Saves anteriores sem esse campo derivam somente uma participação comprovada pelos dados existentes; não recebem relações, tentativas ou recompensas inventadas. Carregar não regrava o arquivo. Identidade de jornada, slots, checkpoints e migrações históricas permanecem. Nen, categoria, Hatsu, especialização, recursos e estado de batalha são preservados.

Fixtures foram produzidas executando a tag real v0.1.1: missão, batalha e próximo turno esperado. A suíte confere todos os campos antigos, o novo histórico vazio quando apropriado, integridade do arquivo original e igualdade do próximo turno/dano/RNG.

O hash `01440e48ef247acfd36de155e396ccffaed297bf6ea91dfe0bb496aa5e89673c` confirma os 174 registros narrativos anteriores, retirando apenas `folio`/`scenery`. Os arquivos originais não foram reescritos; a apresentação de inscrição/regras do exame é adaptada por `describe()` à nova política autorizada.

Não houve mudança em `battle.gd`, `nen.gd`, `hatsu.gd`, `save_slots.gd` ou fórmulas de progressão. `catalog.gd`, `game_state.gd`, `exam.gd` e `storage.gd` receberam os ajustes necessários à regra de repetição. A numeração editorial e as imagens não são resultados narrativos nem consomem RNG.

Compatibilidade é para frente: a v0.1.1 não conhece os oito IDs novos nem a política de tentativas. Conservar backup dos slots/checkpoints antes de atualizar se for necessário voltar à versão anterior.

## Testes executados

**43 suítes, 119.750 verificações, zero falhas na rodada completa final.** O consolidado está em [012_test_results.json](tests/012_test_results.json). As cinco suítes que falharam inicialmente foram corrigidas e reexecutadas; após o ajuste final no carregamento, toda a bateria foi executada novamente e aprovada. Os logs locais têm prefixo `012_final_` e o runner `./tools/run_tests.ps1` permite repetir a bateria com diretórios de dados isolados.

Principais resultados específicos: identidade/conteúdo **1.682/0**, interface visual **504/0**, ocorrências **185/0**, Exame **2.604/0**, combate **7.793/0**, balanceamento/simulações v0.1.1 **65.302/0**. Após o ajuste de importação descrito abaixo, **três cópias independentes sem cache** foram importadas e executadas: códigos 0 e nenhum erro de script, conforme [012_clean_import_results.json](tests/012_clean_import_results.json). Os avisos de finalização citados abaixo continuam explicitados.

As novas verificações cobrem imagens locais, referências e fallback, 16 associações seletivas, texto integral, oito acontecimentos, escolhas com/sem ferramentas, 39 sucessos e 57 fracassos d20, limites de recursos, recompensas únicas, fixtures reais e próximo turno idêntico.

`test_occurrence_012.gd` cobre acontecimentos comuns únicos, persistência após carregar, visitas legadas, missão com múltiplas cenas, esgotamento sem loop, reprovação, intervalo, Saúde, nova seleção, flags arquivadas, RNG, aprovação única e migração sem recompensas. O seletor consumiu **44 oportunidades distintas** no cenário de esgotamento.

As suítes anteriores cobrem seis categorias de Nen, cinco Hatsus/11 especializações, Especialista/checkpoints, Exame, itens, combate, slots, migrações, áudio, toque e botão Voltar. As simulações de combate mantêm os mesmos resultados mecânicos esperados; os perfis comuns/licenciados percorrem 120 jornadas e as missões são simuladas com atributos 5/8.

Foram corrigidas fixtures que reabriam acontecimentos resolvidos a cada resolução de tela ou supunham rendimentos por repetição. Cada cenário de combate agora usa uma jornada independente e semente explícita. Também foram corrigidas a comparação entre inteiros e números JSON no novo histórico e a apresentação da reinscrição ao carregar: o texto contextual agora é reconstruído depois de restaurar a tentativa, e o teste compara também os parágrafos carregados. As regras de jogo não foram enfraquecidas para satisfazer testes antigos.

Resoluções de layout: **320×480, 390×844, 480×860, 768×1024 e 1100×720**. Foram conferidos cabeçalho, quatro abas, textos extensos, última escolha, imagens limitadas, combate, preferências e movimento reduzido. Medição de memória estática do Godot durante 60 trocas de cenas fica em [012_memory_results.json](tests/012_memory_results.json); não mede memória total/GPU ou desempenho do Android.

Algumas suítes históricas encerradas abruptamente ainda emitem avisos de dois objetos/recursos retidos na finalização. Esses avisos foram distinguidos de erros de script/assertivas; não se afirma que os logs estão integralmente livres de avisos. A saída normal e o encerramento do áudio têm seus testes próprios.

Na conferência final sem cache, uma importação paralela de fontes encerrou o processo nativo do Godot com `0xC0000374`; a execução seguinte encontrou recursos ainda não importados. Reimportar a mesma cópia recuperou os recursos. O log e o evento do Windows foram investigados, mas não determinam sozinhos a causa raiz dentro do motor. Como mitigação conservadora, `editor/import/use_multiple_threads=false` configura importação sequencial; depois disso, as três cópias novas passaram. Essa preferência afeta a importação no editor, sem modificar a lógica ou o processamento do jogo. O APK foi reexportado com essa configuração. Não foi observada falha equivalente durante as suítes de partidas.

## Capturas comparativas

As capturas anteriores foram produzidas executando a **tag v0.1.1**, com o mesmo personagem Lia, recursos e tela 390×844. As posteriores são renderizações reais do projeto atualizado, não mockups.

| Tela | Antes | Depois |
|---|---|---|
| Aventura | [v0.1.1](tests/captures/012_before_tab_0_390.png) | [v0.1.2](tests/captures/012_after_tab_0_390.png) |
| Personagem | [v0.1.1](tests/captures/012_before_tab_1_390.png) | [v0.1.2](tests/captures/012_after_tab_1_390.png) |
| Inventário | [v0.1.1](tests/captures/012_before_tab_2_390.png) | [v0.1.2](tests/captures/012_after_tab_2_390.png) |
| Registro | [v0.1.1](tests/captures/012_before_tab_3_390.png) | [v0.1.2](tests/captures/012_after_tab_3_390.png) |

[Abertura ilustrada](tests/captures/012_after_escort_offer.png), [escolhas da abertura](tests/captures/012_after_escort_offer_choices.png), [continuação textual](tests/captures/012_after_escort_prepare.png), [encontro novo](tests/captures/012_after_012_inn.png), [escolhas em 320×480](tests/captures/012_after_choices_320.png) e [combate compacto](tests/captures/012_after_battle_320.png).

## Arquivos criados ou modificados

| Área | Arquivos |
|---|---|
| Interface | `scripts/main.gd`; `scripts/ui/styles.gd`, `document_style.gd`, `notebook.gd`, `masthead.gd`, `editorial_rule.gd`, `adventure_view.gd`, `inventory_view.gd`, `battle_view.gd`, `line_icon.gd`, `motion.gd` |
| Cenários | `scripts/scenery.gd`, `scripts/ui/scenery_view.gd`, `data/scenery.json`, `scenery_assignments.json`, oito `assets/scenery/*.webp`, `SOURCES.md` |
| Tipografia e marca | `assets/fonts/source_sans3/`, `barlow_condensed/`, `source_serif/`; SVGs de marca/bússola/registro/variantes Android e três ícones de escolha; `assets/ASSET_LICENSES.md` |
| Conteúdo e repetição | `data/encounters_012.json`, `editorial_names.json`; `scripts/catalog.gd`, `game_state.gd`, `exam.gd`, `exam_journal.gd`, `storage.gd` |
| Ferramentas | `tools/build_012_content.cjs`, `create_visual_012.cjs`, `prepare_scenery.gd`, `run_tests.ps1`, `export_android.ps1` |
| Testes | `test_identity_012.gd`, `test_identity_visual.gd`, `test_occurrence_012.gd`, `generate_v011_fixtures.gd`, `fixtures/v011/`, ajustes de fixtures/contagens/repetição em suítes históricas, `check_android_apk.ps1` |
| Evidências | Resultados `tests/012_*.json`, capturas `tests/captures/012_*.png` |
| Configuração/documentação | `project.godot`, `export_presets.cfg`, `README.md`, `STAGE_012.md` |

Arquivos `.gd.uid` e `.import` acompanham os recursos. Os geradores não são dependências de execução. Estatísticas e capturas históricas foram preservadas; novas evidências têm prefixo 012.

## Android: APK e validação no aparelho

APK de testes: **`C:\Users\muril\Downloads\Hunter life\Hunter_Life\builds\android\Hunter-Life-0.1.2-test.apk`**.

Gerado e verificado: **34.597.845 bytes**, SHA-256 `4c7df46c500237ac3052acb0da535592dd214d00c108f769f58976a540b7d43b`. Assinatura v2/v3 e alinhamento de 16 KB aprovados; verificação de recursos: **73 verificações, zero falhas**. Nenhum aparelho estava conectado ao ADB durante esta validação.

Pacote `org.hunterlife.prototype`, código 4, nome `0.1.2-test`, ARM64/retrato. Foram preservados modo imersivo, áreas seguras, botão Voltar e retomada. A chave de depuração permanece fora do repositório; não foram versionadas senhas. APKs anteriores não foram substituídos.

Recriar: `./tools/export_android.ps1`. Verificar recursos: `./tests/check_android_apk.ps1`. O exportador verifica assinatura e alinhamento de 16 KB. O verificador confere catálogos, scripts compilados, artes, seis fontes e suas licenças, ícones, áudio e ausência de testes no pacote.

Instalação: salvar a jornada, transferir o APK e atualizar pelo gerenciador de arquivos **sem desinstalar**. Com USB autorizado, pode-se usar `adb install -r <caminho-do-apk>`. Conservar backups antes de atualizar se desejar reverter.

### Pendências e limitações conhecidas

Não há arte pendente ou recurso que exija rede durante o jogo. Ainda dependem do **Galaxy A15 5G e da avaliação humana**:

- Aprovar fidelidade estética, tipografia, contraste e proporção das imagens no aparelho.
- Deslizar sobre textos/botões sem ativar escolhas e alcançar todas as opções.
- Carregar slots antigos, missão/batalha pendente e conferir inventário/Nen.
- Reprovar e tentar novamente o exame quando elegível; conferir bloqueio após aprovação.
- Conferir teclado, áreas seguras, modo imersivo, Voltar, minimizar/retomar e áudio.
- Medir fluidez e memória reais no Android.

O catálogo é finito e os encontros comuns deixam de retornar. A política de nova candidatura usa experiências distintas, sem calendário; não é uma simulação anual do exame. A v0.1.2 está preparada para avaliação, **não declarada pronta para lançamento público**. Não foram iniciados companions, estrelas Hunter ou a próxima versão.

Ao inspecionar o manifesto com `aapt2`, houve aviso sobre a referência `mipmap/themed_icon` do template Android. O mesmo aviso foi reproduzido no APK estável v0.1.1, sem alteração nesta atualização; o ícone principal/adaptativo está incluído. A aparência com ícones temáticos do launcher deve ser conferida no aparelho. Não foi modificado o template do motor para contornar esse aviso.

## Referências e licenças

- Protótipo visual anexado pelo desenvolvedor, comparado com renderizações reais; não incorporado como arte do aplicativo.
- [Source Sans — Adobe](https://github.com/adobe-fonts/source-sans/tree/release/TTF), [Source Serif — Adobe](https://github.com/adobe-fonts/source-serif/tree/release/OTF) e [Barlow — Google Fonts](https://github.com/google/fonts/tree/main/ofl/barlowcondensed): SIL OFL incluídas no projeto/APK.
- [Godot: StyleBox](https://docs.godotengine.org/en/stable/classes/class_stylebox.html) e [Button](https://docs.godotengine.org/en/stable/classes/class_button.html): desenho e quebra nativos, validados no Godot 4.7.2 instalado.
- [Godot: FontVariation](https://docs.godotengine.org/en/stable/classes/class_fontvariation.html), consultada na avaliação inicial. A versão final usa fontes estáticas.
- [Godot: ProjectSettings, importação em múltiplas threads](https://docs.godotengine.org/en/4.5/classes/class_projectsettings.html#class-projectsettings-property-editor-import-use-multiple-threads): referência oficial da opção, confirmada nas importações do motor 4.7.2 instalado.
- [Origem/prompts das oito artes](assets/scenery/SOURCES.md) e [licenças de fontes, áudio e vetores](assets/ASSET_LICENSES.md). As três famílias de fontes têm OFL; os SVGs originais e áudio mantêm CC0. Nenhuma arte oficial ou gravação de terceiros foi extraída.
