extends RefCounted
const INITIAL_ATTRIBUTES = {"strength":5,"agility":5,"intellect":5,"presence":5}
const ATTRIBUTE_NAMES = {"strength":"Força","agility":"Agilidade","intellect":"Intelecto","presence":"Presença"}
const Catalog = preload("res://scripts/catalog.gd")
var catalog = Catalog.new()
var character_name: String = ""
var attributes: Dictionary = INITIAL_ATTRIBUTES.duplicate()
var selected_choice: int = -1
var records: Array[String] = []
var demo: Dictionary = {}
var error: String = ""
var visits: Dictionary = {}
var last_visit: Dictionary = {}
var step: int = 0
var completed: Array = []
var current_adventure: String = ""
var jenny: int = 250
var flags: Dictionary = {}
var seen: Array = []
var current_id: String = ""
var pending_next: String = ""
var active_adventure: bool = false
var result: String = ""
var rng = RandomNumberGenerator.new()
func _init() -> void:
    error = catalog.error
    rng.randomize()
func start(raw_name: String, inclination: int = 0) -> String:
    var clean: String = raw_name.strip_edges().replace("\n"," ").replace("\r"," ").replace("\t"," ")
    if clean.is_empty(): return "Dê um nome ao personagem para começar."
    if clean.length()>32: return "Use um nome com até 32 caracteres."
    if error!="": return error
    character_name=clean; attributes=INITIAL_ATTRIBUTES.duplicate(); jenny=250
    attributes=starting_attributes(inclination)
    visits={};last_visit={};step=0;completed=[];current_adventure=""
    flags={}; seen=[]; pending_next=""; active_adventure=false
    records.assign(["A jornada de %s começou." % character_name])
    open_event(catalog.select(self))
    return ""
func open_event(id: String) -> void:
    current_id=id; demo=catalog.events[id]; selected_choice=-1; result=""
    step+=1;visits[id]=int(visits.get(id,0))+1;last_visit[id]=step
    if id not in seen: seen.append(id)
    if demo["kind"] in ["opportunity","continuation"]: active_adventure=true;current_adventure=demo.get("adventure","")
    if demo["kind"]=="adventure_end": finish_adventure()
    if demo["kind"]=="ending": active_adventure=false;current_adventure=""
func choice_reason(index: int) -> String:
    var choice: Dictionary = demo["choices"][index]
    if not catalog.eligible(choice.get("conditions",{}),self): return "Exige preparação anterior ou recursos adicionais."
    if jenny + int(choice.get("jenny",0)) < 0: return "Jenny insuficiente."
    return ""
func choose(index: int) -> bool:
    if character_name.is_empty() or selected_choice!=-1 or index<0 or index>=demo.get("choices",[]).size(): return false
    if choice_reason(index)!="": return false
    var choice: Dictionary = demo["choices"][index]
    var effect: Dictionary = choice
    var test_text: String = ""
    if choice.has("test"):
        var test: Dictionary = choice["test"]
        var roll: int = rng.randi_range(1,20)
        var value: int = int(attributes[test["attribute"]])
        var success: bool = roll+value>=int(test["difficulty"])
        test_text="\n%s: d20 %d + %d = %d contra %d · %s." % [ATTRIBUTE_NAMES[test["attribute"]],roll,value,roll+value,int(test["difficulty"]),"sucesso" if success else "fracasso"]
        if not success: effect=choice["failure"]
    if int(visits.get(current_id,1))>1:
        effect=effect.duplicate(true)
        effect.erase("attributes")
        if int(effect.get("jenny",0))>0: effect["jenny"]=floori(int(effect["jenny"])*float(demo.get("repeat_reward_scale",0)))
    selected_choice=index
    jenny=maxi(0,jenny+int(effect.get("jenny",0)))
    for key in effect.get("attributes",{}): attributes[key]=clampi(int(attributes[key])+int(effect["attributes"][key]),1,10)
    for key in effect.get("flags",{}): flags[key]=effect["flags"][key]
    if effect.get("finish_adventure",false): finish_adventure()
    pending_next=effect.get("next","")
    result=effect["result"]+test_text
    for key in effect.get("attributes",{}): result+="\n%s: %d/10." % [ATTRIBUTE_NAMES[key],attributes[key]]
    if int(effect.get("jenny",0))!=0: result+="\nJenny: %+d." % int(effect["jenny"])
    records.append("%s — %s" % [demo["title"],choice["label"]]); records.append(result)
    return true
func advance() -> bool:
    if selected_choice<0 or demo["kind"]=="ending": return false
    var next: String = pending_next if pending_next!="" else "crossroads" if active_adventure else catalog.select(self)
    pending_next=""
    open_event(next)
    return true
func serialize() -> Dictionary:
    return {"version":3,"visits":visits,"last_visit":last_visit,"step":step,"completed":completed,"adventure":current_adventure,"name":character_name,"attributes":attributes,"jenny":jenny,"flags":flags,"seen":seen,"current":current_id,"choice":selected_choice,"next":pending_next,"active":active_adventure,"result":result,"records":records,"seed":str(rng.seed),"rng":str(rng.state)}

func finish_adventure() -> void:
    if current_adventure!="" and flags.get(current_adventure+"_completed",false) and current_adventure not in completed:
        completed.append(current_adventure)
        records.append("Aventura concluída: "+current_adventure)
    current_adventure="";active_adventure=false
static func starting_attributes(inclination: int) -> Dictionary:
    var values: Dictionary=INITIAL_ATTRIBUTES.duplicate()
    if inclination==1: values["strength"]=6;values["intellect"]=4
    elif inclination==2: values["agility"]=6;values["presence"]=4
    elif inclination==3: values["intellect"]=6;values["strength"]=4
    return values

