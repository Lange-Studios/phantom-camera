extends Area3D

@export var area_pcam: PhantomCamera3D

func _ready() -> void:
	connect("area_entered", _entered_area)
	connect("area_exited", _exited_area)


func _entered_area(area_3D: Area3D) -> void:
	area_pcam.set_priority(20)

func _exited_area(area_3D: Area3D) -> void:
	area_pcam.set_priority(1)