# Roteiro de validação da entrega

1. Abra `project.godot` no Godot 4.7 e espere a importação. Execute o projeto: a tela principal deve mostrar a logo, os quatro chefões e tocar `menu.wav`.
2. Abra **JOGAR**: os cinco cartões devem permitir iniciar a fase, com Mentor no tutorial. Volte e entre em **PERSONAGENS**; a prévia deve acompanhar o item selecionado, e as roupas de estação começam bloqueadas num save limpo.
3. Jogue o tutorial. Observe a pista do Mentor e repita na pista superior usando D/F/J/K ou as setas. Confira julgamento, combo, energia, pausa com ESC e contagem para continuar.
4. Jogue as quatro estações: flores encobrem pistas na Primavera; folhas saem antes do receptor no Outono; fogo consome energia se tocado no Verão; gelo congela pistas vizinhas no Inverno. Os cenários devem continuar atrás das pistas.
5. Conclua uma fase e confira resultado, recorde e estrelas na seleção. Quatro estrelas desbloqueiam os dois visuais da estação em **PERSONAGENS**.
6. Volte de uma fase: a música do menu deve recomeçar. Abra **EDITOR**: a música do menu deve parar, e o editor deve carregar o áudio e o chart escolhidos. Evite usar SALVAR durante a validação se não quiser alterar o chart.
7. Em **CONFIGURAÇÕES**, confira volumes, sincronia e tela cheia. O volume de música também controla `menu.wav`.

Verificações automatizadas de integração (executar na pasta do projeto):

```powershell
godot --headless --editor --path . --quit
godot --path . --windowed --resolution 1280x720 --script res://tools/check_main_menu.gd
godot --path . --windowed --resolution 1280x720 --script res://tools/check_level_select.gd
godot --path . --windowed --resolution 1280x720 --script res://tools/check_season_hud.gd
godot --path . --windowed --resolution 1280x720 --script res://tools/check_wardrobe_route.gd
godot --headless --path . --script res://tools/check_release_assets.gd
```

Se `godot` não estiver no PATH, substitua pelo caminho do executável Godot. Os testes usam cenas e charts em memória; não concedem progresso real. O teste da seleção também verifica início, repetição e parada da música de menu.
