extends Resource
class_name NoteData

@export var time: float = 0.0
@export_range(0, 3, 1) var lane: int = 0
@export var duration: float = 0.0
@export_enum("tap", "hold", "hazard") var type: String = "tap"
