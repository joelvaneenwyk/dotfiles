--
-- xmonad configuration
--
-- Derived from: http://www.tonicebrian.com/2011/09/05/my-working-environment-with-xmonad/
--

import XMonad
import XMonad.Actions.OnScreen
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ICCCMFocus
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.Grid
import XMonad.Layout.IM
import XMonad.Layout.Minimize
import XMonad.Layout.Named
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Reflect
import XMonad.Layout.ToggleLayouts
import XMonad.Layout.TrackFloating
import qualified XMonad.StackSet as W
import XMonad.Layout.WindowNavigation
import XMonad.Util.Run
import Data.Ratio ((%))

import qualified Data.Map as M

-- Name the workspaces
myWorkspaces = ["1:devA", "2:devB", "3:devC", "4:mail", "5:web", "6:skype", "7:gimp", "8:extra2", "9:irc"]

-- Send applications to their dedicated workspace
myManageHook = composeAll
   [
      (role =? "gimp-dock" <||> role =? "gimp-toolbox" <||> role =? "gimp-image-window") --> (ask >>= doF . W.sink),
      title =? "sup"                --> doShift "4:mail",
      className =? "Google-chrome"  --> doShift "5:web",
      className =? "Skype"          --> doShift "6:skype",
      className =? "Gimp"           --> doShift "7:gimp",
      title =? "weechat"            --> doShift "9:irc"
   ] where role = stringProperty "WM_WINDOW_ROLE"

myKeys conf@(XConfig {XMonad.modMask = modm}) =
   [
      -- Arrow navigation
      ((modm,               xK_Right),    sendMessage $ Go R),
      ((modm,               xK_Left ),    sendMessage $ Go L),
      ((modm,               xK_Up   ),    sendMessage $ Go U),
      ((modm,               xK_Down ),    sendMessage $ Go D),
      ((modm .|. shiftMask, xK_Right),    sendMessage $ Swap R),
      ((modm .|. shiftMask, xK_Left ),    sendMessage $ Swap L),
      ((modm .|. shiftMask, xK_Up   ),    sendMessage $ Swap U),
      ((modm .|. shiftMask, xK_Down ),    sendMessage $ Swap D),

      -- Toggle Fullscreen
      ((modm, xK_f),                      sendMessage ToggleLayout),

      -- Lock Screen
      ((modm .|. shiftMask, xK_l),        safeSpawn "gnome-screensaver-command" ["-l"]),
      ((modm .|. shiftMask, xK_o),        safeSpawn "gnome-screensaver-command" ["-l"]),

      -- Take a screenshot of entire display
      ((modm, xK_Print), spawn "screenshot"),

      -- Launch dmenu with custom settings
      ((modm, xK_p), safeSpawn "dmenu_run" ["-fn", "-*-courier-medium-r-normal-*-*-120-*-*-*-*-*-*", "-nb", "black", "-nf", "green", "-sf", "green", "-sb", "darkblue"]),

      -- Launch calculator, keycode 148 (keysym 0x1008ff1d, XF86Calculator)
      ((0, 0x1008ff1d), spawn "gnome-calculator")
   ]
   ++
   -- mod-{w,d,f} %! Switch to physical/Xinerama screens 1, 2, or 3
   -- mod-shift-{w,d,f} %! Move client to screen 1, 2, or 3
   [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
     | (key, sc) <- zip [xK_w, xK_d, xK_f] [0..]
     , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

newKeys x = M.union (M.fromList (myKeys x)) (keys defaultConfig x)

-- Define the layout
basicLayout = Tall nmaster delta ratio where
    nmaster = 1
    delta   = 3/100
    ratio   = 1/2
tallLayout = named "tall" $ basicLayout
wideLayout = named "wide" $ Mirror basicLayout
singleLayout = named "single" $ noBorders Full
fullscreenLayout = named "fullscreen" $ noBorders Full
imLayout = avoidStruts $ withIM ratio roster chatLayout where
    chatLayout = Grid
    ratio      = 1%7
    roster     = Title("Joel Van Eenwyk - Skype™")
gimpLayout = withIM (0.11) (Role "gimp-toolbox") $ reflectHoriz $
             withIM (0.15) (Role "gimp-dock") Full

myLayoutHook = windowNavigation $ avoidStruts $ skype $ gimp $ irc $ normal where
    skype      = onWorkspace "6:skype" imLayout
    gimp       = onWorkspace "7:gimp" gimpLayout
    irc        = onWorkspace "9:irc" fullscreenLayout
    normal     = tallLayout ||| wideLayout ||| singleLayout

-- Startup actions
myStartupHook = do
   windows (onlyOnScreen 0 "5:web")
   windows (onlyOnScreen 2 "9:irc")

main = do
   xmproc <- spawnPipe "xmobar ~/.xmobarrc"
   xmonad $ withUrgencyHookC NoUrgencyHook urgencyConfig { suppressWhen = Focused } $ ewmh defaultConfig
      {
         manageHook = manageDocks <+> myManageHook <+> manageHook defaultConfig,
         handleEventHook = handleEventHook defaultConfig <+> fullscreenEventHook,
         normalBorderColor = "black",
         focusedBorderColor = "yellow",
         keys = newKeys,
         workspaces = myWorkspaces,
         layoutHook = myLayoutHook,
         startupHook = myStartupHook,
         logHook = takeTopFocus >> dynamicLogWithPP xmobarPP
            {
               ppOutput = hPutStrLn xmproc,
               ppTitle = xmobarColor "green" "" . shorten 50,
               ppUrgent = xmobarColor "yellow" "red" . xmobarStrip
            },
         modMask = mod4Mask,
         terminal = "rxvt"
      }
