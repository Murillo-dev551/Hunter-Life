extends RefCounted
## Capture only around a committed player action, never around rendering/loading.
static func snapshot(s) -> Dictionary:
    return {"level":s.level,"xp":s.xp,"jenny":s.jenny,"health":s.health,"items":s.inventory["items"].duplicate()}
static func changes(before: Dictionary,s,text: String) -> Dictionary:
    var acquired: Array[String]=[]
    for id in s.inventory["items"]:
        if s.inventory["items"][id]>before.items.get(id,0):acquired.append(id)
    return {"success":"· sucesso" in text,"failure":"· fracasso" in text,
        "level":s.level>before.level,"xp":s.xp>before.xp or s.level>before.level,
        "money":s.jenny>before.jenny,"damage":s.health<before.health,
        "items":acquired,"license":"hunter_license" in acquired,
        "ended":not s.battle.is_empty() and s.battle.get("outcome","")!=""}
