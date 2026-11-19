extends SceneTree
const Driver=preload("res://tests/battle_driver.gd")
const State=preload("res://scripts/game_state.gd")
const Storage=preload("res://scripts/storage.gd")
const P=preload("res://scripts/progression.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok: failures+=1;push_error(text)
func run() -> void:
    var s=State.new();s.start("Progresso")
    check(s.level==1 and s.xp==0 and s.health==10 and s.points==0,"Início limpo")
    check(P.chance(5,15)==55 and P.chance(5,16)==50,"Exemplos exatos")
    for attribute in range(1,11):
        for difficulty in range(1,32):
            var count: int=0
            for roll in range(1,21):
                if roll+attribute>=difficulty:count+=1
            check(P.chance(attribute,difficulty)==count*5,"Chance enumerada")
    check(P.award(s,39)==0 and s.xp==39,"Sem nível prematuro")
    check(P.award(s,1)==1 and s.level==2 and s.points==1,"Primeiro nível")
    check(P.award(s,140)==2 and s.level==4 and s.xp==0 and s.points==3,"Múltiplos níveis")
    check(P.spend(s,"strength") and s.attributes["strength"]==6 and s.points==2,"Distribuição consome um ponto")
    s.attributes["strength"]=10
    check(not P.spend(s,"strength") and s.points==2,"Não excede dez")
    for key in s.attributes:s.attributes[key]=10
    P.award(s,1000)
    check(s.points==0,"Sem pontos impossíveis no teto")
    s.start("Escolha");s.seen.erase("market");s.visits.erase("market");s.last_visit.erase("market");s.open_event("market");s.rng.seed=12
    s.choose(0)
    var snapshot: Dictionary=s.serialize().duplicate(true)
    check(s.xp>0 and not s.choose(0) and snapshot==s.serialize(),"Recompensa única")
    Storage.save(s,"user://test_progression.json")
    var loaded=Storage.load_state("user://test_progression.json")
    check(loaded["error"]=="" and loaded["state"].serialize()==snapshot and not loaded["state"].choose(0),"Save não reaplica resultado")
    s.start("Recuperação");s.health=5;s.open_event("rain");s.choose(0)
    check(s.health==8 and s.result.contains("+3 Saúde"),"Recuperação narrativa")
    s.start("Ferimento");s.health=1;s.open_event("bridge")
    var seed_value: int=0
    while seed_value<100:
        s.rng.seed=seed_value
        var r=RandomNumberGenerator.new();r.seed=seed_value
        if r.randi_range(1,20)+5<16: break
        seed_value+=1
    s.choose(0)
    check(s.health==0 and not s.advance() and not s.choose(1) and not s.active_adventure,"Saúde zero encerra trajetória")
    check(s.result.contains("jornada termina"),"Encerramento explicado")
    Storage.save(s,"user://test_progression.json")
    check(Storage.load_state("user://test_progression.json")["state"].health==0,"Encerramento persistente")
    s.start("Retorno");s.seen.erase("dock");s.visits.erase("dock");s.last_visit.erase("dock");s.open_event("dock");s.choose(0)
    var xp: int=s.xp;s.step+=4;s.open_event("dock");s.choose(0)
    check(xp==5 and s.xp==7,"XP reduzido em retorno")
    var old: Dictionary=s.serialize().duplicate(true);old["version"]=3
    for key in ["level","xp","points","health"]:old.erase(key)
    var f=FileAccess.open("user://test_progression.json",FileAccess.WRITE);f.store_string(JSON.stringify(old));f.close()
    var migrated=Storage.load_state("user://test_progression.json")
    check(migrated["error"]=="" and migrated["state"].level==1 and migrated["state"].health==10 and migrated["state"].xp==0,"v3 migra sem prêmios retroativos")
    s.start("Inválido")
    for key in ["level","xp","points","health"]:
        var bad: Dictionary=s.serialize().duplicate(true)
        bad[key]=-1
        f=FileAccess.open("user://test_progression.json",FileAccess.WRITE);f.store_string(JSON.stringify(bad));f.close()
        check(Storage.load_state("user://test_progression.json")["error"]!="","Campo inválido de progressão recusado")
    var distribution: Dictionary={};var max_xp: int=0
    for n in range(100):
        s=State.new();s.rng.seed=n;s.start("Jornada")
        var steps: int=0
        while s.health>0 and s.demo["kind"]!="ending" and steps<100:
            var options: Array=[]
            for i in range(s.demo["choices"].size()):
                if s.choice_reason(i)=="":options.append(i)
            if options.is_empty():check(false,"Sem bloqueio");break
            s.choose(options[s.rng.randi_range(0,options.size()-1)]);Driver.resolve(s);s.advance();steps+=1
        check(steps<100 and (s.health==0 or s.demo["kind"]=="ending"),"Jornada conclui")
        distribution[s.level]=int(distribution.get(s.level,0))+1;max_xp=maxi(max_xp,s.xp)
    print("PROGRESSÃO: %d verificações, %d falhas; 100 jornadas por nível=%s, maior saldo XP=%d" % [checks,failures,distribution,max_xp])
    DirAccess.remove_absolute("user://test_progression.json")
    quit(1 if failures else 0)





