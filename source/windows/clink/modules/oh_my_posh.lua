local script_dir = path.normalise(debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]])
local mycelio_root_dir = path.normalise(script_dir .. "../../../..")

local home = os.getenv("HOME") or os.getenv("USERPROFILE")
local mycelio_config = path.normalise(mycelio_root_dir .. "/packages/shell/.poshthemes/mycelio.omp.json")
local local_oh_my_posh_executable = ""
local oh_my_posh_executable = ""
local loaded = false
local values = {
    home .. "/AppData/Local/Programs/oh-my-posh/bin/oh-my-posh.exe",
    home .. "/.local/go/bin/oh-my-posh.exe",
    "C:\\Program Files (x86)\\oh-my-posh\\bin\\oh-my-posh.exe"
}

for key, value in pairs(values) do
    if os.isfile(local_oh_my_posh_executable) then
        break
    else
        if local_oh_my_posh_executable ~= "" then
            logger.debug('Oh My Posh not found: ' .. local_oh_my_posh_executable)
        end
        local_oh_my_posh_executable = path.normalise(value)
    end
end

if not os.isfile(local_oh_my_posh_executable) then
    logger.warning('Oh My Posh not found: ' .. local_oh_my_posh_executable)
end

if not os.isfile(mycelio_config) then
    logger.warning('Oh My Posh config missing: ' .. mycelio_config)
end

if os.isfile(local_oh_my_posh_executable) and os.isfile(mycelio_config) then
    local_oh_my_posh_executable = "\"" .. local_oh_my_posh_executable .. "\""
    io.popen(local_oh_my_posh_executable .. " --version")
    if not os.geterrorlevel == 0 then
        logger.warning('Oh My Posh version test failed: \'' .. local_oh_my_posh_executable .. '\'')
    else
        oh_my_posh_executable = local_oh_my_posh_executable
        local process = io.popen(oh_my_posh_executable .. " init cmd --config " .. mycelio_config)
        if process ~= nil then
            local command = process:read("*a")
            load(command)()
            logger.info('Initialized Oh My Posh: ' .. local_oh_my_posh_executable)
        else
            logger.error('Oh My Posh init failed: ' .. local_oh_my_posh_executable)
        end
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
