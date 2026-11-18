extends PanelContainer
class_name ConfirmNewName

signal input_submitted(text: String)
signal input_canceled()

@onready var line_edit := %NewNameEdit as LineEdit
@onready var confirm_btn := %ConfirmButt as Button
@onready var cancel_btn := %CancelButt as Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	confirm_btn.button_up.connect(confirm)
	cancel_btn.button_up.connect(cancel)


func open():
	line_edit.text = ''
	line_edit.grab_focus()
	self.visible = true

func confirm():
	input_submitted.emit(line_edit.text)
	self.visible = false

func cancel():
	input_canceled.emit()
	self.visible = false