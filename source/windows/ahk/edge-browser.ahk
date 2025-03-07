#SingleInstance Force  ; Ensures only one instance of this script is running

; Function to collapse side panel in Microsoft Edge
CollapseMsEdgeSidePanel() {
    ; Get all Microsoft Edge windows
    edgeWindows := WinGetList("ahk_exe msedge.exe")

    ; Loop through each Edge window
    for windowID in edgeWindows {
        WinActivate("ahk_id " windowID)

        ; Wait for window to activate
        WinWaitActive("ahk_id " windowID, , 1)

        ; Send keyboard shortcut to toggle side panel (Ctrl+Shift+.)
        Send("^+.")

        ; Small delay between windows
        Sleep(500)
    }
}

; Run the function when script is executed
CollapseMsEdgeSidePanel()

; Optional hotkey to run the function again if needed (Ctrl+Alt+E)
^!e:: CollapseMsEdgeSidePanel()
