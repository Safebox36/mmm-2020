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
    for gK, gV in pairs(config.guards) do
        timer.start{ duration = gV.resetTime, iterations = 1, type = timer.simulate, callback = function() getNextPos(gK, gV) end }
    end
end

local function updateGuards()
    for gK, gV in pairs(config.guards) do
        -- if (g.mobile.aiPlanner:getActivePackage() == nil or g.mobile.aiPlanner:getActivePackage().isDone) then
        if (sqrDist(gK, gV.path[gV.cur]) < 128 and gV.isDone == true) then
            gV.isDone = false
            timer.start{ duration = gV.resetTime, iterations = 1, type = timer.simulate, callback = function() getNextPos(gK, gV) end }
        end
    end
end

local function saveAndQuit()
    mwse.saveConfig('aa_config', config)
end

local function init()
    print("===========")
    print("AA BEGIN...")
    event.register('cellChanged', initGuards)
    event.register('simulate', updateGuards)
    event.register('save', saveAndQuit)
    print("AA SUCCESS")
    print("==========")
end

event.register('initialized', init)