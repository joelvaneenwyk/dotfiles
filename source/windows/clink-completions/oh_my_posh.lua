local script_dir = path.normalise(debug.getinfo(1, "S").source:match[[^@?(.*[\/])[^\/]-$]])
local mycelio_root_dir = path.normalise(script_dir .. "../../..")

local home = os.getenv("HOME") or os.getenv("USERPROFILE")
local ohmyposh_executable = path.normalise(home .. "/.local/go/bin/oh-my-posh.exe")
local mycelio_config = path.normalise(mycelio_root_dir .. "/packages/linux/.poshthemes/mycelio.omp.json")

if not os.isfile(ohmyposh_executable) then
    print('[clink] Oh My Posh not found: ' .. ohmyposh_executable)
elseif not os.isfile(mycelio_config) then
    print('[clink] Oh My Posh config missing: ' .. mycelio_config)
else
    io.popen(ohmyposh_executable .. " --version")
    if not os.geterrorlevel == 0 then
        print('[clink] ⚠ Oh My Posh version test failed: \'' .. ohmyposh_executable .. '\'')
        ohmyposh_executable = ""
    else
        print('[clink] ✔ Using Oh My Posh: \'' .. ohmyposh_executable .. '\'')
    end
end

local ohmyposh_executable_prompt = clink.promptfilter(1)
function ohmyposh_executable_prompt:filter(prompt)
    if ohmyposh_executable ~= '' then
        prompt = io.popen(ohmyposh_executable .. " --config " .. mycelio_config):read("*a")
        return prompt, false
    end
end
