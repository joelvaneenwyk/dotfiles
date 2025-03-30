;;
;; start-fork-gui.ahk
;;
;; author: Joel Van Eenwyk
;;
;; This script launches the Fork Git Client and opens a specific repository.
;;
;; Usage:
;; 1. Run the script with a repository path as command-line argument
;; 2. The script will launch Fork and automatically open that repository
;; 3. A hotkey (Ctrl+Alt+F) is available to launch Fork again
;;
;; Note: If no repository path is provided, the script will show an info dialog.
;;
#Requires AutoHotkey v2.0

#SingleInstance Force  ; Ensures only one instance of this script is running

GetCurrentDirectory()
{
    currentDir := A_WorkingDir
    return currentDir
}

; Function to launch Fork Git Client from the current directory
LaunchForkFromCurrentDir(launchDir := "") {
    ; Determine the starting folder
    if launchDir == ""
    {
        MsgBox("Please run this script with the path to the repository folder as a command-line argument.", "Info")
        return
    }

    MsgBox("A_Temp: " launchDir)

    ; Define the path to the Fork executable
    ForkPath := "C:\Users\" A_UserName "\AppData\Local\Fork\current\Fork.exe"
    ForkWindowTitle := "Fork"
    OpenRepoDialogTitle := "Open Repository..."
    FolderLabelText := "Folder:"
    SelectFolderButtonText := "Select Folder"

    ; Check if Fork exists
    if !FileExist(ForkPath)
    {
        MsgBox("Fork not found at the specified path: " ForkPath, "Error")
        return
    }

    ; Launch Fork
    Run(ForkPath)

    ; Wait for Fork to start by checking for the process
    ProcessWaitClose("Fork.exe", 1)  ; First check if it's already running and closing
    ProcessWait("Fork.exe", 5)      ; Wait up to 10 seconds for Fork to start
    WinWait("ahk_exe Fork.exe", , 5) ; Wait for Fork window to appear
    WinActivate("ahk_exe Fork.exe")  ; Activate the Fork window

    ; Wait a short time after activation (adjust if needed)
    Sleep(500)

    ; Send Ctrl+O to open the "Open Repository" dialog
    Send("^o")

    ; Wait a short time for the dialog to appear (adjust if needed)
    Sleep(500)

    ; Wait for the "Open Repository..." dialog to appear
    if !WinWait(OpenRepoDialogTitle, , 5) ; Wait up to 5 seconds
    {
        MsgBox("Failed to wait for the '" OpenRepoDialogTitle "' dialog.", "Error")
        return
    }

    ; Focus on the Edit control (assuming it's a common Edit control next to "Folder:")
    ControlFocus("Edit1", OpenRepoDialogTitle)

    ; Send the directory from which the script was launched
    Send(launchDir)

    ; Wait a short time before pressing Enter
    Sleep(1000)

    ; Click the "Select Folder" button
    ControlClick(SelectFolderButtonText, OpenRepoDialogTitle)

    ; You might want to add a short delay here to allow Fork to process the selection
    Sleep(500)
}

; Get the starting folder from command-line arguments, default to empty string
startFolder := ""
if A_Args.Length > 0
    startFolder := A_Args[1]
LaunchForkFromCurrentDir(startFolder)

; Optional hotkey to launch Fork again (Ctrl+Alt+F)
^!f:: LaunchForkFromCurrentDir()
