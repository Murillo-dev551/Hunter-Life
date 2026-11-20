extends SceneTree
## Run against the v0.1.1 Git archive to produce genuine save-v10 evidence.
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var s=State.new();s.rng.seed=777;s.start("Caderno anterior",0,"female")
    assert(s.catalog.events.size()==174 and s.serialize().version==10)
    var catalog=[]
    for event in s.catalog.events.values():catalog.append(event)
    var path="user://generated_v011/";DirAccess.make_dir_recursive_absolute(path)
    FileAccess.open(path+"catalog.sha256",FileAccess.WRITE).store_string(JSON.stringify(catalog).sha256_text())
    s.open_event("c_ferry_offer");s.choose(0);s.advance()
    assert(Store.save(s,path+"mission.json")=="" and Store.load_state(path+"mission.json",false).error=="")
    s.open_event("battle_bandit");s.choose(0);s.Battle.act(s,"defend",s.battle.turn)
    assert(Store.save(s,path+"battle.json")=="" and Store.load_state(path+"battle.json",false).error=="")
    s.Battle.act(s,"attack",s.battle.turn);assert(Store.save(s,path+"battle_next.json")=="")
    print("Fixtures v0.1.1 e hash do catálogo produzidos.")
    var audio=root.get_node_or_null("Audio")
    if audio:await audio.shutdown()
    quit()
