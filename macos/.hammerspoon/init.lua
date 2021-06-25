usbWatcher = nil
keyboardLayout = nil

-- Switch keyboard layout when Moonlander is added/removed.
function usbDeviceCallback(data)
   if (data["productName"] == "Moonlander Mark I") then
      if (data["eventType"] == "added") then
         keyboardLayout = "U.S."
         hs.keycodes.setLayout("U.S.")
      elseif (data["eventType"] == "removed") then
         keyboardLayout = "Norman"
         hs.keycodes.setLayout("Norman")
      end
   end
end

usbWatcher = hs.usb.watcher.new(usbDeviceCallback)
usbWatcher:start()

hyper = {"ctrl", "alt", "shift", "command"}

-- Add global hotkeys to switch keyboard layout.
function setLayout(name)
   return function()
      hs.keycodes.setLayout(name)
   end
end

hs.hotkey.bind(hyper, "n", setLayout("Norman"))
hs.hotkey.bind(hyper, "i", setLayout("U.S."))

-- Add global hotkey to switch to Hindi input. This requires making
-- sure that keyboard layout matches attached keyboard layout.
function setHindi()
   hs.keycodes.setLayout(keyboardLayout)
   hs.keycodes.setMethod("Hindi (A→अ)")
end

hs.hotkey.bind(hyper, "o", setHindi)

