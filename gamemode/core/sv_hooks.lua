function GM:ShowHelp(client)
	/*
	if (!client.character) then
		return
	end
	
	netstream.Start(client, "nut_ShowMenu")
	*/
end

function GM:GetDefaultInv(inventory, client, data)
end

function GM:GetDefaultMoney(client, data)
	return nut.config.startingAmount
end

function GM:PlayerInitialSpawn(client)
	client:SetRenderMode(4)
	client:SetColor(Color(0, 0, 0, 0))

	local delay = 0
	
	if (IsValid(client)) then
		client:KillSilent()
		delay = client:Ping() / 50
	end
	
	netstream.Start(client, "nut_LoadingData", "Waiting for local player.")

	timer.Simple(3 + delay, function()
		if (!IsValid(client)) then
			return
		end

		netstream.Start(client, "nut_LoadingData", "Sending current time.")
		netstream.Start(client, "nut_CurTime", nut.util.GetTime())

		client:KillSilent()
		client:StripWeapons()

		netstream.Start(client, "nut_LoadingData", "Initializing player data.")
		client:InitializeData()

		player_manager.SetPlayerClass(client, "player_nut")
		player_manager.RunClass(client, "Spawn")

		netstream.Start(client, "nut_LoadingData", "Loading characters.")
		nut.char.Load(client, function()
			netstream.Start(client, "nut_LoadingData", "Loading other characters.")

			local total = 0
			local time = 0.1

			for k, v in pairs(player.GetAll()) do
				if (v.character and v != client) then
					total = total + 1
				end
			end

			local i = 0

			for k, v in pairs(player.GetAll()) do
				if (v.character and v != client) then
					local fraction = math.max(client:Ping() / 100, 0.1) + 0.05
					i = i + 1
					time = time + fraction

					timer.Simple(k * fraction, function()
						if (IsValid(client) and IsValid(v)) then
							netstream.Start(client, "nut_LoadingData", "Networking characters... "..math.Round((i / total) * 100).."%")
							v.character:Send(nil, client, true)
						end
					end)
				end
			end
		
			timer.Simple(time + math.max(client:Ping() / 100, 0.1) + 0.1, function()
				netstream.Start(client, "nut_CharMenu")
			end)

			local uniqueID = "nut_SaveChar"..client:SteamID()

			timer.Create(uniqueID, nut.config.saveInterval, 0, function()
				if (!IsValid(client)) then
					timer.Remove(uniqueID)

					return
				end

				nut.char.Save(client)
			end)
		end)
	end)
end

function GM:PlayerLoadedChar(client)
	local faction = client.character:GetVar("faction", 9001)
	client:SetTeam(faction)
	client:SetSkin(client.character:GetData("skin", 0))

	client.character:SetVar("id", math.floor(client.character:GetData("id", os.clock() + client:UniqueID())))

	local customClass = client.character:GetData("customClass")

	if (customClass and customClass != "") then
		client:SetNetVar("customClass", customClass)
	else
		client:SetNetVar("customClass", nil)
	end

	if (!client:GetNutVar("sawCredits")) then
		nut.schema.Call("PlayerFirstLoaded", client)
		client:SetNutVar("sawCredits", true)

		nut.util.SendIntroFade(client)

		timer.Simple(15, function()
			if (!IsValid(client)) then
				return
			end
			
			nut.scroll.Send("NutScript: "..nut.lang.Get("schema_author", "Chessnut and rebel1324"), client, function()
				if (IsValid(client)) then
					nut.scroll.Send(SCHEMA.name..": "..nut.lang.Get("schema_author", SCHEMA.author), client)
				end
			end)
		end)
	end
end

function GM:PlayerSpawn(client)
	client:UnRagdoll(true)
	client:SetNoDraw(false)
	client:SetRenderMode(4)
	client:SetColor(Color(255, 255, 255))
	client:SetNetVar("drunk", 0)
	client:SetNetVar("tied", false)
	client:SetNetVar("noDepress", 0)
	client:SetNetVar("blur", 0)
	client:ScreenFadeOut()

	if (!client.character) then
		return
	end

	client:StripWeapons()
	client:SetModel(client.character.model)
	client:Give("nut_fists")

	player_manager.SetPlayerClass(client, "player_nut")
	player_manager.RunClass(client, "Spawn")

	client:SetWalkSpeed(nut.config.walkSpeed)
	client:SetRunSpeed(nut.config.runSpeed)
	client:SetWepRaised(false)

	local groups = client.character:GetData("groups", {})

	for k, v in pairs(groups) do
		client:SetBodygroup(k, v)
	end

	nut.schema.Call("PlayerLoadout", client)
	
	nut.flag.OnSpawn(client)
	nut.attribs.OnSpawn(client)

	local index = client:CharClass()

	if (index) then
		local classTable = nut.class.Get(index)

		if (classTable and classTable.OnSpawn) then
			classTable:OnSpawn(client)
		end
	end
end

function GM:PlayerDisconnected(client)
	nut.char.Save(client)

	timer.Remove("nut_SaveChar"..client:SteamID())
end

function GM:PlayerSpray(client)
	return false
end

function GM:PlayerShouldTakeDamage()
	return true
end

function GM:CanArmDupe()
	print("Duping?")

	return false
end

function GM:GetGameDescription()
	return "NS - "..(SCHEMA and SCHEMA.name or "Unknown")
end

function GM:GetFallDamage(client, speed)
	speed = speed - 580

	return speed * nut.config.fallDamageScale
end

function GM:ShutDown()
	MsgN("NutScript is shutting down...")

	nut.shuttingDown = true

	for k, v in pairs(player.GetAll()) do
		nut.char.Save(v)
	end

	self:SaveTime()
	nut.schema.Call("SaveData")
end

function GM:PlayerSay(client, text, public)
	local result = nut.chat.Process(client, text)

	if (result) then
		return result
	end
	
	return text
end

function GM:CanPlayerSuicide(client)
	return nut.config.canSuicide
end

function GM:PlayerGiveSWEP(client, class, weapon)
	return client:IsAdmin()
end

function GM:PlayerSpawnSWEP(client, class, weapon)
	return client:IsAdmin()
end

function GM:PlayerSpawnEffect(client, model)
	return client:HasFlag("e")
end

function GM:PlayerSpawnNPC(client, npc, weapon)
	return client:HasFlag("n")
end

function GM:PlayerSpawnObject(client)
	return client:HasFlag("e") or client:HasFlag("r")
end

function GM:PlayerSpawnProp(client, model)
	return client:HasFlag("e")
end

function GM:PlayerSpawnRagdoll(client, model, entity)
	return client:HasFlag("r")
end

function GM:PlayerSpawnSENT(client)
	return client:IsAdmin()
end

function GM:PlayerSpawnVehicle(client, model, name, vehicle)
	return client:HasFlag("c")
end

function GM:PlayerSwitchFlashlight(client, state)
	if (!client:CanUseFlashlight()) then
		return false
	end
	
	if (nut.config.flashlight) then
		return true
	end

	return false
end

function GM:RemoveEntitiesByClass(class)
	for k, v in pairs(ents.FindByClass(class)) do
		SafeRemoveEntity(v)
	end
end

function GM:InitPostEntity()
	nut.schema.Call("LoadData")

	if (nut.config.clearMaps) then
		self:RemoveEntitiesByClass("item_healthcharger")
		self:RemoveEntitiesByClass("prop_vehicle*")
		self:RemoveEntitiesByClass("weapon_*")
		self:RemoveEntitiesByClass("item_suitcharger")
	end
end

function GM:PlayerDeath(victim, weapon, attacker)
	local time = CurTime() + nut.config.deathTime
	time = nut.schema.Call("PlayerGetDeathTime", client, time) or time

	
	victim:SetNutVar("deathTime", time)

	timer.Simple(0, function()
		victim:SetMainBar("You are now respawning.", nut.config.deathTime)
		victim:ScreenFadeIn(nut.config.deathTime * 0.25)
	end)
	if (attacker:IsPlayer()) then
		nut.util.AddLog(Format("%s(%s) killed by %s(%s) with %s.", victim:Name(), victim:SteamID(), attacker:Name(), attacker:SteamID(), weapon:GetClass()), LOG_FILTER_MAJOR)
	else
		nut.util.AddLog(Format("%s(%s) killed by %s.", victim:Name(), victim:SteamID(), attacker:GetClass()), LOG_FILTER_MAJOR)
	end
end

function GM:PlayerDeathSound(client)
	local model = string.lower(client:GetModel())
	local gender = "male"

	if (string.find(model, "female") or nut.anim.GetClass(model) == "citizen_female") then
		gender = "female"
	end

	client:EmitSound("vo/npc/"..gender.."01/pain0"..math.random(7, 9)..".wav")

	return true
end

function GM:PlayerHurt(client, attacker, health, damage)
	if (health <= 0) then
		return true
	end

	local model = string.lower(client:GetModel())
	local gender = "male"

	if (string.find(model, "female") or nut.anim.GetClass(model) == "citizen_female") then
		gender = "female"
	end

	client:EmitSound(nut.schema.Call("PlayerPainSound", client) or "vo/npc/"..gender.."01/pain0"..math.random(1, 6)..".wav")

	return true
end

function GM:PlayerDeathThink(client)
	if (client.character and client:GetNutVar("deathTime", 0) < CurTime()) then
		client:Spawn()

		return true
	end
	
	return false
end

function GM:PlayerCanHearPlayersVoice(speaker, listener)
	return nut.config.allowVoice, nut.config.voice3D
end

function GM:PlayerGetFistDamage(client, damage)
	return damage + client:GetAttrib(ATTRIB_STR, 0)
end

function GM:PlayerThrowPunch(client, attempted)
	local value = 0.001

	if (attempted) then
		value = 0.005
	end

	client:UpdateAttrib(ATTRIB_STR, value)
end

function GM:OnPlayerHitGround(client, inWater, onFloater, fallSpeed)
	if (!inWater and !onFloater) then
		client:UpdateAttrib(ATTRIB_ACR, 0.005)
	end
end

function GM:Initialize()
	local date = nut.util.ReadTable("date", true)
	local time = os.time({
		month = nut.config.dateStartMonth,
		day = nut.config.dateStartDay,
		year = nut.config.dateStartYear
	})

	if (#date < 1) then
		time = time * (nut.config.dateMinuteLength / 60)

		nut.util.WriteTable("date", time, true)
		nut.curTime = time
	else
		nut.curTime = date[1] or time
	end

	if (!nut.config.noPersist) then
		game.ConsoleCommand("sbox_persist 1\n")
	end
end

function GM:SaveTime()
	nut.util.WriteTable("date", tostring(nut.util.GetTime()), true)
end

function GM:PlayerUse(client, entity)
	if (entity.NoUse or client:GetNetVar("tied")) then
		if (client:GetNetVar("tied") and SERVER and client:GetNutVar("nextTieMsg", 0) < CurTime()) then
			nut.util.Notify("You can not do this when tied.", client)
			client:SetNutVar("nextTieMsg", CurTime() + 1)
		end

		return false
	end

	return true
end

function GM:KeyPress(client, key)
	local config = nut.config

	-- PlayerUse hook doesn't get called on doors that don't allow +use :c
	if (key == IN_USE) then
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector() * 56
			data.filter = client
		local trace = util.TraceLine(data)
		local entity = trace.Entity

		if (IsValid(entity) and client:GetNetVar("tied")) then
			if (client:GetNutVar("nextTieMsg", 0) < CurTime() and SERVER) then
				nut.util.Notify("You can not do this when tied.", client)
				client:SetNutVar("nextTieMsg", CurTime() + 1)
			end

			return false
		end

		if (IsValid(entity) and entity:IsDoor()) then
			if (nut.schema.Call("PlayerCanUseDoor", client, entity) == false) then
				return
			end

			return nut.schema.Call("PlayerUseDoor", client, entity)
		elseif (entity:IsPlayer()) then
			return nut.schema.Call("PlayerInteract", client, entity)
		end
	elseif (config.holdReloadToToggle and key == IN_RELOAD) then
		timer.Create("nut_ToggleTime"..client:UniqueID(), config.holdReloadTime, 1, function()
			nut.command.SetShowCommandRan(true)
				nut.command.RunCommand(client, "toggleraise", {})
			nut.command.SetShowCommandRan(false)
		end)
	end
end

function GM:KeyRelease(client, key)
	-- Cancel the toggle timer if they let go.
	if (key == IN_RELOAD) then
		timer.Remove("nut_ToggleTime"..client:UniqueID())
	end
end