# Hunter Life — Etapa 5: Fundamentos do Nen

Continuação do projeto existente no Godot 4.7.2. As quatro abas e o tema foram preservados. Há 29 acontecimentos: os 23 anteriores, com três escolhas condicionais acrescentadas, e seis cenas opcionais de aprendizado. As duas aventuras originais continuam disponíveis com ou sem Nen.

## XP e migração
A curva final é exatamente a solicitada: 40 + 20 × (nível − 1), sem ajuste adicional. Custos 40/60/80/100; totais acumulados para níveis 2/3/4: 40/100/180. Recompensas anteriores do catálogo não foram multiplicadas. Aprendizado novo concede apenas 8/8/10 XP pelos três fundamentos, uma vez por marco.

Para migrar v4, o total antigo é `20 × (L−1) × (L+2) + saldo`. Esse total é consumido pela nova curva. Atributos já distribuídos permanecem intactos. Pontos novos disponíveis são `pontos antigos + nível novo − nível antigo`, limitados ao espaço restante até atributos 10. Isso preserva pontos já gastos e não recria recompensas narrativas. Exemplo: nível 3, saldo 50 e um ponto disponível = 250 XP totais; vira nível 4, saldo 70 e dois pontos disponíveis, mantendo os atributos.
Saves v5 não são recalculados ao carregar. Casos antigos de níveis altos dentro do intervalo permitido também foram verificados.

Probabilidade e rolagem mantêm a única regra: enumerar os 20 resultados de d20 + atributo >= dificuldade. Ponto distribuído altera imediatamente o percentual da interface em até cinco pontos percentuais, respeitando 0–100%. A rolagem continua d20, não percentual.

## Descoberta opcional
Mira é uma instrutora original, sem ligação com personagens canônicos ou organizações secretas. Uma aula no pátio pode aparecer entre oportunidades normais. Aceitar inicia seis cenas curtas; adiar volta à jornada; recusar bloqueia novos convites e permite seguir normalmente. Nen não exige nível nem Exame Hunter.

O convite pode reaparecer com intervalo 4 e até três apresentações espontâneas. Após conhecer Mira, quem adiou ou interrompeu antes do despertar também pode retomar pela seção Personagem, enquanto não recusou definitivamente. Não há prêmio por reabrir o convite.

Cenas novas: nen_offer, nen_ten, nen_zetsu, nen_ren, nen_water e nen_done. O aprendizado ocorre por orientação, sem abertura violenta de poros de aura. A técnica seguinte exige a anterior. Não há botão de treino repetitivo.

## Fundamentos e domínio
Cada técnica aprendida é um marco único. Domínio básico vai de 0 a 3 e é independente de nível e XP. Não há aura consumível, habilidades especiais ou árvore de talentos.
- **Ten:** mantém a aura junto ao corpo. Na ponte, uma alternativa ainda exige Agilidade 16; em fracasso Ten evita a escoriação específica. Sua recompensa é menor que a tentativa comum. Não confere invulnerabilidade geral.
- **Zetsu:** suprime a emissão de aura. Na vistoria do riacho, abre uma observação discreta com Agilidade 14; ruído e movimento ainda podem atrapalhar. Não torna o corpo invisível.
- **Ren:** intensifica a emissão. No torneio, abre uma demonstração moderada com Presença 16; em fracasso causa desconforto, sem prêmio e sem vitória garantida. Não é combate.

As escolhas comuns continuam disponíveis. Não há modificador global de atributo ou fórmula de sucesso para Nen. A seção Personagem apresenta despertar, fundamentos e domínio, sem nova aba.

## Adivinhação pela água
A afinidade oculta é sorteada uma vez na criação usando o RNG existente, antes de qualquer escolha. É persistida, mas não aparece em textos ou na interface antes do teste. Assim, carregar um save anterior ao despertar ou consumir outras rolagens não permite mudar a categoria. O teste somente revela o resultado fixado, uma vez, após os três fundamentos. Se for adiado, Personagem oferece procurar Mira para realizá-lo.

Efeitos usados:
- Reforço: volume aumenta.
- Emissão: cor muda.
- Transmutação: sabor muda.
- Materialização: surgem impurezas.
- Manipulação: a folha se move.
- Especialização: efeito fora dos cinco padrões; nesta cena, a folha murcha. Esse exemplo é uma escolha narrativa, não uma manifestação universal de Especialização.

Referências consultadas: [Hunterpedia — Nen](https://hunterxhunter.fandom.com/wiki/Nen?file=Nen_Types_Diagram.svg), [resumo do capítulo 60](https://hunterxhunter.fandom.com/wiki/Chapter_60), [HUNTER×WORLD — adivinhação pela água](https://hunterworld.tokyo/en/about-nenn/nenntypecheck/). As seis categorias têm pesos iguais no protótipo; isso é balanceamento da demonstração, não uma afirmação sobre frequência canônica. A revelação não concede Hatsu.

## Persistência v5
Adiciona `nen: {awakened, techniques, mastery, category, water_done}` e as flags nen_ten/nen_zetsu/nen_ren. A afinidade ainda não revelada é armazenada localmente; o save não é criptografado. Validação verifica ordem de aprendizagem, domínio, categoria, revelação e consistência com flags.
V4 preserva o total de XP e os atributos. V2/v3 continuam migrando sem prêmios retroativos, pela política anterior. Em saves antigos, a afinidade é determinada por um RNG clonado do estado persistido, sem avançar o RNG narrativo da partida; passa a ser persistida no próximo save manual. Não há gravação ou exclusão automática ao carregar.

## Arquivos
Novos: scripts/nen.gd; tests/test_nen.gd; tests/test_nen_visual.gd; STAGE_5.md.
Modificados: scripts/progression.gd; scripts/game_state.gd; scripts/storage.gd; scripts/main.gd; data/events.json; project.godot; tests/test_foundation.gd; tests/test_narrative.gd; tests/test_progression.gd; README.md.
O tema, as quatro abas, as duas aventuras e os sistemas de Saúde/Jenny permaneceram. Os únicos acréscimos às aventuras anteriores foram alternativas condicionais na ponte, no riacho e no torneio.

## Testes
Suítes finais: foundation 41; narrative 1280; story_ui 26; journeys 237; progression 430; progression_ui 4; nen 1239; visual 348; nen_visual 34. Total: **3639 verificações, zero falhas**, com importação e inicialização normal no Godot 4.7.2 sem erros ou avisos. Foram produzidas 40 capturas (35 de regressão e cinco de Nen). O teste novo verifica migração do XP total em vários níveis, pontos preservados, saves altos, estabilidade v5, seis categorias, ocultação/revelação, RNG, prevenção de rerrolagem, marcos, adiamento, recusa e condições das técnicas.
O teste visual verifica a categoria oculta antes da água, a revelação, o percentual atualizado após gastar um ponto e cinco resoluções: 320×480, 390×844, 480×860, 768×1024 e 1100×720. Capturas Nen estão em tests/captures/nen_*.png; logs finais em tests/stage5_*.log.

## Limitações
Conteúdo curto, um instrutor original e três aplicações contextuais. Domínio básico não é maestria; não há consumo de aura, combate, Hatsus, equipamentos ou NPCs autônomos. O teste da água tem uma manifestação ilustrativa por categoria. A categoria oculta não é protegida contra inspeção/edição manual do JSON. Recusa é definitiva nesta jornada; adiamento permite retorno. A Etapa 6 não foi iniciada.

### Simulações finais
Na amostra geral de 100 jornadas com escolhas variadas, 18 terminaram no nível 1, 63 no nível 2 e 19 no nível 3. Não houve necessidade de alterar novamente a curva solicitada.
Em grupos separados, 50 jornadas sem Nen terminaram com níveis 1/2/3 em 18/29/3 casos. Cinquenta com aprendizado prévio terminaram nos níveis 2/3 em 36/14 casos. Nen adiciona cenas e um pouco de XP, mas não é necessário para chegar aos finais.
A amostra de 100 personagens para a água produziu: Reforço 20, Emissão 16, Transmutação 11, Materialização 14, Manipulação 20 e Especialização 19. Não se trata de uma distribuição canônica ou estimativa de raridade; o catálogo usa pesos iguais.
Nenhum teste exigiu apagar ou modificar o slot manual do usuário. As suítes usam arquivos temporários próprios em user://. A Etapa 6 permanece fora desta entrega.
