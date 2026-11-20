extends SceneTree
## Execute against the v0.1.0 Git archive, not the current project.
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
func _initialize() -> void:call_deferred("run")
func fresh():
    var s=State.new();s.rng.seed=777;s.start("Registro anterior");return s
func save_fixture(s,name: String) -> void:
    assert(s.serialize().version==9)
    var directory="user://generated_v010/";DirAccess.make_dir_recursive_absolute(directory)
    assert(Store.save(s,directory+name+".json")=="")
    assert(Store.load_state(directory+name+".json",false).error=="")
func run() -> void:
    var s=fresh();s.open_event("market");s.active_adventure=false;s.current_adventure="";save_fixture(s,"independent")
    s=fresh();s.open_event("escort_offer");s.choose(0);s.advance();save_fixture(s,"mission")
    s=fresh();s.open_event("battle_bandit");s.active_adventure=false;s.current_adventure="";s.choose(0);s.Battle.act(s,"defend",s.battle.turn);save_fixture(s,"battle")
    s.Battle.act(s,"attack",s.battle.turn);save_fixture(s,"battle_next")
    s=fresh();s.active_adventure=false;s.current_adventure=""
    s.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":"Especialização"}
    for technique in s.nen.techniques:s.flags["nen_"+technique]=true
    s.open_event("affinity_offer");s.choose(0);s.advance();s.choose(2);s.advance();save_fixture(s,"affinity")
    print("Cinco fixtures v9 geradas pelo código da tag v0.1.0.")
    var audio=root.get_node_or_null("Audio")
    if audio:await audio.shutdown()
    quit()
