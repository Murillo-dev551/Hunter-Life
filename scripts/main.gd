extends Control
const PlayerText=preload("res://scripts/ui/player_text.gd")
const AudioSettings=preload("res://scripts/ui/audio_settings.gd")
const Feedback=preload("res://scripts/ui/interaction_feedback.gd")
var last_feedback: Dictionary={}
var audio_settings: AcceptDialog
var settings_button: Button
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
const SaveSlots=preload("res://scripts/save_slots.gd")
var slots=SaveSlots.new()
var active_slot: int=0
var active_token: String=""
var selected_slot: int=1
var delete_dialog: ConfirmationDialog
var pending_delete_slot: int=0
var pending_delete_token: String=""
var slot_buttons: Dictionary={}
var creation_previous_state
var creation_previous_slot: int=0
var creation_previous_token: String=""
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
var affinity_checkpoint_dir: String=Storage.AFFINITY_DIR
func _ready() -> void:
    get_window().min_size = Vector2i(320,480)
    theme = UI.make_theme()
    get_node("/root/Audio").preferences_changed.connect(func():
        if UI.Motion.reduced():UI.Motion.cancel_all())
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
    delete_dialog=ConfirmationDialog.new();delete_dialog.title="Excluir jornada";delete_dialog.dialog_autowrap=true;delete_dialog.ok_button_text="Excluir definitivamente";delete_dialog.cancel_button_text="Cancelar";add_child(delete_dialog)
    delete_dialog.confirmed.connect(confirm_slot_deletion)
    delete_dialog.canceled.connect(func():UI.sound("back"))
    show_slots()
func build_header(layout: VBoxContainer) -> void:
    var row = HBoxContainer.new()
    row.add_theme_constant_override("separation",8)
    var emblem=TextureRect.new()
    emblem.texture=preload("res://assets/icons/emblem.svg")
    emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    emblem.custom_minimum_size=Vector2(32,32)
    emblem.size_flags_vertical=Control.SIZE_SHRINK_CENTER
    emblem.tooltip_text="Hunter Life · Emblema do jogo"
    row.add_child(emblem)
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
    settings_button=UI.button("")
    settings_button.custom_minimum_size=Vector2(44,44)
    settings_button.size_flags_horizontal=Control.SIZE_SHRINK_END
    settings_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
    settings_button.tooltip_text="Configurações"
    settings_button.accessibility_name="Configurações"
    UI.button_icon(settings_button,"settings")
    settings_button.pressed.connect(open_audio_settings)
    row.add_child(settings_button)
    layout.add_child(row)
func open_audio_settings() -> void:
    if not is_instance_valid(audio_settings):
        audio_settings=AudioSettings.new();add_child(audio_settings)
    audio_settings.sync()
    audio_settings.popup_centered_clamped(Vector2i(340,340),0.92)
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
        b.pressed.connect(func():UI.sound("tab"))
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
func show_slots(message: String="",warning: bool=true) -> void:
    if creation_previous_state!=null:
        if slots.token(creation_previous_slot)==creation_previous_token:
            state=creation_previous_state;active_slot=creation_previous_slot;active_token=creation_previous_token
        creation_previous_state=null
    clear_pages();creation_view=null
    var content=add_page("Salvamentos")
    var slot_heading=HBoxContainer.new();slot_heading.add_child(UI.icon("saves"));slot_heading.add_child(UI.title("Suas jornadas"));content.add_child(slot_heading)
    var migration: String=slots.migrate_legacy()
    if message!="":content.add_child(UI.label(message,14,UI.ALERT if warning else UI.GREEN))
    if migration!="":content.add_child(UI.label(migration,14,UI.MUTED))
    slot_buttons={}
    for index in range(1,4):
        var card=UI.card(content)
        var info: Dictionary=slots.summary(index)
        var caption="Vazio" if info["empty"] else "Arquivo inválido" if info["error"]!="" else "Jornada salva"
        if not info["empty"] and info["error"]=="" and active_slot==index:caption="Jornada em uso"
        card.add_child(UI.label("Slot %d · %s" % [index,caption],18,UI.ALERT if info["error"]!="" else UI.GREEN))
        if info["error"]!="":UI.Motion.highlight(card.get_parent(),UI.ALERT)
        elif active_slot==index and not info["empty"]:UI.Motion.highlight(card.get_parent(),UI.GOLD)
        var controls: Dictionary={}
        if info["empty"]:
            card.add_child(UI.label("Espaço vazio",14,UI.MUTED))
            var create=UI.button("Iniciar nova jornada")
            create.pressed.connect(func():begin_new_slot(index));card.add_child(create);controls["create"]=create
        else:
            if info["error"]=="":
                var saved=info["state"]
                card.add_child(UI.label(saved.character_name+" · Nível %d" % saved.level,17))
                card.add_child(UI.label(saved.nen["category"] if saved.nen["water_done"] else "Categoria de Nen não revelada",14,UI.MUTED))
            else:card.add_child(UI.label(info["error"],14,UI.ALERT))
            var load_button=UI.button("Carregar jornada",true);load_button.disabled=info["error"]!=""
            load_button.pressed.connect(func():load_slot(index));card.add_child(load_button);controls["load"]=load_button
            var remove=UI.button("Excluir jornada")
            remove.pressed.connect(func():request_slot_deletion(index));card.add_child(remove);controls["delete"]=remove
        slot_buttons[index]=controls
    var recoverable: Array=slots.legacy_candidates()
    if not recoverable.is_empty():
        var card=UI.card(content);card.add_child(UI.label("Registros anteriores de Mira",18,UI.GREEN))
        card.add_child(UI.label("Recupere uma avaliação que ainda não está associada a um slot.",14,UI.MUTED))
        for candidate in recoverable:
            card.add_child(UI.label(candidate["state"].character_name,16))
            for index in range(1,4):
                if slots.occupied(index):continue
                var recover=UI.button("Recuperar no Slot %d" % index)
                recover.pressed.connect(func():
                    var error: String=slots.import_checkpoint(index,candidate["key"])
                    if error=="":load_slot(index)
                    else:show_slots(error))
                card.add_child(recover)
    if active_slot>0:
        var back=UI.button("Voltar à jornada atual")
        back.pressed.connect(build_session);content.add_child(back)
    page_title.text="Salvamentos";chapter.text="Três espaços · Jornadas independentes";balance.text="";journal_button.disabled=true
    for button in navigation:button.disabled=true
    update_navigation(-1)
func begin_new_slot(index: int) -> void:
    if slots.occupied(index):show_slots("Este slot já está ocupado.");return
    selected_slot=index;show_creation()
func request_slot_deletion(index: int) -> void:
    pending_delete_slot=index;pending_delete_token=slots.token(index)
    delete_dialog.dialog_text="Excluir a jornada do Slot %d e seus checkpoints? Esta ação não pode ser desfeita." % index
    delete_dialog.popup_centered_clamped(Vector2i(380,180))
func confirm_slot_deletion() -> void:
    var error: String=slots.delete_slot(pending_delete_slot,pending_delete_token,true)
    if error=="" and active_slot==pending_delete_slot:active_slot=0;active_token="";state=State.new()
    show_slots("Jornada excluída." if error=="" else error,error!="")
func show_creation() -> void:
    if active_slot>0:
        creation_previous_state=state;creation_previous_slot=active_slot;creation_previous_token=active_token
    state = State.new()
    active_slot=0;active_token=""
    clear_pages()
    var content = add_page("Criação")
    content.add_child(UI.label("Nova jornada no Slot %d" % selected_slot,16,UI.GREEN))
    creation_view = Creation.new()
    content.add_child(creation_view)
    creation_view.build(state)
    var continue_button = UI.button("Voltar aos salvamentos")
    content.add_child(continue_button)
    continue_button.pressed.connect(show_slots)
    creation_view.start_requested.connect(create_in_slot)
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
    # Entrada sem persistência para ferramentas de simulação; a interface usa create_in_slot.
    active_slot=0;active_token=""
    creation_previous_state=null
    var error: String = state.start(raw_name,creation_view.inclination.selected if is_instance_valid(creation_view) and creation_view.is_inside_tree() else 0)
    if error != "": creation_view.show_error(error); return
    build_session()
func create_in_slot(raw_name: String) -> void:
    var candidate=State.new()
    var error: String=candidate.start(raw_name,creation_view.inclination.selected)
    if error=="":error=slots.create(selected_slot,candidate)
    if error!="":creation_view.show_error(error);return
    state=candidate;active_slot=selected_slot;active_token=slots.token(active_slot)
    creation_previous_state=null
    build_session()
func load_slot(index: int) -> void:
    var loaded: Dictionary=slots.load_slot(index)
    if loaded["error"]!="":show_slots(loaded["error"]);return
    state=loaded["state"];active_slot=index;selected_slot=index;active_token=loaded["token"]
    build_session()
func build_session() -> void:
    last_feedback={}
    balance.add_theme_color_override("font_color",UI.GREEN)
    chapter.add_theme_color_override("font_color",UI.MUTED)
    clear_pages()
    var content = add_page("Aventura")
    adventure_view = BattleView.new() if not state.battle.is_empty() else Adventure.new()
    content.add_child(adventure_view)
    adventure_view.build(state)
    adventure_view.continue_requested.connect(next_event)
    if state.battle.is_empty():adventure_view.choice_requested.connect(choose)
    else:adventure_view.action_requested.connect(battle_action)
    if not state.battle.is_empty():adventure_view.menu_changed.connect(func():pages.get_child(0).scroll_vertical=0)
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
    UI.Motion.enter(adventure_view)
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
        if state.nen["category"]=="Especialização" and state.nen["water_done"]:
            if state.affinity["result"]!="" and (state.affinity["phase"]=="learned" or state.current_id=="affinity_reveal_"+state.affinity["result"]):
                var developed_category: String=state.Hatsu.category(state.affinity["result"])
                nen_card.add_child(UI.label("Afinidade desenvolvida: "+("Materialização (Conjuração)" if developed_category=="Materialização" else developed_category),16,UI.GREEN))
            elif state.affinity["phase"]=="active":nen_card.add_child(UI.label("Avaliação com Mira em andamento.",14,UI.MUTED))
        if state.hatsu["learned"]:
            nen_card.add_child(UI.label(state.Hatsu.NAMES[state.hatsu["id"]]+" · "+state.Hatsu.LABELS[state.hatsu["specialization"]],16,UI.GREEN))
            nen_card.add_child(UI.label(state.Hatsu.DESCRIPTIONS[state.hatsu["id"]+":"+state.hatsu["specialization"]],14,UI.MUTED))
        elif state.nen["water_done"]:
            var hint: String="Hatsu ainda não desenvolvido. Busque uma oportunidade prática."
            if state.nen["category"]=="Especialização":
                hint="Mira pode orientar uma avaliação para descobrir como sua prática toma forma."
                if state.affinity["phase"]=="active":hint="A habilidade será definida quando as cinco situações terminarem."
                if state.affinity["phase"]=="resolved":hint="Escolha a direção interna da habilidade revelada por Mira." if state.current_id.begins_with("affinity_reveal_") else "Mira está reunindo suas observações para a conversa final."
            nen_card.add_child(UI.label(hint,14,UI.MUTED))
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
    var reset = UI.button("Gerenciar jornadas")
    reset.pressed.connect(show_slots)
    character_content.add_child(reset)
    character_content.add_child(UI.label("Aventuras concluídas: %d" % state.completed.size(),14,UI.GREEN))
    var end_button = UI.button("Escolher o final da jornada")
    end_button.disabled=state.Battle.active(state) or state.health==0 or state.active_adventure or state.demo["kind"]=="ending"
    end_button.tooltip_text="Conclua ou abandone a aventura atual primeiro." if state.active_adventure else ""
    end_button.pressed.connect(func(): state.open_event("crossroads"); build_session())
    character_content.add_child(end_button)
    character_content.add_child(UI.label("Começa uma nova jornada. Salve antes de substituir sua sessão.",13,UI.MUTED))
func choose(index: int) -> void:
    var before=[state.level,state.xp,state.jenny]
    var visual_before=Feedback.snapshot(state)
    var affinity_commit: bool=state.Affinity.locked(state)
    if not state.choose(index): return
    result_sound(before,state.result)
    var checkpoint_error: String=""
    if affinity_commit or state.affinity["phase"]=="active":checkpoint_error=slots.save_checkpoint(active_slot,state,active_token) if active_slot>0 else Storage.save_affinity(state,affinity_checkpoint_dir)
    if not state.battle.is_empty():build_session();present_feedback(visual_before,state.result);return
    adventure_view.refresh(state)
    balance.text = "%d Jenny" % state.jenny
    chapter.text=state.demo["chapter"]
    if state.exam["status"]=="active":chapter.text="Exame Hunter · Etapa %d/4 · Saúde %d/10" % [state.exam["stage"],state.health]
    for child in character_content.get_children():
        character_content.remove_child(child); child.queue_free()
    build_character()
    refresh_inventory()
    refresh_records()
    present_feedback(visual_before,state.result)
    if checkpoint_error!="":adventure_view.consequence.add_child(UI.label(checkpoint_error+" Salve a partida antes de sair.",14,UI.ALERT))
    var scroll = pages.get_child(0)
    scroll.ensure_control_visible.call_deferred(adventure_view.consequence)
func save_current() -> void:
    var error: String=slots.save_slot(active_slot,state,active_token)
    var message = UI.label("Partida salva no Slot %d." % active_slot if error=="" else error,14)
    record_content.add_child(message)
func refresh_records() -> void:
    for child in record_content.get_children():
        record_content.remove_child(child)
        child.queue_free()
    record_content.add_child(UI.title("Registro da jornada"))
    var save_button = UI.button("Salvar no Slot %d" % active_slot if active_slot>0 else "Salvar partida")
    UI.button_icon(save_button,"saves")
    save_button.disabled=active_slot==0
    save_button.pressed.connect(save_current)
    record_content.add_child(save_button)
    record_content.add_child(UI.label("Os primeiros passos de %s." % state.character_name,14,UI.MUTED))
    for entry in state.records:
        var card = UI.card(record_content)
        card.add_child(UI.label(PlayerText.history(entry),16))
    record_content.add_child(UI.label("Decisões e consequências desta jornada.",13,UI.MUTED))
func select_tab(index: int) -> void:
    if state.character_name.is_empty() or index<0 or index>=TABS.size(): return
    if pages.get_child(pages.current_tab) is Control:UI.Motion.stop(pages.get_child(pages.current_tab))
    current_tab = index
    pages.current_tab = index
    page_title.text = "A Jornada" if index==0 else TABS[index]
    update_navigation(index)
    UI.Motion.enter(pages.get_child(index))
func update_navigation(selected: int) -> void:
    for i in range(navigation.size()):
        navigation[i].theme_type_variation = "NavigationActive" if i==selected else "Navigation"
        var color: Color = UI.BG if i==selected else UI.GREEN
        nav_icons[i].color = color
        nav_icons[i].queue_redraw()
        nav_labels[i].add_theme_color_override("font_color",color)

func next_event() -> void:
    var visual_before=Feedback.snapshot(state)
    if not state.advance(): return
    build_session()
    var changes=Feedback.changes(visual_before,state,"")
    if changes.license or changes.xp or changes.money or not changes.items.is_empty():present_feedback(visual_before,"")
    pages.get_child(0).scroll_vertical=0
func load_saved() -> void:
    load_slot(selected_slot)


func allocate_point(attribute: String) -> void:
    if not state.Progress.spend(state,attribute): return
    var tab: int=current_tab
    build_session()
    select_tab(tab)
    character_content.add_child(UI.label("Ponto aplicado: %s agora é %d." % [state.ATTRIBUTE_NAMES[attribute],state.attributes[attribute]],14,UI.GREEN))





func battle_action(id: String, token: int) -> void:
    var before=[state.level,state.xp,state.jenny]
    var visual_before=Feedback.snapshot(state)
    if not state.Battle.act(state,id,token):return
    result_sound(before,state.battle["log"][-1] if not state.battle["log"].is_empty() else "")
    build_session()
    present_feedback(visual_before,state.battle["log"][-1] if not state.battle["log"].is_empty() else "")
    pages.get_child(0).scroll_vertical=0
func present_feedback(before: Dictionary,text: String) -> void:
    last_feedback=Feedback.changes(before,state,text)
    var target: Control=adventure_view.result_panel if not state.battle.is_empty() else adventure_view.story_panel if state.selected_choice<0 else adventure_view.consequence.get_parent()
    var tone=UI.ALERT if last_feedback.failure else UI.GREEN
    UI.Motion.highlight(target,tone)
    if last_feedback.damage and not state.battle.is_empty():UI.Motion.highlight(adventure_view.status_panel,UI.ALERT)
    if last_feedback.money:UI.Motion.highlight(balance,UI.GOLD)
    if last_feedback.level or last_feedback.xp:UI.Motion.highlight(chapter,UI.GOLD)
    if not last_feedback.items.is_empty():UI.Motion.enter(nav_icons[2])
    if (last_feedback.license or last_feedback.level) and not last_feedback.failure and not last_feedback.damage:UI.Motion.highlight(target,UI.GOLD)
func result_sound(before: Array,text: String) -> void:
    # Read already-resolved presentation; never perform another test or roll.
    var cue="select"
    if "· sucesso" in text:cue="success"
    elif "· fracasso" in text:cue="failure"
    if state.xp>before[1] or state.jenny>before[2]:cue="reward"
    if state.level>before[0]:cue="level"
    UI.sound(cue)

func refresh_inventory() -> void:
    for child in inventory_content.get_children():inventory_content.remove_child(child);child.queue_free()
    inventory_view=InventoryView.new();inventory_content.add_child(inventory_view)
    inventory_view.build(state);inventory_view.operation_requested.connect(inventory_operation)
func inventory_operation(id: String,mode: String,token: int) -> void:
    if not state.Items.operate(state,id,mode,token):return
    build_session();select_tab(2)
    inventory_content.add_child(UI.label("Objeto utilizado." if mode=="use" else "Equipamento atualizado.",14,UI.GREEN))
