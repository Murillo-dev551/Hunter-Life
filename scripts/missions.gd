extends RefCounted
const LEGACY=["delivery","survey","escort","ruins"]
const STATES=["offered","active","completed","failed","abandoned","archived"]
static func id_for(event: Dictionary) -> String:
    return event.get("mission",event.get("adventure","") if event.get("adventure","") in LEGACY else "")
static func on_open(s) -> void:
    var id=id_for(s.demo)
    if id=="":return
    if not s.missions.has(id):s.missions[id]="offered" if s.demo["kind"]=="opportunity" else "active"
    var outcome: String=s.demo.get("mission_outcome","")
    if outcome!="" and s.missions[id] in ["offered","active"]:
        s.missions[id]=outcome
        if outcome=="completed":s.flags[id+"_completed"]=true
        s.records.append("Missão %s: %s." % [{"completed":"concluída","failed":"fracassada"}.get(outcome,"encerrada"),s.catalog.mission_name(id)])
static func apply(s,effect: Dictionary) -> void:
    var id=id_for(s.demo)
    if id=="":return
    if s.missions.get(id,"")=="offered":s.missions[id]="active"
    if effect.get("mission_end","")=="abandoned":
        s.missions[id]="abandoned";s.current_adventure="";s.active_adventure=false;s.pending_next=""
        s.records.append("Missão abandonada: "+s.catalog.mission_name(id)+".")
static func finish(s) -> void:
    var id=s.current_adventure
    if id not in LEGACY:return
    if s.missions.get(id,"") in ["active","offered"]:s.missions[id]="completed" if s.flags.get(id+"_completed",false) else "abandoned"
static func incapacitated(s) -> void:
    var id=s.current_adventure
    if id_for(s.demo)!="" and id!="":s.missions[id]="failed"
static func migrate(s) -> Dictionary:
    var data={}
    for id in LEGACY+s.catalog.mission_entries.keys():
        if id in s.completed or s.flags.get(id+"_completed",false):data[id]="completed"
        elif s.current_adventure==id:data[id]="offered" if s.demo["kind"]=="opportunity" and s.selected_choice<0 else "active"
        else:
            for seen_id in s.seen:
                if s.catalog.events[seen_id].get("adventure","")==id:data[id]="archived";break
    return data
static func valid(v: Variant,s) -> bool:
    if not v is Dictionary:return false
    for id in v:
        if id not in LEGACY and not s.catalog.mission_entries.has(id):return false
        if v[id] not in STATES:return false
        if s.catalog.mission_entries.has(id) and s.catalog.events[s.catalog.mission_entries[id]].get("mission_category","")=="hunter" and not s.catalog.eligible({"licensed":true},s):return false
        if v[id] in ["active","offered"] and (s.current_adventure!=id or not s.active_adventure):return false
        if s.catalog.mission_entries.has(id) and (id in s.completed)!=(v[id]=="completed"):return false
    var id=id_for(s.demo)
    if s.demo.has("mission") and not v.has(id):return false
    if id!="" and s.active_adventure and s.current_adventure==id:
        if v.get(id,"") not in ["offered","active"]:return false
    if s.flags.get("journey_deceased",false) and (s.health!=0 or s.active_adventure):return false
    return true
