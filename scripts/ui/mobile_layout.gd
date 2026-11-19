extends RefCounted
static func enter_immersive() -> void:
    if OS.get_name()=="Android":DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
## Safe display pixels -> logical UI coordinates, including stretch/window offset.
static func insets(logical_size: Vector2,safe_pixels: Rect2,screen_transform: Transform2D) -> Vector4:
    if not safe_pixels.has_area():return Vector4.ZERO
    var safe=screen_transform.affine_inverse()*safe_pixels
    safe=safe.intersection(Rect2(Vector2.ZERO,logical_size))
    if not safe.has_area():return Vector4.ZERO
    return Vector4(maxf(0,safe.position.x),maxf(0,safe.position.y),maxf(0,logical_size.x-safe.end.x),maxf(0,logical_size.y-safe.end.y))
