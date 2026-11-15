-- keeps one shared copy of the player's options, taken from whatever instance last exited,
-- and writes it into instances that don't have their own yet

local settings = prism.settings
local masterDirectory = prism.addon.data_dir .. "/shared"

local function split(text)
    local items = {}
    for item in (text or ""):gmatch("[^,%s]+") do
        items[item] = true
    end
    return items
end

-- options.txt is key:value per line, values may contain more colons
local function parse(text)
    local options, order = {}, {}
    for line in (text or ""):gmatch("[^\r\n]+") do
        local key, value = line:match("^([^:]+):(.*)$")
        if key then
            if options[key] == nil then
                table.insert(order, key)
            end
            options[key] = value
        end
    end
    return options, order
end

local function serialize(options, order)
    local lines = {}
    for _, key in ipairs(order) do
        table.insert(lines, key .. ":" .. options[key])
    end
    return table.concat(lines, "\n") .. "\n"
end

-- keybinds were numbers before 1.13 and names after, mixing the two breaks every binding
local function keybindFormat(minecraftVersion)
    local minor = tonumber((minecraftVersion or ""):match("^1%.(%d+)"))
    if minor == nil then
        return "modern"
    end
    return minor < 13 and "legacy" or "modern"
end

local function instanceOptions(id)
    local instance = prism.instances.get(id)
    return instance.mc_dir .. "/options.txt", instance
end

-- copies an instance's options into the shared copy, called when its game exits
local function capture(id)
    local path, instance = instanceOptions(id)
    local text = prism.fs.read(path)
    if not text then
        return false
    end
    prism.fs.mkdir(masterDirectory)
    prism.fs.write(masterDirectory .. "/options.txt", text)
    for file in pairs(split(settings.get("files"))) do
        local source = instance.mc_dir .. "/" .. file
        if prism.fs.exists(source) then
            prism.fs.copy(source, masterDirectory .. "/" .. file .. ".new")
            prism.fs.move(masterDirectory .. "/" .. file .. ".new", masterDirectory .. "/" .. file)
        end
    end
    prism.storage.set("source", {instance = id, minecraft = instance.minecraft})
    return true
end

-- writes the shared options into an instance, returns how many options it set
local function apply(id)
    local master = prism.fs.read(masterDirectory .. "/options.txt")
    if not master then
        return 0
    end
    local path, instance = instanceOptions(id)
    local existing = prism.fs.read(path)
    if existing and settings.get("mode") ~= "always" then
        return 0
    end
    local shared = parse(master)
    local options, order = parse(existing)
    local keep = split(settings.get("keep"))
    local source = prism.storage.get("source", {})
    local sameKeybinds = keybindFormat(source.minecraft) == keybindFormat(instance.minecraft)
    local changed = 0
    for key, value in pairs(shared) do
        local skip = keep[key] or (key:match("^key_") and not sameKeybinds)
        -- an existing file keeps the data version of the game that wrote it, a new one gets the shared one
        if key == "version" and existing then
            skip = true
        end
        if not skip and options[key] ~= value then
            if options[key] == nil then
                table.insert(order, key)
            end
            options[key] = value
            changed = changed + 1
        end
    end
    prism.fs.mkdir(instance.mc_dir)
    prism.fs.write(path, serialize(options, order))
    for file in pairs(split(settings.get("files"))) do
        local target = instance.mc_dir .. "/" .. file
        if prism.fs.exists(masterDirectory .. "/" .. file) and not prism.fs.exists(target) then
            prism.fs.copy(masterDirectory .. "/" .. file, target)
        end
    end
    return changed
end

-- the first time, start from the instance that was played most recently
local function seed()
    if prism.fs.exists(masterDirectory .. "/options.txt") then
        return
    end
    local latest = nil
    for _, instance in ipairs(prism.instances.list()) do
        if prism.fs.exists(instance.mc_dir .. "/options.txt") and (latest == nil or instance.last_launch > latest.last_launch) then
            latest = instance
        end
    end
    if latest then
        capture(latest.id)
        prism.log("started from the options of", latest.name)
    end
end

prism.on_launch(function(launch)
    if not launch.instance then
        return
    end
    local changed = apply(launch.instance.id)
    if changed > 0 then
        prism.log("carried", changed, "options into", launch.instance.name)
        if settings.get("notify") then
            prism.ui.toast("Options Sync: your options were carried over to " .. launch.instance.name)
        end
    end
end)

prism.on_exit(function(exit)
    if exit.instance and not exit.crashed then
        capture(exit.instance.id)
    end
end)

prism.export("capture", capture)
prism.export("apply", apply)

seed()
