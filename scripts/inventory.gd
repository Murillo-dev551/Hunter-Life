extends RefCounted
static var cached: Dictionary={}
static func data() -> Dictionary:
    if cached.is_empty():
        var parser=JSON.new()
        if parser.parse(FileAccess.get_file_as_string("res://data/items.json"))==OK and parser.data is Dictionary:cached=parser.data
    return cached
static func fresh() -> Dictionary:return {"items":{},"equipment":{"weapon":"","protection":""},"revision":0}
static func quantity(s,id: String) -> int:return int(s.inventory["items"].get(id,0))
static func effect_reason(s,effect: Dictionary) -> String:
    if effect.get("items_take",{}).has("hunter_license"):return "A Licença Hunter é permanente."
    for id in effect.get("items_take",{}):
        if id not in data() or quantity(s,id)<int(effect["items_take"][id]):return "Você não possui os objetos necessários."
    for id in effect.get("items_add",{}):
        if id not in data():return "Objeto indisponível."
        var result: int=quantity(s,id)-int(effect.get("items_take",{}).get(id,0))+int(effect["items_add"][id])
        if result>int(data()[id]["max"]):return "Você já possui esse objeto único ou atingiu o limite de quantidade."
    return ""
static func apply(s,effect: Dictionary) -> String:
    var messages: Array[String]=[]
    for field in ["items_take","items_add"]:
        for id in effect.get(field,{}):
            var amount: int=int(effect[field][id])*(1 if field=="items_add" else -1)
            var count: int=quantity(s,id)+amount
            if count==0:
                s.inventory["items"].erase(id)
                for slot in s.inventory["equipment"]:
                    if s.inventory["equipment"][slot]==id:s.inventory["equipment"][slot]=""
            else:s.inventory["items"][id]=count
            messages.append("%+d %s" % [amount,data()[id]["name"]])
    if not messages.is_empty():s.inventory["revision"]=int(s.inventory["revision"])+1
    return "\n"+"\n".join(messages) if not messages.is_empty() else ""
static func reason(s,id: String,mode: String) -> String:
    if s.Battle.active(s):return "Use ou troque objetos somente fora de combate."
    if s.health<=0 or s.demo.get("kind")=="ending":return "Esta jornada terminou."
    if id not in data() or quantity(s,id)<1:return "Você não possui esse objeto."
    var item: Dictionary=data()[id]
    if mode=="use":
        if not item.has("heal"):return "Este objeto não é consumível."
        if s.health>=10:return "Sua Saúde já está completa."
    elif mode in ["equip","unequip"]:
        if not item.has("slot"):return "Este objeto não é equipamento."
        if mode=="equip" and s.inventory["equipment"][item["slot"]]==id:return "Objeto já equipado."
        if mode=="unequip" and s.inventory["equipment"][item["slot"]]!=id:return "Objeto não está equipado."
    else:return "Ação indisponível."
    return ""
static func operate(s,id: String,mode: String,token: int) -> bool:
    if token!=int(s.inventory["revision"]) or reason(s,id,mode)!="":return false
    if mode=="use":
        var before: int=s.health
        s.health=mini(10,s.health+int(data()[id]["heal"]))
        apply(s,{"items_take":{id:1}})
        s.records.append("Usou %s: +%d Saúde (%d/10)." % [data()[id]["name"],s.health-before,s.health])
    else:
        s.inventory["equipment"][data()[id]["slot"]]=id if mode=="equip" else ""
        s.inventory["revision"]=int(s.inventory["revision"])+1
        s.records.append(("Equipou " if mode=="equip" else "Desequipou ")+data()[id]["name"]+".")
    return true
static func valid(v: Variant) -> bool:
    if not v is Dictionary or v.size()!=3 or not v.get("items") is Dictionary or not v.get("equipment") is Dictionary:return false
    if not (v.get("revision") is int or v.get("revision") is float) or not is_finite(float(v["revision"])) or v["revision"]<0 or v["revision"]>1000000 or float(v["revision"])!=floor(float(v["revision"])):return false
    for id in v["items"]:
        var count: Variant=v["items"][id]
        if id not in data() or not (count is int or count is float) or not is_finite(float(count)) or count<1 or count>int(data()[id]["max"]) or float(count)!=floor(float(count)):return false
    if v["equipment"].size()!=2:return false
    for slot in ["weapon","protection"]:
        var id: Variant=v["equipment"].get(slot)
        if not id is String:return false
        if id!="" and (not v["items"].has(id) or data()[id].get("slot")!=slot):return false
    return true
