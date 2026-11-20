extends HBoxContainer
var vignette: Texture2D
func _ready() -> void:
    resized.connect(refresh);refresh()
func refresh() -> void:
    if not vignette:vignette=preload("res://scripts/scenery.gd").texture("city")
    queue_redraw()
func _draw() -> void:
    var y=size.y-2
    draw_line(Vector2.ZERO+Vector2(0,y),Vector2(size.x,y),Color("963D49"),2,true)
    if vignette:
        var width=clampf(size.x-220,76,200)
        var rect=Rect2(size.x-width,0,width,y-5)
        var points=PackedVector2Array([rect.position+Vector2(25,0),Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
        var uv=PackedVector2Array()
        for point in points:uv.append((point-rect.position)/rect.size)
        draw_polygon(points,PackedColorArray([Color.WHITE]),uv,vignette)
    var x=size.x-clampf(size.x-220,76,200)-3
    for i in range(2):
        var offset=i*9
        draw_colored_polygon(PackedVector2Array([Vector2(x-offset,0),Vector2(x+5-offset,0),Vector2(x-16-offset,y-6),Vector2(x-21-offset,y-6)]),Color("963D49") if i==0 else Color("243B5A"))
