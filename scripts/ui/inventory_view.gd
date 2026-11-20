extends VBoxContainer
signal operation_requested(id: String,mode: String,token: int)
const UI=preload("res://scripts/ui/styles.gd")
var buttons: Dictionary={}
func build(state) -> void:
    UI.section(self,"O que você carrega","inventory")
    add_child(UI.label("Saúde %d/10 · %d Jenny" % [state.health,state.jenny],15,UI.GREEN))
    if state.Battle.active(state):add_child(UI.label("Durante o confronto, você pode consultar os objetos, mas não usar ou trocar equipamentos.",14,UI.ALERT))
    if state.inventory["items"].is_empty():
        add_child(UI.label("Sua mochila está vazia. Oportunidades da jornada podem oferecer suprimentos, ferramentas e lembranças.",16,UI.MUTED))
    var previous_category=""
    for id in state.Items.data():
        var count: int=state.Items.quantity(state,id)
        if count==0:continue
        var item: Dictionary=state.Items.data()[id]
        if item.category!=previous_category:
            previous_category=item.category
            add_child(UI.label(str(item.category).to_upper(),12,UI.NAVY));add_child(HSeparator.new())
        var card=UI.card(self)
        card.add_child(UI.label("%s × %d" % [item["name"],count],19,UI.GREEN))
        card.add_child(UI.label(item["category"],13,UI.MUTED))
        card.add_child(UI.label(item["description"],15))
        card.add_child(UI.label(item["effect"],14,UI.MUTED))
        var mode: String="use" if item.has("heal") else "equip" if item.has("slot") else ""
        if item.has("slot") and state.inventory["equipment"][item["slot"]]==id:
            mode="unequip";card.add_child(UI.label("Equipado · "+("Arma" if item["slot"]=="weapon" else "Proteção"),14,UI.GREEN))
            var equipped=UI.box(UI.PANEL,3,UI.NAVY,14);equipped.border_width_left=4
            card.get_parent().add_theme_stylebox_override("panel",equipped)
        if mode!="":
            var b=UI.button({"use":"Usar","equip":"Equipar","unequip":"Desequipar"}[mode])
            var reason: String=state.Items.reason(state,id,mode)
            b.disabled=reason!="";b.tooltip_text=reason
            if reason!="":card.add_child(UI.label(reason,13,UI.MUTED))
            var token: int=state.inventory["revision"]
            b.pressed.connect(func():operation_requested.emit(id,mode,token))
            card.add_child(b);buttons[id]=b
