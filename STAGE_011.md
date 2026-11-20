# v0.1.1 — A Vida de um Hunter

## Escopo e preservação

Atualização de conteúdo e consequências, construída sobre a v0.1.0 Android. O repositório estava limpo antes do trabalho. A tag anotada `v0.1.0` conserva o commit `c30b059`; a implementação foi feita em `feature/v0.1.1-hunter-life`. Os APKs anteriores permanecem em `builds/android/`. Nenhum projeto One Piece Life foi modificado.

Permanecem os três slots, suas identidades de jornada e checkpoints, as quatro abas, áudio, configurações globais, rolagem nativa, modo imersivo, áreas seguras, Exame Hunter, cinco Hatsus e suas especializações. Não foram alteradas as fórmulas de d20, XP, dano, defesa, probabilidades, equipamentos ou fundamentos de Nen. Não foram criados quadro de contratos, menu de missões, calendário ou sistemas de reputação.

## Conteúdo

**174 acontecimentos: 92 anteriores + 82 novos.**

| Distribuição do catálogo completo | Cenas |
|---|---:|
| Cinco novas missões exclusivas de Hunters | 35 |
| Cinco novas missões comuns | 35 |
| Outros acontecimentos, incluindo aventuras anteriores, exame, Nen, desfechos e encontros | 104 |

Os 82 novos são 70 cenas de missão, oito encontros independentes e quatro consequências de decisões anteriores. Entre os encontros, um boletim profissional e o reencontro posterior à captura também exigem licença. A contagem de 35 refere-se às cenas das missões Hunter, não a todo texto que menciona a profissão.

Cada missão nova tem sete acontecimentos: oferta, preparação, desafio, duas rotas, conclusão e fracasso. Uma passagem individual percorre parte desse conjunto; não é necessário visitar as duas ramificações. Abandono pode ser resolvido numa escolha da oferta ou preparação, sem uma cena artificial adicional.

| ID estável | Missão | Personagens e dilemas |
|---|---|---|
| `h_capture` | Uma ordem com endereço | A delegada Nélia exige identificação e custódia de Brás; testemunhos, rendição, perseguição ou confronto no pátio |
| `h_coldchain` | As caixas que não podiam esperar | Célia acompanha a apuração de desvios de medicamentos; preservar provas, proteger informante ou aceitar suborno |
| `h_research` | A estação do capim alto | Olavo e Tainá precisam de proteção para pesquisa; segurança da equipe, documentos e recuperação do material |
| `h_species` | O ninho na margem escura | Dália pede observação de uma ave rara; registrar sem prejudicar o ninho ou negociar com um coletor |
| `h_relic` | O arquivo da pedreira | Estevão e Lia recuperam plantas históricas; avaliar apoios, contratar içamento ou assumir um risco extremo |
| `c_ferry` | A oficina do outro lado | Joana e Rui dependem de uma peça; transporte cuidadoso e conferência real da instalação |
| `c_missing` | O caderno de Amélia | Busca de contas extraviadas; esclarecer um engano sem transformar uma suspeita em acusação |
| `c_rooftops` | Água para a rua de cima | Baltasar inspeciona o abastecimento; acesso a quintais, lavanderia, segurança e direitos de uso |
| `c_fair` | A feira que mudou de margem | Sérgio transporta encomendas; autorizações, promessas anteriores e tentação de vender duas vezes |
| `c_salvage` | O armário sob a estação | Iraci recupera ferramentas; acesso alagado e distinção entre propriedade pessoal e peças de uma bomba |

Hunters também recebem as missões comuns. A licença não exige Nen para esses trabalhos e não torna os testes automáticos. Em uma oportunidade comercial comum, pode dar acesso à consulta da autorização do local. Nas missões profissionais, permite consultar depoimentos e documentação reservada. Nen, ferramentas e Hatsus oferecem alternativas específicas, preservando rotas sem eles.

Os oito encontros são audiência de vizinhança, cozinha comunitária, posto de atendimento, acidente com reboco, música na praça, boletim profissional, venda de pertences de uma viajante e conferência de documentos. Os quatro retornos tratam de testemunho após a captura, trabalho após a feira, cobrança de uma venda duplicada e erro anterior num depósito.

## Escolhas e consequências

- **Captura:** conferir registros permite apresentar uma identificação segura. Uma negociação mal conduzida pode levar à perseguição. A luta usa o assaltante existente; fuga não representa entrega do procurado.
- **Pesquisa:** retirar pessoas e registros essenciais difere de insistir no estojo. Há soluções de negociação, força, corda e Hatsus compatíveis, sem criar uma equipe autônoma.
- **Feira:** respeitar encomendas e vender uma caixa duas vezes produzem estados distintos. A decisão desonesta pode gerar cobrança posterior; a conclusão correta abre um trabalho de conferência.
- **Pedreira:** inspeção, mapa, iluminação, corda e contratação de apoio são alternativas. Correr sob uma laje instável tem advertência narrativa de queda fatal; fracassar nesse teste causa morte e encerra a vida. Esse resultado não é a regra de todos os fracassos.

Nos acontecimentos antigos, cinco fracassos receberam consequências além de XP reduzido: erro no depósito abre cobrança; esforço no cais perde 1 Saúde; a ajuda ao viajante custa 5 Jenny e registra atraso; uma alavanca improvisada custa 8 Jenny; coordenação malsucedida registra a decepção da equipe. XP e recompensas de sucesso desses acontecimentos não foram recalibrados para os testes.

Sem a consequência explícita `death`, Saúde zero conserva a política anterior: incapacidade, socorro e encerramento sem morte automática. O novo campo de efeito é usado somente no risco fatal contextualizado da pedreira. Nenhum combate comum passou a matar automaticamente.

Os finais existentes conservam identificadores e condições. As escolhas anteriores ao encerramento agora descrevem estabelecer-se, assumir trabalho regular ou guardar o diário. Foram revisados `crossroads`, os três encerramentos da entrega e `survey_done`, além do acesso em Personagem. O nome do final aparece depois da decisão. A conclusão das novas missões retorna às oportunidades.

## Missões únicas e persistência

Um pequeno módulo `missions.gd` controla a unidade narrativa; não há um segundo motor de acontecimentos. Cada cena referencia `mission` e `adventure` com o mesmo ID estável. A seleção mantém as continuações obrigatórias antes das oportunidades aleatórias.

Estados persistentes:

```json
{
  "version": 10,
  "gender": "unspecified",
  "missions": {
    "c_ferry": "completed",
    "h_capture": "active",
    "c_missing": "abandoned"
  }
}
```

`offered` identifica uma proposta atual; `active`, um compromisso aceito; `completed`, `failed` e `abandoned` são terminais. `archived` conserva uma tentativa histórica cujo resultado não pode ser comprovado. Ofertas recusadas são abandonadas. Uma missão terminal não volta ao sorteio e suas outras rotas não viram contratos independentes. A nova jornada limpa esse registro.

O mesmo controle inclui Entrega, Levantamento, Escolta e Ruínas, preservando seus IDs. Nen, avaliação de afinidade e exame mantêm seus fluxos próprios, incluindo oportunidades adiáveis. Encontros cotidianos conservam a política anterior de repetição, intervalo e recompensas reduzidas.

A resolução de escolhas continua única e os desfechos pagam uma vez. Reabrir o mesmo acontecimento ainda não resolvido não aumenta visitas ou consome RNG: foi corrigida uma duplicação que podia suprimir uma recompensa ao aplicar a política de repetição. Começar outra vida também limpa o identificador e a apresentação da anterior.

## Gênero e compatibilidade

Criação: **Não especificar**, **Masculino** ou **Feminino**. Apenas identidade e tratamentos pontuais mudam; atributos, perfis, Nen e RNG são os mesmos com a mesma semente. A maioria dos textos continua usando “você”. Um encontro emprega o tratamento contextual “viajante”, “senhor” ou “senhora”. A aba Personagem mostra a escolha e usa a expressão neutra “Hunter com licença”.

O save **v10** adiciona `gender` e `missions`, sem mudar caminhos de slots, geração da jornada ou identidade dos checkpoints. Os demais campos são preservados. Validações recusam gênero desconhecido, missão inexistente, atividade incompatível e missão profissional sem aprovação/licença.

Saves **v2–v9** continuam aceitos. Em v9, o padrão de gênero é `unspecified`. Progresso de missões antigas é inferido somente de aventura ativa, flags, conclusões e cenas visitadas: conclusão comprovada, tentativa atual ou arquivo histórico sem inventar um resultado. Não há itens, XP, relações ou recompensas retroativas. Carregar não regrava o manual; a gravação seguinte usa v10. Checkpoints são lidos pelas migrações existentes e conservam sua associação ao slot.

Cinco fixtures foram produzidas executando o **código da tag v0.1.0**, não fabricando um save v9 com o código novo: encontro independente, escolta em andamento, confronto, próximo turno esperado e avaliação de Especialização. Os testes comparam todos os campos anteriores após normalizar a representação numérica do JSON. O turno seguinte do confronto mantém exatamente os mesmos resultados e RNG.

**Retorno à versão antiga:** v0.1.0 não entende saves v10. Antes de testar no telefone, conservar backup dos slots e checkpoints v9 se houver intenção de voltar. Manter apenas o APK antigo não restaura dados sobrescritos por um novo salvamento. Nenhum arquivo antigo foi apagado automaticamente pela migração.

## Balanceamento e simulações

- Curva de XP permanece `40 + 20 × (nível − 1)`; atributos continuam 1–10 e Saúde 0–10.
- Dificuldades novas concentram-se em 12–14 para trabalhos comuns e 14–17 nos riscos profissionais. Ferramentas e alternativas condicionais podem reduzir o risco ou dispensar um teste específico, sem bônus global.
- Pagamento final das missões comuns: 85–130 Jenny; profissionais: 150–210. XP final: 12–20, além dos marcos intermediários definidos em JSON. Desfechos fracassados conservam pequenos ganhos legítimos; não pagam o contrato completo.
- Pesos das novas ofertas: comuns 4, profissionais 3. `nen_offer` e `exam_invite` passaram de 2 para 4 para não desaparecerem no catálogo maior. Seus requisitos permanecem iguais. Outras oportunidades antigas conservam seus pesos.

### Resultados específicos

1. **494 tentativas com escolhas alternadas:** 201 conclusões, 283 fracassos e dez abandonos. Foram planejadas 50 sementes por missão; seis casos foram descartados porque a abertura inicial já havia registrado a mesma missão. Todas as 70 cenas de missão foram alcançadas; todas as dez missões tiveram conclusão, fracasso e abandono exercitados.
2. **400 tentativas com política cautelosa:** 200 com atributos 5 e sem ferramentas, 200 com atributos 8 e corda/mapa/lanterna. A política consulta testes visíveis, custos e avisos, evita o risco fatal e prioriza alternativas seguras. Conclusões: 182/200 (91%) e 189/200 (94,5%). A comparação é entre perfis completos, não mede isoladamente o efeito de um ponto de atributo. O perfil forte ainda sofreu ferimentos e fracassos.
3. **120 jornadas completas:** quarenta recusando Nen e exame, quarenta abertas a ambos e quarenta começando com licença. A política não distribui os pontos de nível e não usa o estado futuro do RNG para decidir.

| Perfil inicial / decisões | Níveis finais | Encerramento natural / incapacidade | Ofertas de missão / profissionais |
|---|---|---|---:|
| Sem Nen ou exame durante toda a jornada | 4: 29; 5: 11 | 40 / 0 | 189 / 0 |
| Começa sem licença, pode participar do exame | 4: 2; 5: 32; 6: 3; 7: 3 | 39 / 1 | 218 / 30, após aprovação |
| Começa com licença | 2: 1; 4: 1; 5: 1; 6: 37 | 37 / 3 | 378 / 193 |

As simulações de jornada alcançaram 150 acontecimentos distintos. Os outros caminhos são verificados pelos testes dirigidos e pelas suítes históricas; não significa que cada jornada veja todo o catálogo. Houve abertura de Nen em 40/40 jornadas comuns e 38/40 licenciadas; as comuns a recusaram. O Exame apareceu em 40/40 jornadas que começaram sem participação. O máximo foi 259 passos de execução do simulador, que conta escolher e avançar separadamente; não são 259 acontecimentos.

Estes resultados comprovam acessibilidade, continuidade e diferenças entre decisões. Não substituem avaliação humana de escrita, ritmo ou dificuldade no aparelho.

## Arquivos

| Área | Criados ou modificados |
|---|---|
| Conteúdo | `data/journeys_011.json`, `data/revisions_011.json`, `tools/build_011_content.cjs` |
| Missões, apresentação e persistência | `scripts/missions.gd`, `scripts/catalog.gd`, `scripts/game_state.gd`, `scripts/storage.gd` |
| Integração mínima com combate | `scripts/battle.gd`: somente encerra a missão por incapacidade antes de limpar a aventura |
| Interface | `scripts/main.gd`, `scripts/ui/creation_view.gd` |
| Identificação e APK | `project.godot`, `export_presets.cfg`, `tools/export_android.ps1`, `tests/check_android_apk.ps1` |
| Testes novos | `tests/test_life_011.gd`, `tests/test_migration_011.gd`, `tests/test_balance_011.gd`, `tests/test_life_011_visual.gd`, `tests/fixtures/v010/`, `tests/generate_v010_fixtures.gd` |
| Regressão e execução isolada | `tools/run_tests.ps1`; expectativas de contagem/versão em `test_foundation`, `test_expansion`, `test_hatsu_10c`, `test_manipulation`; seleção ponderada em `test_narrative` |
| Evidências | `tests/011_test_results.json`, `tests/011_mission_results.json`, `tests/011_balance_results.json`, `tests/captures/011_*.png` |
| Documentação | `README.md`, `STAGE_011.md` |

Os arquivos `.gd.uid` correspondentes foram gerados pelo Godot. `data/events.json` e os relatórios históricos permanecem intactos. Revisões dos acontecimentos antigos são aplicadas por catálogo de patches, preservando os registros e consequências já resolvidos nos saves. O helper Node é opcional e só regenera os JSONs durante desenvolvimento; não é uma dependência de execução.

## Testes e validação

Executar `./tools/run_tests.ps1` com Godot 4.7.2; aceita `-GodotPath`. O executor atribui um diretório de slots/preferências diferente a cada suíte. Testes renderizados precisam de sessão gráfica. O script `generate_v010_fixtures.gd` é uma ferramenta de reprodução das fixtures e deve ser executado contra o arquivo Git da v0.1.0, não como uma suíte na versão nova.

As novas suítes cobrem catálogo, referências, caminhos, licença, gênero, consequências, finais, resolução única, salvamento durante as missões e confrontos, migração real v9, arquivos inconsistentes e simulações. As anteriores verificam as 16 combinações do exame, Nen, cinco Hatsus, Especialistas, combate, equipamentos, três slots, checkpoints, áudio, configurações, movimento reduzido e rolagem.

**Resultado final: 40 suítes aprovadas, 112.833 verificações, zero falhas de testes.** A suíte de conteúdo foi ampliada e executada novamente após a bateria completa para verificar também venda duplicada → cobrança e erro no depósito → acerto da conta, com salvamento entre os acontecimentos. O consolidado registra essa execução mais recente.

| Validação | Verificações | Resultado |
|---|---:|---|
| Missões, condições, gênero, consequências, finais e persistência | 8.870 | Aprovada |
| Migração com fixtures reais da v0.1.0 e estados inválidos | 166 | Aprovada |
| 400 missões cautelosas e 120 jornadas completas | 60.847 | Aprovada |
| Interface nova, 82 cenas compactas e amostras nas demais resoluções | 1.979 | Aprovada |
| 36 suítes anteriores | 40.971 | Aprovadas |
| Integridade do APK, incluindo scripts compilados da atualização | 36 adicionais | Aprovada |

Também passaram importação/exportação no Godot, verificação da assinatura, comparação do certificado com o APK anterior e alinhamento de 16 KB. `adb devices` não encontrou aparelho conectado.

As 82 cenas novas foram renderizadas em 320×480 e 390×844, verificando largura, navegação e acesso à última escolha por rolagem. Amostras também foram verificadas em 480×860, 768×1024 e 1100×720. As capturas `011_h_capture_offer.png`, `011_h_relic_trial.png`, `011_c_missing_route_a.png`, `011_danger_choices_320.png`, `011_creation_gender.png` e `011_character.png` estão em `tests/captures/`.

Falhas encontradas e corrigidas durante a validação:

- Reabertura de um evento pendente contava uma visita extra e podia suprimir recompensas por tratá-lo como repetição. A abertura agora é idempotente.
- A contagem antiga de oportunidades incluía um evento com peso zero; o teste agora distingue eventos elegíveis de eventos efetivamente sorteáveis.
- A bateria compartilhava um diretório de slots: criar uma jornada num teste tornava ocupado o espaço que outro teste esperava vazio. Foi corrigido o isolamento do executor, preservando a proteção contra sobrescrita.
- A auditoria dos finais encontrou “Encerrar a jornada aqui” em `survey_done`, além das opções já revisadas. A escolha agora descreve o trabalho regular, sem mudar seu destino.
- Um texto comum pressupunha que o protagonista tinha licença; passou a mencionar a prerrogativa como hipótese.

Algumas suítes históricas encerram imediatamente e ainda produzem avisos de `ObjectDB`/recursos de áudio retidos na saída. Não são falhas de assertiva nem erros novos durante a execução; a saída normal usa a liberação existente. O executor distingue esses avisos de erros de scripts, sem ignorar falhas de testes.

## APK e instalação de teste

Arquivo: **`C:\Users\muril\Downloads\Hunter life\Hunter_Life\builds\android\Hunter-Life-0.1.1-test.apk`**.

Identificador preservado: `org.hunterlife.prototype`. `versionCode=3`, `versionName=0.1.1-test`; retrato, ARM64, assinatura de depuração local e alinhamento de páginas de 16 KB. Não há chaves ou senhas adicionadas ao Git. O APK usa a assinatura local existente para atualizar a instalação, sem exigir desinstalação.

Recriar com `./tools/export_android.ps1`; validar com `./tests/check_android_apk.ps1`. Foram verificados a assinatura, alinhamento, bibliotecas ARM64, ausência de testes no pacote, dependências locais de áudio/ícones, os 174 acontecimentos, patches e recursos de rolagem/modo imersivo. O arquivo `.sha256` acompanha o APK.

APK gerado: 30.934.635 bytes. SHA-256: `38b2ad9cbbd4aabc15c86932adac6ac5f8c6b2b2dbc8e4736a64037c2c353656`.

No Galaxy A15 5G, salvar a jornada atual, conservar backup se for preciso retornar ao save v9, transferir o APK e abri-lo pelo gerenciador de arquivos. Autorizar a instalação pela origem utilizada e confirmar a atualização. Não desinstalar a versão anterior para preservar os dados privados do aplicativo. Com ADB já autorizado, a alternativa é `adb install -r <caminho-do-apk>`.

### Validação física pendente

- Carregar os três slots antigos e salvar/carregar uma missão nova, inclusive durante um confronto.
- Criar personagens com as três opções de gênero e conferir o tratamento.
- Jogar uma missão comum sem Nen/licença e outra profissional após aprovação no exame.
- Verificar toque/arrasto em textos e escolhas extensas, sem ações acidentais.
- Conferir tela cheia, áreas seguras, botão Voltar, minimizar/retomar, áudio e preferências.
- Conferir ferimentos, fracassos, pagamento único e que uma missão encerrada não reaparece após reabrir o aplicativo.
- Avaliar legibilidade, ritmo e dificuldade numa partida real.

O APK foi preparado para testes, não declarado pronto para lançamento público. Não houve aparelho Android conectado nesta sessão; instalação, fluidez, toque físico e comportamento de retomada dessa atualização ainda dependem do desenvolvedor. Não foi preparada distribuição Windows ou iniciada outra versão.
