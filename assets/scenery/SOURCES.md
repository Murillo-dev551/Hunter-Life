# Cenários — origem e prompts

Oito ilustrações originais geradas para Hunter Life com a ferramenta integrada **imagegen** em 20/11/2026. Não foram utilizadas imagens extraídas do anime, retratos de NPCs ou uma biblioteca externa. O protótipo enviado orientou a direção da interface; não foi utilizado como fundo estático nem copiado para as artes.

Os originais permanecem no diretório de saídas do imagegen. Os arquivos finais deste projeto estão em `assets/scenery/*.webp`: 960 pixels de largura, proporção panorâmica, conversão WebP sem perdas após redução com Lanczos, feita pelo Godot (`tools/prepare_scenery.gd`). As imagens não são necessárias para entender escolhas ou resultados. Não há atribuição de biblioteca de terceiros associada a essas ilustrações geradas.

## Prompt compartilhado

```text
Use case: illustration-story. Production game asset for Hunter Life: one original environment illustration, not a UI mockup. Subject: {SUBJECT} Style across this library: crisp monochrome black ink on clean white paper, confident manga editorial linework, restrained crosshatching and sparse halftone only for shadows, spacious whites, strong readable silhouettes, refined hand-drawn travel sketch. Wide horizontal panoramic framing approximately 3:1, modest detail readable when displayed at 340 by 110 pixels. Put the important architecture/route in the central horizontal band so it can fit a compact landscape card. Contemporary exploration setting. No foreground characters, no portraits, no lettering, no logo, no UI, no border, no paper texture, no color, no copyrighted franchise symbols. One scene only, coherent composition, clean attractive finished illustration.
```

## Subjects usados (um trabalho por cenário)

### inn.webp

A modest contemporary countryside guesthouse beside a road, timber porch, tiled roof, a small unlettered hanging bed pictogram, a few travel crates, mountain ridge in distance. No medieval architecture.

Original: `exec-b13258c7-cec3-4c26-bc72-2299d469514a.png`.

### city.webp

A small contemporary hillside town with ordinary apartment buildings, a distant observation tower, power poles, stepped streets and trees. No famous buildings.

Original: `exec-1f371534-a5f2-4cad-8129-3e70d01b3e6c.png`.

### forest.webp

A footpath winding through a lush forest, broad trunks, ferns, canopy openings and distant light. Clear path leads the eye.

Original: `exec-24618191-0660-4808-9ab3-6e6155f33154.png`.

### road.webp

A rural gravel road curving over a low ridge, roadside grass and wooden distance posts without text, distant hills and broad clouds.

Original: `exec-2c8e697b-3a36-4487-8220-d9c977936e7c.png`.

### port.webp

A modest working river port, moored civilian cargo boat, dock planks, bollards, ropes and low warehouses. No pirate ships.

Original: `exec-93a4ce8b-55dc-4cfa-960a-2d25c39b40c0.png`.

### ruins.webp

Old civic stone ruins of a water channel and an abandoned records building, broken lintel, worn steps, ivy, surveyable daylight, no temples or magic.

Original: `exec-c199ad88-fdcd-4341-8f1e-4a1d30bb6f5f.png`.

### office.webp

An unoccupied municipal investigation office, wooden desk, closed folders, task lamp, filing shelves and a window. Papers contain no readable writing.

Original: `exec-acdf83c0-6c2a-485c-909a-02eee7c96a25.png`.

### market.webp

A civilian open-air market lane, canvas awnings, produce baskets and closed wooden stalls, ordinary shopfronts, no people in foreground.

Original: `exec-3ecd7f48-3529-4fe5-85f0-f18587c1b658.png`.

## Uso editorial

As associações explícitas estão em `data/scenery_assignments.json`; os encontros novos podem declarar `scenery`. O cadastro `data/scenery.json` contém somente nomes e caminhos, sem pré-carregar texturas. A maioria dos acontecimentos não possui imagem.
