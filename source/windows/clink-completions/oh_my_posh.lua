local script_dir = path.normalise(debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]])
local mycelio_root_dir = path.normalise(script_dir .. "../../..")

local home = os.getenv("HOME") or os.getenv("USERPROFILE")
local mycelio_config = path.normalise(mycelio_root_dir .. "/packages/shell/.poshthemes/mycelio.omp.json")
local local_oh_my_posh_executable = path.normalise(home .. "/.local/go/bin/oh-my-posh.exe")
local oh_my_posh_executable = ""
local loaded = false

if not os.isfile(local_oh_my_posh_executable) then
    print('[clink] Oh My Posh not found: ' .. local_oh_my_posh_executable)
elseif not os.isfile(mycelio_config) then
    print('[clink] Oh My Posh config missing: ' .. mycelio_config)
else
    io.popen(local_oh_my_posh_executable .. " --version")
    if not os.geterrorlevel == 0 then
        print('[clink] WARNING: Oh My Posh version test failed: \'' .. local_oh_my_posh_executable .. '\'')
    else
        oh_my_posh_executable = local_oh_my_posh_executable
        local process = io.popen(oh_my_posh_executable .. " init cmd --config " .. mycelio_config)
        local command = process:read("*a")
        load(command)()
        print('[clink] Initialized Oh My Posh: \'' .. local_oh_my_posh_executable .. '\'')
        loaded = true
    end
end

if not loaded then
    -- A prompt filter that adds a line feed and angle bracket.
    local bracket_prompt = clink.promptfilter(150)
    function bracket_prompt:filter(prompt)
        return prompt .. "\n → "
    end
end
