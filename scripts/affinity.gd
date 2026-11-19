extends RefCounted
# Avaliação provisória e isolada: intenção vale 3; sucesso acrescenta apenas 1.
# Cada uma das cinco cenas oferece exatamente uma abordagem de cada afinidade.
const IDS=["reinforce","emission","transmutation","conjuration","manipulation"]
const ATTRIBUTES={"reinforce":"strength","emission":"agility","transmutation":"agility","conjuration":"intellect","manipulation":"presence"}
static func fresh() -> Dictionary:
    return {"phase":"unstarted","decisions":[],"scores":{"reinforce":0,"emission":0,"transmutation":0,"conjuration":0,"manipulation":0},"result":"","attributes":{}}
static func eligible(s) -> bool:
    return s.nen["category"]=="Especialização" and s.nen["water_done"] and s.nen["mastery"]==3 and not s.hatsu["learned"] and s.affinity["phase"]=="unstarted"
static func locked(s) -> bool:return s.affinity["phase"] in ["active","resolved"]
static func target(s) -> String:
    return "affinity_reveal_"+s.affinity["result"] if s.affinity["phase"]=="resolved" else "affinity_trial_%d" % (s.affinity["decisions"].size()+1)
static func choose_result(scores: Dictionary,decisions: Array,attributes: Dictionary) -> String:
    # 1. Pontos; 2. consistência nas duas decisões finais; 3. atributo inicial;
    # 4. decisão mais recente entre as empatadas. Nenhum sorteio ou ordem fixa de categorias.
    var candidates: Array=IDS.duplicate()
    var best: int=-1
    for id in IDS:best=maxi(best,int(scores[id]))
    candidates=candidates.filter(func(id):return int(scores[id])==best)
    var recent: Dictionary={}
    best=-1
    for id in candidates:
        recent[id]=0
        for decision in decisions.slice(-2):
            if decision["style"]==id:recent[id]+=1
        best=maxi(best,int(recent[id]))
    candidates=candidates.filter(func(id):return recent[id]==best)
    best=-1
    for id in candidates:best=maxi(best,int(attributes[ATTRIBUTES[id]]))
    candidates=candidates.filter(func(id):return int(attributes[ATTRIBUTES[id]])==best)
    for i in range(decisions.size()-1,-1,-1):
        if decisions[i]["style"] in candidates:return decisions[i]["style"]
    return ""
static func reason(s,choice: Dictionary) -> String:
    if choice.get("affinity_start",false) and not eligible(s):return "Esta avaliação exige fundamentos, Especialização revelada e nenhum Hatsu desenvolvido."
    if choice.has("affinity_style") and (s.affinity["phase"]!="active" or s.current_id!=target(s)):return "Esta decisão da avaliação já foi registrada."
    return ""
static func apply(s,choice: Dictionary,roll: int,value: int,difficulty: int,success: bool) -> void:
    if choice.get("affinity_start",false):
        s.affinity["phase"]="active";s.affinity["attributes"]=s.attributes.duplicate()
        s.active_adventure=true;s.current_adventure="affinity"
        s.pending_next=target(s)
    if choice.has("affinity_style"):
        var style: String=choice["affinity_style"]
        s.affinity["decisions"].append({"scene":s.current_id,"choice":s.selected_choice,"style":style,"roll":roll,"value":value,"difficulty":difficulty,"success":success})
        s.affinity["scores"][style]+=3+(1 if success else 0)
        if s.affinity["decisions"].size()==5:
            s.affinity["result"]=choose_result(s.affinity["scores"],s.affinity["decisions"],s.affinity["attributes"])
            s.affinity["phase"]="resolved"
        s.pending_next=target(s)
static func authorized(s,id: String,learning: bool) -> bool:
    return s.nen["category"]=="Especialização" and s.affinity["result"]==id and s.affinity["phase"]==("resolved" if learning else "learned") and (not learning or s.current_id=="affinity_reveal_"+id)
static func integer(v: Variant,low: int,high: int) -> bool:
    return (v is int or v is float) and is_finite(float(v)) and v>=low and v<=high and floor(float(v))==float(v)
static func valid_data(v: Variant,catalog) -> bool:
    if not v is Dictionary or v.size()!=5 or v.get("phase") not in ["unstarted","active","resolved","learned"] or not v.get("decisions") is Array or not v.get("scores") is Dictionary or not v.get("attributes") is Dictionary or not v.get("result") is String:return false
    if v["decisions"].size()>5 or v["scores"].size()!=5:return false
    var scores: Dictionary=fresh()["scores"]
    for id in IDS:
        if not integer(v["scores"].get(id),0,20):return false
    if v["phase"]=="unstarted":return v["decisions"].is_empty() and v["attributes"].is_empty() and v["result"]=="" and v["scores"].values().all(func(value):return int(value)==0)
    if v["attributes"].size()!=4:return false
    for key in ["strength","agility","intellect","presence"]:
        if not integer(v["attributes"].get(key),1,10):return false
    for i in range(v["decisions"].size()):
        var d: Variant=v["decisions"][i]
        if not d is Dictionary or d.size()!=7 or d.get("scene")!="affinity_trial_%d" % (i+1) or not integer(d.get("choice"),0,4) or d.get("style") not in IDS or not d.get("success") is bool:return false
        var choice: Dictionary=catalog.events[d["scene"]]["choices"][int(d["choice"])]
        if choice["affinity_style"]!=d["style"] or not integer(d.get("roll"),1,20) or not integer(d.get("value"),1,10) or not integer(d.get("difficulty"),1,40):return false
        if d["difficulty"]!=choice["test"]["difficulty"] or d["success"]!=(d["roll"]+d["value"]>=d["difficulty"]):return false
        scores[d["style"]]+=3+(1 if d["success"] else 0)
    for id in IDS:
        if scores[id]!=int(v["scores"][id]):return false
    if v["phase"]=="active":return v["decisions"].size()<5 and v["result"]==""
    return v["decisions"].size()==5 and v["result"]==choose_result(scores,v["decisions"],v["attributes"])
static func normalized(v: Dictionary) -> Dictionary:
    var out: Dictionary=v.duplicate(true)
    for key in out["attributes"]:out["attributes"][key]=int(out["attributes"][key])
    for key in out["scores"]:out["scores"][key]=int(out["scores"][key])
    for decision in out["decisions"]:
        for key in ["choice","roll","value","difficulty"]:decision[key]=int(decision[key])
    return out
static func valid_state(s) -> bool:
    var phase: String=s.affinity["phase"]
    if phase=="unstarted":return s.current_adventure!="affinity" and "affinity" not in s.completed and not s.flags.get("affinity_completed",false)
    if s.nen["category"]!="Especialização" or not s.nen["water_done"] or s.nen["mastery"]!=3:return false
    if phase=="learned":
        return s.hatsu["learned"] and s.hatsu["id"]==s.affinity["result"] and "affinity" in s.completed and s.flags.get("affinity_completed",false) and s.current_adventure!="affinity" and not (s.current_id.begins_with("affinity_") and s.selected_choice<0)
    if s.hatsu["learned"] or "affinity" in s.completed or s.flags.get("affinity_completed",false) or not s.active_adventure or s.current_adventure!="affinity" or s.health<=0:return false
    if s.current_id==target(s):return s.selected_choice==-1 and s.pending_next==""
    if s.selected_choice<0 or s.pending_next!=target(s):return false
    var count: int=s.affinity["decisions"].size()
    if count==0:return s.current_id=="affinity_offer" and s.selected_choice==0
    return s.current_id=="affinity_trial_%d" % count and s.affinity["decisions"][-1]["choice"]==s.selected_choice
