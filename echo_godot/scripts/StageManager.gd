extends Node

# Estado simples compartilhado entre menu, seleção de fases, editor e batalha.
var selected_stage: int = 1
var selection_mode: String = "play" # "play" ou "edit"

const DEFAULT_AUDIO: String = "res://audio/music/test_song.wav"

const STAGES: Dictionary = {
    1: {
        "id": 1,
        "season": "PRIMAVERA",
        "chart_path": "res://charts/test_song.json",
        "accent": "#D8759B"
    },
    2: {
        "id": 2,
        "season": "VERÃO",
        "chart_path": "res://charts/stage_2.json",
        "accent": "#E5A83C"
    },
    3: {
        "id": 3,
        "season": "OUTONO",
        "chart_path": "res://charts/stage_3.json",
        "accent": "#C87542"
    },
    4: {
        "id": 4,
        "season": "INVERNO",
        "chart_path": "res://charts/stage_4.json",
        "accent": "#79A9CF"
    }
}

func select_stage(stage_id: int) -> void:
    if STAGES.has(stage_id):
        selected_stage = stage_id

func get_stage_data(stage_id: int = -1) -> Dictionary:
    var requested_id: int = selected_stage if stage_id < 1 else stage_id
    if not STAGES.has(requested_id):
        requested_id = 1
    var stage_data: Dictionary = STAGES[requested_id]
    return stage_data.duplicate(true)

func get_chart_path(stage_id: int = -1) -> String:
    return str(get_stage_data(stage_id).get("chart_path", "res://charts/test_song.json"))

func get_stage_name(stage_id: int = -1) -> String:
    return str(get_stage_data(stage_id).get("season", "PRIMAVERA"))

func get_stage_number(stage_id: int = -1) -> int:
    return int(get_stage_data(stage_id).get("id", 1))
