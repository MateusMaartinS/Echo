extends Node
class_name PlayerInput

# Cada lane aceita a tecla de letra (D F J K) OU a seta equivalente.
# Veja scripts/chart/Lanes.gd pra mudar a ordem/teclas.
#
# Usa _input (e não _unhandled_input) pra que as setas nunca sejam
# "engolidas" pela navegação de foco dos botões da interface.

@export var judge: Judge
var player_turn: bool = false
# Pausa: enquanto bloqueado, as teclas das lanes são ignoradas e NÃO são
# consumidas (as setas voltam a navegar nos botões do menu de pausa).
var blocked: bool = false

# Por lane: quais teclas físicas estão pressionadas agora.
var _down: Array = [{}, {}, {}, {}]

func set_blocked(value: bool) -> void:
    blocked = value
    if value:
        _down = [{}, {}, {}, {}]

func _input(event: InputEvent) -> void:
    if blocked:
        return
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event as InputEventKey
    if key_event.echo:
        return

    var keycode: int = int(key_event.physical_keycode)
    var lane: int = Lanes.lane_for_key(keycode)
    if lane < 0:
        return

    get_viewport().set_input_as_handled()
    var lane_down: Dictionary = _down[lane] as Dictionary

    if key_event.pressed:
        lane_down[keycode] = true
        if player_turn and judge != null:
            judge.try_hit(lane)
    else:
        lane_down.erase(keycode)
        # Só conta como "soltou" quando nenhuma tecla da lane segue apertada.
        if lane_down.is_empty() and judge != null:
            judge.try_release(lane)

func is_lane_down(lane: int) -> bool:
    if lane < 0 or lane >= _down.size():
        return false
    return not (_down[lane] as Dictionary).is_empty()
