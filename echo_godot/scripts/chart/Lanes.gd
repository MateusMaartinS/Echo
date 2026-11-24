extends RefCounted
class_name Lanes

# Fonte única da ordem das lanes e das teclas. Se quiser trocar a ordem
# ou as teclas, é só mexer aqui (PlayerInput, arena, notas e editor leem
# tudo daqui).
#
# Ordem das lanes, de CIMA pra BAIXO:
#   lane 0 = cima | lane 1 = direita | lane 2 = esquerda | lane 3 = baixo
# Cada lane aceita a tecla de letra OU a seta correspondente.

const COUNT: int = 4
const LETTERS: Array = ["D", "F", "J", "K"]
const NAMES: Array = ["CIMA", "DIREITA", "ESQUERDA", "BAIXO"]
const LETTER_KEYS: Array = [KEY_D, KEY_F, KEY_J, KEY_K]
const ARROW_KEYS: Array = [KEY_UP, KEY_RIGHT, KEY_LEFT, KEY_DOWN]

static func lane_for_key(keycode: int) -> int:
    for i in range(COUNT):
        if keycode == int(LETTER_KEYS[i]) or keycode == int(ARROW_KEYS[i]):
            return i
    return -1

static func direction_vector(lane: int) -> Vector2:
    match lane:
        0:
            return Vector2(0.0, -1.0)
        1:
            return Vector2(1.0, 0.0)
        2:
            return Vector2(-1.0, 0.0)
        _:
            return Vector2(0.0, 1.0)

# Contorno de uma seta apontando para a direção da lane, centrada em
# `center`, com "raio" s. Usado pelas notas, pelos receptores e pelo editor.
static func arrow_points(lane: int, center: Vector2, s: float) -> PackedVector2Array:
    var d: Vector2 = direction_vector(lane)
    var p: Vector2 = Vector2(-d.y, d.x)
    var local_points: Array = [
        Vector2(s, 0.0),
        Vector2(4.0, s * 0.62),
        Vector2(4.0, s * 0.22),
        Vector2(-s, s * 0.22),
        Vector2(-s, -s * 0.22),
        Vector2(4.0, -s * 0.22),
        Vector2(4.0, -s * 0.62)
    ]
    var result: PackedVector2Array = PackedVector2Array()
    for v in local_points:
        var lv: Vector2 = v
        result.append(center + d * lv.x + p * lv.y)
    return result

# Mesma seta, mas com o primeiro ponto repetido no fim (contorno fechado).
static func arrow_outline(lane: int, center: Vector2, s: float) -> PackedVector2Array:
    var pts: PackedVector2Array = arrow_points(lane, center, s)
    pts.append(pts[0])
    return pts
