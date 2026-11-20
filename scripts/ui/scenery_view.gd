extends TextureRect
## One compact image, owned by the current card; no animation or event callbacks.
func _ready() -> void:
    expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
    clip_contents=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
    resized.connect(fit_height);fit_height()
func fit_height() -> void:
    custom_minimum_size.y=clampf(size.x/3.2,76,164)
