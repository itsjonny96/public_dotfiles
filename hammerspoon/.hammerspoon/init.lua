-- Momentum scroll for both axes
local axes = {
    vertical = {
        lastTime = 0, timer = nil,
        prop = hs.eventtap.event.properties.scrollWheelEventDeltaAxis1,
        post = function(amt) hs.eventtap.event.newScrollEvent({0, amt}, {}, "pixel"):post() end,
    },
    horizontal = {
        lastTime = 0, timer = nil,
        prop = hs.eventtap.event.properties.scrollWheelEventDeltaAxis2,
        post = function(amt) hs.eventtap.event.newScrollEvent({amt, 0}, {}, "pixel"):post() end,
    },
}

local function startMomentum(axis, direction, velocity)
    if axis.timer then axis.timer:stop() end
    local remaining = velocity
    axis.timer = hs.timer.doEvery(0.016, function()
        remaining = remaining * 0.85
        if math.abs(remaining) < 1 then
            axis.timer:stop(); axis.timer = nil; return
        end
        axis.post(math.floor(remaining) * direction)
    end)
end

local function processAxis(axis, delta)
    local now = hs.timer.absoluteTime() / 1e9
    local gap = now - axis.lastTime
    axis.lastTime = now
    if axis.timer then axis.timer:stop(); axis.timer = nil end

    local boost
    if gap < 0.03 then
        boost = 60; startMomentum(axis, delta, 40)
    elseif gap < 0.07 then
        boost = 30; startMomentum(axis, delta, 20)
    elseif gap < 0.15 then
        boost = 12
    else
        boost = 3
    end
    return delta * boost
end

scrollWatcher = hs.eventtap.new({hs.eventtap.event.types.scrollWheel}, function(event)
    local dy = event:getProperty(axes.vertical.prop)
    local dx = event:getProperty(axes.horizontal.prop)
    local ctrl = event:getFlags().ctrl

    if dy == 1 or dy == -1 then
        if ctrl then
            event:setProperty(axes.vertical.prop, dy)
        else
            event:setProperty(axes.vertical.prop, processAxis(axes.vertical, dy))
        end
    end
    if dx == 1 or dx == -1 then
        if ctrl then
            event:setProperty(axes.horizontal.prop, dx)
        else
            event:setProperty(axes.horizontal.prop, processAxis(axes.horizontal, dx))
        end
    end
    return false
end)
scrollWatcher:start()

configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
    for _, file in pairs(files) do
        if file:sub(-4) == ".lua" then hs.reload(); return end
    end
end)
configWatcher:start()

hs.notify.new({title="Hammerspoon", informativeText="Config loaded"}):send()
