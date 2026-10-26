# Idiota Autoproclamado Herói (protótipo)

RPG de aventura 3D em terceira pessoa para Android, feito em **Godot 4.3 + GDScript** (renderizador Mobile).
Esta é a **base técnica da primeira etapa**: uma pequena região florestal jogável com placeholders.

> ⚠️ Esta base foi escrita **sem acesso ao Godot**. Nada foi executado nem exportado ainda. Veja `docs/TESTES.md`.

## Estrutura
- `assets/` recursos (vazio por enquanto; ver `docs/ASSETS.md`)
- `scenes/main/main.tscn` cena principal (monta o resto por código)
- `scripts/` core, player, enemies, world, ui, save
- `data/` JSON de classes, itens, missões, inimigos e regiões
- `tests/run_tests.gd` testes de dados/salvamento
- `docs/` documentação e painéis de referência
- `.github/workflows/android-build.yml` gera o APK no GitHub Actions

## Abrir e executar
1. Instale o Godot 4.3 (estável) em um computador.
2. Importe a pasta (`project.godot`) e pressione F5.
3. Testes no PC: WASD move, setas giram a câmera, Espaço pula, F ataca, E interage. O mouse emula toque.

## Controles no Android
Analógico flutuante na metade esquerda, arrastar na direita para a câmera, botões Atacar/Pular/Interagir, Menu (inventário, atributos, 10 slots de save).

## Fluxo no celular (Termux + GitHub Actions)
O Godot completo + SDK Android não é prático no Termux; o APK é gerado pelo GitHub Actions.
```
pkg update && pkg install -y git unzip gh
termux-setup-storage
mkdir -p ~/projetos && cd ~/projetos
unzip /sdcard/Download/idiota-autoproclamado-heroi.zip
cd idiota-autoproclamado-heroi
git config --global user.name "Seu Nome"
git config --global user.email "voce@exemplo.com"
git init -b main
git add .
git commit -m "feat: base do protótipo (etapa 1)"
gh auth login            # siga o login pelo navegador; nunca coloque tokens nos arquivos
gh repo create idiota-autoproclamado-heroi --private --source=. --push
```
Depois: no GitHub abra **Actions → Android APK (debug)** → execute (ou aguarde o push) → baixe o artefato `idiota-heroi-apk-debug`, extraia o `.apk` e instale (permita "fontes desconhecidas").
Atualizações: `git add . && git commit -m "..." && git push`.

## Adicionar assets
Coloque modelos (`.glb`) em `assets/models/...`, texturas em `assets/textures/...`, e substitua os placeholders em `scripts/world/world_builder.gd`, `player.gd`, `enemy.gd`. Itens novos: `data/items/items.json`.

## Limitações conhecidas
Tudo é placeholder com primitivas; não há modelo 3D animado, texturas, sons nem animações. Classes, missão, NPC e inimigo são provisórios. Dificuldade noturna (10/12/15/20) não aplicada. Ver `docs/`.
