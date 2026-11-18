extends VBoxContainer
signal start_requested(character_name: String)
const UI = preload("res://scripts/ui/styles.gd")
var name_input: LineEdit
var start_button: Button
var feedback: Label
func build(state) -> void:
    add_child(UI.label("UM NOVO CAMINHO",12,UI.GREEN))
    add_child(UI.title("Sua jornada começa aqui"))
    add_child(UI.label("Toda história precisa de alguém para vivê-la. Escolha seu caminho, com ou sem uma licença Hunter.",16,UI.MUTED))
    var form = UI.card(self)
    form.add_child(UI.label("Como você se chama?",18))
    name_input = LineEdit.new()
    name_input.placeholder_text = "Nome do personagem"
    name_input.max_length = 32
    name_input.custom_minimum_size.y = 52
    name_input.accessibility_name = "Nome do personagem"
    form.add_child(name_input)
    name_input.text_submitted.connect(func(_text): start_requested.emit(name_input.text))
    form.add_child(UI.label("Até 32 caracteres. Você poderá começar outra história na aba Personagem.",13,UI.MUTED))
    feedback = UI.label("",14,UI.ALERT)
    feedback.hide()
    form.add_child(feedback)
    var stats = UI.card(self)
    stats.add_child(UI.label("Seu ponto de partida",18))
    stats.add_child(UI.label("Quatro atributos equilibrados. Nenhuma distribuição de pontos nesta demonstração.",14,UI.MUTED))
    UI.attributes(stats,state.attributes,state.ATTRIBUTE_NAMES)
    start_button = UI.button("Iniciar nova partida",true)
    start_button.pressed.connect(func(): start_requested.emit(name_input.text))
    add_child(start_button)
    add_child(UI.label("Protótipo · Etapa 2\nOportunidades, escolhas e caminhos diferentes.",13,UI.MUTED))
func show_error(message: String) -> void:
    feedback.text = message
    feedback.show()
    name_input.grab_focus()

