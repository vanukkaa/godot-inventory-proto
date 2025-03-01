extends Resource
class_name PlayerData

@export var stats: Dictionary = {
	"strength": int(5),
	"agility": int(5),
	"endurance": int(5),
	"intelligence": int(5),
	"wisdom": int(5),
}

@export var stat_points: Dictionary = {
	"stat_points": int(10),
	"used_points": int(5),
	"available_points": int(10),
	}
func to_dict() -> Dictionary:
	return {
		"stats": stats,
		"stat_points": stat_points,
	}

func from_dict(data: Dictionary) -> void:
	stats = data.get("stats")
	stat_points = data.get("stat_points")
