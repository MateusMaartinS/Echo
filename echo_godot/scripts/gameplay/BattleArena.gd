extends Node2D

# Arena visual do protótipo ECHO.
# A pista do jogador fica acima e a do Lorde abaixo, sobre um fundo de
# papel. O campo do turno ativo recebe um destaque suave para guiar o
# olho do jogador (GDD: "estética 2D estilizada... efeitos luminosos").

@export var ink := Color("#174A9A")
@export var ink_soft := Color(0.09, 0.29, 0.60, 0.22)
@export var paper := Color(0.98, 0.97, 0.94, 0.58)
@export var highlight := Color(0.85, 0.55, 0.12, 1.0)

const LEFT_X := 185.0
const KEY_DIVIDER_X := 302.0
const RIGHT_X := 1210.0
const TARGET_X: float = 302.0
const RECEPTOR_SIZE := 26.0

const PLAYER_RECT := Rect2(185.0, 158.0, 1025.0, 168.0)
const OPPONENT_RECT := Rect2(185.0, 403.0, 1025.0, 168.0)
const PLAYER_LANES := [178.0, 220.0, 262.0, 304.0]
const OPPONENT_LANES := [423.0, 465.0, 507.0, 549.0]

var key_labels: Array = Lanes.LETTERS

# "PLAYER" ou "OPPONENT" — controla qual campo recebe o destaque.
var active_field: String = "OPPONENT"
var pulse: float = 0.0
var opponent_title: String = "LORDE"

func _ready() -> void:
    opponent_title = BossCatalog.display_name(str(LevelDB.selected().get("season", "tutorial")))
    queue_redraw()

func _process(delta: float) -> void:
    pulse += delta
    queue_redraw()

func set_active_field(field_name: String) -> void:
    active_field = field_name

func _draw() -> void:
    _draw_paper_texture()
    _draw_field(PLAYER_RECT, PLAYER_LANES, "PLAYER", active_field == "PLAYER")
    _draw_field(OPPONENT_RECT, OPPONENT_LANES, opponent_title, active_field == "OPPONENT")

func _draw_paper_texture() -> void:
    # Textura sutil de papel por baixo dos dois campos, sem depender de
    # imagens externas (mesma técnica usada no menu / editor).
    var rng := RandomNumberGenerator.new()
    rng.seed = 4242
    for i in range(40):
        var p := Vector2(rng.randf_range(0.0, 1280.0), rng.randf_range(0.0, 720.0))
        var alpha: float = rng.randf_range(0.012, 0.03)
        draw_circle(p, rng.randf_range(10.0, 40.0), Color(0.3, 0.28, 0.25, alpha))

func _draw_field(rect: Rect2, lanes: Array, title: String, is_active: bool) -> void:
    # Destaque suave e pulsante por trás do campo em turno.
    if is_active:
        var glow_alpha: float = 0.08 + sin(pulse * 3.0) * 0.03
        draw_rect(rect.grow(6.0), Color(highlight.r, highlight.g, highlight.b, glow_alpha), true)

    # Fundo quase branco para separar claramente os dois campos sobre o papel.
    draw_rect(rect, paper, true)
    draw_rect(rect, highlight if is_active else ink, false, 3.0 if is_active else 2.0)

    # Título do campo.
    var title_color: Color = highlight if is_active else ink
    draw_string(
        ThemeDB.fallback_font,
        Vector2(rect.position.x, rect.position.y - 9.0),
        title,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        18,
        title_color
    )
    if is_active:
        draw_string(
            ThemeDB.fallback_font,
            Vector2(rect.position.x + 90.0, rect.position.y - 9.0),
            "• SUA VEZ" if title == "PLAYER" else "• OBSERVE",
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            14,
            title_color
        )

    # Divisor das teclas.
    draw_line(
        Vector2(KEY_DIVIDER_X, rect.position.y),
        Vector2(KEY_DIVIDER_X, rect.end.y),
        ink,
        3.0,
        true
    )

    for i in lanes.size():
        var y: float = lanes[i]

        # Linha horizontal de execução.
        draw_line(
            Vector2(LEFT_X, y),
            Vector2(RIGHT_X, y),
            ink_soft,
            2.0,
            true
        )

        # Área visual do alvo.
        _draw_receptor(Vector2(TARGET_X, y), i, is_active)

        # Tecla no início da lane.
        draw_string(
            ThemeDB.fallback_font,
            Vector2(210.0, y + 9.0),
            key_labels[i],
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            24,
            title_color if is_active else ink
        )

    # Última linha inferior do campo.
    draw_line(
        Vector2(LEFT_X, rect.end.y),
        Vector2(RIGHT_X, rect.end.y),
        ink,
        3.0,
        true
    )

func _draw_receptor(center: Vector2, lane: int, is_active: bool) -> void:
    # Receptor vazado inspirado nos indicadores de jogos de ritmo. A seta
    # vem de Lanes (mesma geometria das notas), então sempre combina.
    var s := RECEPTOR_SIZE
    var pts: PackedVector2Array = Lanes.arrow_points(lane, center, s)
    var outline: PackedVector2Array = Lanes.arrow_outline(lane, center, s)

    if is_active:
        # Brilho suave por trás do receptor quando o campo está em turno.
        var glow_radius: float = s * (1.5 + sin(pulse * 4.0 + lane) * 0.08)
        draw_circle(center, glow_radius, Color(highlight.r, highlight.g, highlight.b, 0.10))

    # Fundo muito leve ajuda a enxergar o alvo quando a nota chega.
    draw_colored_polygon(pts, Color(0.98, 0.97, 0.94, 0.32))
    draw_polyline(outline, highlight if is_active else ink, 3.0, true)
