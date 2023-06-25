extends HTTPRequest

var thread: Thread = Thread.new()
var mutex: Mutex = Mutex.new()
var close_request: bool = false
var monitor_dict: Dictionary = {}

var config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	request_completed.connect(_on_request_completed)
	thread.start(toggle_session)
	thread.wait_to_finish()
	
	monitor_on_init()

func _notification(what) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().set_auto_accept_quit(false)
		thread.start(toggle_session)
		thread.wait_to_finish()
		close_request = true

func toggle_session() -> void:
	mutex.lock()
	config.load("res://addons/pogr_plugin/pogr.cfg")
	request("http://postman-echo.com/get", ["CLIENT_ID: " + config.get_value("api","client_id",""), "BUILD_ID: " + config.get_value("api","build_id","")], HTTPClient.METHOD_GET)
	mutex.unlock()

func _on_request_completed(_result, _response_code, _headers, body) -> void:
	var json: Dictionary = JSON.parse_string(body.get_string_from_utf8())
	if(json["headers"]):
		print(json["headers"])
	if(close_request):
		get_tree().quit()

func _exit_tree() -> void:
	thread.wait_to_finish()

func monitor_on_init():
	monitor_dict = {
		"Engine": "Godot Engine " + Engine.get_version_info().string,
		"OS": {
			"name": OS.get_name(),
			"distro": OS.get_distribution_name(),
			"version": OS.get_version()
		},
		"device": OS.get_model_name(),
		"unique_id": OS.get_unique_id(),
		"processor": {
			"name": OS.get_processor_name(),
			"count": OS.get_processor_count()	
		},
		"gpu": {
			"name": RenderingServer.get_video_adapter_name(),
			"vendor": RenderingServer.get_video_adapter_vendor(),
			"driver_info": OS.get_video_adapter_driver_info(),
			"api_version": RenderingServer.get_video_adapter_api_version(),
			"fps": Engine.get_frames_per_second()
		},
	}
	if(OS.has_feature("editor")):
		monitor_dict.merge({"build_type": "editor"})
	elif(OS.has_feature("debug")):
		monitor_dict.merge({"build_type": "debug"})
	elif(OS.has_feature("release")):
		monitor_dict.merge({"build_type": "release"})
	_on_monitor_timer_timeout()

func _on_monitor_timer_timeout() -> void:# add setting to disable that and add missing values like max memory and much more via cpp
	monitor_dict.merge({
		"language": OS.get_locale(),
		"time": "{year}-{month}-{day} {hour}:{minute}:{second}".format(Time.get_datetime_dict_from_system(true)),
		"memory": {
			"max_physical": pogr_plugin.get_sys_monitor_info().max_phys_memory,
			"free_physical": pogr_plugin.get_sys_monitor_info().free_phys_memory,
			"max_virtual": pogr_plugin.get_sys_monitor_info().max_virt_memory,
			"free_virtual": pogr_plugin.get_sys_monitor_info().free_virt_memory,
			"max_pagefile": pogr_plugin.get_sys_monitor_info().max_page_memory,
			"free_pagefile": pogr_plugin.get_sys_monitor_info().free_page_memory,
		},
		"mobile_permissions": OS.get_granted_permissions()
	},true)
	monitor_dict["gpu"].merge({ "fps": Engine.get_frames_per_second() },true) # changes value inside other key
	print(monitor_dict)
	$MonitorTimer.start()
