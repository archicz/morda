concommand.Add("morda_reload", function()
	morda.RestoreDetours()
	morda.ReloadScript()
end)

concommand.Add("changename", function(ply, cmd, args)
	morda.ChangeName(args[1])
end)

concommand.Add("changename_newline", function(ply, cmd, args)
	morda.ChangeName("\n\n\n\n\n\n\n\n\n\n" .. args[1])
end)

// menu panely
morda.menu = {}

// dulezite
morda.fileWrite = _G["file"]["Write"]
morda.fileRead = _G["file"]["Read"]
morda.fileExists = _G["file"]["Exists"]
morda.preVisRT = GetRenderTarget("m0rd4" .. CurTime(), ScrW(), ScrH())
morda.origCapture = nil
morda.origChatAddText = nil

// ovladaci promenne
morda.sendPacket = true

// menu
morda.menuLast = false
morda.menuToggle = false
morda.menuKey = KEY_INSERT
morda.text = "ratscript ratscript ratscript ratscript"

// fonty
surface.CreateFont("morda1", {font = "Arial", extended = true, size = 18, blursize = 4})
surface.CreateFont("morda2", {font = "Arial", extended = true, size = 18})
surface.CreateFont("morda3", {font = "Arial", extended = true, size = 16})
surface.CreateFont("morda4", {font = "Arial", extended = true, size = 12})
surface.CreateFont("morda5", {font = "Arial", extended = false, size = 12})
surface.CreateFont("morda6", {font = "Arial", extended = false, size = 16, outline = true})

// materialy
morda.mats = {}
morda.mats.chams1 = CreateMaterial("1", "VertexLitGeneric", {["$ignorez"] = 1, ["$model"] = 1, ["$basetexture"] = "models/debug/debugwhite"})
morda.mats.chams2 = CreateMaterial("2", "VertexLitGeneric", {["$ignorez"] = 0, ["$model"] = 1, ["$basetexture"] = "models/debug/debugwhite"})

morda.mats.white = Material("vgui/white")
morda.mats.bg = nil
morda.mats.ico_cfg = Material("icon16/cog.png", "smooth")

// cfg
morda.cfg = {}

// cfg - menu
morda.cfg.menu = {}
morda.cfg.menu.logo = true

// moduly
morda.modules = {}

// konstanty pro typy hodnot
VALTYPE_DECIMAL = 0
VALTYPE_ABSOLUTE = 1
VALTYPE_ANGLE = 2

morda.valTypesStringFormats =
{
	[VALTYPE_DECIMAL] = "%.2f",
	[VALTYPE_ABSOLUTE] = "%i",
	[VALTYPE_ANGLE] = "%i°",
}

morda.modules["serverlagger"] = 
{
	["active"] = false,
	["name"] = "Server Lagger",
	["cfg"] = 
	{
		["amount"] =
		{
			["desc"] = "Factor",
			["type"] = "slider",
			["min"] = 1,
			["max"] = 2000,
			["valtype"] = VALTYPE_ABSOLUTE,
			["val"] = 200,
		},
		["key"] = 
		{
			["desc"] = "Lagger Key",
			["type"] = "key",
			["val"] = KEY_HOME,
		},
	},
	["cfgorder"] = {"amount", "key"},
	
	["Init"] = function(mod) end,
	
	["Render"] = function(mod) end,
	
	["RenderScreenspace"] = function(mod) end,
	
	["PreDrawHalos"] = function(mod) end,
	
	["Think"] = function(mod)
		if input.IsKeyDown(mod.cfg.key.val) then
			for i = 1, tonumber(mod.cfg.amount.val) do
				morda.FileFlood()
			end
		end
	end,
	
	["CreateMove"] = function(mod, cmd) end,
}

morda.modules["seqfreeze"] = 
{
	["active"] = false,
	["name"] = "Sequence Freezing",
	["cfg"] = 
	{
		["ticks"] =
		{
			["desc"] = "Ticks",
			["type"] = "slider",
			["min"] = 1,
			["max"] = 16,
			["valtype"] = VALTYPE_ABSOLUTE,
			["val"] = 8,
		},
		["seqadd"] =
		{
			["desc"] = "Add Sequence",
			["type"] = "slider",
			["min"] = 1,
			["max"] = 16,
			["valtype"] = VALTYPE_ABSOLUTE,
			["val"] = 1,
		},
		["freeze"] = 
		{
			["desc"] = "Freeze Key",
			["type"] = "key",
			["val"] = KEY_PAGEDOWN,
		},
	},
	["cfgorder"] = {"ticks", "seqadd", "freeze"},
	
	["Init"] = function(mod) end,
	
	["Render"] = function(mod) end,
	
	["RenderScreenspace"] = function(mod) end,
	
	["PreDrawHalos"] = function(mod) end,
	
	["LockSequence"] = 0,
	
	["SequenceNew"] = 0,
	
	["Next"] = 0,
	
	["Think"] = function(mod) end,
	
	["CreateMove"] = function(mod, cmd)
		if input.IsKeyDown(mod.cfg.freeze.val) then
			morda.SetOutSequence(mod["LockSequence"])
			mod["SequenceNew"] = mod["SequenceNew"] + mod.cfg.seqadd.val
			
			if morda.GetTickCount() > mod["Next"] then
				mod["Next"] = morda.GetTickCount() + mod.cfg.ticks.val
				mod["LockSequence"] = mod["SequenceNew"]
			end
		else
			mod["LockSequence"] = morda.GetOutSequence()
			mod["SequenceNew"] = mod["LockSequence"]
		end
	end,
}

morda.modules["plyvis"] = 
{
	["active"] = false,
	["name"] = "Player Visuals",
	["cfg"] = 
	{
		["ndormant"] = 
		{
			["desc"] = "Not Dormant",
			["type"] = "toggle",
			["val"] = false,
		},
		["alive"] = 
		{
			["desc"] = "Alive",
			["type"] = "toggle",
			["val"] = false,
		},
		["boxesp"] = 
		{
			["desc"] = "Box ESP",
			["type"] = "toggle",
			["val"] = false,
		},
		["boutline"] = 
		{
			["desc"] = "Outline Color",
			["type"] = "color",
			["val"] = Color(0, 200, 200, 255),
		},
		["chams"] = 
		{
			["desc"] = "Chams",
			["type"] = "toggle",
			["val"] = false,
		},
		["chamsvis"] = 
		{
			["desc"] = "Chams Visible",
			["type"] = "color",
			["val"] = Color(0, 255, 0, 255),
		},
		["chamsinvis"] = 
		{
			["desc"] = "Chams Invisible",
			["type"] = "color",
			["val"] = Color(255, 255, 0, 255),
		},
		["glow"] = 
		{
			["desc"] = "Glow",
			["type"] = "toggle",
			["val"] = false,
		},
		["glowblur"] =
		{
			["desc"] = "Glow Blur",
			["type"] = "slider",
			["min"] = 0,
			["max"] = 4,
			["valtype"] = VALTYPE_ABSOLUTE,
			["val"] = 0,
		},
		["glowclr"] = 
		{
			["desc"] = "Glow Color",
			["type"] = "color",
			["val"] = Color(0, 255, 255, 255),
		},
	},
	["cfgorder"] = {"ndormant", "alive", "%", "boxesp", "boutline", "%", "chams", "chamsvis", "chamsinvis", "%", "glow", "glowblur", "glowclr"},
	
	["Init"] = function(mod) end,
	
	["Render"] = function(mod)
		if not mod.cfg.boxesp.val then return end
	
		for _, ply in pairs(player.GetAll()) do
			if ply == LocalPlayer() then continue end
			if ply:IsDormant() and mod.cfg.ndormant.val then continue end
			if not ply:Alive() and mod.cfg.alive.val then continue end
			
			local trans = ply:GetInternalVariable("m_rgflCoordinateFrame")
			local min = ply:OBBMins()
			local max = ply:OBBMaxs()
			
			local visible = true
			local pointsTransformed = {}
			local points = 
			{
				Vector(min.x, min.y, min.z),
				Vector(min.x, max.y, min.z),
				Vector(max.x, max.y, min.z),
				Vector(max.x, min.y, min.z),
				Vector(max.x, max.y, max.z),
				Vector(min.x, max.y, max.z),
				Vector(min.x, min.y, max.z),
				Vector(max.x, min.y, max.z)
			}
			
			for i = 1, 8 do
				local screenCoords = morda.TransformVector(points[i], trans):ToScreen()
				if visible and not screenCoords.visible then visible = false end
				
				pointsTransformed[i] = {["x"] = screenCoords.x, ["y"] = screenCoords.y}
			end
			
			if not visible then continue end
			
			local flb = pointsTransformed[4]
			local brt = pointsTransformed[6]
			local blb = pointsTransformed[1]
			local frt = pointsTransformed[5]
			local frb = pointsTransformed[3]
			local brb = pointsTransformed[2]
			local blt = pointsTransformed[7]
			local flt = pointsTransformed[8]

			local left = flb.x;
			local top = flb.y;
			local right = flb.x;
			local bottom = flb.y;
			
			local arr = {flb, brt, blb, frt, frb, brb, blt, flt}
			
			for i = 1, 8 do
				if left > arr[i].x then left = arr[i].x end
				if top < arr[i].y then top = arr[i].y end
				if right < arr[i].x then right = arr[i].x end
				if bottom > arr[i].y then bottom = arr[i].y end
			end
			
			// LINES
			surface.SetDrawColor(mod.cfg.boutline.val)
			//surface.SetDrawColor(Color(255, 0, 0, 255))
			surface.DrawLine(left, bottom, left, top)
			
			//surface.SetDrawColor(Color(0, 255, 0, 255))
			surface.DrawLine(left, top, right, top)
			
			//surface.SetDrawColor(Color(0, 0, 255, 255))
			surface.DrawLine(right, top, right, bottom)
			
			//surface.SetDrawColor(Color(0, 255, 255, 255))
			surface.DrawLine(right, bottom, left, bottom)
			
			// BLACK OUTLINE
			surface.SetDrawColor(Color(0, 0, 0, 255))
			surface.DrawLine(left - 1, bottom - 1, left - 1, top + 1)
			surface.DrawLine(left - 1, top + 1, right + 1, top + 1)
			surface.DrawLine(right + 1, top + 1, right + 1, bottom - 1)
			surface.DrawLine(right + 1, bottom - 1, left - 1, bottom - 1)
			
			// HP BAR
			surface.SetDrawColor(Color(0, 0, 0, 255))
			surface.DrawLine(right + 4, top + 1, right + 4, bottom - 1)
			surface.DrawLine(right + 4, top + 1, right + 7, top + 1)
			surface.DrawLine(right + 7, top + 1, right + 7, bottom - 1)
			surface.DrawLine(right + 4, bottom - 1, right + 8, bottom - 1)
			
			local healthY = math.Remap(math.Clamp(ply:Health(), 0, ply:GetMaxHealth()), 0, 100, top, bottom - 1)
			
			surface.SetDrawColor(Color(0, 255, 0, 255))
			surface.DrawLine(right + 5, top, right + 5, healthY)
			surface.DrawLine(right + 6, top, right + 6, healthY)
			
			// TEXT
			draw.SimpleText(ply:Nick(), "morda6", (left + right) / 2, top, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText(ply:GetActiveWeapon():GetClass(), "morda6", (left + right) / 2, bottom, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		end
	end,
	
	["RenderScreenspace"] = function(mod)
		if not mod.cfg.chams.val then return end
		
		for _, ply in pairs(player.GetAll()) do
			if ply == LocalPlayer() then continue end
			if ply:IsDormant() and mod.cfg.ndormant.val then continue end
			if not ply:Alive() and mod.cfg.alive.val then continue end
			
			local visR = mod.cfg.chamsvis.val.r / 255
			local visG = mod.cfg.chamsvis.val.g / 255
			local visB = mod.cfg.chamsvis.val.b / 255
			
			local invisR = mod.cfg.chamsinvis.val.r / 255
			local invisG = mod.cfg.chamsinvis.val.g / 255
			local invisB = mod.cfg.chamsinvis.val.b / 255
			
			local wep = ply:GetActiveWeapon()
			if wep:IsValid() then
				cam.Start3D()
					render.SuppressEngineLighting(true)
						render.MaterialOverride(morda.mats.chams1)
						render.SetColorModulation(invisR, invisG, invisB)
						wep:DrawModel()
									
						render.SetColorModulation(visR, visG, visB)
						render.MaterialOverride(morda.mats.chams2)
						wep:DrawModel()
						render.SuppressEngineLighting(false)
				cam.End3D()
			end
			
			cam.Start3D()
				render.SuppressEngineLighting(true)
					render.MaterialOverride(morda.mats.chams1)
					render.SetColorModulation(invisR, invisG, invisB)
					ply:DrawModel()
							
					render.SetColorModulation(visR, visG, visB)
					render.MaterialOverride(morda.mats.chams2)
					ply:DrawModel()
				render.SuppressEngineLighting(false)
			cam.End3D()
		end
	end,
	
	["PreDrawHalos"] = function(mod)
		if not mod.cfg.glow.val then return end
		local glowPlayers = {}
		local count = 0
		
		for _, ply in pairs(player.GetAll()) do
			if ply == LocalPlayer() then continue end
			if ply:IsDormant() and mod.cfg.ndormant.val then continue end
			if not ply:Alive() and mod.cfg.alive.val then continue end
			
			count = count + 1
			glowPlayers[count] = ply
		end
		
		halo.Add(glowPlayers, mod.cfg.glowclr.val, mod.cfg.glowblur.val, mod.cfg.glowblur.val, 1, true, true)
	end,
	
	["Think"] = function(mod) end,
	
	["CreateMove"] = function(mod, cmd) end,
}

morda.modules["aimbot"] = 
{
	["active"] = false,
	["name"] = "Aimbot",
	["cfg"] = 
	{
		["ndormant"] = 
		{
			["desc"] = "Not Dormant",
			["type"] = "toggle",
			["val"] = false,
		},
		["alive"] = 
		{
			["desc"] = "Alive",
			["type"] = "toggle",
			["val"] = false,
		},
		["head"] = 
		{
			["desc"] = "Head",
			["type"] = "toggle",
			["val"] = false,
		},
		["body"] = 
		{
			["desc"] = "Body",
			["type"] = "toggle",
			["val"] = false,
		},
		["ignoretools"] = 
		{
			["desc"] = "Ignore Tools",
			["type"] = "toggle",
			["val"] = false,
		},
		["wallhit"] = 
		{
			["desc"] = "Bypass TraceHit",
			["type"] = "toggle",
			["val"] = false,
		},
		["sortdistance"] = 
		{
			["desc"] = "Sort by Distance",
			["type"] = "toggle",
			["val"] = false,
		},
		["fovenable"] = 
		{
			["desc"] = "Enable FOV",
			["type"] = "toggle",
			["val"] = false,
		},
		["fov"] =
		{
			["desc"] = "FOV",
			["type"] = "slider",
			["min"] = 0,
			["max"] = 180,
			["valtype"] = VALTYPE_ANGLE,
			["val"] = 1,
		},
		["fovclr"] = 
		{
			["desc"] = "FOV Circle Color",
			["type"] = "color",
			["val"] = Color(0, 255, 255, 255),
		},
	},
	["cfgorder"] = {"ndormant", "alive", "%", "head", "body", "%", "ignoretools", "wallhit", "sortdistance", "fovenable", "fov", "fovclr"},
	
	["Init"] = function(mod) end,
	
	["Render"] = function(mod)
		if mod.cfg.fovenable.val then
			local center = Vector(ScrW() / 2, ScrH() / 2, 0)
			local scale = Vector(mod.cfg.fov.val * 6.1, mod.cfg.fov.val * 6.1, 0)
			local segmentdist = 360 / (2 * math.pi * math.max(scale.x, scale.y) / 2)
			
			surface.SetDrawColor(mod.cfg.fovclr.val.r, mod.cfg.fovclr.val.g, mod.cfg.fovclr.val.b, mod.cfg.fovclr.val.a)
			
			for a = 0, 360 - segmentdist, segmentdist do
				surface.DrawLine(center.x + math.cos(math.rad(a)) * scale.x, center.y - math.sin(math.rad(a)) * scale.y, center.x + math.cos(math.rad(a + segmentdist)) * scale.x, center.y - math.sin(math.rad(a + segmentdist)) * scale.y)
			end
		end
	end,
	
	["RenderScreenspace"] = function(mod) end,
	
	["PreDrawHalos"] = function(mod) end,
	
	["Think"] = function(mod) end,
	
	["GetHeadPos"] = function(ply)
		local headPos = ply:LocalToWorld(Vector(0, 0, 10))
		local headID = ply:LookupBone("ValveBiped.Bip01_Head1")
		
		if headID then
			local boneMat = ply:GetBoneMatrix(headID)
			local bonePos = boneMat:GetTranslation()
			local boneAng = boneMat:GetAngles()
			
			headPos = bonePos + (boneAng:Forward() * 2.5)
		end
		
		return headPos
	end,
	
	["GetTorsoPos"] = function(ply)
		local torsoPos = ply:LocalToWorld(Vector(0, 0, 10))
		local torsoID = ply:LookupBone("ValveBiped.Bip01_Pelvis")
		
		if torsoID then
			torsoPos = ply:GetBoneMatrix(torsoID):GetTranslation()
		end
		
		return torsoPos
	end,
	
	["FindTarget"] = function(mod, cmd)
		local targets = {}
		local i = 0
		
		for _, ply in pairs(player.GetAll()) do
			if ply == LocalPlayer() then continue end
			if ply:IsDormant() and mod.cfg.ndormant.val then continue end
			if not ply:Alive() and mod.cfg.alive.val then continue end
			
			local headPos = mod.GetHeadPos(ply)
			local torsoPos = mod.GetTorsoPos(ply)
			
			local canHitHead = false
			local canHitTorso = false
			
			if mod.cfg.head.val then
				canHitHead = morda.TraceHit(headPos)
			end
			
			if mod.cfg.body.val then
				canHitTorso = morda.TraceHit(torsoPos)
			end
			
			if not mod.cfg.wallhit.val and not canHitHead and not canHitTorso then continue end
			
			i = i + 1
			targets[i] =
			{
				["ply"] = ply,
				["canHead"] = canHitHead,
				["canBody"] = canHitTorso,
			}
		end
		
		if mod.cfg.sortdistance.val then
			table.sort(targets, function(a, b)
				return a["ply"]:GetPos():DistToSqr(LocalPlayer():GetPos()) < b["ply"]:GetPos():DistToSqr(LocalPlayer():GetPos())
			end)
		end
		
		if mod.cfg.fovenable.val then
			for _, target in pairs(targets) do
				local checkPos = target["ply"]:GetPos()
				
				if mod.cfg.body.val then
					checkPos = mod.GetTorsoPos(target["ply"])
				end
					
				if mod.cfg.head.val then
					checkPos = mod.GetHeadPos(target["ply"])
				end
				
				local va = cmd:GetViewAngles()
				local pos = checkPos - LocalPlayer():EyePos()
				local ang = pos:Angle()
				
				local CalcX = ang.x - va.x
				local CalcY = ang.y - va.y
				
				if CalcY < 0 then CalcY = CalcY * - 1 end	
				if CalcX < 0 then CalcX = CalcX * - 1 end
				if CalcY > 360 then CalcY = CalcY - 360 end
				if CalcX > 360 then CalcX = CalcX - 360 end
				if CalcY > 180 then CalcY = 360 - CalcY end
				if CalcX > 180 then CalcX = 360 - CalcX end
				
				if CalcX <= mod.cfg.fov.val / 2 and CalcY <= mod.cfg.fov.val * 0.4 then
					return target
				end
			end
		else
			if targets[1] then
				return targets[1]
			end
		end
		
		return nil
	end,
	
	["PredictPos"] = function(pos)
		local myvel = LocalPlayer():GetVelocity()
		local pos = pos - (myvel * engine.TickInterval())
		
		return pos
	end,
	
	["ToolsList"] =
	{
		["weapon_physgun"] = true,
		["gmod_tool"] = true,
		["gmod_camera"] = true,
		["weapon_physcannon"] = true
	},
	
	["IgnoreWeapon"] = function(mod)
		return mod.ToolsList[LocalPlayer():GetActiveWeapon():GetClass()]
	end,
	
	["CreateMove"] = function(mod, cmd)
		if not cmd:KeyDown(IN_ATTACK) then return end
		if not LocalPlayer():Alive() then return end
		if mod.cfg.ignoretools.val and mod.IgnoreWeapon(mod) then return end
		
		local target = mod.FindTarget(mod, cmd)
		if target then
			local bonePos = Vector(0, 0, 0)
			local finalPos = Vector(0, 0, 0)
			
			if mod.cfg.wallhit.val then
				if mod.cfg.body.val then
					bonePos = mod.GetTorsoPos(target["ply"])
				end
					
				if mod.cfg.head.val then
					bonePos = mod.GetHeadPos(target["ply"])
				end
			else
				if target["canBody"] then
					bonePos = mod.GetTorsoPos(target["ply"])
				end
				
				if target["canHead"] then
					bonePos = mod.GetHeadPos(target["ply"])
				end
			end
			
			finalPos = mod.PredictPos(bonePos)
			
			local aimAng = (finalPos - LocalPlayer():GetShootPos()):Angle()
			cmd:SetViewAngles(aimAng)
		end
		
		morda.createMoveRet = mod.cfg.silent.val
	end,
}

morda.modules["fakelag"] = 
{
	["active"] = false,
	["name"] = "Fakelag",
	["cfg"] = 
	{
		["factor"] =
		{
			["desc"] = "Factor",
			["type"] = "slider",
			["min"] = 1,
			["max"] = 16,
			["valtype"] = VALTYPE_ABSOLUTE,
			["val"] = 10,
		},
		["crouch"] = 
		{
			["desc"] = "Fake Crouch",
			["type"] = "toggle",
			["val"] = false,
		},
	},
	["cfgorder"] = {"factor", "crouch"},
	
	["Init"] = function(mod) end,
	
	["Render"] = function(mod) end,
	
	["RenderScreenspace"] = function(mod) end,
	
	["PreDrawHalos"] = function(mod) end,
	
	["Think"] = function(mod) end,
	
	["NextUnlag"] = 0,
	
	["CreateMove"] = function(mod)
		if morda.GetTickCount() > mod["NextUnlag"] then
			morda.sendPacket = true
			mod["NextUnlag"] = morda.GetTickCount() + mod.cfg.factor.val
		else
			morda.sendPacket = false
		end
	end,
}

morda.modules["tts"] = 
{
	["active"] = false,
	["name"] = "TTS Voice",
	["cfg"] = 
	{
		["onlylocal"] = 
		{
			["desc"] = "Only Self",
			["type"] = "toggle",
			["val"] = false,
		}
	},
	["cfgorder"] = {"onlylocal"},
	
	["AddToQueue"] = function(mod, txt)
		if string.sub(txt, 1, 1) == ">" then
			local finalStr = string.upper(string.JavascriptSafe(string.sub(txt, 2, #txt)))
			if #finalStr > 250 then return end
			
			table.insert(mod.Queue, finalStr .. " ]")
		end
	end,
	
	["Init"] = function(mod) end,
	
	["Render"] = function(mod)
		local rainbow = HSVToColor((CurTime() * 200) % 360, 1, 1)
		local rainbow2 = HSVToColor((100 + CurTime() * 200) % 360, 1, 1)

		rainbow.a = menualpha
		rainbow2.a = menualpha

		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(42, 250, 310, 75)

		surface.SetDrawColor(rainbow)
		surface.DrawOutlinedRect(42, 250, 310, 75)

		local textus = string.format("Lmao power.\nStatus: %s\nRemaining: %i", morda.VoiceGetFinished() and "Idle" or "Busy", table.Count(mod.Queue))
		draw.DrawText(textus, "Trebuchet24", 50 + 2, 250 + 2, rainbow2)
		draw.DrawText(textus, "Trebuchet24", 50, 250, rainbow)
	end,
	
	["RenderScreenspace"] = function(mod) end,
	
	["PreDrawHalos"] = function(mod) end,
	
	["Playing"] = false,
	
	["Queue"] = {},
	
	["Tick"] = function(mod)
		if morda.VoiceGetFinished() then
			if not mod.Playing and #mod.Queue > 0 then
				morda.VoicePlaySAM(mod.Queue[1])
				table.remove(mod.Queue, 1)

				mod.Playing = true
			else
				mod.Playing = false
			end
		end
	
		morda.VoiceTick()
	end,
	
	["CreateMove"] = function(mod) end,
}

// util funkce
function morda.DotProduct(v1, v2)
	return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end

function morda.TransformVector(vec, trans)
	local out = Vector(0, 0, 0)
	
	out.x = morda.DotProduct(vec, Vector(trans[1], trans[2], trans[3])) + trans[4]
	out.y = morda.DotProduct(vec, Vector(trans[5], trans[6], trans[7])) + trans[8]
	out.z = morda.DotProduct(vec, Vector(trans[9], trans[10], trans[11])) + trans[12]
	
	return out
end

function morda.LinearGradient(x, y, w, h, stops, horizontal)
	if #stops == 0 then
		return
	elseif #stops == 1 then
		surface.SetDrawColor(stops[1].color)
		surface.DrawRect(x, y, w, h)
		return
	end

	table.SortByMember(stops, "offset", true)

	render.SetMaterial(morda.mats.white)
	mesh.Begin(MATERIAL_QUADS, #stops - 1)
	for i = 1, #stops - 1 do
		local offset1 = math.Clamp(stops[i].offset, 0, 1)
		local offset2 = math.Clamp(stops[i + 1].offset, 0, 1)
		if offset1 == offset2 then continue end

		local deltaX1, deltaY1, deltaX2, deltaY2

		local color1 = stops[i].color
		local color2 = stops[i + 1].color

		local r1, g1, b1, a1 = color1.r, color1.g, color1.b, color1.a
		local r2, g2, b2, a2
		local r3, g3, b3, a3 = color2.r, color2.g, color2.b, color2.a
		local r4, g4, b4, a4

		if horizontal then
			r2, g2, b2, a2 = r3, g3, b3, a3
			r4, g4, b4, a4 = r1, g1, b1, a1
			deltaX1 = offset1 * w
			deltaY1 = 0
			deltaX2 = offset2 * w
			deltaY2 = h
		else
			r2, g2, b2, a2 = r1, g1, b1, a1
			r4, g4, b4, a4 = r3, g3, b3, a3
			deltaX1 = 0
			deltaY1 = offset1 * h
			deltaX2 = w
			deltaY2 = offset2 * h
		end

		mesh.Color(r1, g1, b1, a1)
		mesh.Position(Vector(x + deltaX1, y + deltaY1))
		mesh.AdvanceVertex()

		mesh.Color(r2, g2, b2, a2)
		mesh.Position(Vector(x + deltaX2, y + deltaY1))
		mesh.AdvanceVertex()

		mesh.Color(r3, g3, b3, a3)
		mesh.Position(Vector(x + deltaX2, y + deltaY2))
		mesh.AdvanceVertex()

		mesh.Color(r4, g4, b4, a4)
		mesh.Position(Vector(x + deltaX1, y + deltaY2))
		mesh.AdvanceVertex()
	end
	mesh.End()
end

function morda.SimpleLinearGradient(x, y, w, h, startColor, endColor, horizontal)
	morda.LinearGradient(x, y, w, h, { {offset = 0, color = startColor}, {offset = 1, color = endColor} }, horizontal)
end

// hovna ohledne menu
function morda.DrawLogoPanel(s, w, h)
	if h == 0 then return end

	local x, y = s:LocalToScreen(0, 0)
	
	surface.SetDrawColor(Color(0, 0, 0, 255))
	surface.DrawRect(0, 0, w, h)
	
	surface.SetMaterial(morda.mats.bg)
	surface.SetDrawColor(Color(255, 255, 255))
	surface.DrawTexturedRect(0, 0, w, h)
	
	local T = CurTime()
	
	surface.SetFont("morda2")
	local cx = 0
	local cy = 0
	local totalw, _ = surface.GetTextSize(morda.text)
	totalw = totalw + (4 * #morda.text)
	local scroll = -6 //math.Remap((T * 40) % totalw, 0, totalw, -w, totalw)
	
	for i = 1, #morda.text do
		local char = morda.text[i]
		local cw, ch = surface.GetTextSize(char)
			
		cy = (h / 2) - (math.cos(2 * T + i / 8) * h / 3) - (ch / 2)
			
		surface.SetTextColor(HSVToColor((T * 50 + i * 2) % 360, 1, 1))
		surface.SetTextPos(cx - scroll, cy)
		surface.SetFont("morda1")
		surface.DrawText(char)
			
		surface.SetTextColor(HSVToColor((T * 50 + i * 2) % 360, 1, 1))
		surface.SetTextPos(cx - scroll, cy)
		surface.SetFont("morda2")
		surface.DrawText(char)
			
		cx = cx + cw + 3.75
	end
	
	surface.SetDrawColor(Color(64, 64, 64, 255))
	surface.DrawOutlinedRect(0, 0, w, h)
		
	local hsvS = HSVToColor((T * 50) % 360, 1, 1)
	local hsvE = HSVToColor((T * 50 + (#morda.text * 2)) % 360, 1, 1)
	morda.SimpleLinearGradient(x, y, w, 1, hsvS, hsvE, true)
	morda.SimpleLinearGradient(x, y + h - 1, w, 1, hsvS, hsvE, true)
		
	morda.SimpleLinearGradient(x, y, w / 2, h, Color(0, 0, 0, 255), Color(0, 0, 0, 0), true)
	morda.SimpleLinearGradient(x + w / 2, y, w / 2, h, Color(0, 0, 0, 0), Color(0, 0, 0, 255), true)
end

function morda.DrawStatusPanel(s, w, h)
	surface.SetDrawColor(Color(16, 16, 16, 255))
	surface.DrawRect(0, 0, w, h)
	
	draw.SimpleText("ratscript second edition", "morda3", w / 2, 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText("morda technology pillpress technique", "morda4", w / 2, 16, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		
	surface.SetDrawColor(Color(64, 64, 64, 255))
	surface.DrawOutlinedRect(0, 0, w, h)
end

function morda.ToggleLogoFX()
	morda.cfg.menu.logo = !morda.cfg.menu.logo
	
	if morda.cfg.menu.logo then
		morda.menu.statusPanel:MoveTo(4, morda.menu.logoPanel.realH + 8, 1, 0, -1, function() end)
		morda.menu.logoPanel:SizeTo(morda.menu.logoPanel:GetWide(), morda.menu.logoPanel.realH, 1, 0, -1, function() end)
		
		morda.menu.modulesPanel:MoveTo(4, morda.menu.logoPanel.realH + 8 + morda.menu.statusPanel.realH + 4, 1, 0, -1, function() end)
		morda.menu.modulesPanel:SizeTo(morda.menu.logoPanel:GetWide(), morda.menu.frame:GetTall() - morda.menu.logoPanel.realH - morda.menu.statusPanel.realH - 16, 1, 0, -1, function() end)
	else
		morda.menu.statusPanel:MoveTo(4, 4, 1, 0, -1, function() end)
		morda.menu.logoPanel:SizeTo(morda.menu.logoPanel:GetWide(), 0, 1, 0, -1, function() end)
		
		morda.menu.modulesPanel:MoveTo(4, morda.menu.statusPanel.realH + 8, 1, 0, -1, function() end)
		morda.menu.modulesPanel:SizeTo(morda.menu.logoPanel:GetWide(), morda.menu.frame:GetTall() - morda.menu.statusPanel.realH - 12, 1, 0, -1, function() end)
	end
end

function morda.CreateToggleBtn(parent)
	local btn = vgui.Create("DCheckBox", parent)
	btn:SetText("")
	btn.alphaLerp = 0
	btn.Paint = function(s, w, h)
		surface.SetDrawColor(Color(16, 16, 16, 255))
		surface.DrawRect(0, 0, w, h)
		
		s.alphaLerp = Lerp(20 * FrameTime(), s.alphaLerp, s:GetChecked() and 255 or 0)
		
		surface.SetDrawColor(Color(222, 0, 0, s.alphaLerp))
		surface.DrawRect(3, 3, w - 6, h - 6)
			
		surface.SetDrawColor(Color(64, 64, 64, 255))
		surface.DrawOutlinedRect(0, 0, w, h)
	end
	
	function btn:SetValueNoAnim(val)
		self.alphaLerp = val and 255 or 0
		self:SetValue(val)
	end

	return btn
end

function morda.CreateIconButton(parent)
	local btn = vgui.Create("DButton", parent)
	btn:SetText("")
	btn.Paint = function(s, w, h)
		surface.SetDrawColor(Color(16, 16, 16, 255))
		surface.DrawRect(0, 0, w, h)
		
		if s.mat then
			surface.SetDrawColor(Color(255, 255, 255, 255))
			surface.SetMaterial(s.mat)
			surface.DrawTexturedRect(3, 3, w - 6, h - 6)
		end
			
		surface.SetDrawColor(Color(64, 64, 64, 255))
		surface.DrawOutlinedRect(0, 0, w, h)
	end
	function btn:SetIcon(mat)
		self.mat = mat
	end

	return btn
end

function morda.CreateColorPicker(ctrl)
	local frame = vgui.Create("DPanel")
	frame:SetPos(gui.MouseX(), gui.MouseY())
	frame:SetSize(200, 200)
	frame:MakePopup()
	frame.Paint = function(s, w, h)
		surface.SetDrawColor(Color(32, 32, 32, 255))
		surface.DrawRect(0, 0, w, h)
	end
	frame.Think = function(s)
		if not IsValid(morda.menu.frame) then
			s:Remove()
		end
	end
	
	local closeBtn = vgui.Create("DButton", frame)
	closeBtn:SetText("")
	closeBtn:Dock(TOP)
	closeBtn:DockMargin(2, 2, 2, 2)
	closeBtn:SetTall(15)
	closeBtn.Paint = function(s, w, h)
		surface.SetDrawColor(Color(200, 0, 0, 255))
		surface.DrawRect(0, 0, w, h)
		
		draw.SimpleText("Close", "morda5", w / 2, h / 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.DoClick = function(s)
		ctrl:FuckFrame()
	end
	
	local mixer = vgui.Create("DColorMixer", frame)
	mixer:Dock(FILL)
	mixer:SetPalette(false)
	mixer:SetAlphaBar(true)
	mixer:SetWangs(false)
	mixer:SetColor(ctrl.color)
	
	function mixer:ValueChanged(col)
		ctrl:SetValueColor(Color(col.r, col.g, col.b, col.a))
	end
	
	return frame
end

function morda.CreateColorButton(parent)
	local btn = vgui.Create("DButton", parent)
	btn:SetText("")
	btn.color = Color(255, 255, 255, 255)
	btn.pickerFrame = nil
	btn.Paint = function(s, w, h)
		surface.SetDrawColor(Color(16, 16, 16, 255))
		surface.DrawRect(0, 0, w, h)
		
		surface.SetDrawColor(s.color)
		surface.DrawRect(3, 3, w - 6, h - 6)
			
		surface.SetDrawColor(Color(64, 64, 64, 255))
		surface.DrawOutlinedRect(0, 0, w, h)
	end
	
	function btn:FuckFrame()
		btn.pickerFrame:Remove()
		btn.pickerFrame = nil
	end
	
	function btn:DoClick()
		btn.pickerFrame = morda.CreateColorPicker(btn)
	end
	
	function btn:SetValueColorF(val)
		self.color = val
	end
	
	function btn:SetValueColor(val)
		self.color = val
		self:ColorChanged(val)
	end

	return btn
end

function morda.CreateConfigControl(parent, cfgTbl, cfgName)
	local ctrlType = cfgTbl["type"]
	local ctrlDesc = cfgTbl["desc"]
	
	local ctrlPnl = vgui.Create("DPanel", parent)
	ctrlPnl:SetTall(21)
	ctrlPnl.Paint = function(s, w, h)
		surface.SetDrawColor(Color(64, 64, 64, 255))
		surface.DrawOutlinedRect(0, 0, w, h)
	end
	
	local descLabel = vgui.Create("DLabel", ctrlPnl)
	descLabel:Dock(LEFT)
	descLabel:DockMargin(4, 0, 0, 0)
	descLabel:SetWide(100)
	descLabel:SetFont("morda3")
	descLabel:SetText(ctrlDesc)
	
	local ctrl = 0
	
	if ctrlType == "slider" then
		ctrl = vgui.Create("DSlider", ctrlPnl)
		ctrl.Knob:SetWide(1)
		ctrl:SetTrapInside(false)
		ctrl.ValType = cfgTbl["valtype"]
		ctrl.Min = tonumber(cfgTbl["min"])
		ctrl.Max = tonumber(cfgTbl["max"])
		ctrl.Paint = function(s, w, h)
			surface.SetDrawColor(Color(222, 0, 0, 255))
			surface.DrawRect(3, 3, (s.m_fSlideX * w) - 6, h - 6)
			
			draw.SimpleText(string.format(morda.valTypesStringFormats[s.ValType], cfgTbl["val"]), "morda5", w / 2, h / 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
			surface.SetDrawColor(Color(64, 64, 64, 255))
			surface.DrawOutlinedRect(0, 0, w, h)
		end
		ctrl.TranslateValues = function(s, x, y)
			local mappedVal = math.Remap(x, 0, 1, s.Min, s.Max)
			local finalVal = 0
			
			if s.ValType == VALTYPE_DECIMAL or s.ValType == VALTYPE_ANGLE then
				finalVal = math.Round(mappedVal, 2)
			elseif s.ValType == VALTYPE_ABSOLUTE then
				finalVal = math.floor(mappedVal)
			end
			
			cfgTbl["val"] = finalVal
			
			return x, y
		end
		ctrl.Knob.Paint = function(s, w, h) end
		
		ctrl.m_fSlideX = math.Remap(tonumber(cfgTbl["val"]), ctrl.Min, ctrl.Max, 0, 1)
		
		ctrl:SetWide(175)
		ctrl:Dock(RIGHT)
		ctrl:DockMargin(2, 2, 2, 2)
	elseif ctrlType == "key" then
		ctrl = vgui.Create("DBinder", ctrlPnl)
		ctrl:SetTextColor(Color(0, 0, 0, 0))
		ctrl.OnChange = function(s, key)
			cfgTbl["val"] = key
		end
		ctrl.Paint = function(s, w, h)
			draw.SimpleText(s.Trapping and "Press any key" or input.GetKeyName(s:GetValue()), "morda5", w / 2, h / 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
			surface.SetDrawColor(Color(64, 64, 64, 255))
			surface.DrawOutlinedRect(0, 0, w, h)
		end
		
		ctrl:SetValue(cfgTbl["val"])
		
		ctrl:SetWide(175)
		ctrl:Dock(RIGHT)
		ctrl:DockMargin(2, 2, 2, 2)
	elseif ctrlType == "toggle" then
		ctrl = morda.CreateToggleBtn(ctrlPnl)
		ctrl:SetValueNoAnim(tobool(cfgTbl["val"]))
		ctrl.OnChange = function(s, val)
			cfgTbl["val"] = tobool(val)
		end
		
		ctrl:SetWide(16)
		ctrl:Dock(RIGHT)
		ctrl:DockMargin(2, 2, 2, 2)
	elseif ctrlType == "color" then
		ctrl = morda.CreateColorButton(ctrlPnl)
		ctrl:SetValueColorF(cfgTbl["val"])
		ctrl.ColorChanged = function(s, val)
			cfgTbl["val"] = val
		end
		
		ctrl:SetWide(175)
		ctrl:Dock(RIGHT)
		ctrl:DockMargin(2, 2, 2, 2)
	end
	
	return ctrlPnl
end

function morda.CreateConfigSpacer(parent)
	local ctrlPnl = vgui.Create("DPanel", parent)
	ctrlPnl:SetTall(4)
	ctrlPnl.Paint = function(s, w, h) end
	
	return ctrlPnl
end

function morda.CreateModuleButton(parent, modTbl)
	local colPnl = vgui.Create("DCollapsibleCategory", parent)
	colPnl:SetExpanded(false)
	colPnl.Paint = function(s, w, h)
		surface.SetDrawColor(Color(16, 16, 16, 255))
		surface.DrawRect(0, 0, w, h)
			
		surface.SetDrawColor(Color(64, 64, 64, 255))
		surface.DrawOutlinedRect(0, 0, w, h)
	end
	
	local colHeader = colPnl.Header
	colHeader:SetText("")
	colHeader:SetTall(25)
	colHeader:SetCursor("arrow")
	colHeader.Paint = function(s, w, h) end
	colHeader.DoClick = function(s) end
	
	local activeBtn = morda.CreateToggleBtn(colHeader)
	activeBtn:Dock(LEFT)
	activeBtn:DockMargin(4, 4, 3, 4)
	activeBtn:SetWide(16)
	activeBtn:SetValueNoAnim(modTbl["active"])
	activeBtn.OnChange = function(s, val)
		modTbl["active"] = val
	end
	
	local cfgBtn = morda.CreateIconButton(colHeader)
	cfgBtn.active = false
	cfgBtn:Dock(LEFT)
	cfgBtn:DockMargin(0, 4, 3, 4)
	cfgBtn:SetWide(16)
	cfgBtn:SetIcon(morda.mats.ico_cfg)
	cfgBtn.DoClick = function(s)
		colPnl:Toggle()
	end
	
	local nameLabel = vgui.Create("DLabel", colHeader)
	nameLabel:Dock(FILL)
	nameLabel:SetFont("morda3")
	nameLabel:SetText(modTbl["name"])
	
	local cfgList = vgui.Create("DPanel")
	cfgList:DockMargin(4, -1, 4, 4)
	cfgList.Paint = function(s, w, h) end
	colPnl:SetContents(cfgList)
	
	for _, name in pairs(modTbl["cfgorder"]) do
		local cfgName = name
		local cfgTbl = modTbl["cfg"][cfgName]
		local ctrl = nil
		
		if name == "%" then
			ctrl = morda.CreateConfigSpacer(cfgList)
		else
			ctrl = morda.CreateConfigControl(cfgList, cfgTbl, cfgName)
		end
		
		if IsValid(ctrl) then
			ctrl:Dock(TOP)
			ctrl:DockMargin(0, 0, 0, 3)
		end
	end
	
	local fuckDerma = vgui.Create("DPanel", cfgList)
	fuckDerma:Dock(TOP)
	fuckDerma:DockMargin(0, 0, 0, 2)
	fuckDerma:SetTall(1)
	fuckDerma.Paint = function(s, w, h) end
		
	return colPnl
end

function morda.CreateSaveLoadButtons(parent)
	local saveBtn = vgui.Create("DButton", parent)
	saveBtn:SetText("")
	saveBtn:Dock(LEFT)
	saveBtn:DockMargin(3, 2, 3, 3)
	saveBtn:SetTall(20)
	saveBtn:SetWide(192)
	saveBtn.Paint = function(s, w, h)
		surface.SetDrawColor(Color(200, 0, 0, 255))
		surface.DrawRect(0, 0, w, h)
		
		draw.SimpleText("Save", "morda5", w / 2, h / 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	saveBtn.DoClick = function(s)
		morda.SaveConfig()
	end
	
	local loadBtn = vgui.Create("DButton", parent)
	loadBtn:SetText("")
	loadBtn:Dock(RIGHT)
	loadBtn:DockMargin(3, 2, 3, 3)
	loadBtn:SetTall(20)
	loadBtn:SetWide(192)
	loadBtn.Paint = function(s, w, h)
		surface.SetDrawColor(Color(200, 0, 0, 255))
		surface.DrawRect(0, 0, w, h)
		
		draw.SimpleText("Load", "morda5", w / 2, h / 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	loadBtn.DoClick = function(s)
		morda.LoadConfig()
	end
end

function morda.OpenMenu()
	morda.menu.frame = vgui.Create("DFrame")
	morda.menu.frame:SetSize(400, 640)
	morda.menu.frame:Center()
	morda.menu.frame:SetTitle("")
	morda.menu.frame:ShowCloseButton(false)
	morda.menu.frame:SetDraggable(false)
	morda.menu.frame:MakePopup()
	morda.menu.frame.Paint = function(s, w, h)
		surface.SetDrawColor(Color(32, 32, 32, 255))
		surface.DrawRect(0, 0, w, h)
	end
	
	morda.menu.logoPanel = vgui.Create("DPanel", morda.menu.frame)
	morda.menu.logoPanel:SetPos(4, 4)
	morda.menu.logoPanel.realH = 120
	morda.menu.logoPanel:SetSize(morda.menu.frame:GetWide() - 8, morda.cfg.menu.logo and morda.menu.logoPanel.realH or 0)
	morda.menu.logoPanel.Paint = morda.DrawLogoPanel
	
	morda.menu.statusPanel = vgui.Create("DPanel", morda.menu.frame)
	morda.menu.statusPanel:SetPos(4, morda.cfg.menu.logo and (morda.menu.logoPanel.realH + 8) or 4)
	morda.menu.statusPanel.realH = 50
	morda.menu.statusPanel:SetSize(morda.menu.frame:GetWide() - 8, morda.menu.statusPanel.realH)
	morda.menu.statusPanel.Paint = morda.DrawStatusPanel
	
	morda.menu.logoDisable = vgui.Create("DButton", morda.menu.statusPanel)
	morda.menu.logoDisable:SetText("")
	morda.menu.logoDisable:Dock(TOP)
	morda.menu.logoDisable:SetTall(30)
	morda.menu.logoDisable.Paint = function(s, w, h) end
	morda.menu.logoDisable.DoClick = morda.ToggleLogoFX
	
	morda.CreateSaveLoadButtons(morda.menu.statusPanel)
	
	morda.menu.modulesPanel = vgui.Create("DPanel", morda.menu.frame)
	morda.menu.modulesPanel:SetPos(4, morda.cfg.menu.logo and (morda.menu.logoPanel.realH + 8 + morda.menu.statusPanel.realH + 4) or morda.menu.statusPanel.realH + 8)
	morda.menu.modulesPanel:SetSize(morda.menu.frame:GetWide() - 8, morda.cfg.menu.logo and (morda.menu.frame:GetTall() - morda.menu.logoPanel.realH - morda.menu.statusPanel.realH - 16) or morda.menu.frame:GetTall() - morda.menu.statusPanel.realH - 12)
	morda.menu.modulesPanel.Paint = function(s, w, h)
		surface.SetDrawColor(Color(16, 16, 16, 255))
		surface.DrawRect(0, 0, w, h)
		
		surface.SetDrawColor(Color(64, 64, 64, 255))
		surface.DrawOutlinedRect(0, 0, w, h)
	end
	
	morda.menu.modulesPanelList = vgui.Create("DScrollPanel", morda.menu.modulesPanel)
	morda.menu.modulesPanelList:Dock(FILL)
	morda.menu.modulesPanelList:DockMargin(2, 2, 2, 2)
	morda.menu.modulesPanelList:GetVBar():SetWide(0)
	
	for modName, modTbl in pairs(morda.modules) do
		local pnl = morda.CreateModuleButton(morda.menu.modulesPanelList, modTbl)
		pnl:Dock(TOP)
		pnl:DockMargin(0, 0, 0, 2)
	end
end

function morda.CloseMenu()
	morda.menu.frame:Close()
	morda.menu.frame = nil
end

function morda.ToggleMenu()
	local menuBtn = input.IsKeyDown(morda.menuKey)
	
	if menuBtn and menuBtn != menuLast then
		morda.menuToggle = !morda.menuToggle
		
		if morda.menuToggle then
			if not morda.mats.bg then
				steamworks.DownloadUGC(2498039788, function(path)
					game.MountGMA(path)
					
					morda.mats.bg = Material("pozadi")
					morda.OpenMenu()
				end)
			else
				morda.OpenMenu()
			end
		else
			morda.CloseMenu()
		end
	end
	
	menuLast = menuBtn
end

// hlavni kokotiny pod timhle
function morda.SaveConfig()
	local configs = {}
	
	for modName, modTbl in pairs(morda.modules) do
		configs[modName] = {}
		configs[modName]["cfg"] = {}
		configs[modName]["active"] = modTbl["active"]
		
		for cfgName, cfgTbl in pairs(modTbl["cfg"]) do
			configs[modName]["cfg"][cfgName] = cfgTbl["val"]
		end
	end
	
	morda.fileWrite("@.txt", util.TableToJSON(configs))
end

function morda.LoadConfig()
	if not morda.fileExists("@.txt", "DATA") then return end
	local data = morda.fileRead("@.txt", "DATA")
	local configs = util.JSONToTable(data)
	
	for modName, modTbl in pairs(configs) do
		morda.modules[modName]["active"] = modTbl["active"]
		
		for cfgName, cfgVal in pairs(modTbl["cfg"]) do
			morda.modules[modName]["cfg"][cfgName]["val"] = cfgVal
		end
	end
	
	if IsValid(morda.menu.frame) then
		morda.CloseMenu()
		morda.OpenMenu()
	end
end

function morda.TraceHit(pos)
	return util.TraceLine({start = LocalPlayer():GetShootPos(), endpos = pos, mask = MASK_SHOT, filter = player.GetAll()}).Fraction == 1
end

function morda.renderCapture(...)
	print("Screengrab detected.")
	
	render.SetRenderTarget(morda.preVisRT)
	return morda.origCapture(...)
end

function morda.chatAddText(...)
	morda.origChatAddText(...)
	
	local ttsMod = morda.modules["tts"]
	if not ttsMod["active"] then return end
	
	local args = {...}
	local onlyLocal = ttsMod.cfg.onlylocal.val
	
	if onlyLocal then
		if IsEntity(args[1]) and args[1] == LocalPlayer() then
			for k, v in pairs(args) do
				if type(v) == "string" and #v > 5 then
					ttsMod.AddToQueue(ttsMod, string.sub(v, 3, #v))
				end
			end
		end
	else
		for k, v in pairs(args) do
			if type(v) == "string" and #v > 5 then
				ttsMod.AddToQueue(ttsMod, string.sub(v, 3, #v))
			end
		end
	end
end

function morda.Detour()
	morda.origCapture = _G["render"]["Capture"]
	_G["render"]["Capture"] = morda.renderCapture
	
	morda.origChatAddText = _G["chat"]["AddText"]
	_G["chat"]["AddText"] = morda.chatAddText
end

function morda.RestoreDetours()
	_G["render"]["Capture"] = morda.origCapture
	_G["chat"]["AddText"] = morda.origChatAddText
end

function morda.Init()
	morda.Detour()

	for modName, modTbl in pairs(morda.modules) do
		pcall(modTbl["Init"], modTbl)
	end
end

hook.Add("RenderScene", "", function(origin, angles, fov)
    local view =
	{
        x = 0,
        y = 0,
        w = ScrW(),
        h = ScrH(),
        dopostprocess = true,
        origin = origin,
        angles = angles,
        fov = fov,
        drawhud = true,
        drawmonitors = true,
        drawviewmodel = true
    }
	
	render.RenderView(view)
	render.CopyTexture(nil, morda.preVisRT)
	
    cam.Start2D()
		for modName, modTbl in pairs(morda.modules) do
			if modTbl["active"] then
				pcall(modTbl["Render"], modTbl)
			end
		end
    cam.End2D()
 
    return true
end)

hook.Add("Think", "", function()
	morda.ToggleMenu()
	
	for modName, modTbl in pairs(morda.modules) do
		if modTbl["active"] then
			pcall(modTbl["Think"], modTbl)
		end
	end
end)

hook.Add("Tick", "", function()
	for modName, modTbl in pairs(morda.modules) do
		if modTbl["active"] then
			pcall(modTbl["Tick"] or function() end, modTbl)
		end
	end
end)

hook.Add("RenderScreenspaceEffects", "", function()
	if morda.renderingRT then return end

	for modName, modTbl in pairs(morda.modules) do
		if modTbl["active"] then
			pcall(modTbl["RenderScreenspace"], modTbl)
		end
	end
end)

hook.Add("PreDrawHalos", "", function()
	for modName, modTbl in pairs(morda.modules) do
		if modTbl["active"] then
			pcall(modTbl["PreDrawHalos"], modTbl)
		end
	end
end)

hook.Add("CreateMove", "", function(cmd)
	if cmd:CommandNumber() == 0 then return end
	
	morda.UpdatePrediction()
	
	morda.StartPrediction()
		for modName, modTbl in pairs(morda.modules) do
			if modTbl["active"] then
				pcall(modTbl["CreateMove"], modTbl, cmd)
			end
		end
	morda.EndPrediction()
	
	return true
end)