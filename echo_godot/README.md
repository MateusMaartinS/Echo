# ECHO

Jogo de ritmo 2D feito em Godot 4.7. O jogador observa a frase de um cantor e repete suas notas em quatro pistas. A entrega inclui o tutorial com Mentor e as fases Primavera/Flora, Outono/Silas, Verão/Solana e Inverno/Bóreas.

## Abrir e jogar

1. Clone ou baixe **esta pasta inteira** e abra `project.godot` no Godot 4.7.
2. Aguarde a primeira importação de músicas e sprites.
3. Execute o projeto, escolha **JOGAR** e selecione uma das cinco fases.

As músicas e charts estão em `audio/music/` e `charts/`. `menu.wav` toca nos menus e para durante uma fase ou no editor. Nenhum save é necessário para iniciar: progresso, visual equipado e configurações são criados em `user://` conforme o jogo é usado.

## Controles

| Pista | Direção | Tecla |
| --- | --- | --- |
| 1 | ↑ | D |
| 2 | → | F |
| 3 | ← | J |
| 4 | ↓ | K |

Segure notas longas até o fim. `ESC` pausa ou volta; `R` reinicia a fase; `F11` alterna tela cheia. Nos menus, use setas, Enter ou mouse. Em **PERSONAGENS**, Tab alterna entre masculino e feminino, as setas escolhem e Enter equipa.

## Estações

| Fase | Cantor | Mecânica |
| --- | --- | --- |
| Tutorial | Mentor | Apresenta notas simples, longas e os quatro obstáculos |
| Primavera | Flora | Flores encobrem duas linhas: memorize a frase |
| Outono | Silas | Notas-folha saem voando: deixe passar |
| Verão | Solana | Evite as notas de fogo |
| Inverno | Bóreas | Evite gelo, que congela linhas vizinhas |

Cada fase concede até quatro estrelas por notas acertadas (limiares: 50%, 70%, 85%, 95%). Quatro estrelas numa estação desbloqueiam seus visuais masculino e feminino.

## Editor e dados

**EDITOR** no menu principal abre a seleção de fases para edição. Cada fase tem um chart JSON com BPM, frases, notas e eventos. O editor permite criar e alterar frases, notas longas e obstáculos, copiar/colar trechos, desfazer, salvar e testar. O tutorial oferece todas as ferramentas.

`scripts/chart/LevelDB.gd` cadastra as fases. `scripts/chart/Lanes.gd` define o mapeamento das quatro pistas. A resposta do jogador é derivada das notas do oponente pelo atraso configurado no chart.

O [GDD](GDD_ECHO_entrega_parcial.txt) documenta regras, interface e status. [TEST.md](TEST.md) contém um roteiro curto de validação. O cache `.godot/` e os saves locais são ignorados pelo Git; o projeto importa os assets de origem ao abrir.
