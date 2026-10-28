# Assets

## Reais (recortados dos painéis 2D fornecidos pelo autor) - uso provisório
- `assets/textures/terrain/`: grama, neve, areia, terra, pedra (amostras de ~80px ampliadas para 256px e tornadas repetíveis por mistura de bordas; baixa resolução, trocar por texturas finais).
- `assets/textures/madeira.png`: madeira (mesmo processo).
- `assets/ui/icons/`: 118 ícones de itens recortados dos painéis (recursos, consumíveis, ferramentas, mobília, equipamentos). Ligados em `data/items/items.json` (campo `icone`). Os ícones de equipamento (capacetes, peitorais, luvas, maças) vêm de um painel de baixa qualidade.
- `assets/ui/portraits/heroi.png`: retrato do herói (HUD).
- `docs/referencias/`: painéis originais (guia de modelagem; NÃO são modelos 3D).

## Personagem (modelo real do autor, otimizado)
`assets/characters/heroi.glb`: modelo fornecido pelo autor, reduzido de 1,25 milhão para ~28 mil triângulos, com esqueleto de 16 ossos (rig AUTOMÁTICO, pesos simples) e 7 animações geradas por código (idle, walk, run, attack_light, attack_heavy, jump, dodge). A espada é uma peça provisória presa à mão direita. Deformações nos ombros podem ter pequenos defeitos; o ideal é um artista refinar pesos e animações no Blender. Pipeline em `tools/modelo/`. O modelo original (44 MB) não está no repositório.
Se o GLB falhar ao carregar, o jogo usa o boneco provisório de primitivas.

## Placeholders (primitivas)
Lobo, NPC, árvores, rochas (com textura), props.

## Ainda NÃO existem
Modelos 3D (.glb) de herói, NPCs, árvores, rochas, construções, itens e equipamentos; esqueleto/rig; animações reais; normal/roughness/AO dos terrenos (as miniaturas dos painéis não são mapas confiáveis); texturas de água; sons.
Os painéis de NPCs, árvores, rochas e grama servem como referência para a modelagem futura.

## Árvore 3D (Tree.fbx, pacote "Tutos trees 2.8")
`assets/models/trees/arvore_grande.glb`: tronco e galhos reais simplificados (~3 mil triângulos) e copa feita de 70 blocos verdes de baixo polígono, posicionados onde estavam as folhas do arquivo original. Não usa as cópias de folhagem originais (3 mil cópias, cerca de 1,5 mil triângulos cada) porque pesariam demais no celular.
Materiais: cor sólida, sem textura. O arquivo original tem texturas de casca (normal e rugosidade), mas não a cor base; por isso a casca é marrom sólida.
Licença: VERIFICAR antes de publicar (o pacote original não traz indicação de licença no arquivo).
