extends Control
@export var mode: String="underline"
func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    custom_minimum_size.y=6 if mode=="underline" else 25
    resized.connect(queue_redraw)
func _draw() -> void:
    if mode=="underline":
        draw_colored_polygon(PackedVector2Array([Vector2(0,4),Vector2(6,0),Vector2(size.x*0.84,2),Vector2(size.x*0.5,3),Vector2(0,6)]),Color("963D49"))
    else:
        draw_line(Vector2(0,size.y/2),Vector2(size.x,size.y/2),Color("343C43"),0.8,true)
        for i in range(8):
            var x=size.x-8-i*6
            draw_line(Vector2(x,size.y-3),Vector2(x+7,3),Color("343C43",0.5),0.8,true)
