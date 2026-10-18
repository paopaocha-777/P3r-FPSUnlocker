local UEHelpers = require("UEHelpers")

-- Change this value if you want a different cap.
local TARGET_FPS = 200
local FPS_COMMAND = "t.MaxFPS " .. tostring(TARGET_FPS)

local fixLoopStarted = false
local setFrameRateHookInstalled = false
local applySettingsHookInstalled = false
local announced = false

local cachedEngine = nil
local cachedKsl = nil
local cachedSettings = nil

local function log(message)
    print("[S3R] " .. message .. "\n")
end

-- Resolve these lazily. The old mod cached them while the Lua mods were still
-- starting, which made it depend on exactly when the engine finished loading.
local function getEngine()
    if cachedEngine and cachedEngine:IsValid() then
        return cachedEngine
    end

    cachedEngine = nil

    local engine = FindFirstOf("Engine")
    if engine and engine:IsValid() then
        cachedEngine = engine
        return engine
    end

    return nil
end

local function getKismetSystemLibrary()
    if cachedKsl and cachedKsl:IsValid() then
        return cachedKsl
    end

    cachedKsl = nil

    local ok, ksl = pcall(UEHelpers.GetKismetSystemLibrary, true)
    if ok and ksl and ksl:IsValid() then
        cachedKsl = ksl
        return ksl
    end

    return nil
end

local function getGameUserSettings()
    if cachedSettings and cachedSettings:IsValid() then
        return cachedSettings
    end

    cachedSettings = nil

    local settings = StaticFindObject("/Script/Engine.Default__GameUserSettings")
    if not (settings and settings:IsValid()) then
        settings = FindFirstOf("GameUserSettings")
    end

    if settings and settings:IsValid() then
        cachedSettings = settings
        return settings
    end

    return nil
end

local function executeConsoleCommand(command)
    local engine = getEngine()
    if not engine then
        return false
    end

    local ksl = getKismetSystemLibrary()
    if ksl then
        local ok = pcall(function()
            ksl:ExecuteConsoleCommand(engine, command, nil)
        end)
        if ok then
            return true
        end
    end

    -- Fallback for builds where the Kismet CDO cannot be resolved yet.
    local ok = pcall(function()
        engine:ExecuteConsoleCommand(command, nil)
    end)
    return ok
end

local function applyEngineFpsLimit()
    local engine = getEngine()
    if not engine then
        return
    end

    -- Keep the fixed-rate path at the same value in case the game re-enables it.
    pcall(function() engine.bUseFixedFrameRate = false end)
    pcall(function() engine.bSmoothFrameRate = false end)
    pcall(function() engine.FixedFrameRate = TARGET_FPS end)
end

local function applySettingsFpsLimit()
    local settings = getGameUserSettings()
    if not settings then
        return
    end

    -- Set the property without invoking the setter every 100 ms. The setter
    -- hook below still catches the game's own attempts to restore 60 FPS.
    pcall(function() settings.FrameRateLimit = TARGET_FPS end)
end

local function applyFix()
    applyEngineFpsLimit()
    applySettingsFpsLimit()
    executeConsoleCommand(FPS_COMMAND)

    if not announced and getEngine() then
        announced = true
        log(tostring(TARGET_FPS) .. " FPS cap active")
    end
end

local function installHooks()
    if not setFrameRateHookInstalled then
        local ok, preId = pcall(function()
            return RegisterHook(
                "/Script/Engine.GameUserSettings:SetFrameRateLimit",
                function(_, newLimit)
                    -- Any menu/settings code that asks for 60 is rewritten to the cap.
                    pcall(function() newLimit:set(TARGET_FPS) end)
                end,
                function()
                    executeConsoleCommand(FPS_COMMAND)
                end
            )
        end)

        if ok and preId then
            setFrameRateHookInstalled = true
            log("SetFrameRateLimit hook installed")
        end
    end

    if not applySettingsHookInstalled then
        local ok, preId = pcall(function()
            return RegisterHook(
                "/Script/Engine.GameUserSettings:ApplySettings",
                function(context)
                    -- ApplySettings reads FrameRateLimit before applying it.
                    local settings = context:get()
                    pcall(function() settings.FrameRateLimit = TARGET_FPS end)
                end,
                function()
                    -- Undo anything the original ApplySettings installed.
                    applyFix()
                end
            )
        end)

        if ok and preId then
            applySettingsHookInstalled = true
            log("ApplySettings hook installed")
        end
    end
end

local burstGeneration = 0

local function scheduleFixBurst()
    burstGeneration = burstGeneration + 1
    local generation = burstGeneration
    local delays = { 0, 50, 100, 200, 400, 800, 1600 }

    for _, delay in ipairs(delays) do
        ExecuteWithDelay(delay, function()
            -- A later level/menu transition supersedes an older burst.
            if generation ~= burstGeneration then
                return
            end

            ExecuteInGameThread(function()
                applyFix()
            end)
        end)
    end
end

local function startFixLoop()
    if fixLoopStarted then
        return
    end

    fixLoopStarted = true
    log("Initializing")

    LoopAsync(100, function()
        ExecuteInGameThread(function()
            applyFix()
            installHooks()
        end)
        return false
    end)
end

startFixLoop()
scheduleFixBurst()

NotifyOnNewObject("/Script/Engine.Level", function()
    scheduleFixBurst()
end)

NotifyOnNewObject("/Script/Engine.PlayerController", function()
    scheduleFixBurst()
end)

-- Available in UE4SS 3.x, but keep this optional so the same file also works
-- on builds where the global hook helper is absent.
pcall(function()
    RegisterLoadMapPostHook(function()
        scheduleFixBurst()
    end)
end)
