extends RefCounted
const OPTIONS=[["exam_crossing","exam_endurance"],["exam_inquiry","exam_capture"],["exam_survival","exam_team"],["exam_duel","exam_judgment"]]
static func fresh() -> Dictionary:return {"status":"unentered","sequence":[],"stage":0,"setbacks":0,"awarded":false}
static func route(s) -> String:
    return {"approved":"exam_pass","failed":"exam_fail","withdrawn":"exam_withdraw"}.get(s.exam["status"],"")
static func conclude(s,status: String) -> void:
    if s.exam["status"]!="active":return
    s.exam["status"]=status;s.active_adventure=false;s.current_adventure=""
    s.pending_next=route(s) if s.health>0 else ""
    s.records.append("Exame Hunter: "+{"approved":"aprovação","failed":"reprovação","withdrawn":"desistência"}[status]+".")
static func apply(s,effect: Dictionary) -> String:
    if effect.get("exam_start",false) and s.exam["status"]=="unentered":
        s.exam["status"]="active";s.exam["stage"]=1
        for pair in OPTIONS:s.exam["sequence"].append(pair[s.rng.randi_range(0,1)])
        s.active_adventure=true;s.current_adventure="exam";s.pending_next="exam_arrival"
    if s.exam["status"]!="active":return ""
    s.exam["setbacks"]+=int(effect.get("exam_setback",0))
    if effect.get("exam_withdraw",false):conclude(s,"withdrawn")
    elif effect.get("exam_fail",false):conclude(s,"failed")
    elif effect.get("exam_decide",false):conclude(s,"approved" if s.exam["setbacks"]<=2 else "failed")
    elif effect.get("exam_trial",false):s.pending_next="exam_interval_%d" % s.exam["stage"]
    elif effect.get("exam_continue",false):
        if s.current_id.begins_with("exam_interval_"):s.exam["stage"]+=1
        s.pending_next=s.exam["sequence"][s.exam["stage"]-1]
    return "\nAdvertências registradas: %d. A avaliação final admite até duas." % s.exam["setbacks"] if effect.get("exam_setback",0)>0 else ""
static func on_open(s) -> void:
    if s.current_id!="exam_pass" or s.exam["status"]!="approved" or s.exam["awarded"]:return
    s.exam["awarded"]=true
    s.Items.apply(s,{"items_add":{"hunter_license":1}})
    s.Progress.award(s,int(s.demo.get("exam_reward_xp",0)))
    s.records.append("Licença Hunter recebida. +%d XP." % int(s.demo.get("exam_reward_xp",0)))
static func battle_end(s,outcome: String) -> void:
    if s.current_id!="exam_duel" or s.exam["status"]!="active":return
    if s.health==0:conclude(s,"failed")
    elif outcome in ["victory","enemy_yield"]:conclude(s,"approved" if s.exam["setbacks"]<=2 else "failed")
    elif outcome=="yielded" and s.flags.get("exam_helped",false) and s.battle["turn"]>=2:conclude(s,"approved" if s.exam["setbacks"]<=1 else "failed")
    elif outcome in ["yielded","fled"]:conclude(s,"failed")
static func valid(v: Variant,s) -> bool:
    if not v is Dictionary or v.size()!=5 or v.get("status") not in ["unentered","active","approved","failed","withdrawn"] or not v.get("sequence") is Array or not v.get("awarded") is bool:return false
    for key in ["stage","setbacks"]:
        if not (v.get(key) is int or v.get(key) is float) or not is_finite(float(v[key])) or v[key]<0 or v[key]>100 or float(v[key])!=floor(float(v[key])):return false
    if v["status"]=="unentered":
        if not v["sequence"].is_empty() or v["stage"]!=0 or v["setbacks"]!=0 or v["awarded"]:return false
    else:
        if v["sequence"].size()!=4 or v["stage"]<1 or v["stage"]>4:return false
        for i in range(4):
            if v["sequence"][i] not in OPTIONS[i]:return false
    if v["status"]=="approved" and (v["stage"]!=4 or v["setbacks"]>2):return false
    if v["awarded"]!=(s.Items.quantity(s,"hunter_license")==1) or (v["awarded"] and v["status"]!="approved"):return false
    if s.current_id in ["exam_pass","exam_fail","exam_withdraw"] and s.current_id!={"approved":"exam_pass","failed":"exam_fail","withdrawn":"exam_withdraw"}.get(v["status"],""):return false
    if v["status"]=="active":
        if s.demo.get("adventure")!="exam":return false
        if s.health<=0 or s.current_adventure!="exam" or not s.active_adventure:return false
        for i in range(4):
            if s.current_id in OPTIONS[i] and (v["stage"]!=i+1 or v["sequence"][i]!=s.current_id):return false
        if s.current_id.begins_with("exam_interval_"):
            var interval: int=int(s.current_id.trim_prefix("exam_interval_"))
            if interval!=int(v["stage"]) and not (s.selected_choice>=0 and interval==int(v["stage"])-1 and s.pending_next==v["sequence"][int(v["stage"])-1]):return false
    elif s.current_adventure=="exam" or s.active_adventure and s.demo.get("adventure")=="exam":return false
    if v["status"] in ["failed","withdrawn","approved"] and s.current_id.begins_with("exam_") and s.demo["kind"]=="continuation" and s.selected_choice<0:return false
    return true
