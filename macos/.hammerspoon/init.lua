usbWatcher = nil
keyboardLayout = hs.keycodes.currentLayout()

-- Switch keyboard layout when Moonlander is added/removed.
function usbDeviceCallback(data)
   if (data["productName"] == "Moonlander Mark I") then
      if (data["eventType"] == "added") then
         keyboardLayout = "U.S."
         hs.keycodes.setLayout(keyboardLayout)
      elseif (data["eventType"] == "removed") then
         keyboardLayout = "Norman"
         hs.keycodes.setLayout(keyboardLayout)
      end
   end
end

usbWatcher = hs.usb.watcher.new(usbDeviceCallback)
usbWatcher:start()

hyper = {"ctrl", "alt", "shift", "command"}
meh = {"ctrl", "alt", "shift"}

-- run stackline
stackline = require "stackline"
stackline:init()

