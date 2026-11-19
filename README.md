# Hunter Life

**Hunter Life** é um RPG textual de escolhas inspirado na estrutura de aventuras de *Life in Adventure*, ambientado no universo de *Hunter × Hunter*. Você cria um protagonista original e conduz sua jornada por trabalhos, descobertas, pequenas aventuras e confrontos opcionais.

O jogo é um protótipo local em **Godot 4.7.2 e GDScript**, com interface vertical de diário de explorador. O Exame Hunter é uma possibilidade, não um objetivo obrigatório. Personagens e situações do catálogo são originais; não é necessário acompanhar acontecimentos canônicos.

**Etapa atual: 10H — Animações e Refinamento dos Menus.** Transições curtas, resultados destacados e configurações compactas complementam o Diário de Explorador. A preferência global **Reduzir animações** mantém a apresentação imediata. Os três slots, os 92 acontecimentos e as regras existentes foram preservados. Consulte o [relatório 10H](STAGE_10H.md).

**Android v0.1.0 — revisão de experiência:** APK atual em `builds/android/Hunter-Life-0.1.0-test2.apk`. Corrige o repasse de toque para a rolagem nativa e ativa o modo imersivo, preservando retrato e áreas seguras. A primeira versão já foi instalada e executada no Galaxy A15 5G pelo desenvolvedor; **esta revisão precisa de nova validação no aparelho e não é uma versão aprovada para lançamento público**. Veja [causa, testes e atualização do APK](STAGE_ANDROID_REVISION_1.md) e o [relatório da preparação inicial](STAGE_ANDROID.md).

## Funcionalidades

| Sistema | Disponível no protótipo |
|---|---|
| Personagem | Nome e quatro perfis iniciais equilibrados |
| Atributos | Força, Agilidade, Intelecto e Presença, limitados a 1–10 |
| Progressão | XP, níveis e pontos de atributo distribuídos pelo jogador |
| Recursos | Saúde 0–10 e Jenny para custos e recompensas narrativas |
| Narrativa | 92 acontecimentos escritos em JSON, condições, flags e continuações prioritárias |
| Aventuras | Entrega da Serra, Levantamento da Trilha, Escolta de um comerciante, Expedição às ruínas e Exame Hunter opcional |
| Escolhas | Alternativas com testes, recursos, ferramentas, Nen ou consequências sem rolagem |
| Confrontos | Turnos narrativos, intenções observáveis e comandos em quatro categorias |
| Inventário | Nove itens, incluindo consumíveis, equipamentos, ferramentas e Licença Hunter |
| Registro | Histórico das decisões, rolagens, recursos e encerramentos |
| Persistência | Três slots independentes, com salvamento durante batalhas, provas e avaliação de afinidade |

A navegação usa quatro abas: **Aventura**, **Personagem**, **Inventário** e **Registro**. O conteúdo tem rolagem vertical; a navegação inferior permanece acessível em janelas compactas.

### Escolhas, testes e progressão

Os testes seguem uma única fórmula:

```text
1d20 + atributo ≥ dificuldade
```

Antes da escolha, aparecem atributo, dificuldade e chance real de sucesso. Com atributo 5 contra dificuldade 15, por exemplo, a chance é 55%. O resultado mostra a rolagem e suas consequências. Alterar atributos atualiza as probabilidades.

A experiência necessária para o próximo nível é `40 + 20 × (nível atual − 1)`: 40, 60, 80, 100 XP… Cada nível concede um ponto para distribuir em Personagem; pontos guardados persistem e respeitam o espaço restante até o teto dos atributos. XP vem de conquistas declaradas no catálogo, inclusive alguns fracassos relevantes. Escolhas triviais não concedem XP automaticamente.

Saúde não cai apenas por avançar acontecimentos. Ferimentos e recuperação dependem de escolhas. Em zero, o personagem recebe socorro e abandona a vida de aventuras, encerrando a jornada por incapacidade, sem morte automática.

Concluir uma aventura normalmente devolve o personagem às oportunidades. Finais definitivos resultam de decisões explícitas ou incapacidade. Eventos únicos e repetíveis têm limites; retornos de atividades repetíveis reduzem recompensas e não concedem novamente objetos ou atributos.

### Escolta e expedição

Na escolta, **Orlan** negocia o pagamento e espera que a carga chegue ao mercado. Preparar a rota ou a corda muda as alternativas do percurso; uma cobrança irregular pode ser negociada, paga, contornada ou enfrentada. Fuga e rendição encerram a escolta sem pagamento pela entrega. A conclusão não encerra a jornada.

Na expedição, **Lídia e Bento** examinam um antigo canal: travessia, inscrições de uso da água e retirada segura. É possível produzir um relato completo ou parcial, priorizar a segurança ou ocultar um fragmento para vendê-lo. As decisões podem reaparecer depois em novas conversas e cobranças.

As duas aventuras têm seis acontecimentos cada, podem ocorrer em ordens diferentes e não exigem Nen, Hatsu ou licença. Todos os novos encontros são únicos por jornada; as atividades repetíveis anteriores mantêm seus limites.

## Nen e Hatsus

O aprendizado de Nen surge como oportunidade opcional com a instrutora **Mira**. Você pode aceitar, adiar ou recusar, sem requisito de nível ou participação no Exame Hunter. A sequência inclui um desafio prático com resultados distintos e orientação assistida em caso de dificuldade.

Os fundamentos implementados são **Ten**, **Zetsu** e **Ren**. Seu domínio básico evolui por três marcos narrativos, separadamente do nível geral. As aplicações são contextuais: Ten protege contra certos impactos; Zetsu ajuda na discrição e fuga, sem invisibilidade; Ren pode auxiliar em ações de pressão, sem vitória automática.

A categoria é sorteada uma única vez na criação, permanece oculta e só é revelada pela **adivinhação pela água**, após os fundamentos. As seis categorias disponíveis são Reforço, Emissão, Transmutação, Materialização, Manipulação e Especialização. O protótipo utiliza pesos iguais para o sorteio. Carregar não permite sortear novamente a afinidade.

| Categoria | Hatsu implementado | Especializações |
|---|---|---|
| Reforço | Corpo Temperado | Potência ou Resistência |
| Emissão | Projétil de Aura | Potência, Alcance ou Precisão |
| Transmutação | Fio de Aura | Contenção ou Mobilidade |
| Materialização (Conjuração) | Escudo Materializado | Resistência ou Cobertura |
| Manipulação | Agulha de Comando | Controle de Objetos ou Comando Motor |
| Especialização | Um dos cinco Hatsus acima, definido pela avaliação | As mesmas especializações da habilidade revelada |

Desenvolver um Hatsu exige uma oportunidade prática posterior à revelação da categoria. A especialização é persistente e não pode ser trocada livremente. Não há criação livre de habilidades nem consumo detalhado de aura.

Fio de Aura produz um filamento aderente e elástico: Contenção limita um movimento, enquanto Mobilidade usa apoios próximos. Escudo Materializado cria uma peça temporária de porte pessoal: Resistência absorve mais impacto; Cobertura protege uma passagem breve e pode desviar uma investida. Os efeitos de proteção valem só na resposta atual, e aberturas na próxima ação. Ambos exigem uma ação comum entre usos especiais e podem falhar. “Materialização” permanece o valor interno da categoria chamada Conjuração, preservando os salvamentos existentes.

Agulha de Comando exige fixar ou acertar uma agulha no alvo. Controle de Objetos atua sobre peças pequenas, próximas e acessíveis; fica indisponível em confrontos sem objeto apropriado. Comando Motor interfere por um instante num movimento simples, sem controlar a consciência. Ambos podem criar uma abertura e reduzir parte da resposta atual, sem dano automático, controle permanente ou munição para administrar. Também respeitam o intervalo compartilhado entre técnicas.

### Afinidade do Especialista

Depois dos fundamentos e da revelação de Especialização pela água, Mira pode oferecer uma avaliação opcional. Ao aceitar, o personagem assume as cinco situações até um resultado permanente. Sucessos e fracassos permitem continuar; não há menu para escolher entre os cinco Hatsus nem pontuação de afinidade na interface.

Mira interpreta o conjunto das decisões e revela a habilidade correspondente. O jogador escolhe somente a especialização interna dessa habilidade. A categoria continua **Especialização**; o Hatsu usa exatamente as regras, limites e alternativas narrativas da categoria original, sem bônus especial. Não é possível repetir a avaliação ou trocar a habilidade após conhecer o resultado.

## Batalhas narrativas

Os confrontos aparecem dentro de acontecimentos, na aba Aventura. A tela apresenta adversário, Saúde dos participantes, turno, comportamento observável, ações e resultado anterior.

As ações básicas são atacar com Força ou Agilidade, defender, esquivar, fugir e render-se. Preparação, guarda, abertura e repetição de ações influenciam o resultado. Intenções descrevem movimentos, sem indicar qual botão é a resposta ideal.

O menu principal apresenta **Atacar**, **Defender**, **Nen / Hatsu** e **Outras ações**. Abra uma categoria para ver suas ações e use **Voltar ao menu principal** para retornar. Navegar não consome turno nem altera RNG, dano ou efeitos. Depois de uma ação válida, o menu principal reaparece. Técnicas indisponíveis têm explicação; o único Hatsu mostrado é o aprendido pelo personagem.

Há um assaltante, uma lutadora experiente e o candidato necessário ao confronto final do exame. Nen e Hatsus oferecem alternativas específicas, com uma ação comum entre usos especiais. Equipamentos têm vantagens restritas ao contexto. Não é preciso conhecer Nen para vencer confrontos adequados.

Vitória, desistência do adversário, fuga, rendição e incapacidade têm consequências diferentes. Dinheiro não é concedido por derrotar qualquer pessoa: recompensas dependem do acontecimento. Não há regeneração automática por turno, mapa tático ou movimentação em tempo real.

## Inventário

| Item | Aplicação |
|---|---|
| Bandagem | Recupera até 3 de Saúde fora de combate |
| Remédio simples | Recupera até 5 de Saúde; oferta limitada |
| Faca de viagem | Pequena vantagem em ataques comuns contra o assaltante |
| Colete reforçado | Redução parcial em investidas anunciadas, sem anular impactos |
| Corda resistente | Alternativas específicas de travessia |
| Lanterna | Investigação de local escuro |
| Mapa regional | Orientação em rotas declaradas no catálogo |
| Lembrança de viagem | Registro da entrega, sem bônus |
| Licença Hunter | Credencial única e permanente, desbloqueando conteúdo exclusivo |

Objetos são obtidos por compras, serviços, encontros ou conclusões narrativas. Compras respeitam Jenny e limites de quantidade. Ferramentas são reutilizáveis salvo quando a escolha indica consumo; a doação de uma bandagem, por exemplo, remove uma unidade.

Consumíveis não são desperdiçados com Saúde cheia. Os espaços **Arma** e **Proteção** são equipados pela aba Inventário. Usar consumíveis ou trocar equipamento durante uma batalha não é permitido. A licença não pode ser consumida ou equipada.

## Exame Hunter

Uma inscrição opcional pode surgir entre as oportunidades. É possível investigar, inscrever-se, adiar ou ignorar. Uma participação é permitida por jornada, sem calendário ou exames anuais. Nen, Hatsu e nível mínimo não são exigidos.

Ao confirmar a participação, o RNG seleciona uma de duas provas em cada etapa. As quatro escolhas ficam salvas, produzindo até **16 combinações** de uma sequência fixa de textos previamente escritos.

| Etapa | Alternativa A | Alternativa B |
|---|---|---|
| 1 | Travessia perigosa | Percurso de resistência |
| 2 | Investigação de informações | Captura de uma fita |
| 3 | Sobrevivência e abrigo | Desafio coletivo |
| 4 | Confronto individual | Prova de decisão |

Os examinadores originais **Selma** e **Rui** conduzem as provas. **Nara**, cooperativa, **Daro**, competitivo, e **Ivo**, pragmático, reaparecem conforme as situações. Acordos, ajuda ou sabotagem são registrados em flags e podem alterar alternativas posteriores. Não são NPCs autônomos nem possuem relações numéricas.

Falhas comuns geram advertências, perda de Saúde ou atrasos. Até duas advertências podem ser aceitas na avaliação final; fraude e sabotagem podem causar reprovação imediata. O confronto final também aceita uma rendição avaliada após pelo menos um turno, caso tenha havido cooperação e no máximo uma advertência. Fugir ou render-se fora dessa condição reprova, sem transformar o exame em uma morte obrigatória.

Aprovação concede uma **Licença Hunter** e 40 XP. A licença aparece no Inventário; Personagem informa a condição de Hunter licenciado. Ela abre **Uma consulta reservada a Hunters**, um trabalho civil com teste de Intelecto e pagamento condicionado ao resultado.

Reprovação e desistência preservam o XP já obtido e permitem voltar à jornada, desde que haja Saúde. Não é possível tentar outra edição na mesma partida. Nos intervalos, consumíveis podem ser usados fora de combate. As aventuras anteriores continuam disponíveis.

## Áudio e identidade visual

A trilha instrumental original **Caderno de campo** acompanha a leitura em loop, sem reiniciar ao trocar de aba. Oito efeitos curtos identificam confirmação, escolha, navegação, retorno, sucesso, fracasso, recompensa e subida de nível. Avisos simultâneos usam prioridade para evitar sobreposição.

O botão de ajustes no cabeçalho abre **Configurações**. Música e efeitos possuem volumes e opções de silenciar independentes, aplicados imediatamente e restaurados entre sessões. O painel também oferece **Reduzir animações**: interrompe os efeitos visuais ativos e apresenta as próximas mudanças imediatamente, preservando os destaques estáticos. As preferências ficam em `user://audio.cfg`, nas seções de áudio e acessibilidade, separadas dos três slots. Arquivos ausentes ou inválidos usam valores padrão seguros.

Abas e cartões usam transições de 0,14 segundo; pressionar um botão recebe uma resposta de 0,10 segundo. Os textos aparecem completos e os controles continuam disponíveis durante os efeitos. Resultados d20, dano, XP, Jenny, itens e Licença Hunter são destacados após ações reais; carregar uma jornada não reapresenta recompensas.

O emblema de cartão e bússola identifica o jogo; ele não representa uma Licença Hunter conquistada. Os ícones mantêm os textos das abas e categorias de combate. Música, efeitos e SVGs são locais e originais, sem dependências de internet. Consulte [origem e licenças dos recursos](assets/ASSET_LICENSES.md).

## Como jogar

### Requisitos e instalação

- Godot **4.7.2**, versão usada na validação.
- Um computador capaz de executar o renderizador de compatibilidade do Godot.
- Não há plugins ou dependências externas obrigatórias.

No gerenciador do Godot, selecione **Importar**, escolha o `project.godot` desta pasta e abra o projeto. Pressione **F5** para executar.

A janela inicial é vertical, 480×860, com mínimo de 320×480. Fontes Source Sans 3 e Cinzel são preferidas quando disponíveis; fontes locais substitutas permitem executar sem downloads.

### Controles

1. Escolha **Slot 1**, **Slot 2** ou **Slot 3**. Em um espaço vazio, inicie uma jornada e informe nome e inclinação; em um ocupado, use **Carregar jornada**.
2. Na Aventura, escolha uma ação e use **Continuar jornada** após ler o resultado. Em combate, abra a categoria desejada.
3. Consulte atributos, Nen e condição de Hunter em **Personagem**; **Gerenciar jornadas** retorna ao menu de slots.
4. Use ou equipe objetos em **Inventário**, fora de batalhas.
5. No **Registro**, clique em **Salvar no Slot N** para salvar a jornada correspondente.
6. Para liberar um espaço, use **Excluir jornada** e confirme. Cancelar preserva o arquivo.

A roda do mouse ou a barra de rolagem permite acessar conteúdo longo. Salve antes de trocar de jornada. Voltar do formulário de criação sem iniciar outra partida conserva a sessão anterior em memória.

## Salvamento e compatibilidade

No Android, os arquivos `user://` ficam na área privada do aplicativo; o formato v9 e os três slots são os mesmos. O botão Voltar fecha configurações, cancela diálogos ou retorna de submenus antes de oferecer a saída. Em uma jornada vinculada a slot, **Salvar e sair** grava o estado antes de fechar; falhas de gravação impedem o fechamento. O salvamento manual continua disponível no Registro. Salve antes de deixar o aplicativo em segundo plano: o Android pode encerrar processos suspensos. Desinstalar o aplicativo remove os dados locais.

Os saves ficam no diretório de dados **Hunter Life Prototype** definido pelo Godot. Consulte o caminho por **Project > Open User Data Folder**. Cada slot tem arquivos próprios:

| Espaço | Arquivo manual | Checkpoints |
|---|---|---|
| Slot 1 | `user://saves/slot_1/save.json` | `user://saves/slot_1/checkpoints/` |
| Slot 2 | `user://saves/slot_2/save.json` | `user://saves/slot_2/checkpoints/` |
| Slot 3 | `user://saves/slot_3/save.json` | `user://saves/slot_3/checkpoints/` |

O formato atual é **v9**. Preserva personagem, recursos, progressão, flags, registros, visitas, equipamentos, Nen, Hatsu, RNG e batalha, além de participação no exame, sequência de provas, etapa, advertências e resultado. A licença está vinculada à aprovação.

O menu valida os arquivos antes de mostrar nome, nível e categoria conhecida. Uma nova jornada só pode ocupar espaço vazio; salvar usa o slot e a geração da sessão carregada. A criação grava um primeiro estado. Os avanços comuns continuam com salvamento manual.

Na primeira execução, o antigo `user://hunter_life.json` é migrado para o **Slot 1**, se ele estiver vazio. O original é mantido como backup. Um registro de migração evita repetir a importação, inclusive depois de excluir o slot. Se o Slot 1 estiver ocupado ou algum arquivo estiver inválido, ele não é substituído; uma mensagem informa a situação. Migrações interrompidas podem ser retomadas com os registros existentes.

A avaliação usa `affinity`, com decisões, rolagens e resultado permanente. Cada decisão gera checkpoint no diretório do slot, associado à jornada pela identificação da 10E e por uma geração própria do slot. Carregar retoma o registro mais adiantado sem repetir decisões; um manual mais recente prevalece. Checkpoints antigos em `user://affinity_checkpoints/` são adotados durante a migração da jornada correspondente. Registros válidos ainda sem slot podem ser recuperados explicitamente em espaço vazio pelo menu. Excluir uma jornada remove seus checkpoints associados, sem tocar nos outros slots.

As migrações de v2 a v8 permanecem disponíveis. Saves v8 recebem participação não iniciada e nenhuma licença retroativa. Carregar não aplica recompensas, não sorteia provas novas e não grava o arquivo automaticamente. O próximo salvamento manual utiliza v9. Arquivos inválidos são recusados com mensagem em português antes de substituir a sessão em memória.

A gravação usa arquivo temporário e substituição após sucesso. A exclusão exige confirmação. O JSON é local e não criptografado; não há sincronização em nuvem ou navegador de backups.

## Testes automatizados

Na pasta do projeto, com o executável Godot no `PATH` (ou substituindo `godot` pelo caminho completo):

```powershell
# Validação do projeto
godot --headless --editor --path . --quit

# Ambiente isolado para testes de interface: não usa os slots reais.
$testRun = [DateTime]::UtcNow.Ticks
$env:HUNTER_LIFE_DATA_ROOT = 'user://test_run_' + $testRun

# Principais suítes funcionais
godot --headless --path . --script res://tests/test_exam.gd
godot --headless --path . --script res://tests/test_battle.gd
godot --headless --path . --script res://tests/test_inventory.gd
godot --headless --path . --script res://tests/test_nen.gd
godot --headless --path . --script res://tests/test_hatsu.gd
godot --headless --path . --script res://tests/test_narrative_revision.gd
godot --headless --path . --script res://tests/test_expansion.gd
godot --headless --path . --script res://tests/test_hatsu_10c.gd
godot --headless --path . --script res://tests/test_manipulation.gd
godot --headless --path . --script res://tests/test_affinity.gd
godot --headless --path . --script res://tests/test_slots.gd

# Verificações com renderização e capturas
godot --path . --script res://tests/test_exam_visual.gd
godot --path . --script res://tests/test_visual.gd
godot --path . --script res://tests/test_narrative_revision_visual.gd
godot --path . --script res://tests/test_expansion_visual.gd
godot --path . --script res://tests/test_hatsu_10c_visual.gd
godot --path . --script res://tests/test_manipulation_visual.gd
godot --path . --script res://tests/test_affinity_visual.gd
godot --path . --script res://tests/test_slots_ui.gd
godot --path . --script res://tests/test_combat_menu.gd
godot --path . --script res://tests/test_audio_identity.gd
godot --path . --script res://tests/test_polish.gd
godot --path . --script res://tests/test_android.gd
godot --path . --script res://tests/test_touch_scroll.gd

Remove-Item Env:HUNTER_LIFE_DATA_ROOT
```

Os testes visuais precisam de renderização real: não use `--headless` neles. As outras suítes em `tests/test_*.gd` cobrem criação, progressão, continuidade, textos e interfaces específicas. Testes usam arquivos temporários próprios, sem substituir o slot manual do jogador.

As resoluções verificadas são 320×480, 390×844, 480×860, 768×1024 e 1100×720. A verificação de textos percorre os 92 acontecimentos em 320×480 e 390×844. Logs atuais ficam em `tests/stage10h_*.log`; imagens, em `tests/captures/`. As 33 suítes anteriores passaram, junto da nova suíte de polimento: trocas rápidas, integridade do RNG, resultados, recompensas, configurações, foco e movimento reduzido. Resultados e limitações estão no [relatório 10H](STAGE_10H.md).

## Limitações e desenvolvimento futuro

O catálogo é finito e possui poucas aventuras. As provas do exame são combinações de oito textos fixos, não geração de histórias. Os candidatos não têm IA autônoma. Há cinco Hatsus e uma especialização fixa por personagem. O Especialista reproduz um deles pela avaliação provisória da 10E; não há um sexto Hatsu ou versão superior. Controle de Objetos utiliza alvos explicitamente definidos, sem inventário de adversários ou simulação livre de mecanismos.

Não há calendário, exames anuais, mundo aberto, grupos permanentes, fabricação, peso, durabilidade, comércio dinâmico ou economia avançada. Também não há combate em tempo real, equipamentos personalizáveis ou consumo detalhado de aura. Nenhum desses sistemas é apresentado como disponível nesta versão.

O desenvolvimento inclui o Bloco 10H. A trilha usa timbres sintetizados leves; não há trilhas dinâmicas ou gravações instrumentais. Exportação de pacote PCK foi verificada, mas não foi produzido um executável Windows independente. Testes de layout não substituem validação em celulares físicos. Alguns testes antigos que encerram o processo imediatamente ainda podem emitir avisos de áudio retido no fechamento; a saída normal pela janela utiliza liberação gradual.

Um APK Android de depuração foi gerado e verificado, separado da exportação Windows. Para reconstruí-lo no computador configurado, execute `./tools/export_android.ps1`; requisitos e opções estão no [relatório Android](STAGE_ANDROID.md). JDK e SDK são necessários apenas para gerar o APK, não para jogar no telefone. A v0.1.1 não foi iniciada.

## Histórico resumido

As Etapas 1–3 estabeleceram a interface, o motor narrativo e as primeiras jornadas. Os relatórios técnicos históricos disponíveis foram preservados:

| Etapa | Relatório |
|---|---|
| 4 | [Progressão, XP e recursos](STAGE_4.md) |
| 5 | [Fundamentos do Nen](STAGE_5.md) |
| 6 | [Hatsus e personalização](STAGE_6.md) |
| 7 | [Batalhas narrativas](STAGE_7.md) |
| 8 | [Inventário funcional](STAGE_8.md) |
| 9 | [Exame Hunter](STAGE_9.md) |
| 10A | [Revisão narrativa dos acontecimentos](STAGE_10A.md) |
| 10B | [Expansão das aventuras e consequências](STAGE_10B.md) |
| 10C | [Fio de Aura e Escudo Materializado](STAGE_10C.md) |
| 10D | [Agulha de Comando](STAGE_10D.md) |
| 10E | [Afinidade do Especialista](STAGE_10E.md) |
| 10F | [Três slots e menu de combate](STAGE_10F.md) |
| 10G | [Áudio e identidade visual](STAGE_10G.md) |
| 10H | [Animações e refinamento dos menus](STAGE_10H.md) |
| Android v0.1.0 | [Preparação, APK de teste e validação física pendente](STAGE_ANDROID.md) |
| Android revisão 1 | [Rolagem nativa por toque e modo imersivo](STAGE_ANDROID_REVISION_1.md) |
