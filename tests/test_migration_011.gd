extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
const PATH="user://test_migration_011.json"
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func run() -> void:
    for name in ["independent","mission","battle","affinity"]:
        var path="res://tests/fixtures/v010/"+name+".json"
        var bytes=FileAccess.get_file_as_string(path)
        var original: Dictionary=JSON.parse_string(bytes)
        var loaded=Store.load_state(path,false)
        check(loaded.error=="","Fixture real v0.1.0: "+name+" "+loaded.error)
        if loaded.error!="":continue
        var s=loaded.state;var data: Dictionary=JSON.parse_string(JSON.stringify(s.serialize()))
        for key in original:
            if key!="version":check(data[key]==original[key],"Preserva campo v9: "+name+"/"+key)
        check(s.gender=="unspecified","Identidade antiga sem gênero presumido")
        check(FileAccess.get_file_as_string(path)==bytes,"Carregar não regrava v9")
        check(Store.save(s,PATH)=="","Nova gravação v10")
        var again=Store.load_state(PATH,false)
        check(again.error=="" and JSON.parse_string(JSON.stringify(again.state.serialize()))==data,"Continuidade v9→v10")
        if name=="battle":
            var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/v010/battle_next.json"))
            s.Battle.act(s,"attack",s.battle.turn)
            for key in expected:
                if key!="version":check(JSON.parse_string(JSON.stringify(s.serialize()))[key]==expected[key],"Mesmo turno e RNG da v0.1.0: "+key)
        if name=="affinity":
            var directory="user://test_migration_011_checkpoints/"
            check(Store.save_affinity(s,directory)=="","Checkpoint antigo preservado na migração")
            var restored=Store.restore_affinity(s,directory)
            check(restored.error=="" and restored.state.affinity==s.affinity,"Retoma avaliação com checkpoint")
            DirAccess.remove_absolute(directory+Store.affinity_key(s)+".json")
            DirAccess.remove_absolute(directory+"latest")
    var s=State.new();s.rng.seed=812;s.start("Validação");s.open_event("market")
    for bad in [{"gender":"invalid"},{"missions":{"unknown":"completed"}},{"missions":{"c_ferry":"active"}},{"missions":{"h_capture":"abandoned"}}]:
        var data=s.serialize().duplicate(true)
        for key in bad:data[key]=bad[key]
        FileAccess.open(PATH,FileAccess.WRITE).store_string(JSON.stringify(data))
        check(Store.load_state(PATH,false).error!="","Recusa estado impossível: "+str(bad))
    DirAccess.remove_absolute(PATH)
    print("MIGRAÇÃO 011: %d verificações, %d falhas" % [checks,failures])
    quit(1 if failures else 0)
