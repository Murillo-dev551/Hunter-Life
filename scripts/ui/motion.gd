extends RefCounted
const Document=preload("res://scripts/ui/document_style.gd")
## Presentation only. One tween per control; no delays or gameplay callbacks.
static var targets: Array[WeakRef]=[]
static func reduced() -> bool:
    var tree=Engine.get_main_loop() as SceneTree
    return tree and tree.root.has_node("Audio") and tree.root.get_node("Audio").preferences.get("reduce_motion",false)
static func stop(control: Control) -> void:
    var tween=control.get_meta("ui_tween") if control.has_meta("ui_tween") else null
    if tween and tween.is_valid():tween.kill()
    if control.has_meta("ui_tween"):control.remove_meta("ui_tween")
    control.modulate=Color.WHITE;control.self_modulate=Color.WHITE
static func cancel_all() -> void:
    for ref in targets:
        var control=ref.get_ref()
        if is_instance_valid(control):stop(control)
    targets.clear()
static func enter(control: Control,duration: float=0.14,pressed: bool=false) -> void:
    stop(control)
    if reduced() or not control.is_inside_tree():return
    targets=targets.filter(func(ref):return is_instance_valid(ref.get_ref()) and ref.get_ref()!=control)
    targets.append(weakref(control))
    var property="self_modulate" if pressed else "modulate"
    control.set(property,Color(0.9,0.9,0.9,1) if pressed else Color(1,1,1,0.88))
    var tween=control.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    control.set_meta("ui_tween",tween)
    tween.tween_property(control,property,Color.WHITE,duration)
static func highlight(panel: Control,tone: Color) -> void:
    panel.set_meta("feedback_tone",tone)
    if panel is Label:panel.add_theme_color_override("font_color",tone)
    if panel is PanelContainer:
        var style=panel.get_theme_stylebox("panel").duplicate()
        if style is StyleBoxFlat or style is Document:
            style.border_color=tone;style.set_border_width_all(2)
            style.bg_color=style.bg_color.lerp(tone,0.07)
            panel.add_theme_stylebox_override("panel",style)
    enter(panel)
