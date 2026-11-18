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
func start(raw_name: String) -> String:
    var clean: String = raw_name.strip_edges().replace("\n"," ").replace("\r"," ").replace("\t"," ")
    if clean.is_empty(): return "Dê um nome ao personagem para começar."
    if clean.length()>32: return "Use um nome com até 32 caracteres."
    if error!="": return error
    character_name=clean; attributes=INITIAL_ATTRIBUTES.duplicate(); jenny=250
    flags={}; seen=[]; pending_next=""; active_adventure=false
    records.assign(["A jornada de %s começou." % character_name])
    open_event(catalog.select(self))
    return ""
func open_event(id: String) -> void:
    current_id=id; demo=catalog.events[id]; selected_choice=-1; result=""
    if id not in seen: seen.append(id)
    if demo["kind"]=="opportunity": active_adventure=true
    if demo["kind"]=="ending": active_adventure=false
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
    selected_choice=index
    jenny=maxi(0,jenny+int(effect.get("jenny",0)))
    for key in effect.get("attributes",{}): attributes[key]=clampi(int(attributes[key])+int(effect["attributes"][key]),1,10)
    for key in effect.get("flags",{}): flags[key]=effect["flags"][key]
    pending_next=effect.get("next","")
    result=effect["result"]+test_text
    for key in effect.get("attributes",{}): result+="\n%s: %d/10." % [ATTRIBUTE_NAMES[key],attributes[key]]
    if int(effect.get("jenny",0))!=0: result+="\nJenny: %+d." % int(effect["jenny"])
    records.append("%s — %s" % [demo["title"],choice["label"]]); records.append(result)
    return true
func advance() -> bool:
    if selected_choice<0 or demo["kind"]=="ending": return false
    var next: String = pending_next if pending_next!="" else "end_home" if active_adventure else catalog.select(self)
    pending_next=""
    open_event(next)
    return true
func serialize() -> Dictionary:
    return {"version":2,"name":character_name,"attributes":attributes,"jenny":jenny,"flags":flags,"seen":seen,"current":current_id,"choice":selected_choice,"next":pending_next,"active":active_adventure,"result":result,"records":records,"seed":str(rng.seed),"rng":str(rng.state)}

