# Pipeline do modelo do herói (otimização + rig + animações)
O `.glb` original (1,25 milhão de triângulos, 44 MB, sem esqueleto) é pesado demais para o celular e NÃO está no repositório.
Estes scripts (Python + numpy/Pillow/scipy) geraram `assets/characters/heroi.glb`:
1. `build_mesh.py` reduz a malha (agrupamento de vértices respeitando ilhas de UV e grupos de ossos) para ~28 mil triângulos.
2. `riglib.py` define o esqueleto de 16 ossos e os pesos de skin (automáticos).
3. `anim.py` define as animações (idle, walk, run, attack_light, attack_heavy, jump, dodge).
4. `export_glb.py` grava o GLB com esqueleto e animações.
Requer `pos.npy`, `uv.npy`, `idx.npy`, `island.npy` e `tex0.jpg` extraídos do GLB original. O rig é automático e simples: um artista deve refinar pesos e animações no Blender quando possível.
