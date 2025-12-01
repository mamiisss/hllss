-- ███████╗██╗███████╗██╗  ██╗ █████╗     ██████╗ ██╗   ██╗██████╗  █████╗ ███████╗███████╗
-- ██╔════╝██║██╔════╝██║  ██║██╔══██╗    ██╔══██╗╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██╔════╝
-- █████╗  ██║███████╗███████║███████║    ██████╔╝ ╚████╔╝ ██████╔╝███████║███████╗███████╗
-- ██╔══╝  ██║╚════██║██╔══██║██╔══██║    ██╔══██╗  ╚██╔╝  ██╔═══╝ ██╔══██║╚════██║╚════██║
-- ███████╗██║███████║██║  ██║██║  ██║    ██████╔╝   ██║   ██║     ██║  ██║███████║███████║
-- ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝
-- Advanced Anti-Cheat Bypass | Standalone Module

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ADONIS ANTI-CHEAT BYPASS SYSTEM
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

spawn(function()
    local getgc = getgc or debug.getgc
    local hookfunction = hookfunction
    local getrenv = getrenv
    local debugInfo = (getrenv and getrenv().debug and getrenv().debug.info) or debug.info
    local newcclosure = newcclosure or function(f) return f end

    if not (getgc and hookfunction and getrenv and debugInfo) then
        warn("[Eisha Bypass] Required functions not available")
        return
    end

    local IsDebug = false
    local DetectedMeth, KillMeth
    local AdonisFound = false
    local hooks = {}

    -- Detect Adonis presence
    for _, value in getgc(true) do
        if typeof(value) == "table" then
            local hasDetected = typeof(rawget(value, "Detected")) == "function"
            local hasKill = typeof(rawget(value, "Kill")) == "function"
            local hasVars = rawget(value, "Variables") ~= nil
            local hasProcess = rawget(value, "Process") ~= nil

            if hasDetected or (hasKill and hasVars and hasProcess) then
                AdonisFound = true
                break
            end
        end
    end

    if not AdonisFound then
        return
    end

    -- Hook Adonis methods
    for _, value in getgc(true) do
        if typeof(value) == "table" then
            local detected = rawget(value, "Detected")
            local kill = rawget(value, "Kill")

            -- Hook Detected method
            if typeof(detected) == "function" and not DetectedMeth then
                DetectedMeth = detected
                local hook
                hook = hookfunction(DetectedMeth, function(methodName, methodFunc)
                    return true
                end)
                table.insert(hooks, DetectedMeth)
            end

            -- Hook Kill method
            if rawget(value, "Variables") and rawget(value, "Process") and typeof(kill) == "function" and not KillMeth then
                KillMeth = kill
                local hook
                hook = hookfunction(KillMeth, function(killFunc)
                end)
                table.insert(hooks, KillMeth)
            end
        end
    end

    -- Hook debug.info to prevent detection
    if DetectedMeth and debugInfo then
        local hook
        hook = hookfunction(debugInfo, newcclosure(function(...)
            local functionName = ...
            if functionName == DetectedMeth then
                return coroutine.yield(coroutine.running())
            end
            return hook(...)
        end))
    end
end)

return true
