extends RefCounted
const CATEGORIES=["Reforço","Emissão","Transmutação","Materialização","Manipulação","Especialização"]
const WATER=["O volume da água aumenta e ela transborda.","A água muda de cor.","Sob orientação, você percebe uma mudança no sabor da água.","Pequenas impurezas aparecem na água.","A folha se move sobre a superfície da água.","A folha murcha, uma alteração fora dos outros cinco padrões. Mira identifica um sinal de Especialização."]
static func fresh() -> Dictionary:
    return {"awakened":false,"techniques":[],"mastery":0,"category":"","water_done":false}
static func apply(state, effect: Dictionary) -> String:
    var technique: String=effect.get("nen_learn","")
    if technique in ["ten","zetsu","ren"] and technique not in state.nen["techniques"]:
        state.nen["techniques"].append(technique)
        state.nen["awakened"]=true
        state.nen["mastery"]=state.nen["techniques"].size()
        state.flags["nen_"+technique]=true
        if state.nen["category"]=="":state.nen["category"]=CATEGORIES[state.rng.randi_range(0,5)]
    if effect.get("water_test",false) and state.nen["mastery"]==3 and not state.nen["water_done"]:
        state.nen["water_done"]=true
        return "\n"+WATER[CATEGORIES.find(state.nen["category"])]+"\nCategoria revelada: "+state.nen["category"]+". Nenhum Hatsu foi criado."
    return ""
static func valid(value: Variant) -> bool:
    if not value is Dictionary or value.size()!=5:return false
    if not value.get("awakened") is bool or not value.get("water_done") is bool or not value.get("techniques") is Array:return false
    var list: Array=value["techniques"]
    if list.size()>3:return false
    for i in range(list.size()):
        if list[i]!=["ten","zetsu","ren"][i]:return false
    if not (value.get("mastery") is int or value.get("mastery") is float) or value["mastery"]!=list.size():return false
    if value["awakened"]!=(list.size()>0):return false
    if not value.get("category") is String:return false
    if list.is_empty():return value["category"] in CATEGORIES and not value["water_done"]
    return value["category"] in CATEGORIES and (not value["water_done"] or list.size()==3)


