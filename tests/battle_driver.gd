extends RefCounted
static func resolve(s) -> void:
    var turns: int=0
    while s.Battle.active(s) and turns<30:
        var action: String="defend" if s.battle["intent"]=="charge" and s.battle["last"]!="defend" else "attack"
        s.Battle.act(s,action,s.battle["turn"]);turns+=1
