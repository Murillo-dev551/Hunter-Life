extends RefCounted
const BG = Color("F1E8D7")
const PANEL = Color("F9F5EC")
const INK = Color("343C43")
const NAVY = Color("243B5A")
const GREEN = NAVY # Compatibility alias for the existing presentation API.
const GOLD = Color("806230") # Darker gold keeps small reward/focus text readable on paper.
const ALERT = Color("963D49")
const MUTED = Color("59616A")
const LINE = Color("B9B6AE")
const BODY=preload("res://assets/fonts/source_sans3/SourceSans3.ttf")
const DISPLAY=preload("res://assets/fonts/barlow_condensed/BarlowCondensed-SemiBold.ttf")
const BRAND=preload("res://assets/fonts/barlow_condensed/BarlowCondensed-BoldItalic.ttf")
const SERIF=preload("res://assets/fonts/source_serif/SourceSerif4-Semibold.otf")
const SERIF_ITALIC=preload("res://assets/fonts/source_serif/SourceSerif4-It.otf")
const BOLD=preload("res://assets/fonts/source_sans3/SourceSans3-Bold.ttf")
const Document=preload("res://scripts/ui/document_style.gd")
const CHOICES={"accept":preload("res://assets/icons/choice_accept.svg"),"talk":preload("res://assets/icons/choice_talk.svg"),"back":preload("res://assets/icons/choice_back.svg")}
static var emphasis_pattern: RegEx
const Icon = preload("res://scripts/ui/line_icon.gd")
const Motion=preload("res://scripts/ui/motion.gd")
static func box(color: Color, radius: int = 12, border: Color = Color.TRANSPARENT, padding: int = 16) -> StyleBoxFlat:
    var b = StyleBoxFlat.new()
    b.bg_color = color
    b.set_corner_radius_all(mini(radius,3))
    b.set_border_width_all(1 if border.a > 0 else 0)
    b.border_color = border
    for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: b.set_content_margin(side,padding)
    return b
static func make_theme() -> Theme:
    var t = Theme.new()
    t.default_font = BODY
    t.default_font_size = 16
    for type in ["Label","Button","LineEdit"]:
        t.set_color("font_color",type,INK)
    t.set_constant("separation","VBoxContainer",14)
    t.set_constant("separation","HBoxContainer",12)
    t.set_stylebox("panel","PanelContainer",document(PANEL,"panel",INK,14))
    t.set_stylebox("normal","LineEdit",box(PANEL,3,LINE,12))
    t.set_stylebox("focus","LineEdit",box(Color.TRANSPARENT,8,GREEN,14))
    t.set_color("caret_color","LineEdit",GREEN)
    t.set_color("font_placeholder_color","LineEdit",MUTED)
    for variant in ["Primary","Secondary","Navigation","NavigationActive"]:
        t.set_type_variation(variant,"Button")
        var primary: bool = variant == "Primary" or variant == "NavigationActive"
        var nav: bool = variant.begins_with("Navigation")
        var normal=box(ALERT if variant=="NavigationActive" else NAVY if primary or nav else PANEL,3,Color.TRANSPARENT if primary or nav else NAVY,8 if nav else 14)
        if primary and not nav:normal.border_color=ALERT;normal.border_width_left=4
        var finish="nav_active" if variant=="NavigationActive" else "primary" if primary else "button"
        t.set_stylebox("normal",variant,document(normal.bg_color,finish,BG if nav else INK,8 if nav else 14))
        t.set_stylebox("hover",variant,document(Color("1C2F48") if primary or nav else Color("E7DFCF"),finish,GOLD,8 if nav else 14))
        t.set_stylebox("pressed",variant,document(ALERT if primary or nav else Color("DDD7CB"),finish,NAVY,8 if nav else 14))
        t.set_stylebox("focus",variant,box(Color.TRANSPARENT,9,GOLD,10 if nav else 14))
        t.set_stylebox("disabled",variant,document(Color("E3DFD5"),"button",LINE,8 if nav else 14))
        for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: t.set_color(state,variant,BG if primary or nav else INK)
        t.set_color("font_disabled_color",variant,MUTED)
    for control in ["OptionButton","CheckBox"]:
        for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:t.set_color(state,control,INK)
        t.set_color("font_disabled_color",control,MUTED)
    for state in ["normal","hover","pressed","disabled"]:
        t.set_stylebox(state,"OptionButton",box(PANEL,3,NAVY if state!="disabled" else LINE,10))
    t.set_stylebox("focus","OptionButton",box(Color.TRANSPARENT,3,GOLD,10))
    t.set_stylebox("panel","PopupMenu",box(PANEL,3,NAVY,8))
    t.set_color("font_color","PopupMenu",INK)
    t.set_color("font_hover_color","PopupMenu",BG)
    t.set_stylebox("hover","PopupMenu",box(NAVY,1))
    t.set_constant("v_separation","PopupMenu",12)
    t.set_stylebox("background","ProgressBar",box(Color("D9D6CC"),2,Color.TRANSPARENT,0))
    t.set_stylebox("fill","ProgressBar",box(GREEN,4,Color.TRANSPARENT,0))
    var separator = StyleBoxLine.new()
    separator.color = LINE
    separator.thickness = 1
    t.set_stylebox("separator","HSeparator",separator)
    return t
static func document(color: Color,finish: String="panel",border: Color=INK,padding: int=14) -> StyleBox:
    var style=Document.new();style.bg_color=color;style.border_color=border;style.finish=finish
    for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,padding)
    return style
static func label(text: String, font_size: int = 16, color: Color = INK) -> Label:
    var l = Label.new()
    l.text = text
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    l.add_theme_font_size_override("font_size",font_size)
    l.add_theme_color_override("font_color",color)
    return l
static func narrative(text: String) -> RichTextLabel:
    var r=RichTextLabel.new();r.fit_content=true;r.scroll_active=false;r.mouse_filter=Control.MOUSE_FILTER_IGNORE
    r.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    r.add_theme_font_override("normal_font",BODY);r.add_theme_font_override("bold_font",BOLD)
    r.add_theme_font_size_override("normal_font_size",18);r.add_theme_color_override("default_color",INK)
    if not emphasis_pattern:
        emphasis_pattern=RegEx.new()
        var names=JSON.parse_string(FileAccess.get_file_as_string("res://data/editorial_names.json"))
        emphasis_pattern.compile("\\b(?:"+"|".join(names)+")\\b|\\b[0-9]+(?:[.][0-9]+)* Jenny\\b")
    var offset=0
    for match in emphasis_pattern.search_all(text):
        r.add_text(text.substr(offset,match.get_start()-offset))
        var token=match.get_string();r.push_color(ALERT if token.ends_with("Jenny") else NAVY);r.push_bold();r.add_text(token);r.pop();r.pop()
        offset=match.get_end()
    r.add_text(text.substr(offset))
    return r
static func title(text: String, font_size: int = 26) -> Label:
    var l = label(text,font_size)
    l.add_theme_font_override("font",DISPLAY)
    return l
static func section(parent: Node,text: String,kind: String="record") -> void:
    var row=HBoxContainer.new();row.add_theme_constant_override("separation",8)
    row.add_child(icon(kind));row.add_child(title(text,22));parent.add_child(row)
    parent.add_child(HSeparator.new())
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
