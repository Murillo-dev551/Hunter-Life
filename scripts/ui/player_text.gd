extends RefCounted
# Tradução na apresentação: IDs e registros já persistidos não são alterados.
const OUTCOMES={"victory":"Vitória","enemy_yield":"Desistência do adversário","fled":"Fuga bem-sucedida","yielded":"Rendição do personagem","incapacity":"Incapacidade de continuar"}
const ADVENTURES={"delivery":"Entrega da Serra","survey":"Levantamento da Trilha","nen":"Aprendizado dos fundamentos do Nen","escort":"Escolta de um comerciante","ruins":"Expedição às ruínas"}
static func outcome(id: String) -> String:
    return OUTCOMES.get(id,"Resultado do confronto")
static func history(entry: String) -> String:
    var prefix: String="Aventura concluída: "
    if entry.begins_with(prefix):
        var id: String=entry.trim_prefix(prefix)
        if ADVENTURES.has(id):return prefix+ADVENTURES[id]
    return entry
