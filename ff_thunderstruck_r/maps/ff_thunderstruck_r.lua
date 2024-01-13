-------------------------------------------------------------------------------------------------------------
-- ff_thunderstruck_r.lua
-- descended from ff_lastteamstanding.lua by Pon.id
-- thunderstruck redux by Soap Breaker (Gumbuk 9)
-- credits to mv for upgrading the CheckTeamAliveState function
-- cheers
-------------------------------------------------------------------------------------------------------------

IncludeScript("base_teamplay");


---------------------------------
-- Global Variables (these can be changed to whatever you want)
---------------------------------

TEAM_POINTS_PER_WIN = 10
BLUE_TEAM_NAME = "Blue"
RED_TEAM_NAME = "Red"
YELLOW_TEAM_NAME = "Yellow"
GREEN_TEAM_NAME = "Green"

SPEED_MODIFIER = 1.3
FRICTION_MODIFIER = 0.6
BLASTJUMP_MODIFIER = Vector( 1.2, 1.2, 1.4 )


---------------------------------
-- Functions
---------------------------------

-- Startup. Pretty basic stuff.
function startup()
-- set up team limits (only red & blue)
	SetPlayerLimit( Team.kBlue, 0 )
	SetPlayerLimit( Team.kRed, 0 )
	SetPlayerLimit( Team.kYellow, -1 )
	SetPlayerLimit( Team.kGreen, -1 )

	SetTeamName( Team.kRed, RED_TEAM_NAME )
	SetTeamName( Team.kBlue, BLUE_TEAM_NAME )
	SetTeamName( Team.kYellow, YELLOW_TEAM_NAME )
	SetTeamName( Team.kGreen, GREEN_TEAM_NAME )

	-- Blue Team Class limits (only soldier)
	for i = Team.kBlue, Team.kGreen do
	local team = GetTeam(i)
		team:SetClassLimit( Player.kScout, -1 )
		team:SetClassLimit( Player.kSniper, -1 )
		team:SetClassLimit( Player.kSoldier, 0 )
		team:SetClassLimit( Player.kDemoman, -1 )
		team:SetClassLimit( Player.kMedic, -1 )
		team:SetClassLimit( Player.kHwguy, -1 )
		team:SetClassLimit( Player.kPyro, -1 )
		team:SetClassLimit( Player.kSpy, -1 )
		team:SetClassLimit( Player.kEngineer, -1 )
		team:SetClassLimit( Player.kCivilian, -1 )
    end
end

function player_spawn( player_entity )
	local player = CastToPlayer( player_entity )
	player:AddHealth( 400 )
	player:AddArmor( 400 )

	player:AddAmmo( Ammo.kNails, 400 )
	player:AddAmmo( Ammo.kShells, 400 )
	player:AddAmmo( Ammo.kRockets, 400 )
	player:AddAmmo( Ammo.kCells, 400 )
	player:AddAmmo( Ammo.kDetpack, 1 )
	player:RemoveAmmo( Ammo.kGren2, 4 )
	player:RemoveAmmo( Ammo.kGren1, 4 )
	player:AddAmmo( Ammo.kGren1, 2 )
	
	player:SetFriction( FRICTION_MODIFIER )
	player:AddEffect( EF.kSpeedlua1, -1, 0, SPEED_MODIFIER )
	
end

function precache()
	PrecacheSound("misc.bloop")
end


-- Calls a function to check if a team has won every time someone dies
function player_killed( killed_entity )
	local player = CastToPlayer( killed_entity )
	player:Spectate ( SpecMode.kRoaming )
	player:SetRespawnable( false )
	CheckTeamAliveState()
end

-- Check team win if someone disconnects, to prevent game getting stuck in 1v* situations
function player_disconnect()
	CheckTeamAliveState()
	return true
end

-- Checks to see if people are still alive. If one team is all dead, declare the other team the winners.
function CheckTeamAliveState()
	ConsoleToAll( "CheckTeamAliveState" )
	teamz = {}

	for i = Team.kBlue, Team.kGreen do
		col = Collection()
		col:GetByFilter({CF.kPlayers, i+14})
		
		teamz[i] = {}
		teamz[i].alive = 0
		teamz[i].index = i

		for player in col.items do
			local player = CastToPlayer(player)
			if player:IsAlive() then 
				teamz[i].alive = teamz[i].alive + 1 
			end
		end
	end
	
	-- checks to see if rest of the teams are all dead. If so, declare the suriving team the winner, and start new round. If not, set the killed player to spectate
	
	local aliveTeams = {}

	for _, team in pairs(teamz) do
	    if team.alive > 0 then
	        table.insert(aliveTeams, team)
	    end
	end

	if #aliveTeams == 1 then
	    local winner = aliveTeams[1]

	    local winningTeam = GetTeam(winner.index)
	    BroadCastMessage(winningTeam:GetName() .. " win!")
	    BroadCastSound("misc.bloop")
	    winningTeam:AddScore(10)

	    AddSchedule("respawnall", 3, respawnall)
		elseif #aliveTeams == 0 then -- If either team has no players, then exit. Just one person running about shouldn't get boxed up.
			AddSchedule("respawnall", 1 , respawnall)
		else
	    return
	end
end

-- checks that enemies are damaging, not self or fall damage
function player_ondamage( player, damageinfo )
  	local attacker = damageinfo:GetAttacker()
  	-- -- If no attacker do nothing
  	-- if not attacker then 
		-- damageinfo:SetDamage(0)
		-- return
  	-- end

  	-- -- If attacker not a player do nothing
  	-- if not IsPlayer(attacker) then 
	 	-- damageinfo:SetDamage(0)
		-- return
  	-- end
  	local playerAttacker = CastToPlayer(attacker)

 	-- If player is damaging self do no damage and modify knockback
  	if player:GetId() == playerAttacker:GetId() then
		print("fgsfds")
		-- damageinfo:SetDamage(0)
		damageinfo:SetDamageForce( damageinfo:GetDamageForce() * BLASTJUMP_MODIFIER )
		return 
  	end
end


-- Respawns all players.
function RespawnEveryone()
	ApplyToAll({ AT.kRemovePacks, AT.kRemoveProjectiles, AT.kRespawnPlayers, AT.kRemoveBuildables, AT.kRemoveRagdolls, AT.kStopPrimedGrens, AT.kReloadClips, AT.kAllowRespawn, AT.kReturnDroppedItems })
end


---------------------------------
-- Scheduled functions
---------------------------------

function respawnall()
	RespawnEveryone()
end

-----------------------------------------------------------------------------
-- spawn validty checking
-----------------------------------------------------------------------------

-- makes sure the VIP can only spawn in their teams base
normal_spawn = info_ff_teamspawn:new({ validspawn = function(self, player)
		return EVENT_ALLOWED
end})

-- Ties the map's spawn entities to the above functions
normalspawn = normal_spawn:new()

-- team spawns, if wanted
team_spawn = info_ff_teamspawn:new({ validspawn = function(self, player)
		return player:GetTeamId() == self.team
end})

bluespawn = team_spawn:new({ team = Team.kBlue })
redspawn = team_spawn:new({ team = Team.kRed })


-----------------------------------------------------------------------------
-- Lua jumppad/upjet because i like jumppads but dislike trigger_push
-----------------------------------------------------------------------------
upjet_simple = trigger_ff_script:new({ force = Vector( 0, 0, 800 ), exponent = 0.9 })

function upjet_simple:allowed( input_entity )
	if IsPlayer( input_entity ) then return true; end
end

function upjet_simple:onstarttouch( input_entity )
	local player = CastToPlayer( input_entity )
	local startvel = player:GetVelocity()

	player:SetVelocity( Vector(
	startvel.x * self.exponent + self.force.x,
	startvel.y * self.exponent + self.force.y,
	startvel.z * self.exponent + self.force.z ) )
end

sjet_001 = upjet_simple:new({ force = Vector( 00, 50, 800 ), exponent = 0 })