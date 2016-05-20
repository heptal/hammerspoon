--- === hs.swiftdylib ===
---
--- Allows Hammerspoon to respond to URLs

local mod_name = "swiftdylib"
hs.swiftloader(mod_name)

local module = require("hs."..mod_name..".internal")
return module
