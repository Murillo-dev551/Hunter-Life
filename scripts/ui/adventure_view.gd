extends VBoxContainer
signal choice_requested(index: int)
signal record_requested
signal continue_requested
const UI = preload("res://scripts/ui/styles.gd")
var choice_buttons: Array[Button] = []
var consequence: VBoxContainer
var result_text: Label
var selected_text: Label
func build(state) -> void:
    var story = UI.card(self)
    var banner = PanelContainer.new()
    banner.add_theme_stylebox_override("panel",UI.box(UI.GREEN,5,Color.TRANSPARENT,6))
    banner.add_child(UI.label("FINAL DA JORNADA" if state.demo["kind"]=="ending" else "AVENTURA CONCLUÍDA" if state.demo["kind"]=="adventure_end" else "ACONTECIMENTO",11,UI.BG))
    story.add_child(banner)
    story.add_child(UI.label(state.demo["title"],22))
    for paragraph in state.demo["paragraphs"]: story.add_child(UI.label(paragraph,16))
    add_child(UI.label("Fim da jornada" if state.demo["kind"]=="ending" else "O que você fará?",17))
    for i in range(state.demo["choices"].size()):
        var b = UI.button(state.demo["choices"][i]["label"],i==0)
        if state.demo["choices"][i].has("test"):
            var test: Dictionary = state.demo["choices"][i]["test"]
            b.text+="\n◇ %s · Dificuldade %d" % [state.ATTRIBUTE_NAMES[test["attribute"]],int(test["difficulty"])]
            b.custom_minimum_size.y=72
            b.add_theme_font_size_override("font_size",14)
        b.alignment = HORIZONTAL_ALIGNMENT_LEFT
        b.pressed.connect(func(): choice_requested.emit(i))
        add_child(b)
        choice_buttons.append(b)
    consequence = UI.card(self)
    consequence.add_child(UI.label("SUA ESCOLHA",12,UI.GREEN))
    selected_text = UI.label("",17,UI.GREEN)
    consequence.add_child(selected_text)
    result_text = UI.label("",16)
    consequence.add_child(result_text)
    var next_button = UI.button("Continuar jornada",true)
    next_button.pressed.connect(func(): continue_requested.emit())
    consequence.add_child(next_button)
    var record_button = UI.button("Ver registro da jornada")
    record_button.pressed.connect(func(): record_requested.emit())
    consequence.add_child(record_button)
    refresh(state)
func refresh(state) -> void:
    var chosen: bool = state.selected_choice >= 0
    for i in range(choice_buttons.size()):
        choice_buttons[i].disabled = chosen or state.choice_reason(i)!=""
        if not chosen: choice_buttons[i].tooltip_text=state.choice_reason(i)
        if chosen: choice_buttons[i].tooltip_text = "Sua escolha" if i==state.selected_choice else "Acontecimento resolvido"
    consequence.get_parent().visible = chosen
    if chosen:
        selected_text.text = state.records[-2].get_slice(" — ",1) if state.records.size()>=2 else state.demo["choices"][state.selected_choice]["label"]
        result_text.text = state.result



