class_name ChampionData
extends Resource

@export_group("Identity")
@export var id: String = "unit_id"
@export var display_name: String = "Unit Name"
@export var role: String = "Role" # e.g., Tank, DPS, Mage
@export var icon: Texture2D # You can use PlaceholderTexture2D for now
@export var color: Color = Color.WHITE

@export_group("Stats")
@export var cost: int = 3
@export var hp: int = 100
@export var damage: int = 10
@export var attack_speed: float = 1.0

@export_group("Skills")
@export var skill_name: String = ""
@export var description: String = ""
