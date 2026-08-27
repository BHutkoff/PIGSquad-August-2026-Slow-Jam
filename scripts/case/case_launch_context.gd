extends Node

var _skip_case1_intro_once: bool = false


func begin_normal_case1() -> void:
	_skip_case1_intro_once = false


func request_case1_retry() -> void:
	_skip_case1_intro_once = true


func consume_case1_intro_skip() -> bool:
	var should_skip: bool = _skip_case1_intro_once
	_skip_case1_intro_once = false
	return should_skip

