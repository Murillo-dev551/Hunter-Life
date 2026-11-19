extends RefCounted
var events: Dictionary = {}
var error: String = ""
func _init() -> void:
    var parser = JSON.new()
    if parser.parse(FileAccess.get_file_as_string("res://data/events.json")) != OK or not parser.data is Array:
        error = "Catálogo inválido."; return
    for event in parser.data:
        if not event is Dictionary or not event.get("id") is String or events.has(event["id"]) or not event.get("choices") is Array:
            error = "Evento inválido ou duplicado."; return
        if not event.get("title") is String or not event.get("paragraphs") is Array or not event.get("conditions") is Dictionary or not event.get("weight") is float and not event.get("weight") is int:
            error="Descrição de evento inválida."; return
        if event.get("kind") not in ["independent","opportunity","continuation","ending","adventure_end","hub"] or event["weight"]<0:
            error="Categoria ou peso inválido."; return
        events[event["id"]] = event
    for event in events.values():
        for reward in event.get("battle_rewards",{}).values():
            if reward.has("next") and not events.has(reward["next"]): error = "Continuação de confronto inexistente."
        for choice in event["choices"]:
            for effect in [choice,choice.get("failure",{})]:
                if effect.has("next") and not events.has(effect["next"]): error = "Continuação inexistente."
func eligible(conditions: Dictionary, state) -> bool:
    if conditions.has("exam_status") and state.exam["status"]!=conditions["exam_status"]:return false
    for id in conditions.get("items",{}):
        if state.Items.quantity(state,id)<int(conditions["items"][id]):return false
    if conditions.has("hatsu_available"):
        if state.hatsu["learned"] or not state.nen["water_done"] or state.nen["mastery"]!=3 or state.nen["category"]!=conditions["hatsu_available"]:return false
    if conditions.has("hatsu"):
        var required: Dictionary=conditions["hatsu"]
        if not state.hatsu["learned"] or state.hatsu["id"]!=required["id"] or state.hatsu["specialization"]!=required["specialization"]:return false
    for key in conditions.get("flags",{}):
        if state.flags.get(key,false) != conditions["flags"][key]: return false
    if state.jenny < int(conditions.get("jenny",0)): return false
    for key in conditions.get("attributes",{}):
        if int(state.attributes.get(key,0)) < int(conditions["attributes"][key]): return false
    return true
func select(state) -> String:
    if state.active_adventure: return state.pending_next if state.pending_next!="" else "crossroads"
    var candidates: Array[String] = []
    var total: int = 0
    for id in events:
        var event: Dictionary = events[id]
        if event["kind"] not in ["independent","opportunity"] or not available(id,state) or not eligible(event["conditions"],state): continue
        total += int(event["weight"])
        candidates.append(id)
    if total <= 0: return "crossroads"
    var roll: int = state.rng.randi_range(1,total)
    for id in candidates:
        roll -= int(events[id]["weight"])
        if roll <= 0: return id
    return "crossroads"

func available(id: String, state) -> bool:
    var policy: Dictionary = events[id].get("repeat",{"max":1,"gap":0})
    return int(state.visits.get(id,0)) < int(policy["max"]) and state.step-int(state.last_visit.get(id,-100000)) >= int(policy["gap"])
