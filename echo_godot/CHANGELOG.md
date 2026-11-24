# Changelog — merged build

## V12 — estrelas e pausa com contagem
- **Estrelas** (4 por fase) = fração de notas acertadas ao terminar (50/70/85/95%). Melhor resultado salvo em `user://progress.cfg`; aparece no topo de cada cartão (com tooltip dos limiares) e na tela de resultado (animada), com recorde, notas acertadas e "próxima estrela". Total de estrelas no cabeçalho da seleção. Limiares em `Progress.gd`.
- **Pausa** com ESC / botão PAUSA: CONTINUAR, REINICIAR, SAIR PARA AS FASES. Ao continuar: contagem de 4 tempos (BPM da fase, com som) antes da música voltar; ESC na contagem volta ao menu. Pausa automática ao perder o foco da janela.
- `Conductor` congela a posição enquanto pausado; `PlayerInput` deixa de consumir as setas na pausa; nota longa em andamento é perdoada ao pausar.

## V11 — tutorial, copiar/colar, configurações, energia
- **Energia balanceada**: perde menos (miss −6, erro −3, fogo −10, soltar nota longa −3) e recupera mais (+1,5/+1 por acerto, +3 por nota longa, +3 a cada 10 acertos seguidos). Constantes `ENERGY_*` no `ScoreManager.gd`.
- **Cartão TUTORIAL** (primeiro da lista): editor com todas as ferramentas (NOTA, FOGO, GELO, FOLHA, FLOR — teclas 1 a 5). Música: `audio/music/tutorial.wav`.
- Editor: **COPIAR/COLAR frases** (várias em sequência, com flores; COLAR AQUI e COLAR SOBRE), **DESFAZER** (Ctrl+Z, 40 passos), atalhos Ctrl+C/V, painel esquerdo reorganizado.
- **CONFIGURAÇÕES** no menu: volume da música, volume dos efeitos, sincronia (ms) e tela cheia, salvos em disco. Novos autoloads `GameSettings` e `Sfx`.
- **Sons de botão** (hover/click) ligados automaticamente em todo botão; ganchos de SFX de gameplay por julgamento. Arquivos em `audio/sfx/` (placeholders de interface incluídos).

## V10 — fases, notas longas, novas teclas e mecânicas de estação
- **Seleção de fase** (JOGAR no menu): 4 cartões (Primavera, Outono, Verão, Inverno) com JOGAR e EDITAR NOTAS. Cadastro em `LevelDB.gd`; música de cada fase = arquivo `audio/music/<fase>.wav|ogg|mp3`, sem mexer em código.
- Caminho do áudio/chart agora vem **só** do `LevelDB` (Editor e Jogo leem o mesmo lugar — fim da classe de bug em que o editor salvava num arquivo e o jogo carregava outro).
- **Teclas**: lanes de cima pra baixo = cima, direita, esquerda, baixo; cada lane aceita letra (D F J K) ou seta. Centralizado em `Lanes.gd`. Setas das notas/receptores usam a mesma geometria (e agora com o contorno fechado).
- **Notas longas** (`duration` no chart): arrastar no editor; no jogo, segurar até o fim (HoldOK com bônus / HoldBreak).
- **Mecânicas**: FLOR (primavera, eventos no editor), FOGO (verão), GELO (inverno), FOLHA (outono).
- Editor: ferramentas (teclas 1/2), trilha FLORES, preview de arrasto, LIMPAR com confirmação, título mostra a fase.
- Menu principal: EDITOR substituído por SAIR (o editor agora é acessado pela seleção de fase).
- Arquivos órfãos de versões antigas movidos para `_legacy_nao_usado/`.

## V8 — design pass (fullscreen + visual polish)
- Jogo abre em **tela cheia** por padrão (`project.godot`, `window/size/mode=3`); **F11** alterna pra janela a qualquer momento (útil pra iterar no editor do Godot). Aspect ratio preservado (`stretch/aspect="keep"`), então não distorce em telas fora de 16:9.
- `BattleArena.gd`: fundo com textura de papel sutil, e o campo do turno ativo (PLAYER ou LORDE) ganha um destaque laranja pulsante — inclusive nos receptores — pra deixar claro de quem é a vez sem precisar ler o texto.
- `DemoCharacters.gd`: Player e Lorde deixaram de ser dois bonecos-palito idênticos. Player agora segura um violão simples; Lorde ganhou manto/capuz pontudo e um cajado com um broto, reforçando que é uma entidade da natureza, não um humano. Quem está tocando ganha um halo.
- Notas do Player agora são laranja (antes eram um azul quase idêntico ao do Lorde, difícil de distinguir à distância) — a cor "laranja = você" se repete no destaque do campo, no halo do personagem e nas notas, criando uma linguagem visual consistente.
- Notas ganharam um brilho suave atrás da seta e um anel que "estoura" ao serem julgadas.
- Texto de julgamento (Perfect/Good/Bad/Miss) agora muda de cor conforme o resultado e dá uma pequena "batida" de escala ao aparecer; reposicionado pro vão entre os dois campos (antes ficava meio grudado embaixo do campo do Lorde).
- `ResultPanel`, a barra de energia e os botões (MENU, JOGAR, EDITOR) deixaram de usar o visual cinza padrão do Godot — agora seguem o mesmo papel + tinta azul + bordas do resto do jogo.
- Botão do menu principal renomeado de PLAY para **JOGAR**.

## V7 — merged editor + visual gameplay
- V6 click/timeline phrase editor kept as the authoring workflow.
- Main menu kept with PLAY and EDITOR.
- V2 visual battle layout restored: paper look, PLAYER upper field, LORDE lower field, character sketches and HUD.
- Gameplay lanes now use the D/F/J/K target column at x=302, so notes travel across the full field from right to left.
- Gameplay reads the JSON chart produced by the editor.
- Player response is generated from the same phrase notes using `response_delay_beats`.
- Fixed note movement/setup compatibility between spawner and note scene.


## 2026-09-21 — Timeline baseada na duração do áudio
- Timeline agora usa a duração real de `test_song.wav` para representar a música inteira.
- Adicionados helpers `get_song_length_seconds()` e `get_song_length_beats()` em `ChartEditor.gd`.
- Mantido espaço extra para frases/respostas que ultrapassem o final do áudio.
- `Conductor.gd` e fallback de `Battle.gd` padronizados em 144 BPM.


## 2026-09-22 — Timeline baseada na duração real do áudio
- `ChartEditor.gd`: adicionados `get_song_length_seconds()` e `get_song_length_beats()`.
- `Timeline.gd`: tamanho mínimo agora é calculado a partir da duração real do áudio e do BPM.
- Timeline continua podendo crescer além do áudio para acomodar frases/respostas.
- Adicionado marcador visual `FIM` no final do áudio.
- `Conductor.gd` e fallback de `Battle.gd` padronizados em 144 BPM.
