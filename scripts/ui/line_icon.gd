extends Control
const TEXTURES={
    "adventure":preload("res://assets/icons/adventure.svg"),
    "character":preload("res://assets/icons/character.svg"),
    "inventory":preload("res://assets/icons/inventory.svg"),
    "record":preload("res://assets/icons/record.svg"),
    "settings":preload("res://assets/icons/settings.svg"),
    "saves":preload("res://assets/icons/saves.svg"),
    "attack":preload("res://assets/icons/attack.svg"),
    "defend":preload("res://assets/icons/defend.svg"),
    "nen":preload("res://assets/icons/nen.svg"),
    "other":preload("res://assets/icons/other.svg")}
var kind: String="adventure"
var color: Color=Color("315C4C")
func _ready() -> void:
    custom_minimum_size=Vector2(22,22)
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)
func _draw() -> void:
    draw_texture_rect(TEXTURES.get(kind,TEXTURES.adventure),Rect2((size-Vector2(22,22))/2,Vector2(22,22)),false,color)
