extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func setup(enemy: String,seed_value: int=1):
    var s=State.new();s.rng.seed=seed_value;s.start("Confronto");s.open_event("battle_"+enemy);s.choose(0);return s
func run() -> void:
    var s=setup("bandit")
    check(s.Battle.active(s) and s.selected_choice==0 and not s.advance(),"Confronto suspende narrativa")
    var t: int=s.battle["turn"]
    check(s.Battle.act(s,"defend",t) and s.health>=9,"Defender investida reduz dano")
    check(not s.Battle.act(s,"attack",t),"Token antigo não repete turno")
    check(s.battle["opening"],"Defesa cria abertura")
    Store.save(s,"user://test_battle.json")
    var loaded=Store.load_state("user://test_battle.json")
    check(loaded["error"]=="","Save em batalha válido")
    var other=loaded["state"]
    s.Battle.act(s,"attack",s.battle["turn"]);other.Battle.act(other,"attack",other.battle["turn"])
    check(s.serialize()==other.serialize(),"RNG e danos equivalentes após carregar")
    for enemy in ["bandit","fighter"]:
        s=setup(enemy);s.Battle.act(s,"yield",1)
        check(s.battle["outcome"]=="yielded" and not s.Battle.active(s),"Rendição distinta de vitória")
        var xp: int=s.xp;var money: int=s.jenny
        check(not s.Battle.act(s,"yield",1) and xp==s.xp and money==s.jenny,"Sem prêmio duplicado")
        check(s.advance() and s.battle.is_empty(),"Narrativa retoma após encerramento")
    var stats: Dictionary={}
    for enemy in ["bandit","fighter"]:
        for strategy in ["attack","tactical","defend","flee"]:
            var wins: int=0;var total: int=0;var longest: int=0;var results: Dictionary={}
            for seed_value in range(200):
                s=setup(enemy,seed_value)
                var turns: int=0
                while s.Battle.active(s) and turns<30:
                    var action: String=strategy
                    if strategy=="tactical":
                        action="defend" if s.battle["intent"]=="charge" and s.battle["last"]!="defend" else "dodge" if s.battle["intent"]=="guard" else "quick" if s.battle["last"]=="attack" else "attack"
                    s.Battle.act(s,action,s.battle["turn"]);turns+=1
                    check(s.health>=0 and s.health<=10 and s.battle["hp"]>=0,"Limites de Saúde")
                check(turns<30 and not s.Battle.active(s),"Sem defesa infinita ou fuga impossível")
                if s.battle["outcome"] in ["victory","enemy_yield"]:wins+=1
                results[s.battle["outcome"]]=int(results.get(s.battle["outcome"],0))+1
                total+=turns;longest=maxi(longest,turns)
            stats[enemy+"_"+strategy]={"wins":wins,"mean_turns":total/200.0,"max":longest,"outcomes":results}
    for technique in ["ten","zetsu","ren"]:
        s=setup("bandit")
        check(s.Battle.reason(s,technique)!="","Técnica ausente bloqueada")
        s.nen["techniques"]=[technique]
        check(s.Battle.reason(s,technique)=="","Técnica aprendida disponível")
        s.Battle.act(s,technique,1)
        if s.Battle.active(s):check(s.Battle.reason(s,technique)!="","Aura exige ação comum entre usos")
    for pair in [["reinforce","power"],["reinforce","resistance"],["emission","power"],["emission","range"],["emission","precision"]]:
        s=setup("fighter")
        s.hatsu={"learned":true,"id":pair[0],"specialization":pair[1]}
        check(s.Battle.reason(s,"hatsu")=="","Especialização permite ação")
        check(s.Battle.act(s,"hatsu",1),"Hatsu resolve ação específica")
    s=setup("fighter");s.health=1
    while s.Battle.active(s):s.Battle.act(s,"defend",s.battle["turn"])
    check(s.health==0 and s.battle["outcome"]=="incapacity" and not s.advance(),"Incapacidade encerra jornada")
    s=setup("bandit");var old: Dictionary=s.serialize().duplicate(true);old["version"]=6;old.erase("battle");old["choice"]=-1;old["result"]=""
    var f=FileAccess.open("user://test_battle.json",FileAccess.WRITE);f.store_string(JSON.stringify(old));f.close()
    var migrated=Store.load_state("user://test_battle.json")
    check(migrated["error"]=="" and migrated["state"].battle.is_empty() and migrated["state"].nen==s.nen,"Migração v6 sem confronto retroativo")
    for attribute in [3,5,8]:
        for hp in [3,10]:
            for seed_value in range(20):
                s=setup("fighter",seed_value);s.health=hp
                for key in s.attributes:s.attributes[key]=attribute
                var turns: int=0
                while s.Battle.active(s) and turns<30:
                    s.Battle.act(s,"quick" if s.battle["last"]=="attack" else "attack",s.battle["turn"]);turns+=1
                check(turns<30 and not s.Battle.active(s),"Atributos e Saúde diferentes terminam sem bloqueio")
    s=setup("fighter");s.Battle.act(s,"yield",1)
    Store.save(s,"user://test_battle.json")
    var done=Store.load_state("user://test_battle.json")
    check(done["error"]=="" and not done["state"].Battle.act(done["state"],"yield",1),"Save encerrado não repete prêmio")
    var invalid: Dictionary=s.serialize().duplicate(true);invalid["battle"]["hp"]=999
    f=FileAccess.open("user://test_battle.json",FileAccess.WRITE);f.store_string(JSON.stringify(invalid));f.close()
    check(Store.load_state("user://test_battle.json")["error"]!="","Saúde inimiga inválida recusada")
    var ability_stats: Dictionary={}
    for ability in ["ten","zetsu","ren","reinforce:power","reinforce:resistance","emission:power","emission:range","emission:precision"]:
        var wins: int=0;var escaped: int=0;var total: int=0
        for seed_value in range(50):
            s=setup("fighter",seed_value)
            s.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"category":"Reforço" if ability.begins_with("reinforce") else "Emissão","water_done":true}
            for technique in ["ten","zetsu","ren"]:s.flags["nen_"+technique]=true
            var special: String=ability
            if ability.contains(":"):
                var parts=ability.split(":");s.hatsu={"learned":true,"id":parts[0],"specialization":parts[1]};special="hatsu"
            var turns: int=0
            while s.Battle.active(s) and turns<30:
                var action: String=special if s.Battle.reason(s,special)=="" else "quick" if s.battle["last"]=="attack" else "attack"
                s.Battle.act(s,action,s.battle["turn"]);turns+=1
            check(turns<30 and not s.Battle.active(s),"Simulação com habilidade não bloqueia")
            if s.battle["outcome"] in ["victory","enemy_yield"]:wins+=1
            if s.battle["outcome"]=="fled":escaped+=1
            total+=turns
        ability_stats[ability]={"wins":wins,"escaped":escaped,"mean_turns":total/50.0}
    print("SIMULAÇÕES HABILIDADES: ",JSON.stringify(ability_stats))
    print("BATALHAS: %d verificações, %d falhas; simulações=%s" % [checks,failures,JSON.stringify(stats)])
    f=FileAccess.open("res://tests/battle_results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"baseline":stats,"abilities":ability_stats},"  "));f.close()
    DirAccess.remove_absolute("user://test_battle.json")
    quit(1 if failures else 0)



