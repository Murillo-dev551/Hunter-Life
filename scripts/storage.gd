extends RefCounted
const State = preload("res://scripts/game_state.gd")
const PATH = "user://hunter_life.json"
static func save(state, path: String = PATH) -> String:
    if state.character_name.is_empty(): return "Crie um personagem primeiro."
    var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
    if not file: return "Não foi possível salvar."
    file.store_string(JSON.stringify(state.serialize())); file.flush()
    var code: Error = file.get_error(); file.close()
    if code!=OK or DirAccess.rename_absolute(path+".tmp",path)!=OK: return "Falha na gravação."
    return ""
static func integer(v: Variant, low: int, high: int) -> bool:
    return (v is int or v is float) and is_finite(float(v)) and float(v)==floor(float(v)) and v>=low and v<=high
static func load_state(path: String = PATH) -> Dictionary:
    var f = FileAccess.open(path,FileAccess.READ)
    if not f: return {"error":"Nenhuma partida salva encontrada."}
    var parser = JSON.new()
    if parser.parse(f.get_as_text())!=OK: return {"error":"Salvamento inválido."}
    var d: Variant = parser.data
    if not d is Dictionary: return {"error":"Salvamento inválido."}
    var s = State.new()
    for key in ["name","current","next","result","seed","rng"]:
        if not d.get(key) is String: return {"error":"Campo de texto inválido."}
    if d.get("version")!=2 or d["name"].strip_edges().is_empty() or d["name"].length()>32 or not s.catalog.events.has(d["current"]): return {"error":"Identidade ou evento inválido."}
    if d["next"]!="" and not s.catalog.events.has(d["next"]): return {"error":"Continuação inválida."}
    if not d.get("active") is bool or not d.get("attributes") is Dictionary or not d.get("flags") is Dictionary or not d.get("seen") is Array or not d.get("records") is Array: return {"error":"Estado incompleto."}
    if not integer(d.get("jenny"),0,1000000) or not integer(d.get("choice"),-1,s.catalog.events[d["current"]]["choices"].size()-1): return {"error":"Valores inválidos."}
    for key in State.INITIAL_ATTRIBUTES:
        if not integer(d["attributes"].get(key),1,10): return {"error":"Atributos inválidos."}
    for value in d["flags"].values():
        if not value is bool: return {"error":"Flag inválida."}
    var seen: Array = []
    for id in d["seen"]:
        if not id is String or not s.catalog.events.has(id) or id in seen: return {"error":"Eventos visitados inválidos."}
        seen.append(id)
    for line in d["records"]:
        if not line is String: return {"error":"Registro inválido."}
    if d["current"] not in seen or not d["seed"].is_valid_int() or not d["rng"].is_valid_int(): return {"error":"Continuidade inválida."}
    if d["choice"]==-1 and (d["next"]!="" or d["result"]!=""): return {"error":"Escolha inconsistente."}
    s.character_name=d["name"]; s.attributes=d["attributes"]; s.jenny=int(d["jenny"]); s.flags=d["flags"]; s.seen=seen
    s.current_id=d["current"]; s.demo=s.catalog.events[s.current_id]; s.selected_choice=int(d["choice"]); s.pending_next=d["next"]; s.active_adventure=d["active"]; s.result=d["result"]; s.records.assign(d["records"])
    for key in s.attributes: s.attributes[key]=int(s.attributes[key])
    s.rng.seed=int(d["seed"]); s.rng.state=int(d["rng"])
    return {"state":s,"error":""}

