extends SceneTree
const Driver=preload("res://tests/battle_driver.gd")
const State = preload("res://scripts/game_state.gd")
const Storage = preload("res://scripts/storage.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok: failures+=1;push_error(text)
func complete(s, id: String) -> void:
    s.open_event(id)
    if id=="offer":
        s.choose(0);s.advance();s.choose(0);s.advance();s.choose(1);s.advance();s.choose(0);s.advance()
    else:
        s.choose(1);s.advance();s.choose(1);s.advance();s.choose(0);s.advance()
    check(s.demo["kind"]=="adventure_end" and not s.active_adventure,"Conclusão separada de jornada")
    check(Storage.save(s,"user://test_journey.json")=="","Salva conclusão")
    check(Storage.load_state("user://test_journey.json")["error"]=="","Carrega conclusão")
    s.choose(0);s.advance()
    check(s.demo["kind"]!="ending","Retorno às oportunidades")
func run() -> void:
    for order in [["offer","survey_offer"],["survey_offer","offer"]]:
        var s=State.new();s.start("Jornada")
        for id in order: complete(s,id)
        check(s.completed.size()==2,"Duas aventuras na mesma partida, nas duas ordens")
        Storage.save(s,"user://test_journey.json")
        var loaded=Storage.load_state("user://test_journey.json")
        check(loaded["error"]=="" and loaded["state"].serialize()==s.serialize(),"Continuidade integral entre aventuras")
    for profile in range(4):
        var values: Dictionary=State.starting_attributes(profile)
        check(values.values().reduce(func(a,b):return a+b,0)==20 and values.values().all(func(v):return v>=4 and v<=6),"Perfis iniciais equilibrados")
    var s=State.new();s.start("Repetição")
    s.open_event("dock");s.choose(0)
    var first: int=s.jenny
    check(not s.choose(0) and s.jenny==first,"Duplo clique não paga")
    check(not s.catalog.available("dock",s),"Intervalo impede repetição imediata")
    s.step+=4
    check(s.catalog.available("dock",s),"Intervalo por acontecimentos libera retorno")
    s.open_event("dock");s.choose(0)
    check(s.jenny-first==9,"Retorno paga metade")
    Storage.save(s,"user://test_journey.json")
    var repeated=Storage.load_state("user://test_journey.json")
    check(repeated["error"]=="" and repeated["state"].serialize()==s.serialize() and not repeated["state"].choose(0),"Save preserva contagem e bloqueio da recompensa repetida")
    s.step+=4;s.open_event("dock");s.choose(0);s.step+=4
    check(not s.catalog.available("dock",s),"Limite de três turnos impede exploração indefinida")
    s.start("Flags");s.flags["merchant_help"]=true
    check(s.catalog.eligible(s.catalog.events["merchant_return"]["conditions"],s),"Ajuda abre indicação")
    s.flags["dishonest"]=true
    check(not s.catalog.eligible(s.catalog.events["merchant_return"]["conditions"],s),"Desonestidade fecha indicação")
    for id in ["journey_home","journey_path","journey_duty"]:
        s.open_event(id);check(not s.advance() and s.demo["kind"]=="ending","Final definitivo")
    s.start("Antigo");s.open_event("bridge")
    var data: Dictionary=s.serialize().duplicate(true);data["version"]=2
    for key in ["visits","last_visit","step","adventure","completed"]: data.erase(key)
    var f=FileAccess.open("user://test_journey.json",FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
    var old=Storage.load_state("user://test_journey.json")
    check(old["error"]=="" and old["state"].current_adventure=="delivery","Migração v2 em aventura")
    data["current"]="end_home";data["active"]=false;data["seen"].append("end_home")
    f=FileAccess.open("user://test_journey.json",FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
    old=Storage.load_state("user://test_journey.json")
    check(old["error"]=="" and old["state"].current_id=="journey_home","Final antigo continua final")
    var results: Dictionary={};var longest: int=0
    for n in range(100):
        s=State.new();s.rng.seed=n;s.start("Simulação")
        var steps: int=0
        while s.health>0 and s.demo["kind"]!="ending" and steps<100:
            var options: Array=[]
            for i in range(s.demo["choices"].size()):
                if s.choice_reason(i)=="": options.append(i)
            if options.is_empty():check(false,"Nenhum bloqueio sem saída");break
            s.choose(options[s.rng.randi_range(0,options.size()-1)]);Driver.resolve(s);s.advance();steps+=1
        check((s.demo["kind"]=="ending" or s.health==0) and steps<100,"Partida completa chega a final")
        check(s.attributes.values().all(func(v):return v>=1 and v<=10),"Atributos dentro dos limites")
        results[s.current_id]=int(results.get(s.current_id,0))+1;longest=maxi(longest,steps)
    print("JORNADAS: %d verificações, %d falhas; 100 partidas, finais=%s, máximo=%d escolhas" % [checks,failures,results,longest])
    DirAccess.remove_absolute("user://test_journey.json")
    quit(1 if failures else 0)



