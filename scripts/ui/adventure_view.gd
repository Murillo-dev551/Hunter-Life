extends VBoxContainer
signal choice_requested(index: int)
signal record_requested
signal continue_requested
const UI = preload("res://scripts/ui/styles.gd")
var choice_buttons: Array[Button] = []
var consequence: VBoxContainer
var result_text: Label
var selected_text: Label
var advance_button: Button
var story_panel: Control
var illustration: TextureRect
const Scenery=preload("res://scripts/scenery.gd")
func build(state) -> void:
    var story = UI.card(self)
    story_panel=story.get_parent()
    story_panel.add_theme_stylebox_override("panel",UI.document(UI.PANEL,"story",UI.INK,14))
    story.add_theme_constant_override("separation",12)
    var banner = PanelContainer.new()
    var banner_style=UI.document(UI.NAVY,"ribbon",UI.NAVY,6);banner_style.content_margin_right=24
    banner.add_theme_stylebox_override("panel",banner_style)
    var ribbon=HBoxContainer.new();ribbon.add_theme_constant_override("separation",6);banner.add_child(ribbon)
    ribbon.add_child(UI.icon("adventure",UI.BG))
    var kind=UI.title("FINAL DA JORNADA" if state.health==0 or state.demo["kind"]=="ending" else "AVENTURA CONCLUÍDA" if state.demo["kind"]=="adventure_end" else "ACONTECIMENTO",14);kind.add_theme_color_override("font_color",UI.BG);ribbon.add_child(kind)
    var folio=UI.label("%03d" % int(state.demo.get("folio",1)),11,UI.BG);folio.size_flags_horizontal=Control.SIZE_SHRINK_END;folio.autowrap_mode=TextServer.AUTOWRAP_OFF;folio.custom_minimum_size.x=23;ribbon.add_child(folio)
    story.add_child(banner)
    var title=UI.label(state.demo["title"],29);title.add_theme_font_override("font",UI.BOLD);story.add_child(title)
    story.add_child(preload("res://scripts/ui/editorial_rule.gd").new())
    if state.demo.has("scenery"):
        var texture=Scenery.texture(state.demo["scenery"])
        if texture:
            illustration=preload("res://scripts/ui/scenery_view.gd").new()
            illustration.texture=texture
            illustration.accessibility_name="Ilustração de ambiente: "+str(Scenery.data()[state.demo.scenery].name)
            story.add_child(illustration)
    for paragraph in state.demo["paragraphs"]:
        story.add_child(UI.narrative(paragraph))
    var question=UI.card(self)
    question.get_parent().add_theme_stylebox_override("panel",UI.document(UI.BG,"button",UI.INK,7))
    var heading=UI.label("Fim da jornada" if state.demo["kind"]=="ending" else "O que você fará?",19);heading.add_theme_font_override("font",UI.SERIF_ITALIC);question.add_child(heading)
    for i in range(state.demo["choices"].size()):
        var b = UI.button(state.demo["choices"][i]["label"],i==0)
        b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        b.add_theme_font_override("font",UI.SERIF);b.add_theme_font_size_override("font_size",18)
        var icon="adventure"
        var lower: String=state.demo.choices[i].label.to_lower()
        if lower.begins_with("recusar") or lower.begins_with("não assumir") or lower.begins_with("deixar") or lower.begins_with("voltar"):icon="other"
        elif lower.begins_with("negociar") or lower.begins_with("pedir"):icon="record"
        UI.button_icon(b,icon)
        if lower.begins_with("aceitar") or lower.begins_with("assumir") or lower.begins_with("confirmar"):b.icon=UI.CHOICES.accept
        elif icon=="other":b.icon=UI.CHOICES.back
        elif icon=="record":b.icon=UI.CHOICES.talk
        b.add_theme_constant_override("icon_max_width",25);b.add_theme_constant_override("h_separation",10)
        if state.demo["choices"][i].has("test"):
            var test: Dictionary = state.demo["choices"][i]["test"]
            b.text+="\n◇ %s · Dificuldade %d · %d%%" % [state.ATTRIBUTE_NAMES[test["attribute"]],int(test["difficulty"]),state.Progress.chance(int(state.attributes[test["attribute"]]),int(test["difficulty"]))]
            b.custom_minimum_size.y=72
            b.add_theme_font_size_override("font_size",15)
        b.custom_minimum_size.y=maxf(b.custom_minimum_size.y,b.text.count("\n")*24+52)
        b.alignment = HORIZONTAL_ALIGNMENT_LEFT
        b.pressed.connect(func(): choice_requested.emit(i))
        add_child(b)
        choice_buttons.append(b)
    consequence = UI.card(self)
    UI.section(consequence,"SUA ESCOLHA","record")
    selected_text = UI.label("",17,UI.GREEN)
    consequence.add_child(selected_text)
    result_text = UI.label("",18)
    consequence.add_child(result_text)
    var next_button = UI.button("Jornada encerrada" if state.health==0 else "Continuar jornada",true)
    next_button.disabled=state.health==0
    advance_button=next_button
    next_button.pressed.connect(func(): continue_requested.emit())
    consequence.add_child(next_button)
    var record_button = UI.button("Ver registro da jornada")
    record_button.pressed.connect(func(): record_requested.emit())
    consequence.add_child(record_button)
    refresh(state)
func refresh(state) -> void:
    var chosen: bool = state.selected_choice >= 0
    advance_button.disabled=state.health==0
    if state.health==0: advance_button.text="Jornada encerrada"
    for i in range(choice_buttons.size()):
        choice_buttons[i].disabled = chosen or state.choice_reason(i)!=""
        if not chosen: choice_buttons[i].tooltip_text=state.choice_reason(i)
        if chosen: choice_buttons[i].tooltip_text = "Sua escolha" if i==state.selected_choice else "Acontecimento resolvido"
        if chosen and i==state.selected_choice:
            var selected=UI.document(UI.PANEL,"button",UI.GOLD,14)
            choice_buttons[i].add_theme_stylebox_override("disabled",selected)
    consequence.get_parent().visible = chosen
    if chosen:
        selected_text.text = state.demo["choices"][state.selected_choice]["label"]
        var prefix: String=state.demo["title"]+" — "
        for i in range(state.records.size()-1,-1,-1):
            if state.records[i].begins_with(prefix): selected_text.text=state.records[i].trim_prefix(prefix);break
        result_text.text = state.result
