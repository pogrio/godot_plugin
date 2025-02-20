#include "pogr_plugin.h"
#include <stdio.h>
#ifdef _WIN32
#include <Windows.h>
#endif
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/editor_plugin.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/os.hpp>
#include <godot_cpp/variant/array.hpp>

pogr_plugin *pogr_plugin::singleton = nullptr;

void pogr_plugin::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("debug"), &pogr_plugin::debug);
    ClassDB::bind_method(D_METHOD("get_sys_monitor_info"), &pogr_plugin::get_sys_monitor_info);
}

pogr_plugin *pogr_plugin::get_singleton()
{
    return singleton;
}
pogr_plugin::pogr_plugin()
{
    singleton = this;
}
pogr_plugin::~pogr_plugin()
{
    singleton = nullptr;
}

void pogr_plugin::debug()
{
#ifdef _WIN32
    MEMORYSTATUSEX statex;

    statex.dwLength = sizeof(statex);

    GlobalMemoryStatusEx(&statex);
    UtilityFunctions::print(vformat("Maximum RAM capacity in KB: %s", statex.ullTotalPhys / 1024));
#endif
}

Dictionary pogr_plugin::get_sys_monitor_info()
{
    Dictionary sys_monitor_info;
    sys_monitor_info["max_phys_memory"] = "unknown";
    sys_monitor_info["free_phys_memory"] = "unknown";
    sys_monitor_info["max_page_memory"] = "unknown";
    sys_monitor_info["free_page_memory"] = "unknown";
    sys_monitor_info["max_virt_memory"] = "unknown";
    sys_monitor_info["free_virt_memory"] = "unknown";
    String cpu_percent = "unknown";
#ifdef _WIN32
    MEMORYSTATUSEX statex;
    statex.dwLength = sizeof(statex);
    GlobalMemoryStatusEx(&statex);
    sys_monitor_info["max_phys_memory"] = statex.ullTotalPhys;
    sys_monitor_info["free_phys_memory"] = statex.ullAvailPhys;
    sys_monitor_info["max_page_memory"] = statex.ullTotalPageFile;
    sys_monitor_info["free_page_memory"] = statex.ullAvailPageFile;
    sys_monitor_info["max_virt_memory"] = statex.ullTotalVirtual;
    sys_monitor_info["free_virt_memory"] = statex.ullAvailVirtual;
    // CPU Percentage
    // TODO: Fix
    /*PackedStringArray cpupercentoutput;
    PackedStringArray args;
    args.push_back("cpu");
    args.push_back("get");
    args.push_back("loadpercentage");
    OS p_os;
    p_os.execute("wmic", args, cpupercentoutput, true);
    cpu_percent = String(cpupercentoutput[0]).split(",")[2].strip_escapes();*/
#endif
    sys_monitor_info["cpu_load_percentage"] = cpu_percent;

    sys_monitor_info.make_read_only();
    return sys_monitor_info;
}