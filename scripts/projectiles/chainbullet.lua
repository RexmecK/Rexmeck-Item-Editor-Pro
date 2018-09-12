
function init()
  local over = false;
  
  if config.getParameter("disabled") then
	update = function(dt) end
	hit = function(entityId) end
	trigger = function() end
	setTargets = function(targets) end
	seekTarget = function() end
	over = true;
  end
  
  if config.getParameter("loadscripts") and not over then
	update = nil;
	hit = nil;
	trigger = nil;
	setTargets = nil;
	seekTarget = nil;
	over = true;
	
	for i,v in pairs(config.getParameter("loadscripts")) do
		require(v)
	end
	
	init()
  end
  
  if not over then
  
	require "/scripts/vec2.lua"
	require "/scripts/util.lua"
	
	self.seekSpeed = config.getParameter("seekSpeed", 30)
	self.triggered = config.getParameter("triggered", false)
	self.targets = config.getParameter("targets")
	if not self.targets then projectile.die() end
	if not self.triggered then
		self.chainPower = config.getParameter("power")
		projectile.setPower(0)
	end
	end
  
end

function update(dt)
  if self.targets and #self.targets > 0 then
    if self.triggered then
      seekTarget()
    end
  else
    projectile.die()
  end
end

function hit(entityId)
  local targetIndex = contains(self.targets, entityId)
  if targetIndex then
    if self.triggered then
      table.remove(self.targets, targetIndex)
    else
      projectile.processAction({
          action = "projectile",
          type = config.getParameter("chainProjectile"),
          angle = 0,
          inheritDamageFactor = 1.0,
          config = {
            power = self.chainPower,
            seekSpeed = 70,
            targets = self.targets,
            triggered = true
          }
        })
      projectile.die()
    end
  end
end

function trigger()
  self.triggered = true
end

function setTargets(targets)
  self.targets = targets
end

function seekTarget()
  self.targets = util.filter(self.targets, function(targetId)
    return targetId ~= entityId and world.entityExists(targetId)
  end)
  table.sort(self.targets, function(a,b)
    return world.magnitude(mcontroller.position(), world.entityPosition(a)) < world.magnitude(mcontroller.position(), world.entityPosition(b))
  end)

  -- change direction to the closest target in the list
  if #self.targets > 0 then
    local newTarget = self.targets[1]
    local direction = vec2.norm(world.distance(world.entityPosition(newTarget), mcontroller.position()))
    mcontroller.setVelocity(vec2.mul(direction, self.seekSpeed))
  end
end
