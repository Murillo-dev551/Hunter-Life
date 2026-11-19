extends ScrollContainer
## Route pointer input to Godot's own scrolling. No gesture recognition here.
var touch_navigation: bool=false
var refresh_pending: bool=false
func _ready() -> void:
    if OS.get_name()=="Android":enable_touch_navigation()
func enable_touch_navigation() -> void:
    touch_navigation=true
    scroll_deadzone=12
    # Touching a partly visible button must not jump to its focus position.
    follow_focus=false
    _prepare_branch(self)
func _schedule_refresh(_node: Node=null) -> void:
    if not touch_navigation or refresh_pending:return
    refresh_pending=true
    call_deferred("_refresh")
func _refresh() -> void:
    refresh_pending=false
    _prepare_branch(self)
func _prepare_branch(node: Node) -> void:
    if node==get_v_scroll_bar() or node==get_h_scroll_bar():return
    if node!=self and node is ScrollContainer:return
    if node!=self and node is Control and (node is Button or node is Container or node is ProgressBar):
        # Keep sliders, text input and popup selectors under their native control.
        if not node is OptionButton and node.mouse_filter==Control.MOUSE_FILTER_STOP:node.mouse_filter=Control.MOUSE_FILTER_PASS
    if not node.child_entered_tree.is_connected(_schedule_refresh):node.child_entered_tree.connect(_schedule_refresh)
    for child in node.get_children():_prepare_branch(child)
