# Echo Pixel

Fonte bitmap original do projeto, com letras desenhadas em uma grade 5×7, acentos em português, números, pontuação e setas. As letras minúsculas usam a mesma forma das maiúsculas.

O arquivo `echo_pixel.fnt` usa uma base de 10 px. A HUD de referência usa principalmente 20 e 30 px, múltiplos inteiros da base, sem suavização ou MSDF. O atlas é `echo_pixel.png`.

Para reconstruir o atlas e o descritor, execute o Godot com `--headless --path <projeto> --script res://tools/build_echo_pixel_font.gd`. Não há dependência de fontes instaladas no Windows ou downloads externos.
