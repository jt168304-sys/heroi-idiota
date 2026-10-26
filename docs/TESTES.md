# Critérios de aceitação (todos NÃO VERIFICADOS: sem Godot no ambiente de geração)
1 Projeto abre; 2 referências de cenas/recursos; 3 personagem aparece; 4 movimento; 5 câmera por toque; 6 colisões; 7 ataque registra dano; 8 inimigo derrotável; 9 roleta; 10 inventário; 11 missão; 12 ciclo temporal; 13 salvar/carregar; 14 exportação Android; 15 APK instala.
Rodar: `godot --headless --path . -s tests/run_tests.gd` (dados, XP, missão, save).
Riscos conhecidos: erros de sintaxe GDScript não detectados; workflow do Actions e configuração do SDK não testados.
