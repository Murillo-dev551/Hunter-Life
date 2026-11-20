extends StyleBox
## Native theme resource with clipped document corners. Properties remain
## StyleBoxFlat-compatible for focus, disabled states and existing feedback.
@export var finish: String="panel"
@export var accent: Color=Color("963D49")
@export var bg_color: Color=Color("F9F5EC")
@export var border_color: Color=Color("343C43")
@export var border_width: float=1.2
func set_border_width_all(value: int) -> void:border_width=value
func _get_minimum_size() -> Vector2:
    return Vector2(content_margin_left+content_margin_right,content_margin_top+content_margin_bottom)
func contour(rect: Rect2,cut: float) -> PackedVector2Array:
    var a=rect.position;var b=rect.end
    return PackedVector2Array([a+Vector2(cut,0),Vector2(b.x-cut,a.y),Vector2(b.x,a.y+cut),b-Vector2(0,cut),b-Vector2(cut,0),Vector2(a.x+cut,b.y),Vector2(a.x,b.y-cut),a+Vector2(0,cut)])
func line(item: RID,points: PackedVector2Array,color: Color,width: float) -> void:
    var closed=points.duplicate();closed.append(points[0])
    RenderingServer.canvas_item_add_polyline(item,closed,PackedColorArray([color]),width,true)
func _draw(item: RID,rect: Rect2) -> void:
    if finish=="ribbon":
        var a=rect.position;var b=rect.end;var h=rect.size.y
        RenderingServer.canvas_item_add_polygon(item,PackedVector2Array([a+Vector2(7,0),Vector2(b.x-17,a.y),b-Vector2(24,0),Vector2(a.x,b.y)]),PackedColorArray([bg_color]))
        for i in range(2):
            var x=b.x-13+i*7
            RenderingServer.canvas_item_add_polygon(item,PackedVector2Array([Vector2(x,a.y),Vector2(x+4,a.y),Vector2(x-3,b.y),Vector2(x-7,b.y)]),PackedColorArray([accent]))
        return
    var cut=minf(10,rect.size.y/5)
    var points=contour(rect.grow(-1),cut)
    RenderingServer.canvas_item_add_polygon(item,points,PackedColorArray([bg_color]))
    var ink=border_color if border_color.a>0 else Color("343C43")
    line(item,points,ink,border_width)
    if finish=="primary" or finish=="nav_active":
        line(item,contour(rect.grow(-4),maxf(cut-2,1)),Color("F1E8D7"),0.8)
        var a=rect.position
        RenderingServer.canvas_item_add_polyline(item,PackedVector2Array([a+Vector2(cut,0),a+Vector2(0,cut),Vector2(a.x,rect.end.y-cut)]),PackedColorArray([accent]),3.5,true)
    elif finish in ["panel","story"]:
        line(item,contour(rect.grow(-4),maxf(cut-2,1)),Color(ink,0.22),0.6)
        var a=rect.position;var b=rect.end
        RenderingServer.canvas_item_add_line(item,a+Vector2(7,20),a+Vector2(7,9),ink,0.8,true)
        RenderingServer.canvas_item_add_line(item,Vector2(b.x-6,b.y-21),b-Vector2(6,9),ink,0.8,true)
        if finish=="story":
            var clip=PackedVector2Array([Vector2(b.x-8,a.y+24),Vector2(b.x-3,a.y+7),Vector2(b.x+3,a.y+5),Vector2(b.x+6,a.y+10),Vector2(b.x,a.y+31),Vector2(b.x-5,a.y+33),Vector2(b.x-8,a.y+28),Vector2(b.x-2,a.y+9)])
            RenderingServer.canvas_item_add_polyline(item,clip,PackedColorArray([ink]),1.3,true)
