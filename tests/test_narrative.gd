extends SceneTree
const State = preload("res://scripts/game_state.gd")
const Storage = preload("res://scripts/storage.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok: failures+=1; push_error(text)
func run() -> void:
    var s = State.new()
    s.start("Lia")
    var distribution: Dictionary = {}
    for i in range(1000):
        s.seen=[];s.visits={};s.last_visit={};s.active_adventure=false;s.current_adventure=""
        var id: String = s.catalog.select(s)
        distribution[id]=int(distribution.get(id,0))+1
        check(s.catalog.events[id]["weight"]>0,"Somente eventos independentes elegíveis")
    check(distribution.size()==12,"Seleção diversificada")
    s.open_event("bridge")
    check(s.choice_reason(1)!="","Flag bloqueia desvio")
    s.flags["prepared"]=true
    check(s.choice_reason(1)=="","Flag libera desvio")
    s.jenny=0
    check(not s.choose(2),"Recursos bloqueiam escolha paga")
    for ending_choice in range(3):
        s.start("Lia"); s.open_event("offer")
        check(s.choose(0) and s.advance() and s.current_id=="route","Continuação prioritária")
        s.choose(0); s.advance()
        check(s.current_id=="bridge" and s.flags.get("prepared",false),"Estado da aventura preservado")
        s.choose(1); s.advance()
        check(s.current_id=="delivery","Ramificação coerente")
        s.choose(ending_choice); s.advance()
        check(s.demo["kind"]=="adventure_end", "Conclusão não é final da jornada")
        s.choose(1);s.advance()
        check(s.demo["kind"]=="ending" and not s.advance(),"Final explícito alcançável")
        check(Storage.save(s,"user://test_narrative.json")=="","Salva final")
        check(Storage.load_state("user://test_narrative.json")["error"]=="","Carrega final: "+Storage.load_state("user://test_narrative.json")["error"])
    for seed_value in range(50):
        s.start("Teste");s.open_event("market");s.rng.seed=seed_value
        Storage.save(s,"user://test_narrative.json")
        var loaded: Dictionary = Storage.load_state("user://test_narrative.json")
        check(loaded["error"]=="","Save válido: "+loaded["error"])
        if loaded["error"]!="": quit(1);return
        var other = loaded["state"]
        s.choose(0); other.choose(0)
        check(s.serialize()==other.serialize(),"Rolagem mantida após carregar")
        check(s.result.contains("d20"),"Teste legível")
        var money: int = s.jenny
        check(not s.choose(0) and s.jenny==money,"Sem recompensa duplicada")
        Storage.save(s,"user://test_narrative.json")
        other=Storage.load_state("user://test_narrative.json")["state"]
        check(not other.choose(0) and other.jenny==money,"Escolha resolvida permanece resolvida")
    s.start("Teste");s.active_adventure=false
    for id in s.catalog.events: s.visits[id]=100;s.last_visit[id]=s.step
    check(s.catalog.select(s)=="crossroads","Esgotamento tem encerramento seguro")
    for invalid in ["{", "[]", "{}",'{"version":2,"jenny":-4}']:
        var f=FileAccess.open("user://test_narrative.json",FileAccess.WRITE);f.store_string(invalid);f.close()
        check(Storage.load_state("user://test_narrative.json")["error"]!="","Save inválido recusado")
    DirAccess.remove_absolute("user://test_narrative.json")
    print("MOTOR: %d verificações, %d falhas; seleção=%s" % [checks,failures,distribution])
    quit(1 if failures else 0)






