config = mwse.loadConfig('aa_config')

local function sqrDist(g, p)
    local gPos = tes3.getReference(g).mobile.position
    local pPos = tes3.getReference(p).position
    local dist = math.sqrt(
        math.pow(math.abs(gPos.x - pPos.x), 2) +
        math.pow(math.abs(gPos.y - pPos.y), 2) +
        math.pow(math.abs(gPos.z - pPos.z), 2)
    )
    return dist
end

local function getCloserGuard(gK)
    local closestGuard = {k = "", v = 65535}
    for cK, cV in pairs(config[tes3.getPlayerCell().id].guards) do
        if (cK ~= gK) then
            if (sqrDist(cK, gK) < closestGuard.v) then
                closestGuard.k = cK
                closestGuard.v = sqrDist(cK, gK)
            end
        end
    end
    local c = tes3.getReference(closestGuard.k)
    c.mobile:startCombat(tes3.player.mobile)
end

local function checkVision(gK)
    local g = tes3.getReference(gK)
    local gR = g.orientation.z
    local gP = g.position
    local pP = tes3.player.position
    local delta = (pP.x - gP.x) / (pP.z - gP.z)
    -- print(gR .. " - " .. math.atan(delta) .. " - " .. math.abs(gR - math.atan(delta)) .. " - " .. math.abs(gR - math.atan(delta)) / 3.14 * 180)
    return math.abs(gR - math.atan(delta)) / 3.14 * 180 <= 60
end

local function getNextPos(gK, gV)
    local next
    if (gV.dir == 0) then
        next = gV.cur + 1
        if (gV.path[next] == nil) then
            next = 1
        end
    else
        next = gV.cur + (1 * gV.dir)
        if (gV.path[next] == nil) then
            gV.dir = gV.dir * -1
            next = gV.cur + (1 * gV.dir)
        end
    end
    gV.cur = next
    tes3.setAITravel{reference = gK, destination = tes3.getReference(gV.path[next]).position}
    gV.isDone = true
end

local function initGuards()
    -- start checks
    if (config[tes3.getPlayerCell().id] ~= nil and tes3.getGlobal("aa_begin") == 0) then
        tes3.setGlobal("aa_begin", 1)
    elseif (config[tes3.getPlayerCell().id] == nil) then
        tes3.setGlobal("aa_begin", 0)
    end

    for gK, gV in pairs(config[tes3.getPlayerCell().id].guards) do
        timer.start{ duration = gV.resetTime, iterations = 1, type = timer.simulate, callback = function() getNextPos(gK, gV) end }
    end
end

local function updateGuards()
    if (tes3.getGlobal("aa_begin")) then
        for gK, gV in pairs(config[tes3.getPlayerCell().id].guards) do
            -- trigger combat
            if (config[tes3.getPlayerCell().id].alarmTriggered and tes3.getReference(gK).mobile.inCombat == false) then
                tes3.getReference(gK).mobile:startCombat(tes3.player.mobile)
            -- run to trigger alarm
            elseif (config[tes3.getPlayerCell().id].guards[gK].isAlarmed) then
                if (sqrDist(gK, config[tes3.getPlayerCell().id].alarm) <= 128) then
                    config[tes3.getPlayerCell().id].alarmTriggered = true
                end
            -- normal patrol
            else
                if (checkVision(gK) and tes3.testLineOfSight{reference1 = gK, reference2 = tes3.player} and mwscript.getDistance{reference = gK, target = tes3.player} <= 128 * 3) then
                    -- tes3.setGlobal("Random100", 80)
                    -- tes3.playVoiceover{actor = gK, voiceover = tes3.voiceover.flee}
                    -- print(gK .. " - true (" .. mwscript.getDistance{reference = gK, target = tes3.player} .. ")")
                    local a = tes3.getReference(config[tes3.getPlayerCell().id].alarm)
                    local g = tes3.getReference(gK)
                    g.mobile.forceRun = true
                    tes3.setAITravel{reference = gK, destination = a.position}
                    config[tes3.getPlayerCell().id].guards[gK].isAlarmed = true
                    getCloserGuard(gK)
                end
                if (sqrDist(gK, gV.path[gV.cur]) < 128 and gV.isDone == true) then
                    gV.isDone = false
                    timer.start{ duration = gV.resetTime, iterations = 1, type = timer.simulate, callback = function() getNextPos(gK, gV) end }
                end
            end
        end
    end
end

local function saveAndQuit()
    mwse.saveConfig('aa_config', config)
end

local function init()
    print("===========")
    print("AA AI BEGIN...")
    event.register('cellChanged', initGuards)
    event.register('simulate', updateGuards)
    event.register('save', saveAndQuit)
    print("AA AI SUCCESS")
    print("==========")
end

event.register('initialized', init)