extends AcceptDialog
const UI=preload("res://scripts/ui/styles.gd")
var sliders: Dictionary={}
var mutes: Dictionary={}
var numbers: Dictionary={}
var reduce_motion: CheckBox
var scroll: ScrollContainer
var status: Label
func _ready() -> void:
    title="Configurações";ok_button_text="Concluir";borderless=true
    theme=UI.make_theme()
    for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:theme.set_color(state,"CheckBox",UI.INK)
    get_ok_button().theme_type_variation="Secondary"
    get_ok_button().custom_minimum_size.y=44
    add_theme_stylebox_override("panel",UI.box(UI.BG,12,UI.GOLD,12))
    scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(250,272);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
    var content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",6);scroll.add_child(content)
    content.add_child(UI.title("Configurações",22))
    var audio=get_node("/root/Audio")
    for key in ["music","effects"]:
        var heading=HBoxContainer.new();content.add_child(heading)
        heading.add_child(UI.label("Música" if key=="music" else "Efeitos sonoros",16,UI.GREEN))
        var mute=CheckBox.new();mute.text="Silenciar";mute.accessibility_name="Silenciar música" if key=="music" else "Silenciar efeitos";mute.button_pressed=audio.preferences["mute_"+key];mute.custom_minimum_size.y=36;heading.add_child(mute);mutes[key]=mute
        mute.toggled.connect(func(value):audio.change("mute_"+key,value);report())
        var row=HBoxContainer.new();content.add_child(row)
        var slider=HSlider.new();slider.min_value=0;slider.max_value=100;slider.step=1;slider.value=audio.preferences[key]*100
        slider.custom_minimum_size=Vector2(140,30);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider);sliders[key]=slider
        var number=UI.label("%d%%" % slider.value,14);number.custom_minimum_size.x=42;number.size_flags_horizontal=Control.SIZE_SHRINK_END;row.add_child(number)
        numbers[key]=number
        slider.accessibility_name="Volume da música" if key=="music" else "Volume dos efeitos"
        slider.value_changed.connect(func(value):number.text="%d%%" % value;audio.change(key,value/100.0);report())
    content.add_child(HSeparator.new())
    reduce_motion=CheckBox.new();reduce_motion.text="Reduzir animações";reduce_motion.button_pressed=audio.preferences.reduce_motion;reduce_motion.custom_minimum_size.y=40;content.add_child(reduce_motion)
    reduce_motion.toggled.connect(func(value):audio.change("reduce_motion",value);report())
    content.add_child(UI.label("Preferências de todas as jornadas.",12,UI.MUTED))
    status=UI.label("",14,UI.ALERT);status.hide();content.add_child(status)
    confirmed.connect(func():audio.cue("back"));canceled.connect(func():audio.cue("back"))
func sync() -> void:
    var audio=get_node("/root/Audio")
    for key in sliders:
        sliders[key].set_value_no_signal(audio.preferences[key]*100)
        numbers[key].text="%d%%" % sliders[key].value
        mutes[key].set_pressed_no_signal(audio.preferences["mute_"+key])
    reduce_motion.set_pressed_no_signal(audio.preferences.reduce_motion)
    report()
func report() -> void:
    status.text="Não foi possível salvar as preferências. Verifique o acesso à pasta de dados." if get_node("/root/Audio").save_error!=OK else ""
    status.visible=status.text!=""
