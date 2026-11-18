extends RefCounted
# XP é saldo para o próximo nível: 80, 120, 160... Sem segunda rolagem.
static func threshold(level: int) -> int:
    return 80+40*(level-1)
static func chance(attribute: int, difficulty: int) -> int:
    var successes: int=0
    for roll in range(1,21):
        if roll+attribute>=difficulty: successes+=1
    return successes*5
static func room(state) -> int:
    var total: int=0
    for value in state.attributes.values(): total+=10-int(value)
    return total
static func award(state, amount: int) -> int:
    var old: int=state.level
    state.xp+=maxi(0,amount)
    while state.xp>=threshold(state.level):
        state.xp-=threshold(state.level)
        state.level+=1
        state.points=mini(room(state),state.points+1)
    return state.level-old
static func spend(state, attribute: String) -> bool:
    if state.health<=0 or state.character_name.is_empty() or state.points<=0 or not state.attributes.has(attribute) or int(state.attributes[attribute])>=10: return false
    state.attributes[attribute]=int(state.attributes[attribute])+1
    state.points-=1
    state.records.append("Ponto distribuído: %s agora é %d." % [state.ATTRIBUTE_NAMES[attribute],state.attributes[attribute]])
    return true
