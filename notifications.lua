-- Lua script
-- Made for OBS Studio
-- Made by: @CoccodrillooXDS
-- MIT License

-- Import OBS libraries and create global variables
obs = obslua
script_path = ""
version = "2.0.0"
OS_TYPE = nil

-- Function to detect the OS and if linux, detect flatpak usage
function detect_os()
    if package.config:sub(1,1) == '\\' then
        return "win"
    elseif package.config:sub(1,1) == '/' then
        if os.execute('uname -s | grep Darwin > /dev/null') == 0 then
            return "mac"
        elseif os.execute('flatpak-spawn --help > /dev/null') == 0 then
            return "linux-flatpak"
        else
            return "linux"
        end
    end
end

-- Function to send a notification to the desktop
-- OS: Windows, macOS, Linux
-- Windows: Requires BurntToast module for PowerShell (gets installed during the script_load phase)
-- macOS: Requires a modern version of macOS
-- Linux: Requires notify-send
function send_notification(title, message)
    -- Check if the OS is Windows, macOS or Linux and send the notification accordingly
    if OS_TYPE == "win" then
        -- Windows
        local file = io.open(script_path .. 'notifications.txt', 'w')
        file:write(title .. ',' .. message .. '\n')
        file:close()
    elseif OS_TYPE == "mac" then
        os.execute('osascript -e \'display notification "' .. message .. '" with title "' .. title .. '"\'')
    elseif OS_TYPE == "linux-flatpak" then
        os.execute('flatpak-spawn --host notify-send "' .. title .. '" "' .. message .. '"')
    elseif OS_TYPE == "linux" then
        os.execute('notify-send "' .. title .. '" "' .. message .. '"')
    end
end

-- Function to handle OBS events
-- OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED: When the replay buffer saves a replay
-- OBS_FRONTEND_EVENT_STREAMING_STARTED: When the stream starts
-- OBS_FRONTEND_EVENT_STREAMING_STOPPED: When the stream stops
-- OBS_FRONTEND_EVENT_RECORDING_STARTED: When the recording starts
-- OBS_FRONTEND_EVENT_RECORDING_STOPPED: When the recording stops
function on_event(event)
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
        print("Replay Saved")
        send_notification('Instant Replay', 'Saved replay!')
    end
    if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED then
        print("Streaming Started")
        send_notification('Streaming', 'Stream started!')
    end
    if event == obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED then
        print("Streaming Stopped")
        send_notification('Streaming', 'Stream stopped!')
    end
    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
        print("Recording Started")
        send_notification('Recording', 'Recording started!')
    end
    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
        print("Recording Stopped")
        send_notification('Recording', 'Recording stopped!')
    end
end

-- OBS function
function script_properties()
    local props = obs.obs_properties_create()
    return props
end

-- Script description for the OBS Scripts dialog
function script_description()
    return "Sends a notification to the desktop when something happens.\n\nMade by @CoccodrillooXDS\nVersion: " .. version
end

-- OBS function when the script gets loaded
function script_load(settings)
    print("Loading script...")
    OS_TYPE = detect_os()
    -- Check if the OS is Windows and, if so, launch the PowerShell script with the setup argument
    if package.config:sub(1,1) == '\\' then
        -- Windows
        print("The BurntToast module is required for this script to work on Windows. Checking if it's installed...")

        local info = debug.getinfo(1, "S")
        script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

        os.execute('start /min conhost powershell -ExecutionPolicy Bypass -File "' .. script_path .. 'notifications.ps1" setup')

    end
    print("Script loaded. OS: " .. OS_TYPE)
    -- send_notification("test", "debug")
    -- Add the event callback function to the OBS events
    obs.obs_frontend_add_event_callback(on_event)
end
