<img width="277" height="159" alt="image" src="https://github.com/user-attachments/assets/f547df6d-86f1-4314-8b0a-04176037e999" />

this is how u would setup the Zone Register

# ZonePlus (Roblox Luau)

A lightweight, event-driven zone management system for Roblox.

ZonePlus lets you register parts as "zones" and automatically detect when players:

* Enter a zone
* Stay inside a zone
* Leave a zone

Built on top of a class system and event bus, it is designed for scalability, clean architecture, and minimal overhead.

---

## FEATURES

* Automatic zone registration via BaseParts
* Event-driven (no polling needed externally)
* Supports multiple zones at once
* Per-zone update interval support
* Auto-cleanup when parts are destroyed
* Centralized event system via EventBus
* Strong typing support (Luau strict)

---

## REQUIREMENTS

This module depends on:

* ClassSystem
* EventBus
* Signal (optional internal use)
* Zone (zone logic handler)

Structure example:

ReplicatedStorage
└── Modules
├── ClassSystem
├── EventBus
├── Signal
└── ZonePlus (this module)

---

## SETUP

Require the module:

```lua id="zp1"
local Replicated = game:GetService("ReplicatedStorage")
local Modules = Replicated:WaitForChild("Modules")

local ZonePlus = require(Modules.ZonePlus)
```

Create an instance:

```lua id="zp2"
local Zones = ZonePlus.new(1) -- 1 second interval (default)
```

---

## BASIC USAGE

Register a zone:

```lua id="zp3"
local part = workspace.ZonePart

Zones:Register(part)
```

Each part becomes a tracked zone using its Name as the identifier.

---

## EVENT SYSTEM

ZonePlus uses an internal EventBus.

Available events:

* "PlayerEntered"   → Player enters a zone
* "PlayerStaying"   → Player remains inside
* "PlayerLeft"      → Player exits
* "ZoneRegistered"  → New zone added
* "ZoneRemoved"     → Zone removed
* "ZonesStarted"    → All zones started
* "ZonesStopped"    → All zones stopped

---

## EVENT EXAMPLES

Player enters a zone:

```lua id="zp4"
Zones:On("PlayerEntered", function(player, zoneName)
    print(player.Name .. " entered " .. zoneName)
end)
```

Player leaves a zone:

```lua id="zp5"
Zones:On("PlayerLeft", function(player, zoneName)
    print(player.Name .. " left " .. zoneName)
end)
```

Zone registered:

```lua id="zp6"
Zones:On("ZoneRegistered", function(zone)
    print("Zone registered:", zone)
end)
```

---

## MULTIPLE ZONES

Register multiple parts:

```lua id="zp7"
for _, part in ipairs(workspace.Zones:GetChildren()) do
    if part:IsA("BasePart") then
        Zones:Register(part)
    end
end
```

---

## START / STOP SYSTEM

Start all zones:

```lua id="zp8"
Zones:StartAll()
```

Stop all zones:

```lua id="zp9"
Zones:StopAll()
```

---

## REMOVING ZONES

Remove manually:

```lua id="zp10"
Zones:Remove("ZonePartName")
```

Zones are also automatically removed if the part is destroyed.

---

## CUSTOM INTERVAL PER ZONE

You can override the update interval using an attribute:

```lua id="zp11"
part:SetAttribute("ZoneTime", 0.25)
```

This makes the zone update faster than the global interval.

---

## INTERNAL DESIGN

* Each zone is handled by a Zone object

* ZonePlus manages all zones in a dictionary:

  Zones = {
  ["ZoneName"] = ZoneInstance
  }

* EventBus is used for all communication

* Zones start automatically when registered

---

## TYPE INFORMATION

ZoneEvents:

"PlayerEntered"
"PlayerStaying"
"PlayerLeft"
"ZoneRegistered"
"ZoneRemoved"
"ZonesStarted"
"ZonesStopped"

---

## EXAMPLE (FULL)

```lua id="zp12"
local Replicated = game:GetService("ReplicatedStorage")
local Modules = Replicated:WaitForChild("Modules")

local ZonePlus = require(Modules.ZonePlus)

local Zones = ZonePlus.new(1)

-- Register zones
for _, part in ipairs(workspace.Zones:GetChildren()) do
    if part:IsA("BasePart") then
        Zones:Register(part)
    end
end

-- Events
Zones:On("PlayerEntered", function(player, zoneName)
    print(player.Name .. " entered " .. zoneName)
end)

Zones:On("PlayerLeft", function(player, zoneName)
    print(player.Name .. " left " .. zoneName)
end)
```

---

## PERFORMANCE NOTES

* Uses interval-based checks (default = 1 second)
* Per-zone intervals supported
* No unnecessary allocations during runtime
* Scales well with many zones

---

## NOTES

* Zone names must be unique (uses part.Name)
* Registering the same part twice returns the existing zone
* Ensure parts exist before registering
* EventBus must not be nil

---

## LICENSE

Free to use in any project.
Attribution optional.
