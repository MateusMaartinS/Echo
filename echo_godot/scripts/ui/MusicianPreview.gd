extends Node2D

# Run scenes/MusicianPreview.tscn to inspect the puppet independently of a chart.
var puppets: Array[PaperMusician] = []
var titles := ["REPOUSO", "CIMA / D", "DIREITA / F", "ESQUERDA / J", "BAIXO / K"]

func _ready() -> void:
    for i in range(5):
        var puppet := PaperMusician.new()
        puppet.position = Vector2(140 + i * 250, 395)
        puppet.scale = Vector2(1.24, 1.24)
        puppet.preview_pose = i - 1
        add_child(puppet)
        puppets.append(puppet)
    if "--export-character-preview" in OS.get_cmdline_user_args():
        await RenderingServer.frame_post_draw
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png("res://art_preview/protagonista.png")
        get_tree().quit()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color("#f7f3e9"))
    var graphite := Color("#393b35")
    draw_string(ThemeDB.fallback_font, Vector2(62, 87), "ECHO  /  ESTUDO DO PROTAGONISTA", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, graphite)
    draw_string(ThemeDB.fallback_font, Vector2(62, 125), "Boneco palito • camiseta branca • cargo verde • tênis", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, graphite)
    for i in range(5):
        var x: float = 140 + i * 250
        draw_line(Vector2(x - 90, 534), Vector2(x + 90, 534), Color(0.23, 0.24, 0.21, 0.16), 1.0)
        draw_string(ThemeDB.fallback_font, Vector2(x - 110, 585), titles[i], HORIZONTAL_ALIGNMENT_CENTER, 220, 21, graphite)
    draw_string(ThemeDB.fallback_font, Vector2(62, 667), "Poses base • transições suaves no jogo • rosto sem detalhes, conforme os esboços", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, graphite)
