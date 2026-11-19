extends Control
const PlayerText=preload("res://scripts/ui/player_text.gd")
const UI = preload("res://scripts/ui/styles.gd")
const State = preload("res://scripts/game_state.gd")
const Creation = preload("res://scripts/ui/creation_view.gd")
const InventoryView=preload("res://scripts/ui/inventory_view.gd")
var inventory_view
var inventory_content: VBoxContainer
const BattleView=preload("res://scripts/ui/battle_view.gd")
const Adventure = preload("res://scripts/ui/adventure_view.gd")
const TABS = ["Aventura","Personagem","Inventário","Registro"]
const ICONS = ["adventure","character","inventory","record"]
const Storage = preload("res://scripts/storage.gd")
var attribute_buttons: Dictionary={}
var state = State.new()
var margin: MarginContainer
var chapter: Label
var page_title: Label
var balance: Label
var journal_button: Button
var pages: TabContainer
var navigation: Array[Button] = []
var nav_icons: Array[Control] = []
var nav_labels: Array[Label] = []
var creation_view
var adventure_view
var record_content: VBoxContainer
var character_content: VBoxContainer
var current_tab: int = 0
func _ready() -> void:
    get_window().min_size = Vector2i(320,480)
    theme = UI.make_theme()
    var background = ColorRect.new()
    background.color = UI.BG
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    margin = MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)
    var layout = VBoxContainer.new()
    layout.add_theme_constant_override("separation",16)
    margin.add_child(layout)
    build_header(layout)
    layout.add_child(HSeparator.new())
    var context = HBoxContainer.new()
    chapter = UI.label("Prólogo · Seu personagem",13,UI.MUTED)
    context.add_child(chapter)
    balance = UI.label("",13,UI.GREEN)
    balance.autowrap_mode = TextServer.AUTOWRAP_OFF
    balance.size_flags_horizontal = Control.SIZE_SHRINK_END
    context.add_child(balance)
    layout.add_child(context)
    pages = TabContainer.new()
    pages.tabs_visible = false
    pages.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
    pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(pages)
    layout.add_child(HSeparator.new())
    build_navigation(layout)
    resized.connect(responsive)
    responsive()
    show_creation()
func build_header(layout: VBoxContainer) -> void:
    var row = HBoxContainer.new()
    var titles = VBoxContainer.new()
    titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    titles.add_theme_constant_override("separation",4)
    titles.add_child(UI.label("HUNTER LIFE",12,UI.GREEN))
    page_title = UI.label("Uma nova jornada",24)
    titles.add_child(page_title)
    row.add_child(titles)
    journal_button = UI.button("",true)
    journal_button.custom_minimum_size = Vector2(44,44)
    journal_button.size_flags_horizontal = Control.SIZE_SHRINK_END
    journal_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    journal_button.tooltip_text = "Abrir registro"
    journal_button.accessibility_name = "Abrir registro"
    var icon = UI.icon("adventure",UI.BG)
    icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    journal_button.add_child(icon)
    journal_button.pressed.connect(func(): select_tab(3))
    row.add_child(journal_button)
    layout.add_child(row)
func build_navigation(layout: VBoxContainer) -> void:
    var row = HBoxContainer.new()
    row.add_theme_constant_override("separation",4)
    for i in range(TABS.size()):
        var b = UI.button("")
        b.accessibility_name = TABS[i]
        b.tooltip_text = TABS[i]
        b.theme_type_variation = "Navigation"
        b.custom_minimum_size = Vector2(0,62)
        var content = VBoxContainer.new()
        content.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        content.add_theme_constant_override("separation",3)
        content.alignment = BoxContainer.ALIGNMENT_CENTER
        var icon = UI.icon(ICONS[i])
        content.add_child(icon)
        nav_icons.append(icon)
        var text = UI.label(TABS[i],12,UI.GREEN)
        text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        text.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content.add_child(text)
        nav_labels.append(text)
        b.add_child(content)
        b.pressed.connect(func(): select_tab(i))
        row.add_child(b)
        navigation.append(b)
    layout.add_child(row)
func responsive() -> void:
    if not margin: return
    var horizontal: int = maxi(12 if size.x<380 else 20,int((size.x-760)/2))
    for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,horizontal)
    for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,16 if size.y>=600 else 10)
func add_page(title: String) -> VBoxContainer:
    var scroll = ScrollContainer.new()
    scroll.name = title
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.follow_focus = true
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    pages.add_child(scroll)
    var content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation",14)
    scroll.add_child(content)
    return content
func clear_pages() -> void:
    for child in pages.get_children():
        pages.remove_child(child)
        child.queue_free()
func show_creation() -> void:
    state = State.new()
    clear_pages()
    var content = add_page("Criação")
    creation_view = Creation.new()
    content.add_child(creation_view)
    creation_view.build(state)
    var continue_button = UI.button("Continuar partida salva")
    content.add_child(continue_button)
    continue_button.pressed.connect(load_saved)
    creation_view.start_requested.connect(start_game)
    page_title.text = "Uma nova jornada"
    chapter.text = "Prólogo · Seu personagem"
    balance.text = ""
    journal_button.disabled = true
    for b in navigation: b.disabled = true
    update_navigation(-1)
    call_deferred("focus_creation")
func focus_creation() -> void:
    if is_instance_valid(creation_view) and creation_view.is_inside_tree() and state.character_name.is_empty(): creation_view.name_input.grab_focus()
func start_game(raw_name: String) -> void:
    var error: String = state.start(raw_name,creation_view.inclination.selected)
    if error != "": creation_view.show_error(error); return
    build_session()
func build_session() -> void:
    clear_pages()
    var content = add_page("Aventura")
    adventure_view = BattleView.new() if not state.battle.is_empty() else Adventure.new()
    content.add_child(adventure_view)
    adventure_view.build(state)
    adventure_view.continue_requested.connect(next_event)
    if state.battle.is_empty():adventure_view.choice_requested.connect(choose)
    else:adventure_view.action_requested.connect(battle_action)
    adventure_view.record_requested.connect(func(): select_tab(3))
    character_content = add_page("Personagem")
    build_character()
    inventory_content=add_page("Inventário")
    refresh_inventory()
    record_content = add_page("Registro")
    refresh_records()
    chapter.text = state.demo["chapter"]
    if state.exam["status"]=="active":chapter.text="Exame Hunter · Etapa %d/4 · Saúde %d/10" % [state.exam["stage"],state.health]
    balance.text = "%d Jenny" % state.jenny
    chapter.text=state.demo["chapter"]
    if state.exam["status"]=="active":chapter.text="Exame Hunter · Etapa %d/4 · Saúde %d/10" % [state.exam["stage"],state.health]
    balance.tooltip_text = "Recursos disponíveis nesta jornada."
    journal_button.disabled = false
    for b in navigation: b.disabled = false
    select_tab(0)
func build_character() -> void:
    character_content.add_child(UI.title(state.character_name))
    character_content.add_child(UI.label("Hunter licenciado" if state.exam["status"]=="approved" and state.exam["awarded"] else "Sem Licença Hunter",14,UI.GREEN))
    character_content.add_child(UI.label("Viajante · Uma história por escrever",15,UI.MUTED))
    var progress = UI.card(character_content)
    progress.add_child(UI.label("Nível %d · Saúde %d/10" % [state.level,state.health],20,UI.GREEN))
    progress.add_child(UI.label("%d / %d XP para o próximo nível" % [state.xp,state.Progress.threshold(state.level)],14))
    var xp_bar=ProgressBar.new()
    xp_bar.max_value=state.Progress.threshold(state.level);xp_bar.value=state.xp;xp_bar.show_percentage=false;xp_bar.custom_minimum_size.y=9
    progress.add_child(xp_bar)
    progress.add_child(UI.label("Pontos disponíveis: %d" % state.points,16))
    var allocation=HFlowContainer.new()
    progress.add_child(allocation)
    attribute_buttons={}
    for attribute in state.ATTRIBUTE_NAMES:
        var add_button=UI.button("+1 "+state.ATTRIBUTE_NAMES[attribute])
        attribute_buttons[attribute]=add_button
        add_button.disabled=state.Battle.active(state) or state.points==0 or int(state.attributes[attribute])>=10 or state.health==0
        add_button.pressed.connect(func(): allocate_point(attribute))
        allocation.add_child(add_button)
    var nen_card=UI.card(character_content)
    nen_card.add_child(UI.label("Nen",20,UI.GREEN))
    if not state.nen["awakened"]:
        nen_card.add_child(UI.label("Você ainda não conhece Nen.",14,UI.MUTED))
        if "nen_offer" in state.seen and not state.flags.get("nen_declined",false):
            var resume_nen=UI.button("Retomar o convite de Mira")
            resume_nen.disabled=state.Battle.active(state) or state.active_adventure or state.health==0 or state.demo["kind"]=="ending"
            resume_nen.pressed.connect(func(): state.open_event("nen_ten");build_session())
            nen_card.add_child(resume_nen)
    else:
        var technique_names: Array[String]=[]
        for technique in state.nen["techniques"]:technique_names.append(str(technique).capitalize())
        nen_card.add_child(UI.label("Fundamentos: %s · Domínio básico %d/3" % [", ".join(technique_names),state.nen["mastery"]],14))
        if state.nen["water_done"]:nen_card.add_child(UI.label("Categoria: "+("Materialização (Conjuração)" if state.nen["category"]=="Materialização" else state.nen["category"]),16,UI.GREEN))
        else:nen_card.add_child(UI.label("Categoria ainda não revelada.",14,UI.MUTED))
        if state.hatsu["learned"]:
            nen_card.add_child(UI.label(state.Hatsu.NAMES[state.hatsu["id"]]+" · "+state.Hatsu.LABELS[state.hatsu["specialization"]],16,UI.GREEN))
            nen_card.add_child(UI.label(state.Hatsu.DESCRIPTIONS[state.hatsu["id"]+":"+state.hatsu["specialization"]],14,UI.MUTED))
        elif state.nen["water_done"]:
            nen_card.add_child(UI.label("Hatsu ainda não desenvolvido. Busque uma oportunidade prática." if state.nen["category"] in state.Hatsu.CATEGORIES.values() else "Ainda não há Hatsu implementado para esta categoria. Sua jornada pode continuar normalmente.",14,UI.MUTED))
        if state.nen["mastery"]==3 and not state.nen["water_done"]:
            var water=UI.button("Procurar Mira para o teste da água")
            water.disabled=state.Battle.active(state) or state.active_adventure or state.health==0 or state.demo["kind"]=="ending"
            water.pressed.connect(func(): state.open_event("nen_water");build_session())
            nen_card.add_child(water)
    var stats = UI.card(character_content)
    stats.add_child(UI.label("Atributos",20))
    UI.attributes(stats,state.attributes,state.ATTRIBUTE_NAMES)
    character_content.add_child(UI.label("As escolhas podem alterar seus atributos. Os confrontos usam os atributos atuais.",14,UI.MUTED))
    if "exam_invite" in state.seen and state.exam["status"]=="unentered" and not state.flags.get("exam_ignored",false):
        var resume_exam=UI.button("Consultar inscrição Hunter")
        resume_exam.disabled=state.active_adventure or state.Battle.active(state) or state.health==0 or state.demo["kind"]=="ending"
        resume_exam.pressed.connect(func():state.open_event("exam_info");build_session())
        character_content.add_child(resume_exam)
    var reset = UI.button("Criar outro personagem")
    reset.pressed.connect(show_creation)
    character_content.add_child(reset)
    character_content.add_child(UI.label("Aventuras concluídas: %d" % state.completed.size(),14,UI.GREEN))
    var end_button = UI.button("Escolher o final da jornada")
    end_button.disabled=state.Battle.active(state) or state.health==0 or state.active_adventure or state.demo["kind"]=="ending"
    end_button.tooltip_text="Conclua ou abandone a aventura atual primeiro." if state.active_adventure else ""
    end_button.pressed.connect(func(): state.open_event("crossroads"); build_session())
    character_content.add_child(end_button)
    character_content.add_child(UI.label("Começa uma nova jornada. Salve antes de substituir sua sessão.",13,UI.MUTED))
func choose(index: int) -> void:
    if not state.choose(index): return
    if not state.battle.is_empty():build_session();return
    adventure_view.refresh(state)
    balance.text = "%d Jenny" % state.jenny
    chapter.text=state.demo["chapter"]
    if state.exam["status"]=="active":chapter.text="Exame Hunter · Etapa %d/4 · Saúde %d/10" % [state.exam["stage"],state.health]
    for child in character_content.get_children():
        character_content.remove_child(child); child.queue_free()
    build_character()
    refresh_inventory()
    refresh_records()
    var scroll = pages.get_child(0)
    scroll.ensure_control_visible.call_deferred(adventure_view.consequence)
func save_current() -> void:
    var message = UI.label("Partida salva." if Storage.save(state)=="" else "Falha ao salvar.",14)
    record_content.add_child(message)
func refresh_records() -> void:
    for child in record_content.get_children():
        record_content.remove_child(child)
        child.queue_free()
    record_content.add_child(UI.title("Registro da jornada"))
    var save_button = UI.button("Salvar partida")
    save_button.pressed.connect(save_current)
    record_content.add_child(save_button)
    record_content.add_child(UI.label("Os primeiros passos de %s." % state.character_name,14,UI.MUTED))
    for entry in state.records:
        var card = UI.card(record_content)
        card.add_child(UI.label(PlayerText.history(entry),16))
    record_content.add_child(UI.label("Decisões e consequências desta jornada.",13,UI.MUTED))
func select_tab(index: int) -> void:
    if state.character_name.is_empty() or index<0 or index>=TABS.size(): return
    current_tab = index
    pages.current_tab = index
    page_title.text = "A Jornada" if index==0 else TABS[index]
    update_navigation(index)
func update_navigation(selected: int) -> void:
    for i in range(navigation.size()):
        navigation[i].theme_type_variation = "NavigationActive" if i==selected else "Navigation"
        var color: Color = UI.BG if i==selected else UI.GREEN
        nav_icons[i].color = color
        nav_icons[i].queue_redraw()
        nav_labels[i].add_theme_color_override("font_color",color)

func next_event() -> void:
    if not state.advance(): return
    build_session()
    pages.get_child(0).scroll_vertical=0
func load_saved() -> void:
    var loaded: Dictionary = Storage.load_state()
    if loaded["error"]!="": creation_view.show_error(loaded["error"]); return
    state=loaded["state"]
    build_session()


func allocate_point(attribute: String) -> void:
    if not state.Progress.spend(state,attribute): return
    var tab: int=current_tab
    build_session()
    select_tab(tab)
    character_content.add_child(UI.label("Ponto aplicado: %s agora é %d." % [state.ATTRIBUTE_NAMES[attribute],state.attributes[attribute]],14,UI.GREEN))





func battle_action(id: String, token: int) -> void:
    if not state.Battle.act(state,id,token):return
    build_session()
    pages.get_child(0).scroll_vertical=0

func refresh_inventory() -> void:
    for child in inventory_content.get_children():inventory_content.remove_child(child);child.queue_free()
    inventory_view=InventoryView.new();inventory_content.add_child(inventory_view)
    inventory_view.build(state);inventory_view.operation_requested.connect(inventory_operation)
func inventory_operation(id: String,mode: String,token: int) -> void:
    if not state.Items.operate(state,id,mode,token):return
    build_session();select_tab(2)
    inventory_content.add_child(UI.label("Objeto utilizado." if mode=="use" else "Equipamento atualizado.",14,UI.GREEN))
