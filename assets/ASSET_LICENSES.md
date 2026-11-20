# Recursos do Hunter Life

Os arquivos WAV em `audio/music/` e `audio/sfx/`, os dez ícones SVG e o emblema em `icons/` foram criados originalmente para este projeto. Não incorporam gravações, samples, melodias de terceiros, fontes, bibliotecas de ícones ou imagens do anime.

Esses recursos originais e seus geradores em `tools/create_audio.cjs` e `tools/create_icons.cjs` são disponibilizados sob **CC0 1.0 Universal**, sem atribuição obrigatória. Esta declaração é limitada a esses recursos; não licencia marcas, personagens, obras Hunter × Hunter ou o código restante do projeto.

Texto da dedicação: https://creativecommons.org/publicdomain/zero/1.0/

## Catálogo

| Arquivo | Origem / função |
|---|---|
| `audio/music/field_notes.wav` | “Caderno de campo”, composição instrumental sintetizada original, 64 segundos, loop circular |
| `audio/sfx/click.wav` | Confirmação curta |
| `audio/sfx/select.wav` | Escolha narrativa |
| `audio/sfx/tab.wav` | Navegação |
| `audio/sfx/back.wav` | Retorno/cancelamento |
| `audio/sfx/success.wav` | Sucesso de teste |
| `audio/sfx/failure.wav` | Fracasso de teste |
| `audio/sfx/reward.wav` | Recompensa |
| `audio/sfx/level.wav` | Subida de nível |
| `icons/*.svg` | Dez ícones monocromáticos de 24 unidades e um emblema colorido de cartão/bússola |

Os geradores usam apenas Node.js e módulos nativos, em tempo de desenvolvimento. Godot reproduz os arquivos locais já incluídos. Node.js e acesso à internet não são necessários para jogar.

As variantes Android `app_icon.svg`, `app_foreground.svg`, `app_background.svg` e `app_monochrome.svg` derivam do mesmo emblema original e estão cobertas pela mesma dedicação CC0. Não incorporam arte oficial da Licença Hunter.

## Identidade visual v0.1.2

O emblema, a bússola e o livro foram redesenhados originalmente em SVG, com variantes Android, por `tools/create_visual_012.cjs`. O mesmo gerador produz os três ícones de escolhas: aperto de mãos, conversa e retorno. A mesma dedicação CC0 acima se aplica a esses vetores originais. Não reproduzem o símbolo oficial da Licença Hunter.

Os oito cenários em `scenery/*.webp` foram gerados originalmente com a ferramenta integrada imagegen para o projeto, sem imagens de terceiros incorporadas. Origem, prompts, arquivos originais e conversão estão em [scenery/SOURCES.md](scenery/SOURCES.md). Nenhuma imagem é um retrato de NPC.

### Fontes distribuídas localmente

| Família / arquivos | Autoria / origem | Licença incluída |
|---|---|---|
| Source Sans 3 Regular e Bold, `fonts/source_sans3/*.ttf` | Adobe / Paul D. Hunt; [repositório oficial Source Sans](https://github.com/adobe-fonts/source-sans/tree/release/TTF) | SIL Open Font License 1.1, `fonts/source_sans3/OFL.txt` |
| Source Serif 4 Semibold e Italic, `fonts/source_serif/*.otf` | Adobe / Frank Grießhammer; [repositório oficial Source Serif](https://github.com/adobe-fonts/source-serif/tree/release/OTF) | SIL Open Font License 1.1, `fonts/source_serif/OFL.txt` |
| Barlow Condensed SemiBold e Bold Italic, `fonts/barlow_condensed/*.ttf` | The Barlow Project Authors; [Google Fonts, repositório oficial](https://github.com/google/fonts/tree/main/ofl/barlowcondensed) | SIL Open Font License 1.1, `fonts/barlow_condensed/OFL.txt` |

Os arquivos de fonte foram mantidos sem alteração de seus desenhos. Source Sans 3 é a face Regular estática (400), para evitar selecionar acidentalmente um peso muito leve e manter a leitura consistente. As fontes não estão sob CC0: suas licenças OFL e avisos de autoria acompanham o APK. Nenhum download é feito durante o jogo.
