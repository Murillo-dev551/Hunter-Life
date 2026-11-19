extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func setup():
    var s=State.new();s.rng.seed=8;s.start("Mochila");return s
func grant(s,items: Dictionary) -> void:s.Items.apply(s,{"items_add":items})
func run() -> void:
    var s=setup()
    check(s.Items.data().size()==9 and s.inventory["items"].is_empty(),"Catálogo e início vazio")
    s.open_event("supply_stall");s.jenny=14
    check(not s.choose(0) and s.jenny==14,"Compra sem saldo bloqueada")
    s.jenny=15;check(s.choose(0) and s.jenny==0 and s.Items.quantity(s,"bandage")==1,"Compra aplica custo e item")
    check(not s.choose(0) and s.Items.quantity(s,"bandage")==1,"Compra não duplica")
    var token: int=s.inventory["revision"]
    check(not s.Items.operate(s,"bandage","use",token) and s.Items.quantity(s,"bandage")==1,"Cura não desperdiçada com Saúde cheia")
    s.health=8
    check(s.Items.operate(s,"bandage","use",token) and s.health==10 and s.Items.quantity(s,"bandage")==0,"Cura limitada e consumo")
    check(not s.Items.operate(s,"bandage","use",token),"Clique antigo bloqueado")
    grant(s,{"bandage":2,"medicine":1,"knife":1,"vest":1,"rope":1,"map":1,"lantern":1,"souvenir":1})
    check(s.Items.effect_reason(s,{"items_add":{"knife":1}})!="","Objeto único não duplica")
    check(s.Items.effect_reason(s,{"items_add":{"bandage":4}})!="","Limite de quantidade")
    s.health=2;s.Items.operate(s,"medicine","use",s.inventory["revision"])
    check(s.health==7 and s.Items.quantity(s,"medicine")==0,"Remédio cura cinco")
    check(s.Items.operate(s,"knife","equip",s.inventory["revision"]) and s.inventory["equipment"]["weapon"]=="knife","Equipar arma")
    check(s.Items.operate(s,"vest","equip",s.inventory["revision"]) and s.inventory["equipment"]["protection"]=="vest","Equipar proteção")
    s.open_event("bridge")
    check(s.choice_reason(s.demo["choices"].size()-1)=="","Corda libera travessia")
    s.choose(s.demo["choices"].size()-1)
    check(s.Items.quantity(s,"rope")==1,"Ferramenta reutilizável não consumida")
    s.open_event("dark_store");s.choose(2)
    check(s.Items.quantity(s,"bandage")==1,"Doação consome uma unidade indicada")
    s.open_event("battle_bandit");s.choose(0)
    check(not s.Items.operate(s,"bandage","use",s.inventory["revision"]) and not s.Items.operate(s,"knife","unequip",s.inventory["revision"]),"Uso e troca bloqueados no combate")
    check(s.Battle.test(s,"attack")["difficulty"]==11,"Faca reduz dificuldade contextual")
    s.battle["intent"]="charge";s.health=10
    s.Battle.act(s,"attack",s.battle["turn"])
    check(s.health==8,"Colete reduz investida de três para dois")
    Store.save(s,"user://test_inventory.json")
    var loaded=Store.load_state("user://test_inventory.json")
    check(loaded["error"]=="" and loaded["state"].serialize()==s.serialize(),"Inventário e batalha preservados no save")
    var other=loaded["state"]
    s.Battle.act(s,"attack",s.battle["turn"]);other.Battle.act(other,"attack",other.battle["turn"])
    check(s.serialize()==other.serialize(),"Efeitos equipados e RNG continuam idênticos")
    s=setup();grant(s,{"knife":1,"vest":1})
    s.Items.operate(s,"knife","equip",s.inventory["revision"]);s.Items.operate(s,"vest","equip",s.inventory["revision"])
    s.open_event("battle_fighter");s.choose(0)
    check(s.Battle.test(s,"attack")["difficulty"]==14,"Faca não afeta treino amistoso")
    s.nen["techniques"]=["ten","zetsu","ren"]
    check(s.Battle.test(s,"ren")["difficulty"]==15,"Faca não se acumula com Ren")
    s.Battle.act(s,"ten",1);check(s.health==10,"Colete não gera cura ou dano negativo com Ten")
    s=setup();grant(s,{"knife":1});s.Items.operate(s,"knife","equip",s.inventory["revision"])
    check(s.Items.operate(s,"knife","unequip",s.inventory["revision"]) and s.inventory["equipment"]["weapon"]=="","Desequipar")
    var old: Dictionary=s.serialize().duplicate(true);old["version"]=7;old.erase("inventory")
    var f=FileAccess.open("user://test_inventory.json",FileAccess.WRITE);f.store_string(JSON.stringify(old));f.close()
    loaded=Store.load_state("user://test_inventory.json")
    check(loaded["error"]=="" and loaded["state"].inventory["items"].is_empty() and loaded["state"].nen==s.nen,"Migração v7 vazia sem alterar categoria")
    for bad in [{"items":{"unknown":1},"equipment":{"weapon":"","protection":""},"revision":0},{"items":{"knife":2},"equipment":{"weapon":"","protection":""},"revision":0},{"items":{},"equipment":{"weapon":"knife","protection":""},"revision":0}]:
        var payload: Dictionary=s.serialize().duplicate(true);payload["inventory"]=bad
        f=FileAccess.open("user://test_inventory.json",FileAccess.WRITE);f.store_string(JSON.stringify(payload));f.close()
        check(Store.load_state("user://test_inventory.json")["error"]!="","Save inválido recusado")
    var stats: Dictionary={}
    for equipped in [false,true]:
        var wins: int=0;var hp: int=0
        for seed_value in range(200):
            s=setup();s.rng.seed=seed_value
            if equipped:
                grant(s,{"knife":1,"vest":1});s.Items.operate(s,"knife","equip",s.inventory["revision"]);s.Items.operate(s,"vest","equip",s.inventory["revision"])
            s.open_event("battle_bandit");s.choose(0)
            var turns: int=0
            while s.Battle.active(s) and turns<30:s.Battle.act(s,"attack",s.battle["turn"]);turns+=1
            check(turns<30 and not s.Battle.active(s),"Batalha equipada não bloqueia")
            if s.battle["outcome"] in ["victory","enemy_yield"]:wins+=1
            hp+=s.health
        stats["equipado" if equipped else "sem_equipamento"]={"wins":wins,"mean_health":hp/200.0}
    const Driver=preload("res://tests/battle_driver.gd")
    var journeys: Dictionary={}
    for equipped in [false,true]:
        var ends: Dictionary={}
        for seed_value in range(50):
            s=State.new();s.rng.seed=seed_value;s.start("Jornada com objetos")
            if equipped:
                grant(s,{"knife":1,"vest":1});s.Items.operate(s,"knife","equip",s.inventory["revision"]);s.Items.operate(s,"vest","equip",s.inventory["revision"])
            var steps: int=0
            while s.health>0 and s.demo["kind"]!="ending" and steps<100:
                var options: Array=[]
                for i in range(s.demo["choices"].size()):
                    if s.choice_reason(i)=="":options.append(i)
                if options.is_empty():check(false,"Jornada sem saída");break
                s.choose(options[s.rng.randi_range(0,options.size()-1)]);Driver.resolve(s);s.advance();steps+=1
            check(steps<100 and (s.health==0 or s.demo["kind"]=="ending"),"Jornada equipada ou não chega ao fim")
            ends["incapacidade" if s.health==0 else "final narrativo"]=int(ends.get("incapacidade" if s.health==0 else "final narrativo",0))+1
        journeys["equipado" if equipped else "vazio"]=ends
    print("JORNADAS INVENTÁRIO: ",journeys)
    print("INVENTÁRIO: %d verificações, %d falhas; simulações=%s" % [checks,failures,stats])
    DirAccess.remove_absolute("user://test_inventory.json")
    quit(1 if failures else 0)
