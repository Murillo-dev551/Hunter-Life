extends RefCounted
var events: Dictionary = {}
var error: String = ""
var mission_entries: Dictionary={}
const Scenery=preload("res://scripts/scenery.gd")
func _init() -> void:
    var parser = JSON.new()
    if parser.parse(FileAccess.get_file_as_string("res://data/events.json")) != OK or not parser.data is Array:
        error = "Catálogo inválido."; return
    var all_events: Array=parser.data
    var expansion=JSON.parse_string(FileAccess.get_file_as_string("res://data/journeys_011.json"))
    if not expansion is Array:error="Expansão narrativa inválida.";return
    all_events.append_array(expansion)
    var encounters=JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters_012.json"))
    var art=JSON.parse_string(FileAccess.get_file_as_string("res://data/scenery_assignments.json"))
    if not encounters is Array or not art is Dictionary:error="Apresentação do catálogo inválida.";return
    all_events.append_array(encounters)
    var revisions=JSON.parse_string(FileAccess.get_file_as_string("res://data/revisions_011.json"))
    if not revisions is Dictionary:error="Revisão narrativa inválida.";return
    for event in all_events:
        if revisions.has(event.get("id","")):
            var patch: Dictionary=revisions[event["id"]]
            for key in patch:
                if key=="choice_patches":
                    for index in patch[key]:
                        for field in patch[key][index]:event["choices"][int(index)][field]=patch[key][index][field]
                else:event[key]=patch[key]
        if not event is Dictionary or not event.get("id") is String or events.has(event["id"]) or not event.get("choices") is Array:
            error = "Evento inválido ou duplicado."; return
        if not event.get("title") is String or not event.get("paragraphs") is Array or not event.get("conditions") is Dictionary or not event.get("weight") is float and not event.get("weight") is int:
            error="Descrição de evento inválida."; return
        if event.get("kind") not in ["independent","opportunity","continuation","ending","adventure_end","hub"] or event["weight"]<0:
            error="Categoria ou peso inválido."; return
        if art.has(event["id"]):event["scenery"]=art[event["id"]]
        if event.has("scenery") and not Scenery.valid(event["scenery"]):error="Referência de cenário inválida.";return
        event["folio"]=events.size()+1
        events[event["id"]] = event
        if event.has("mission") and event["kind"]=="opportunity":
            if mission_entries.has(event["mission"]):error="Missão com entradas duplicadas.";return
            mission_entries[event["mission"]]=event["id"]
    for id in art:
        if not events.has(id):error="Ilustração associada a um acontecimento inexistente.";return
    for event in events.values():
        for reward in event.get("battle_rewards",{}).values():
            if reward.has("next") and not events.has(reward["next"]): error = "Continuação de confronto inexistente."
        for choice in event["choices"]:
            for effect in [choice,choice.get("failure",{})]:
                if effect.has("next") and not events.has(effect["next"]): error = "Continuação inexistente."
func eligible(conditions: Dictionary, state) -> bool:
    if conditions.get("licensed",false) and not (state.exam["status"]=="approved" and state.exam["awarded"] and state.Items.quantity(state,"hunter_license")==1):return false
    if state.level<int(conditions.get("level",1)) or state.health<int(conditions.get("health",0)):return false
    if conditions.get("affinity_available",false) and not state.Affinity.eligible(state):return false
    if conditions.has("exam_status") and state.exam["status"]!=conditions["exam_status"]:
        if conditions["exam_status"]!="unentered" or not state.Exam.can_start(state):return false
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
    if id=="exam_invite" and state.exam.status=="failed":return state.Exam.can_offer(state)
    # Legacy repeat budgets never re-enqueue an already experienced world scene.
    if id in state.seen or int(state.visits.get(id,0))>0:return false
    var mission: String=events[id].get("mission",events[id].get("adventure","") if events[id].get("adventure","") in state.Missions.LEGACY else "")
    if mission!="" and state.missions.has(mission):return false
    var policy: Dictionary = events[id].get("repeat",{"max":1,"gap":0})
    return int(state.visits.get(id,0)) < int(policy["max"]) and state.step-int(state.last_visit.get(id,-100000)) >= int(policy["gap"])
func mission_name(id: String) -> String:
    return events[mission_entries[id]]["title"] if mission_entries.has(id) else {"delivery":"Entrega da Serra","survey":"Levantamento da Trilha","escort":"Escolta de um comerciante","ruins":"Expedição às ruínas"}.get(id,"Trabalho anterior")
func adventures() -> Array:
    var ids: Array=[]
    for event in events.values():
        var id: String=event.get("adventure","")
        if id!="" and id not in ids:ids.append(id)
    return ids
func describe(id: String,s) -> Dictionary:
    var event: Dictionary=events[id].duplicate(true)
    if id=="exam_info":event.paragraphs[2]="Selma explica que uma reprovação não encerra toda possibilidade de candidatura. Outra seleção exige voltar em condições de viajar e com experiências novas fora das provas. Quem já recebeu a licença não volta a disputar uma vaga."
    if id=="exam_invite" and (s.exam.status=="failed" or s.Exam.Journal.history(s).size()>1):
        event.title="Outra seleção do Exame Hunter"
        event.paragraphs=["Depois de outros trabalhos e caminhos, você encontra um novo aviso de inscrições. A funcionária reconhece o registro da sua reprovação; não tenta apagar o resultado anterior nem oferece um atalho para a licença.","Ela pode receber outra candidatura. As provas serão as desta seleção; antes de assinar, você pode perguntar pelas condições ou seguir viagem sem se comprometer."]
    var treatment={"male":"senhor","female":"senhora","unspecified":"viajante"}[s.gender]
    for i in range(event["paragraphs"].size()):event["paragraphs"][i]=event["paragraphs"][i].replace("{tratamento}",treatment)
    return event
