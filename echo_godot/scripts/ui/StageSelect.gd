extends Control

@onready var title_label: Label = $Title
@onready var subtitle_label: Label = $Subtitle
@onready var status_label: Label = $Status
@onready var mode_button: Button = $ModeSwitch

func _ready() -> void:
    Conductor.stop()
    MenuMusic.start()
    _refresh_mode_text()

func _refresh_mode_text() -> void:
    var editing: bool = StageManager.selection_mode == "edit"
    title_label.text = "EDITOR DE FASES" if editing else "ESCOLHA SUA FASE"
    subtitle_label.text = "Selecione qual fase deseja editar." if editing else "Cada estação guarda sua própria batalha."
    mode_button.text = "IR PARA SELEÇÃO DE JOGO" if editing else "EDITAR FASES"
    status_label.text = "Fase selecionada: %d — %s" % [StageManager.selected_stage, StageManager.get_stage_name()]

func _select_stage(stage_id: int) -> void:
    StageManager.select_stage(stage_id)
    var chart_path: String = StageManager.get_chart_path(stage_id)

    if StageManager.selection_mode == "edit":
        get_tree().change_scene_to_file("res://scenes/Editor.tscn")
        return

    var chart: Dictionary = ChartIO.load_chart(chart_path)
    if chart.is_empty():
        status_label.text = "Não foi possível abrir o chart desta fase. Confira: " + chart_path.get_file()
        return

    chart = ChartData.ensure_shape(chart)
    var phrases: Array = chart.get("phrases", []) as Array
    var has_notes: bool = false
    for raw_phrase in phrases:
        if raw_phrase is Dictionary:
            var phrase: Dictionary = raw_phrase as Dictionary
            var notes: Array = phrase.get("notes", []) as Array
            if not notes.is_empty():
                has_notes = true
                break

    if not has_notes:
        status_label.text = "FASE %d — %s ainda não tem notas. Use EDITAR FASES para começar." % [stage_id, StageManager.get_stage_name(stage_id)]
        return

    get_tree().change_scene_to_file("res://scenes/Battle.tscn")

func _on_stage_1_pressed() -> void:
    _select_stage(1)

func _on_stage_2_pressed() -> void:
    _select_stage(2)

func _on_stage_3_pressed() -> void:
    _select_stage(3)

func _on_stage_4_pressed() -> void:
    _select_stage(4)

func _on_mode_switch_pressed() -> void:
    StageManager.selection_mode = "edit" if StageManager.selection_mode == "play" else "play"
    _refresh_mode_text()

func _on_back_pressed() -> void:
    Conductor.stop()
    get_tree().change_scene_to_file("res://scenes/Main.tscn")
