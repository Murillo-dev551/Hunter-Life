extends Control
var kind: String = "adventure"
var color: Color = Color("315C4C")
func _ready() -> void:
    custom_minimum_size = Vector2(22,22)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)
func stroke(points: Array) -> void:
    var vertices = PackedVector2Array()
    for p in points: vertices.append(Vector2(p[0],p[1])+ (size-Vector2(22,22))/2)
    draw_polyline(vertices,color,1.5,true)
func _draw() -> void:
    var center: Vector2 = (size-Vector2(22,22))/2
    match kind:
        "character":
            draw_arc(center+Vector2(11,6),3,0,TAU,24,color,1.5,true)
            stroke([[4,20],[4,17],[6,13],[16,13],[18,17],[18,20]])
        "inventory":
            stroke([[4,20],[4,7],[18,7],[18,20],[4,20]])
            stroke([[8,7],[8,3],[14,3],[14,7]])
            stroke([[7,12],[15,12],[15,17],[7,17],[7,12]])
        "record":
            stroke([[5,3],[17,3],[17,19],[7,19],[7,3]])
            stroke([[9,7],[14,7]])
            stroke([[9,11],[14,11]])
            stroke([[9,15],[12,15]])
        _:
            stroke([[11,5],[6,3],[2,4],[2,17],[6,16],[11,19],[16,16],[20,17],[20,4],[16,3],[11,5],[11,19]])
