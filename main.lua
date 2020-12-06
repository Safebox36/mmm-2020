config = mwse.loadConfig('aa_config')

local function sqrDist(g, p)
    local gPos = tes3.getReference(g).mobile.position
    local pPos = tes3.getReference(p).position
    local dist = math.sqrt(
        math.pow(math.abs(gPos.x - pPos.x), 2) +
        math.pow(math.abs(gPos.y - pPos.y), 2) +
        math.pow(math.abs(gPos.z - pPos.z), 2)
    )
    print(dist)
    return dist
end

local function getNextPos(gK, gV)
    local next = gV.cur + (1 * gV.dir)
    print("Next: " .. next)
    print(gV.path[next])
    if (gV.path[next] == nil) then
        gV.dir = gV.dir * -1
        next = gV.cur + (1 * gV.dir)
        print("Corrected Next: " .. next)
        print(gV.path[next])
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

local function init()
    print("===========")
    print("AA BEGIN...")
    event.register('cellChanged', initGuards)
    event.register('simulate', updateGuards)
    print("AA SUCCESS")
    print("==========")
end

event.register('initialized', init)