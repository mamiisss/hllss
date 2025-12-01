-- ███████╗██╗███████╗██╗  ██╗ █████╗     ██████╗ ██╗   ██╗██████╗  █████╗ ███████╗███████╗
-- ██╔════╝██║██╔════╝██║  ██║██╔══██╗    ██╔══██╗╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██╔════╝
-- █████╗  ██║███████╗███████║███████║    ██████╔╝ ╚████╔╝ ██████╔╝███████║███████╗███████╗
-- ██╔══╝  ██║╚════██║██╔══██║██╔══██║    ██╔══██╗  ╚██╔╝  ██╔═══╝ ██╔══██║╚════██║╚════██║
-- ███████╗██║███████║██║  ██║██║  ██║    ██████╔╝   ██║   ██║     ██║  ██║███████║███████║
-- ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝
------------------------------------------------------------------------------------------------------------------

spawn(function()
    -- Environment check with fallbacks (Luraph-safe)
    local _getreg = getreg or debug.getregistry
    local _getgc = getgc or debug.getgc
    local _hookfunc = hookfunction
    local _getrenv = getrenv
    local _debugInfo = (_getrenv and _getrenv().debug and _getrenv().debug.info) or debug.info
    local _newcc = newcclosure or function(f) return f end
    local _isfunchooked = isfunctionhooked or function() return false end
    local _filtergc = filtergc

    -- Early return if missing required functions
    if not (_getgc and _hookfunc) then
        return
    end

    local detectedThreads = {}
    local hookedFunctions = {}
    local adonisFound = false

    ---------------------------------------------------------------------------------------------------
    -- METHOD 1: Thread Detection (Luraph-Safe)
    ---------------------------------------------------------------------------------------------------
    local function DetectThreads()
        if not _getreg then return end
        
        for _, obj in pairs(_getreg()) do
            if typeof(obj) ~= "thread" then continue end
            
            local success, source = pcall(debug.info, obj, 1, "s")
            if success and source then
                local src = tostring(source)
                if src:match(".Core.Anti") or src:match(".Plugins.Anti_Cheat") then
                    adonisFound = true
                    table.insert(detectedThreads, obj)
                end
            end
        end
    end

    ---------------------------------------------------------------------------------------------------
    -- METHOD 2: GC Table Detection (Enhanced with filtergc support)
    ---------------------------------------------------------------------------------------------------
    local function DetectTables()
        local adonisTables = {}
        
        -- Try optimized filtergc first
        if _filtergc then
            local filtered = _filtergc("table", {
                Keys = { "Detected", "RLocked" }
            }, false)

            for _, tbl in pairs(filtered) do
                if typeof(rawget(tbl, "Detected")) == "function" then
                    table.insert(adonisTables, tbl)
                    adonisFound = true
                end
            end
        else
            -- Fallback to standard GC scan
            for _, obj in pairs(_getgc(true)) do
                if typeof(obj) ~= "table" then continue end
                
                local hasDetected = typeof(rawget(obj, "Detected")) == "function"
                local hasRLocked = rawget(obj, "RLocked")
                
                if hasDetected and hasRLocked then
                    table.insert(adonisTables, obj)
                    adonisFound = true
                end
            end
        end
        
        return adonisTables
    end

    ---------------------------------------------------------------------------------------------------
    -- METHOD 3: Safe Function Hooking (Anti-Tamper Protection)
    ---------------------------------------------------------------------------------------------------
    local function HookAdonisFunctions(adonisTables)
        for _, tbl in pairs(adonisTables) do
            for _, func in pairs(tbl) do
                -- Skip if not function or already hooked
                if typeof(func) ~= "function" then continue end
                if _isfunchooked(func) then continue end
                if hookedFunctions[func] then continue end
                
                -- Safe hook with anti-tamper protection
                local success = pcall(function()
                    local hooked = _hookfunc(func, _newcc(function(action, info, nocrash)
                        -- Anti-tamper: Don't crash, just yield
                        coroutine.yield(coroutine.running())
                        return task.wait(9e9)
                    end))
                    
                    hookedFunctions[func] = true
                end)
            end
        end
    end

    ---------------------------------------------------------------------------------------------------
    -- METHOD 4: debug.info Hook (Luraph-Safe Anti-Detection)
    ---------------------------------------------------------------------------------------------------
    local detectedMethod = nil
    
    local function HookDebugInfo()
        if not _getrenv or not _debugInfo then return end
        
        -- Find Detected method first
        for _, obj in pairs(_getgc(true)) do
            if typeof(obj) == "table" then
                local detected = rawget(obj, "Detected")
                if typeof(detected) == "function" then
                    detectedMethod = detected
                    break
                end
            end
        end
        
        if not detectedMethod then return end
        
        -- Safe hook with fallback
        pcall(function()
            _hookfunc(_debugInfo, _newcc(function(...)
                local funcName = ...
                if funcName == detectedMethod then
                    return coroutine.yield(coroutine.running())
                end
                return _debugInfo(...)
            end))
        end)
    end

    ---------------------------------------------------------------------------------------------------
    -- EXECUTION: Run all bypass methods
    ---------------------------------------------------------------------------------------------------
    
    -- Step 1: Detect threads
    pcall(DetectThreads)
    
    -- Step 2: Close detected threads
    for _, thread in pairs(detectedThreads) do
        pcall(coroutine.close, thread)
    end
    
    task.wait(0.05)
    
    -- Step 3: Detect Adonis tables
    local adonisTables = {}
    pcall(function()
        adonisTables = DetectTables()
    end)
    
    -- Only proceed if Adonis was found
    if not adonisFound then
        return
    end
    
    task.wait(0.05)
    
    -- Step 4: Hook Adonis functions
    pcall(HookAdonisFunctions, adonisTables)
    
    task.wait(0.05)
    
    -- Step 5: Hook debug.info for anti-detection
    pcall(HookDebugInfo)
    
    ---------------------------------------------------------------------------------------------------
    -- CONTINUOUS PROTECTION: Re-check every 5 seconds
    ---------------------------------------------------------------------------------------------------
    task.spawn(function()
        while true do
            task.wait(5)
            
            -- Re-detect and close new threads
            pcall(function()
                local newThreads = {}
                for _, obj in pairs(_getreg()) do
                    if typeof(obj) == "thread" then
                        local success, source = pcall(debug.info, obj, 1, "s")
                        if success and source then
                            local src = tostring(source)
                            if src:match(".Core.Anti") or src:match(".Plugins.Anti_Cheat") then
                                table.insert(newThreads, obj)
                            end
                        end
                    end
                end
                
                for _, thread in pairs(newThreads) do
                    pcall(coroutine.close, thread)
                end
            end)
        end
    end)
end)

return true
