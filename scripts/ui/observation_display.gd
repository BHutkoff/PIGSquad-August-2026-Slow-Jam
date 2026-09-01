class_name ObservationDisplay
extends CanvasLayer

@export_range(0.5, 10.0, 0.1) var display_duration: float = 7.0
@export_range(0.1, 3.0, 0.1) var fade_duration: float = 0.5

@export_category("Layout")
@export_range(0.3, 0.7, 0.05) var panel_width_ratio: float = 0.5
@export_range(100.0, 320.0, 4.0) var maximum_layout_height: float = 220.0
@export_range(8.0, 96.0, 2.0) var bottom_margin: float = 32.0
@export_range(8, 40, 1) var content_padding: int = 18
@export_range(240.0, 480.0, 8.0) var banner_width: float = 360.0
@export_range(36.0, 96.0, 2.0) var banner_height: float = 76.0
@export_range(0.0, 24.0, 1.0) var banner_gap: float = 6.0

@export_category("Text")
@export_range(14, 30, 1) var observation_font_size: int = 20
@export_range(24, 44, 1) var banner_font_size: int = 28

@onready var observation_anchor: VBoxContainer = $UIRoot/ObservationAnchor
@onready var panel: PanelContainer = $UIRoot/ObservationAnchor/Panel
@onready var margin: MarginContainer = $UIRoot/ObservationAnchor/Panel/Margin
@onready var observation_label: Label = $UIRoot/ObservationAnchor/Panel/Margin/ObservationLabel
@onready var discovery_label: Label = (
	$UIRoot/ObservationAnchor/Panel/Margin/ObservationLabel/DiscoveryLabel
)

var _time_remaining: float = 0.0


func _ready() -> void:
	_apply_layout()
	panel.visible = false
	discovery_label.visible = false
	set_process(false)


func _process(delta: float) -> void:
	_time_remaining -= delta
	if _time_remaining <= 0.0:
		panel.visible = false
		discovery_label.visible = false
		set_process(false)
		return

	var fade_start: float = minf(fade_duration, display_duration)
	var alpha: float = clampf(_time_remaining / maxf(fade_start, 0.001), 0.0, 1.0)
	panel.modulate.a = alpha
	discovery_label.modulate.a = alpha


func show_observation(message: String, clue_discovered: bool = false) -> void:
	observation_label.text = message
	discovery_label.visible = clue_discovered

	if clue_discovered:
		discovery_label.text = "CLUE DISCOVERED - C Key - Open Case Review"
	else:
		discovery_label.text = ""

	_apply_content_padding()
	_time_remaining = display_duration
	panel.modulate.a = 1.0
	discovery_label.modulate.a = 1.0
	panel.visible = true
	set_process(true)


func _apply_layout() -> void:
	var half_width: float = panel_width_ratio * 0.5
	observation_anchor.anchor_left = 0.5 - half_width
	observation_anchor.anchor_top = 1.0
	observation_anchor.anchor_right = 0.5 + half_width
	observation_anchor.anchor_bottom = 1.0
	observation_anchor.offset_left = 0.0
	observation_anchor.offset_top = -bottom_margin - maximum_layout_height
	observation_anchor.offset_right = 0.0
	observation_anchor.offset_bottom = -bottom_margin
	observation_label.label_settings.font_size = observation_font_size
	discovery_label.label_settings.font_size = banner_font_size
	_apply_content_padding()


func _apply_content_padding() -> void:
	margin.add_theme_constant_override("margin_left", content_padding)
	margin.add_theme_constant_override("margin_top", content_padding)
	margin.add_theme_constant_override("margin_right", content_padding)
	margin.add_theme_constant_override("margin_bottom", content_padding)
	discovery_label.anchor_left = 1.0
	discovery_label.anchor_top = 0.0
	discovery_label.anchor_right = 1.0
	discovery_label.anchor_bottom = 0.0
	discovery_label.offset_left = float(content_padding) - banner_width
	discovery_label.offset_top = -float(content_padding) - banner_gap - banner_height
	discovery_label.offset_right = float(content_padding)
	discovery_label.offset_bottom = -float(content_padding) - banner_gap
