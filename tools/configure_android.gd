extends SceneTree

func _initialize() -> void:
    var sdk := OS.get_environment("ANDROID_SDK_ROOT")
    if sdk.is_empty():
        sdk = OS.get_environment("ANDROID_HOME")
    var jdk := OS.get_environment("JAVA_HOME")
    if sdk.is_empty() or jdk.is_empty():
        push_error("ANDROID_SDK_ROOT and JAVA_HOME required")
        quit(1)
        return
    var settings := EditorInterface.get_editor_settings()
    settings.set_setting("export/android/android_sdk_path", sdk)
    settings.set_setting("export/android/java_sdk_path", jdk)
    settings.save()
    print("Configured Android export paths")
    quit()
