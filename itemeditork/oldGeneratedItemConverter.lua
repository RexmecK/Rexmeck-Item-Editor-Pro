
function rW(str) --replaces old wavs to ogg
    return (str):gsub(".wav", ".ogg")
end

function convertPixel(vec2, inverted)
	local newV = {0,0}
	newV[1] = vec2[1] * 0.125
	newV[2] = vec2[2] * 0.125
	if inverted then
	    newV[1] = -newV[1]
	    newV[2] = -newV[2]
	end
	return newV
end

function vec2add(vec2, vec2a)
	return {vec2[1] + vec2a[1], vec2[2] + vec2a[2]}
end

function vec2sub(vec2, vec2a)
	return {vec2[1] - vec2a[1], vec2[2] - vec2a[2]}
end

function CheckOldItem(item)
	if item.name == "generatedsword" then
		return true
	elseif item.name == "generatedgun" then
		return true
	end
	return false
end

function GeneratedConvert(item)
	if item.name == "generatedsword" then
		return convertGeneratedSword(item)
	elseif item.name == "generatedgun" then
		return convertGeneratedGun(item)
	else
		return {name = "perfectlygenericitem", count = 1, parameters = {shortdescription = "GenItemConverter: Invalid item name!"}}
	end
end

function convertGeneratedGun(item)
    local function buildPrimary(item)
        local n = {
    		name = "Gun Fire",
    		class = "GunFire",
    		scripts = {"/items/active/weapons/ranged/gunfire.lua"},
    		
    		baseDps = 0,
    		energyUsage = 0,
    		fireType = "auto",
    		fireTime = 0.0,
    		inaccuracy = item.parameters.inaccuracy or 0,
    		projectileCount = item.parameters.projectileCount,
    		
    		projectileType = "invisibleprojectile",
    		projectileParameters = {
				timeToLive = 0.01,
				damageType = "NoDamage",
			    actionOnReap = {
			        {
						delaySteps = 0,
						specification = {
							size = 1,
							layer = "front",
							timeToLive = 0.1,
							fullbright = true,
							animation = item.parameters.muzzleEffect.animation,
							type = "animated",
							position = {1,0},
							color = {255, 255, 255, 255}
						},
						action = "particle",
						rotate = true
					}, 
					{
						delaySteps = 0,
						action = "projectile",
						fuzzAngle = 0,
						angleAdjust = 0,
						type = item.parameters.projectileType,
						config = item.parameters.projectile or {},
						autoFlipAdjust = true
					}
				},
				universalDamage = false,
				power = 0,
				speed = 0
			},
    		stances = {
    			fire = {
					allowRotate = true,
					weaponRotation = 0,
					allowFlip = true,
					armRotation = 0,
					twoHanded = item.parameters.twoHanded or true,
					duration = 0
    			},
    			idle = {
					allowRotate = true,
					weaponRotation = 0,
					allowFlip = true,
					armRotation = 0,
					twoHanded = item.parameters.twoHanded or true
    			},
    			cooldown = {
					allowFlip = true,
					weaponRotation = 0,
					allowRotate = true,
					armRotation = 0,
					recoil = true,
					twoHanded = item.parameters.twoHanded or true,
					duration = item.parameters.fireTime
    			}
    		}
	    }
	    return n
    end
    
    local function buildAnimationCustom(item)
        local n = {
            sounds = {fire = { pool = {"/assetmissing.ogg"}, volume = 1.0, pitchMultiplier = 1.0}},
    		particleEmitters = {
    		    altMuzzleFlash = {active = false, particles = jarray(), offsetRegion = {0,0,0,0}, transformationGroups = {"muzzle"}, emissionRate = 7}
    		},
    		lights = {
    		    muzzleFlash = {
    		        color = {0,0,0}
    		    }
    		},
            animatedParts = {
                parts = {
                    muzzleFlash = {
                        properties = {
                            offset = {0,0}
                        },
                        partStates = {
                            firing = {
                                fire = {
                                    properties = {
                                        image = "/assetmissing.png"
                                    }
                                }
                            }
                        }
                    },
                    middle = {
                        properties = {
                            image = "/assetmissing.png"
                        }
                    },
                    butt = {
                        properties = {
                            image = "/assetmissing.png"
                        }
                    },
                    barrel = {
                        properties = {
                            image = "/assetmissing.png"
                        }
                    }
                }
            } 
        }
        for i,v in pairs(item.parameters.drawables) do
            n.animatedParts.parts["drawable_"..i] = {
                properties = {
    		        image = v.image,
    		        offset = convertPixel(vec2sub(v.position, item.parameters.handPosition)),
    		        zLevel = i,
    		        transformationGroups = {"weapon"},
    		        centered = true
                }
            }
        end
        if item.parameters.muzzleEffect.fireSound then
            local newPool = {}
    		for i,v in pairs(item.parameters.muzzleEffect.fireSound) do
    			if i == 1 then
    				n.sounds.fire.volume = item.parameters.muzzleEffect.fireSound[1].volume or 1.0
    			end
    			table.insert(newPool, (rW(v.file)))
    		end
    		n.sounds.fire.pool = newPool
        end
        return n
    end
    
    item.parameters.primaryAbility = buildPrimary(item)
    item.parameters.animationCustom = buildAnimationCustom(item)
    
	item.parameters.baseOffset = {0,0}
	item.parameters.muzzleOffset = convertPixel( vec2sub(vec2sub(item.parameters.firePosition, item.parameters.handPosition), {12,0}) )
	
	item.parameters.drawables = nil
	item.parameters.muzzleEffect = nil
	item.parameters.muzzleFlashes = nil
	item.parameters.inspectionKind = nil
	item.parameters.handPosition = nil
	item.parameters.hands = nil
	item.parameters.firePosition = nil
	item.parameters.fireTime = nil
	item.parameters.fireSound = nil
	item.parameters.projectile = nil
	item.parameters.projectileType = nil
	item.parameters.projectileTypes = nil
	item.parameters.projectileCount = nil
	item.parameters.projectileSeparation = nil
	item.parameters.recoilTime = nil
	item.parameters.generated = nil
	item.parameters.palette = nil
	item.parameters.rateOfFire = nil
	item.parameters.inaccuracy = nil
	item.parameters.directories = nil
	item.parameters.name = nil
	item.parameters.nameGenerator = nil
	item.parameters.baseDps = nil -- who cares
    
	item.parameters.tooltipKind = "base"
	item.parameters.category = "Rexmeck Item Editor Pro"
    return {
		name = "commonpistol",
		count = item.count,
		parameters = item.parameters
	}
end

function convertGeneratedSword(item)
        
    local function buildSounds(item)
    	local n = {fireSound = { pool = {"/assetmissing.ogg"}, volume = 1.0, pitchMultiplier = 1.0}, fire = { pool = {"/assetmissing.ogg"}}, altFire = { pool = {"/assetmissing.ogg"}}}
    	
    	if item.soundEffect and item.soundEffect.fireSound then
    		local newPool = {}
    		for i,v in pairs(item.soundEffect.fireSound) do
    			if i == 1 then
    				n.fireSound.volume = item.soundEffect.fireSound[1].volume or 1.0
    			end
    			table.insert(newPool, (rW(v.file)))
    		end
    		
    		n.fireSound.pool = newPool
    	end
    	
    	return n
    end
    
    local function buildDTA(item)
    	local n = {
    		animatedParts = {parts = {},
    		    stateTypes = {
    		        stances ={
    		            default = "idle",
    		            states = {
    		                altIdle = {
                                frames = 1,
                                cycle = 0.07,
    		                },
    		                altFire = {
                                frames = 1,
                                cycle = 0.07,
    		                },
    		                altCooldown = {
                                frames = 1,
                                cycle = 0.07,
    		                },
    		                idle = {
                                frames = 1,
                                cycle = 0.07,
    		                },
    		                fire = {
                                frames = 1,
                                cycle = 0.07,
    		                },
    		                cooldown = {
                                frames = 1,
                                cycle = 0.07,
    		                }
    		            }
    		        }
    		    }
    		},
    		transformationGroups = {weapon = {interpolated = false}, swoosh = {interpolated = false}},
    		sounds = buildSounds(item.parameters),
    		particleEmitters = {
    		    altMuzzleFlash = {active = false, particles = jarray(), offsetRegion = {0,0,0,0}, transformationGroups = {"muzzle"}, emissionRate = 7}
    		},
    		lights = {
    		    muzzleFlash = {
    		        color = {0,0,0}
    		    }
    		}
    	}
    	for i,v in pairs(item.parameters.drawables) do
    	    if not v.position then
    	        v.position = {0,0}
    	    end
    		n.animatedParts.parts["drawable_"..i] = {
    			properties = {
    				image = v.image,
    				offset = convertPixel(v.position),
    				zLevel = i,
    				transformationGroups = {"weapon"},
    				rotationCenter = {0, 0},
    				centered = true
    			},
    			partStates = {
                  stances = {
                    fire = {
                        properties = {
    			    	    offset = convertPixel(vec2sub(v.position, item.parameters.primaryStances.windup.handPosition)),
                        }
                    },
                    idle = {
                        properties = {
    			    	    offset = convertPixel(vec2sub(v.position, item.parameters.primaryStances.idle.handPosition)),
                        }
                    },
                    cooldown = {
                        properties = {
    			    	    offset = convertPixel(vec2sub(v.position, item.parameters.primaryStances.cooldown.handPosition)),
                        }
                    }
                  }
                }
    		}
    		if item.parameters.altStances then
    		    n.animatedParts.parts["drawable_"..i].partStates.stances.altFire = {
    		        properties = {
    			    	    offset = convertPixel(vec2sub(v.position, item.parameters.altStances.windup.handPosition)),
                    }
    		    }
    		    n.animatedParts.parts["drawable_"..i].partStates.stances.altIdle = {
    		        properties = {
    			    	    offset = convertPixel(vec2sub(v.position, item.parameters.altStances.idle.handPosition)),
                    }
    		    }
    		    n.animatedParts.parts["drawable_"..i].partStates.stances.altCooldown = {
    		        properties = {
    			    	    offset = convertPixel(vec2sub(v.position, item.parameters.altStances.cooldown.handPosition)),
                    }
    		    }
    		    
    	    end
    	end
    	n.animatedParts.parts.butt = {
    		properties = {
    			image = "/assetmissing.png",
    			offset = {0, 0},
    			zLevel = 0,
    			transformationGroups = {"weapon"},
    		}
    	}
    	n.animatedParts.parts.middle = {
    		properties = {
    			image = "/assetmissing.png",
    			offset = {0, 0},
    			zLevel = 0,
    			transformationGroups = {"weapon"},
    		}
    	}
    	n.animatedParts.parts.barrel = {
    		properties = {
    			image = "/assetmissing.png",
    			offset = {0, 0},
    			zLevel = 0,
    			transformationGroups = {"weapon"},
    		}
    	}
    	n.animatedParts.parts.muzzleFlash = {
    		properties = {
    			zLevel = -1,
    			transformationGroups = {"muzzle"},
    			centered = true,
    			offset = {0, 0}
    		},
    		partStates = {
    			firing = {
    				fire = {
    					properties = {
    						image = "/assetmissing.png"
    					}
    				}
    			}
    		}
    	}
    	
    	return n
    end
    
    local function buildStance(stance, directional, state)
    	local n = {}
    	n.weaponOffset = {0,0}
    	if state == "cooldown" or state == "altCooldown" then
        	n.duration = stance.duration * 0.25
        	n.playSounds = {"fireSound"}
    	else
    	    n.duration = stance.duration
    	end
    	n.armRotation = stance.armAngle
    	n.weaponRotation = stance.swordAngle
    	n.animationStates = {stances = state}
    	n.frontArmFrame = stance.armFrameOverride
    	n.backArmFrame = stance.armFrameOverride
    	n.twoHanded = stance.twoHanded
    	if directional == nil then 
    	    n.allowRotate = true
    	else
    	    n.allowRotate = directional
    	end
    	n.allowFlip = true
    	return n
    end
    
    local function buildPrimary(item)
    	local isRotate = item.parameters.primaryStances.directional
    	local n = {
    		name = "Gun Fire",
    		class = "GunFire",
    		scripts = {"/items/active/weapons/ranged/gunfire.lua"},
    		
    		baseDps = 100,
    		energyUsage = 0,
    		fireType = "auto",
    		fireTime = item.parameters.fireTime,
    		inaccuracy = 0,
    		projectileCount = 1,
    		
    		projectileType = item.parameters.primaryStances.projectileType,
    		projectileParameters = item.parameters.primaryStances.projectile,
    		stances = {
    			fire = buildStance(item.parameters.primaryStances.windup, isRotate, "fire"),
    			idle = buildStance(item.parameters.primaryStances.idle, isRotate, "idle"),
    			cooldown = buildStance(item.parameters.primaryStances.cooldown, isRotate, "cooldown"),
    		}
    	}
    	
    	return n
    end
    
    local function buildAlt(item)
    	local isRotate = item.parameters.altStances.directional
    	local n = {
    		name = "Alt Fire",
    		class = "AltFireAttack",
    		scripts = {"/items/active/weapons/ranged/abilities/altfire.lua"},
    		
    		baseDps = 100,
    		energyUsage = 0,
    		fireType = "auto",
    		fireTime = item.parameters.fireTime,
    		inaccuracy = 0,
    		projectileCount = 1,
    		
    		projectileType = item.parameters.altStances.projectileType,
    		projectileParameters = item.parameters.altStances.projectile,
    		stances = {
    			fire = buildStance(item.parameters.altStances.windup, isRotate, "altFire"),
    			idle = buildStance(item.parameters.altStances.idle, isRotate, "altIdle"),
    			cooldown = buildStance(item.parameters.altStances.cooldown, isRotate, "altCooldown"),
    		}
    	}
    	
    	return n
    end
    
	item.parameters.animationCustom = buildDTA(item)
	item.parameters.animation = "/items/active/weapons/ranged/gun.animation"
	item.parameters.animationParts = {
		butt = "/assetmissing.png",
		barrel = "/assetmissing.png",
		muzzleFlash = "/assetmissing.png",
		middle = "/assetmissing.png"
	}
	item.parameters.primaryAbility = buildPrimary(item)
	if item.parameters.altStances then
	    item.parameters.altAbility = buildAlt(item)
	end
	if item.parameters.twoHanded then
		item.parameters.twoHanded = true
	elseif not item.parameters.twoHanded and item.parameters.primaryStances.idle.twoHanded then
	    item.parameters.twoHanded = true
	else
		item.parameters.twoHanded = false
	end
	
	item.parameters.baseOffset = {0,0}
	item.parameters.muzzleOffset = vec2add(convertPixel(item.parameters.firePosition), {-1.75,0.5})
	item.parameters.elementalType = "physical"
	
	item.parameters.primaryStances = nil
	item.parameters.altStances = nil
	item.parameters.drawables = nil
	item.parameters.soundEffect = nil
	item.parameters.inspectionKind = nil
	item.parameters.firePosition = nil
	item.parameters.fireTime = nil
	item.parameters.fireAfterWindup = nil
	item.parameters.generated = nil
	
	item.parameters.tooltipKind = "base"
	item.parameters.category = "Rexmeck Item Editor Pro"
	return {
		name = "commonpistol",
		count = item.count,
		parameters = item.parameters
	}
end

