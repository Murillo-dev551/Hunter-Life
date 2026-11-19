extends RefCounted
const SPECS={"reinforce":["power","resistance"],"emission":["power","range","precision"]}
const NAMES={"reinforce":"Corpo Temperado","emission":"Projétil de Aura"}
const LABELS={"power":"Potência","resistance":"Resistência","range":"Alcance","precision":"Precisão"}
const DESCRIPTIONS={"reinforce:power":"Aura aplicada a esforços intensos, em testes físicos específicos.","reinforce:resistance":"Amortece impactos específicos; não confere imunidade geral.","emission:power":"Impactos mais fortes em obstáculos adequados.","emission:range":"Alcança objetos distantes, com teste de Agilidade.","emission:precision":"Atinge mecanismos pequenos, com teste de Intelecto."}
static func fresh() -> Dictionary:return {"id":"","specialization":"","learned":false}
static func category(id: String) -> String:return "Reforço" if id=="reinforce" else "Emissão"
static func can_learn(state, id: String, spec: String) -> bool:
    return id in SPECS and spec in SPECS[id] and not state.hatsu["learned"] and state.nen["water_done"] and state.nen["mastery"]==3 and state.nen["category"]==category(id)
static func valid(v: Variant, state) -> bool:
    if not v is Dictionary or v.size()!=3 or not v.get("learned") is bool or not v.get("id") is String or not v.get("specialization") is String:return false
    if not v["learned"]:return v["id"]=="" and v["specialization"]==""
    return v["id"] in SPECS and v["specialization"] in SPECS[v["id"]] and state.nen["water_done"] and state.nen["mastery"]==3 and state.nen["category"]==category(v["id"])
static func apply(state, effect: Dictionary) -> String:
    if not effect.has("hatsu_learn"):return ""
    var data: Dictionary=effect["hatsu_learn"]
    if not can_learn(state,data["id"],data["specialization"]):return ""
    state.hatsu={"id":data["id"],"specialization":data["specialization"],"learned":true}
    return "\nHatsu desenvolvido: %s · %s." % [NAMES[data["id"]],LABELS[data["specialization"]]]
