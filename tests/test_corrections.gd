extends SceneTree
# Regressões da revisão 0.1.2: atalhos de eventos, conclusão do Nen e retomada de Ten.
const State=preload("res://scripts/game_state.gd")
const Storage=preload("res://scripts/storage.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok: failures+=1;push_error(text)
func battle_choice(s) -> int:
    for i in range(s.demo["choices"].size()):
        if s.demo["choices"][i].has("battle"):return i
    return -1
func roundtrip(s,label: String) -> void:
    var path: String="user://test_corrections.json"
    check(Storage.save(s,path)=="","Salva: "+label)
    var loaded: Dictionary=Storage.load_state(path,false)
    check(loaded["error"]=="","Carrega: "+label+" "+str(loaded.get("error","")))
    if loaded["error"]=="":check(loaded["state"].serialize()==s.serialize(),"Continuidade integral: "+label)
func run() -> void:
    # Atalhos da aba Personagem depois de um confronto encerrado não herdam a batalha.
    for target in ["crossroads","exam_info","nen_ten","nen_water"]:
        var s=State.new();s.start("Atalho");s.rng.seed=11;s.rng.state=11
        s.open_event("battle_bandit")
        check(s.choose(battle_choice(s)) and s.Battle.active(s),"Confronto iniciado antes de "+target)
        var guard: int=0
        while s.Battle.active(s) and guard<40:
            var action: String="flee" if s.health>3 else "yield"
            s.Battle.act(s,action,int(s.battle["turn"]));guard+=1
        check(not s.Battle.active(s) and s.health>0,"Confronto encerrado sem incapacidade")
        s.open_event(target)
        check(s.battle.is_empty() and s.pending_next=="" and s.current_id==target,"Atalho limpa confronto e continuação: "+target)
        roundtrip(s,"atalho "+target)
    # Conclusão da aventura de Nen depois do teste da água.
    var n=State.new();n.start("Mira")
    n.open_event("nen_offer");n.choose(0);n.advance()
    n.choose(0);n.advance()
    n.choose(1);n.advance()
    n.choose(0);n.advance()
    check(n.current_id=="nen_water","Chega ao teste da água")
    n.choose(0);n.advance()
    check(n.current_id=="nen_done","Chega ao encerramento")
    n.choose(0)
    check("nen" in n.completed and n.nen["water_done"],"Nen registrado entre as aventuras concluídas")
    roundtrip(n,"Nen concluído")
    # Adiar o teste da água não conclui a aventura; realizá-lo depois conclui.
    var p=State.new();p.start("Adiar")
    p.open_event("nen_offer");p.choose(0);p.advance();p.choose(0);p.advance();p.choose(1);p.advance();p.choose(0);p.advance()
    p.choose(1);p.advance();p.choose(0)
    check("nen" not in p.completed,"Adiar o teste não conclui a aventura")
    p.advance();p.open_event("nen_water");p.choose(0);p.advance();p.choose(0)
    check("nen" in p.completed,"Teste realizado depois conclui a aventura")
    # Retomar o convite depois de interromper Ten concede o XP normal da prática.
    var r=State.new();r.start("Retomar")
    r.open_event("nen_offer");r.choose(0);r.advance();r.choose(1);r.advance()
    var before: int=r.xp+r.level*1000
    r.open_event("nen_ten");r.choose(0)
    check(r.xp+r.level*1000>before and "+8 XP" in r.result,"Ten retomado concede XP")
    print("CORREÇÕES 0.1.2: %d verificações, %d falhas" % [checks,failures])
    quit(1 if failures>0 else 0)
