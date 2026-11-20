extends Control
func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE;resized.connect(queue_redraw)
func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,size),Color("F1E8D7"))
    draw_line(Vector2(13,5),Vector2(13,size.y-5),Color("343C43",0.32),0.7,true)
    for ratio in [0.16,0.38,0.60,0.82]:
        var y=size.y*ratio
        draw_circle(Vector2(4,y),4,Color("343C43"))
        draw_line(Vector2(0,y),Vector2(7,y),Color("343C43"),2,true)
    draw_line(Vector2(16,size.y-4),Vector2(size.x-8,size.y-4),Color("343C43",0.32),0.7,true)
