# Hunter Life — Etapa 1

Protótipo textual independente, ambientado em Hunter × Hunter. Interface inspirada na referência fornecida, com criação de personagem e uma cena fixa de três escolhas. Não há motor narrativo completo.

## Executar

1. No gerenciador do Godot, importe o `project.godot` desta pasta.
2. Abra no Godot 4.7.2, versão instalada e usada na validação.
3. Pressione **F5**.
4. Informe um nome e clique em **Iniciar nova partida**. Se necessário, role o formulário para ver os quatro atributos e o botão.

O projeto usa o renderizador de compatibilidade e não exige plugins, conexão à internet, imagens ou fontes baixadas. A janela inicial é vertical, 480×860; o tamanho mínimo é 320×480. O conteúdo central tem rolagem e a navegação fica fora dela.

## Funcionalidades

- Criação com nome de até 32 caracteres, validação contextual e quatro atributos de valor inicial 5/10: Força, Agilidade, Intelecto e Presença.
- Aventura com título, capítulo, texto, três escolhas e uma consequência diferente por opção.
- Cada cena é resolvida uma vez por sessão; cliques repetidos não duplicam registros.
- Abas Aventura, Personagem, Inventário e Registro; atalho superior para o registro.
- Inventário é apenas uma tela de apresentação, explicitamente indisponível.
- A aba Personagem permite criar outro personagem e reiniciar a demonstração.
- Registro das escolhas e consequências em memória.
- Paleta `#F3EBDD`, `#E3D3B8`, `#292C2A`, `#315C4C`, `#B58A45` e `#A14B43` centralizada em um tema reutilizável.
- Ícones desenhados com controles nativos. A imagem de referência não é usada como fundo.
- Source Sans 3 e Cinzel são preferidas quando instaladas. Na ausência delas, são usadas fontes do sistema, como Segoe UI/Arial para textos e Georgia para títulos, com fallback do Godot.

## Arquivos criados

| Arquivo | Função |
|---|---|
| `project.godot` | Configuração e diretório de dados próprio |
| `main.tscn` | Cena principal |
| `scripts/main.gd` | Composição da tela, navegação e sessão |
| `scripts/game_state.gd` | Personagem, validação e resolução da demonstração |
| `scripts/ui/styles.gd` | Tema, cores, fontes e componentes reutilizáveis |
| `scripts/ui/line_icon.gd` | Ícones nativos de traço |
| `scripts/ui/creation_view.gd` | Formulário inicial e atributos |
| `scripts/ui/adventure_view.gd` | Narrativa, escolhas e consequência |
| `data/demo_event.json` | Dados da única cena fixa |
| `tests/test_foundation.gd` | Testes de estado, validação, sinais e navegação |
| `tests/test_visual.gd` | Testes com renderização e capturas |
| `tests/captures/.gdignore` | Evita importar capturas como recursos do jogo |
| `.gitignore` | Exclui cache local e logs do controle de versão |
| `README.md` | Uso, escopo e evidências |

O Godot também gera os arquivos `.gd.uid` correspondentes aos scripts. O cache `.godot/` é local e descartável. Logs e capturas ficam em `tests/`.

O JSON já separa conteúdo e interface, mas só esse arquivo fixo é carregado. Não há catálogo, seleção dinâmica, condições de eventos, encadeamento ou aplicação genérica de efeitos. Isso permite ampliar o conteúdo posteriormente sem construir uma abstração desnecessária nesta etapa.

## Testar manualmente

1. Tente iniciar sem nome: aparece uma mensagem junto ao campo.
2. Digite um nome e inicie: os quatro atributos ficam disponíveis em Personagem.
3. Visite as quatro abas e volte à Aventura; o estado é preservado.
4. Selecione uma escolha: sua consequência aparece abaixo e as três opções ficam desativadas.
5. Abra Registro e confira a decisão.
6. Em Personagem, crie outro personagem para experimentar as outras duas escolhas.
7. Redimensione a janela e confira rolagem, cabeçalho e navegação inferior.
8. Feche e reabra: uma nova sessão começa, pois não há salvamento nesta etapa.

## Testes automatizados

A partir desta pasta, com o executável Godot no PATH:

```powershell
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/test_foundation.gd
godot --path . --script res://tests/test_visual.gd
```

O teste visual exige renderização real; não deve usar `--headless`. Ele captura as telas em `tests/captures/`, nas resoluções 320×480, 390×844, 480×860, 768×1024 e 1100×720. Os testes verificam nome inválido, atributos, todas as escolhas, repetição de cliques, reinício, sinais, abas, cabeçalho, ausência de transbordamento horizontal e acesso ao botão inicial por rolagem.

Resultados executados no Godot 4.7.2: **41 verificações funcionais + 348 verificações visuais = 389 verificações, nenhuma falha**. Foram produzidas **35 capturas** em cinco resoluções. Criação, aventura, resultado e layout amplo foram inspecionados visualmente. A importação pelo editor e a inicialização normal do projeto também terminaram sem erros ou avisos nos logs finais. Capturas de criação, aventura, personagem, inventário, registro e consequência ficam disponíveis para avaliação visual.

## Limites conhecidos

- Não há salvamento persistente; tudo é mantido somente nesta sessão.
- Os 250 Jenny mostrados são um saldo ilustrativo fixo. Não há economia nem recompensas.
- Nen, combate, progressão de atributos, NPCs autônomos, missões, mundo aberto, geração procedural e inventário funcional não foram implementados.
- A cena não avança para uma segunda aventura após a decisão. Para testar outra opção, crie outro personagem.
- Em telas compactas, a criação e as consequências exigem rolagem. A navegação inferior permanece disponível.
- A aparência das fontes pode variar conforme as fontes instaladas no computador.
- Compatibilidade foi executada no Godot 4.7.2 instalado; versões anteriores não foram testadas.

Nenhum arquivo dos projetos One Piece Life foi alterado. A etapa 2 não foi iniciada.
