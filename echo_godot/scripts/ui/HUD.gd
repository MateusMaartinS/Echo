extends CanvasLayer

@onready var score_manager: ScoreManager = get_parent().get_node("ScoreManager")
@onready var score_label: Label = $TopBar/Score
@onready var combo_label: Label = $TopBar/Combo
@onready var energy_bar: ProgressBar = $TopBar/Energy
@onready var accuracy_label: Label = $TopBar/Accuracy

func _ready() -> void:
    score_manager.score_changed.connect(_on_score_changed)
    score_manager.combo_changed.connect(_on_combo_changed)
    score_manager.energy_changed.connect(_on_energy_changed)
    _on_score_changed(score_manager.score)
    _on_combo_changed(score_manager.combo)
    _on_energy_changed(score_manager.energy)

func _process(_delta: float) -> void:
    accuracy_label.text = "ACCURACY  %.1f%%" % score_manager.get_accuracy()

func _on_score_changed(value: int) -> void:
    score_label.text = "SCORE  %06d" % value

func _on_combo_changed(value: int) -> void:
    combo_label.text = "COMBO  x%d" % value

func _on_energy_changed(value: float) -> void:
    energy_bar.value = value
