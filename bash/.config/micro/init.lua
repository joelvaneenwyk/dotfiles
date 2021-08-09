local config = import("micro/config")
local shell = import("micro/shell")
local micro = import("micro")

function init()
    micro.Log("Custom 'dotfiles' configuration.")

    micro.InfoBar():Message("Initialized 'mycelio' configuration. Use 'F2' to save and 'F4' to exit.")

    shell.RunCommand("plugin install gotham-colors")
    shell.RunCommand("set colorscheme gotham-colors")

    -- true means overwrite any existing binding to Ctrl-r
    -- this will modify the bindings.json file
    config.TryBindKey("Ctrl-Shift-r", "lua:initlua.gorun", true)
end

function gorun(bp)
    local buf = bp.Buf
    if buf:FileType() == "go" then
        -- the true means run in the foreground
        -- the false means send output to stdout (instead of returning it)
        shell.RunInteractiveShell("go run " .. buf.Path, true, false)
    end
end

