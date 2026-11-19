# Recursos originais — Etapa 10G

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
