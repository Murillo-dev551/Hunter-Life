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
        if event.get("kind") not in ["independent","opportunity","continuation","ending"] or event["weight"]<0:
            error="Categoria ou peso inválido."; return
        events[event["id"]] = event
    for event in events.values():
        for choice in event["choices"]:
            for effect in [choice,choice.get("failure",{})]:
                if effect.has("next") and not events.has(effect["next"]): error = "Continuação inexistente."
func eligible(conditions: Dictionary, state) -> bool:
    for key in conditions.get("flags",{}):
        if state.flags.get(key,false) != conditions["flags"][key]: return false
    if state.jenny < int(conditions.get("jenny",0)): return false
    for key in conditions.get("attributes",{}):
        if int(state.attributes.get(key,0)) < int(conditions["attributes"][key]): return false
    return true
func select(state) -> String:
    var candidates: Array[String] = []
    var total: int = 0
    for id in events:
        var event: Dictionary = events[id]
        if event["kind"] not in ["independent","opportunity"] or id in state.seen or not eligible(event["conditions"],state): continue
        total += int(event["weight"])
        candidates.append(id)
    if total <= 0: return "end_home"
    var roll: int = state.rng.randi_range(1,total)
    for id in candidates:
        roll -= int(events[id]["weight"])
        if roll <= 0: return id
    return "end_home"

