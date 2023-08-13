-- luacheck: globals clink.promptcoroutine io.popenyield

-- Custom script to setup Oh My Posh.
-- @type fun(string):string?
local function omp_cli(omp, config_file)
    local args = '"' .. omp .. '" init cmd'
    -- args = '"' .. oh_my_posh_executable .. '"' .. ' init cmd --config "' .. mycelio_config .. '"'
    print('##[cmd] ' .. args)

    local file_handle
    local pclose

    ---@type string?
    local out = nil
    local code = 99
    local ok = false
    local what = ''
    local loaded = false

    command = '"' .. args .. '"'
    local _, ismain = coroutine.running()
    local output
    if ismain then
        file_handle, pclose = io.popen(command)
    else
        file_handle, pclose = io.popenyield(command)
    end

    if file_handle then
        out = ''
        while (true) do
            local line = file_handle:read("*line")
            if not line then
                break
            end
            out = out .. line
        end

        file_handle:close()

        if pclose then
            ok, what, code = pclose()
        elseif out then
            ok = true
            code = 0
        end

        -- print(lua_setup)
        local result, syntaxError = load(out, nil, "t")
        if not result then
            print("There was a syntax error:", syntaxError)
        else
            result(config_file)
            print('[clink] Initialized Oh My Posh: \'' .. omp .. '\'')
            loaded = true
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

    return out, code
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

---@type string
local script_dir = path.normalise(debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]])
---@type string
local mycelio_root_dir = path.normalise(script_dir .. "../../..")

local home = os.getenv("HOME") or os.getenv("USERPROFILE") or "~"

---@type string?
local mycelio_config = path.normalise(mycelio_root_dir .. "/packages/shell/.poshthemes/mycelio.omp.json", '\\')

---@type boolean
local loaded = false

---@type string
local local_oh_my_posh_executable = path.normalise(home .. "/.local/go/bin/oh-my-posh.exe", '\\')

---@type string
local global_exe = path.normalise([[C:/Program Files (x86)/oh-my-posh/bin/oh-my-posh.exe]], '\\')

---@type string?
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
    local lua_setup, exit_code = omp_cli(oh_my_posh_executable)
    if not exit_code == 0 then
        print('[clink] WARNING: Oh My Posh version test failed: \'' .. oh_my_posh_executable .. '\'')
    elseif not lua_setup then
        print('[clink] WARNING: Oh My Posh initialization did not return setup script: \'' .. oh_my_posh_executable .. '\'')
    end
end
