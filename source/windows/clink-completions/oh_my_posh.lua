local script_dir = path.normalise(debug.getinfo(1, "S").source:match[[^@?(.*[\/])[^\/]-$]])
local mycelio_root_dir = path.normalise(script_dir .. "../../..")

local home = os.getenv("HOME") or os.getenv("USERPROFILE")
local ohMyPosh = path.normalise(home .. "/.local/go/bin/oh-my-posh.exe")
local mycelioConfig = path.normalise(mycelio_root_dir .. "/packages/linux/.poshthemes/mycelio.omp.json")

if not os.isfile(ohMyPosh) then
    print('[clink] Oh My Posh not found: ' .. ohMyPosh)
elseif not os.isfile(mycelioConfig) then
    print('[clink] Oh My Posh config missing: ' .. mycelioConfig)
else
    io.popen(ohMyPosh .. " --version")
    if not os.geterrorlevel == 0 then
        print('[clink] Oh My Posh version test failed: \'' .. ohMyPosh .. '\'')
    else
        print('[clink] Using Oh My Posh: \'' .. ohMyPosh .. '\'')
        local ohmyposh_prompt = clink.promptfilter(1)
        function ohmyposh_prompt:filter(prompt)
            prompt = io.popen(ohMyPosh .. " --config " .. mycelioConfig):read("*a")
            return prompt, false
        end
    end
end
