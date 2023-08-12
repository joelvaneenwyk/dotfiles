local path = require "path"
local os = require "os"
--
-- Custom script to setup Oh My Posh.
--
function omp_cli(args)
    print(args)
    local result = io.popen(args)
    local out = result and result:read("*a")
    return out
end

local function run_posh_command(command)
    command = '"' .. command .. '"'
    local _, ismain = coroutine.running()
    local output
    if ismain then
        output = io.popen(command):read("*a")
    else
        output = io.popenyield(command):read("*a")
    end
    return output
end

-- function escape(args)
--     local result = io.popen(args)
--     local out = result:read("*a")
--     return out
-- end

local script_dir = path.normalise(debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]])
local mycelio_root_dir = path.normalise(script_dir .. "../../..")

local home = os.getenv("HOME") or os.getenv("USERPROFILE")
local mycelio_config = path.normalise(mycelio_root_dir .. "/packages/shell/.poshthemes/mycelio.omp.json")
local loaded = false

local local_oh_my_posh_executable = path.normalise(home .. "/.local/go/bin/oh-my-posh.exe")
local global_exe = [[C:/Program Files (x86)/oh-my-posh/bin/oh-my-posh.exe]]
local oh_my_posh_executable = nil

if os.isfile(global_exe) then
    oh_my_posh_executable = global_exe
elseif os.isfile(local_oh_my_posh_executable) then
    oh_my_posh_executable = local_oh_my_posh_executable
end

if not os.isfile(oh_my_posh_executable) then
    print('[clink] Oh My Posh not found: ' .. oh_my_posh_executable)
    oh_my_posh_executable = nil
end

if not os.isfile(mycelio_config) then
    print('[clink] Oh My Posh config missing: ' .. mycelio_config)
    mycelio_config = nil
end

if mycelio_config and oh_my_posh_executable then
    print('[clink] Found Oh My Posh: ' .. oh_my_posh_executable)
    print('[clink] Found Oh My Posh config: ' .. mycelio_config)
    local lua_setup = omp_cli('"' .. oh_my_posh_executable .. '"' .. ' init cmd')

    if not os.geterrorlevel == 0 then
        print('[clink] WARNING: Oh My Posh version test failed: \'' .. oh_my_posh_executable .. '\'')
    elseif not lua_setup then
        print('[clink] WARNING: Oh My Posh initialization did not return setup script: \'' .. oh_my_posh_executable .. '\'')
    else
        print(lua_setup)
        local result, syntaxError = load(lua_setup, "oh_my_posh_init", "t", _ENV)
        if not result then
            print("There was a syntax error:", syntaxError)
        else
            print('[clink] Initialized Oh My Posh: \'' .. oh_my_posh_executable .. '\'')
            -- result(mycelio_config)
            loaded = true
        end
    end
end

if not loaded then
    -- A prompt filter that adds a line feed and angle bracket.
    local bracket_prompt = clink.promptfilter(150)
    function bracket_prompt:filter(prompt)
        return prompt .. "\n → "
    end
    print('[clink] Initialized backup prompt since Oh My Posh failed.')
end
