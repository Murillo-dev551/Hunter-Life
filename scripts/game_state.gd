extends RefCounted
# Uma sessão em memória. Sem motor de eventos, economia ou salvamento nesta etapa.
const INITIAL_ATTRIBUTES = {"strength":5,"agility":5,"intellect":5,"presence":5}
const ATTRIBUTE_NAMES = {"strength":"Força","agility":"Agilidade","intellect":"Intelecto","presence":"Presença"}
var character_name: String = ""
var attributes: Dictionary = INITIAL_ATTRIBUTES.duplicate()
var selected_choice: int = -1
var records: Array[String] = []
var demo: Dictionary = {}
var error: String = ""
func _init() -> void:
    var file = FileAccess.open("res://data/demo_event.json",FileAccess.READ)
    if not file:
        error = "Não foi possível carregar a demonstração."
        return
    var parser = JSON.new()
    if parser.parse(file.get_as_text()) != OK:
        error = "O arquivo da demonstração está inválido."
        return
    var value: Variant = parser.data
    if not value is Dictionary or not value.get("title") is String or not value.get("chapter") is String or not value.get("paragraphs") is Array or not value.get("choices") is Array:
        error = "A demonstração está incompleta."
        return
    if value["choices"].size() != 3:
        error = "A demonstração precisa de três escolhas."
        return
    for paragraph in value["paragraphs"]:
        if not paragraph is String: error = "Texto demonstrativo inválido."; return
    for choice in value["choices"]:
        if not choice is Dictionary or not choice.get("label") is String or not choice.get("result") is String:
            error = "Escolha demonstrativa inválida."
            return
    demo = value
func start(raw_name: String) -> String:
    var clean: String = raw_name.strip_edges().replace("\n"," ").replace("\r"," ").replace("\t"," ")
    if clean.is_empty(): return "Dê um nome ao personagem para começar."
    if clean.length() > 32: return "Use um nome com até 32 caracteres."
    if error != "": return error
    character_name = clean
    attributes = INITIAL_ATTRIBUTES.duplicate()
    selected_choice = -1
    records.assign(["A jornada de %s começou. Os quatro atributos iniciais são 5." % character_name])
    return ""
func choose(index: int) -> bool:
    if character_name.is_empty() or selected_choice != -1 or index < 0 or index >= demo.get("choices",[]).size(): return false
    selected_choice = index
    records.append("%s — %s" % [demo["title"],demo["choices"][index]["label"]])
    records.append(demo["choices"][index]["result"])
    return true
