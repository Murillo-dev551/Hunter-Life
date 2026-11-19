extends RefCounted
const BG = Color("F3EBDD")
const PANEL = Color("E3D3B8")
const INK = Color("292C2A")
const GREEN = Color("315C4C")
const GOLD = Color("B58A45")
const ALERT = Color("A14B43")
const MUTED = Color("62675F")
const Icon = preload("res://scripts/ui/line_icon.gd")
const Motion=preload("res://scripts/ui/motion.gd")
static func box(color: Color, radius: int = 12, border: Color = Color.TRANSPARENT, padding: int = 16) -> StyleBoxFlat:
    var b = StyleBoxFlat.new()
    b.bg_color = color
    b.set_corner_radius_all(radius)
    b.set_border_width_all(1 if border.a > 0 else 0)
    b.border_color = border
    for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: b.set_content_margin(side,padding)
    return b
static func make_theme() -> Theme:
    var t = Theme.new()
    var font = SystemFont.new()
    font.font_names = PackedStringArray(["Source Sans 3","Segoe UI","Noto Sans","Arial"])
    t.default_font = font
    t.default_font_size = 16
    for type in ["Label","Button","LineEdit"]:
        t.set_color("font_color",type,INK)
    t.set_constant("separation","VBoxContainer",14)
    t.set_constant("separation","HBoxContainer",12)
    t.set_stylebox("panel","PanelContainer",box(PANEL))
    t.set_stylebox("normal","LineEdit",box(Color("FAF6EE"),8,GOLD,14))
    t.set_stylebox("focus","LineEdit",box(Color.TRANSPARENT,8,GREEN,14))
    t.set_color("caret_color","LineEdit",GREEN)
    t.set_color("font_placeholder_color","LineEdit",MUTED)
    for variant in ["Primary","Secondary","Navigation","NavigationActive"]:
        t.set_type_variation(variant,"Button")
        var primary: bool = variant == "Primary" or variant == "NavigationActive"
        var nav: bool = variant.begins_with("Navigation")
        t.set_stylebox("normal",variant,box(GREEN if primary else BG if nav else Color("FAF6EE"),9,Color.TRANSPARENT if primary or nav else Color("C9B28B"),10 if nav else 14))
        t.set_stylebox("hover",variant,box(Color("254A3D") if primary else PANEL,9,GOLD,10 if nav else 14))
        t.set_stylebox("pressed",variant,box(Color("254A3D") if primary else Color("D6C4A4"),9,GREEN,10 if nav else 14))
        t.set_stylebox("focus",variant,box(Color.TRANSPARENT,9,GOLD,10 if nav else 14))
        t.set_stylebox("disabled",variant,box(Color("DED7C9"),9,Color.TRANSPARENT,10 if nav else 14))
        for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: t.set_color(state,variant,BG if primary else GREEN if nav else INK)
        t.set_color("font_disabled_color",variant,MUTED)
    t.set_stylebox("background","ProgressBar",box(Color("CDBFA7"),4,Color.TRANSPARENT,0))
    t.set_stylebox("fill","ProgressBar",box(GREEN,4,Color.TRANSPARENT,0))
    var separator = StyleBoxLine.new()
    separator.color = Color("C9B28B")
    separator.thickness = 1
    t.set_stylebox("separator","HSeparator",separator)
    return t
static func label(text: String, font_size: int = 16, color: Color = INK) -> Label:
    var l = Label.new()
    l.text = text
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    l.add_theme_font_size_override("font_size",font_size)
    l.add_theme_color_override("font_color",color)
    return l
static func title(text: String, font_size: int = 26) -> Label:
    var l = label(text,font_size)
    var font = SystemFont.new()
    font.font_names = PackedStringArray(["Cinzel","Georgia","Noto Serif"])
    l.add_theme_font_override("font",font)
    return l
static func button(text: String, primary: bool = false) -> Button:
    var b = Button.new()
    b.text = text
    b.theme_type_variation = "Primary" if primary else "Secondary"
    b.custom_minimum_size.y = 52
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.pressed.connect(func():sound("back" if text.begins_with("Voltar") or text.begins_with("Cancelar") else "click"))
    b.button_down.connect(func():Motion.enter(b,0.10,true))
    return b
static func sound(id: String) -> void:
    var tree=Engine.get_main_loop() as SceneTree
    if tree and tree.root.has_node("Audio"):tree.root.get_node("Audio").cue(id)
static func button_icon(button_node: Button, kind: String) -> void:
    button_node.icon=Icon.TEXTURES[kind]
    button_node.add_theme_constant_override("icon_max_width",18)
    button_node.add_theme_constant_override("h_separation",6)
    for state in ["icon_normal_color","icon_hover_color","icon_pressed_color","icon_focus_color"]:
        button_node.add_theme_color_override(state,BG if button_node.theme_type_variation=="Primary" else GREEN)
static func icon(kind: String, color: Color = GREEN) -> Control:
    var i = Icon.new()
    i.kind = kind
    i.color = color
    return i
static func card(parent: Node) -> VBoxContainer:
    var panel = PanelContainer.new()
    parent.add_child(panel)
    var content = VBoxContainer.new()
    panel.add_child(content)
    return content
static func attributes(parent: Node, values: Dictionary, names: Dictionary) -> void:
    for id in names:
        var row = HBoxContainer.new()
        row.add_child(label(names[id],15))
        var number = label("%d / 10" % int(values[id]),15,GREEN)
        number.size_flags_horizontal = Control.SIZE_SHRINK_END
        number.custom_minimum_size.x = 44
        row.add_child(number)
        parent.add_child(row)
        var bar = ProgressBar.new()
        bar.max_value = 10
        bar.value = values[id]
        bar.show_percentage = false
        bar.custom_minimum_size.y = 7
        parent.add_child(bar)
