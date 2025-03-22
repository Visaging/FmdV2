script_name("FMD GANG - THE MOD")
script_author("FMD GANG")

require"lib.moonloader"
require"lib.sampfuncs"

local ev, vkeys, flag = require "lib.samp.events", require "vkeys", require ('moonloader').font_flag
local inicfg = require 'inicfg'
local imgui, ffi = require 'mimgui', require 'ffi'
local encoding = require "encoding"
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
encoding.default = 'CP1251'
u8 = encoding.UTF8
local playerName, mfont = nil, nil
local recentPatient, loadPatient = 69, 0
local isCharVesting, isLoading, getCurrentPatients, deliverPatient, togd, mousepos = false, false, false, false, false, false
local currentPatientIds, currentPatients, currentAcceptedPatients, fpos = {}, {}, {}, {}
local keys = {
	vkeys.VK_1,
	vkeys.VK_2,
	vkeys.VK_3,
	vkeys.VK_4,
	vkeys.VK_5,
	vkeys.VK_6,
	vkeys.VK_7,
	vkeys.VK_8,
	vkeys.VK_9
}

local fmd = inicfg.load({
	main = {
		saved = 0,
		accepted = 0,
		bprice = 200,
		hprice = 40,
		toggled = true,
		dline = false,
		cfacrad = false,
		sbadge = false,
		bxpos = 296,
		bypos = 202,
		bfontsize = 14,
		bfont = "Arial",
		daily = false,
		mdate = 0,
		dtarget = 5,
		dsaved = 0
	},
	facradio = {r = 0.55, g = 0.21, b = 1, a = 1},
	fontflag = {true,false,true,true},
}, 'fmdV2.ini')

local presettings = {facradio = imgui.new.float[4](fmd.facradio.r, fmd.facradio.g, fmd.facradio.b, fmd.facradio.a),}

local _menu = false
imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
    style()
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
	imgui.GetIO().Fonts:Clear()
    imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\'.."calibri.ttf", 14, nil, glyph_ranges)
	font2 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\'.."calibri.ttf", 12, nil, glyph_ranges)
end)

imgui.OnFrame(function() return _menu and not isGamePaused() end,
function()
    width, height = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(275, 370), imgui.Cond.FirstUseEver)
    imgui.BeginCustomTitle("FMD Mod V2 | Settings", 30, main_win, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar)
        imgui.BeginChild("##69", imgui.ImVec2(265, 330), true)
            imgui.SetCursorPos(imgui.ImVec2(65, 5))
            if imgui.Checkbox(u8"Enable FMD Mod", new.bool(fmd.main.toggled)) then fmd.main.toggled = not fmd.main.toggled saveIni() end
            imgui.Separator()
            imgui.SetCursorPos(imgui.ImVec2(5, 35))
            imgui.BeginChild("##69-1", imgui.ImVec2(255, 160), true)
				if imgui.Button(u8'Faction Radio Color', imgui.ImVec2(-1, 25)) then imgui.OpenPopup('fradclr') end
				if imgui.BeginPopup('fradclr') then
					imgui.BeginChild("##1", imgui.ImVec2(200, 60), true)
					if imgui.Checkbox(u8"Change Faction Radio Color", new.bool(fmd.main.cfacrad)) then fmd.main.cfacrad = not fmd.main.cfacrad saveIni() end
					imgui.Spacing()
					imgui.Text("Select Color: ") imgui.SameLine() imgui.ColorEdit4('##presettings.facradio', presettings.facradio, imgui.ColorEditFlags.NoInputs)
					imgui.EndChild()
				imgui.EndPopup()
				end
				if imgui.Button(u8'Set Prices/Patient Numbers', imgui.ImVec2(-1, 25)) then imgui.OpenPopup('setmenu') end
				if imgui.BeginPopup('setmenu') then
					imgui.BeginChild("##2", imgui.ImVec2(230, 100), true)
					local fnb, fnh, fnd, fna = new.int(fmd.main.bprice), new.int(fmd.main.hprice), new.int(fmd.main.saved), new.int(fmd.main.accepted)
					imgui.PushItemWidth(100)
					imgui.Text("Vest Price: ") imgui.SameLine(120) if imgui.DragInt("##vestprice", fnb, imgui.InputTextFlags.EnterReturnsTrue) then if fnb[0] <= 1000 and fnb[0] >= 200 then fmd.main.bprice = fnb[0] saveIni() end end if imgui.IsItemHovered() then imgui.SetTooltip('Should be between $200 to $1000.') end
					imgui.Text("Heal Price: ") imgui.SameLine(120) if imgui.DragInt("##healprice", fnh, imgui.InputTextFlags.EnterReturnsTrue) then if fnh[0] <= 100 and fnh[0] >= 20 then fmd.main.hprice = fnh[0] saveIni() end end if imgui.IsItemHovered() then imgui.SetTooltip('Should be between $20 to $100.') end
					imgui.Text("Patients Delivered: ") imgui.SameLine(120) if imgui.DragInt("##delivered", fnd, imgui.InputTextFlags.EnterReturnsTrue) then fmd.main.saved = fnd[0] saveIni() end
					imgui.Text("Patients Accepted: ") imgui.SameLine(120) if imgui.DragInt("##accepted", fna, imgui.InputTextFlags.EnterReturnsTrue) then fmd.main.accepted = fna[0] saveIni() end
					imgui.EndChild()
				imgui.EndPopup()
				end
				if imgui.Button(u8'Badge Indicator', imgui.ImVec2(-1, 25)) then imgui.OpenPopup('badgemenu') end
				if imgui.BeginPopup('badgemenu') then
					imgui.BeginChild("##3", imgui.ImVec2(300, 120), true)
						imgui.SetCursorPos(imgui.ImVec2(65, 5))
						if imgui.Checkbox(u8("Enable Badge Indicator"), new.bool(fmd.main.sbadge)) then fmd.main.sbadge = not fmd.main.sbadge saveIni() end
						imgui.Separator()
						imgui.Text("Overlay Position: ") imgui.SameLine() 
						if imgui.Button(mousepos and u8'Cancel##1' or u8'Move with mouse##1', imgui.ImVec2(130, 20)) then mousepos = not mousepos if mousepos then sampAddChatMessage('Press {FF0000}'..vkeys.id_to_name(vkeys.VK_LBUTTON)..' {FFFFFF}to save the position.', -1) end end
		
						fnt = new.char[256](fmd.main.bfont)
						imgui.Text("Font: ") imgui.SameLine() imgui.PushItemWidth(120)
						if imgui.InputText('##font', fnt, sizeof(fnt), imgui.InputTextFlags.EnterReturnsTrue) then fmd.main.bfont = u8:decode(str(fnt)) applyfont() saveIni() end
						imgui.SameLine(0, 10)
						fntsize = new.int(fmd.main.bfontsize)
						imgui.Text("Font Size: ") imgui.SameLine() imgui.PushItemWidth(50)
						if imgui.DragInt("##fontsize", fntsize, imgui.InputTextFlags.EnterReturnsTrue) then fmd.main.bfontsize = fntsize[0] applyfont() saveIni() end
						imgui.Separator()
						finfo = {names = {'Bold','Italics','Border','Shadow'}} 
						for v = 1, 4 do  
							if imgui.Checkbox(u8(finfo.names[v]), new.bool(fmd.fontflag[v])) then 
								fmd.fontflag[v] = not fmd.fontflag[v] 
								applyfont()
							end
							imgui.SameLine(0, 15)
						end
					imgui.EndChild()
				imgui.EndPopup()
				end
				if imgui.Button(u8'Daily Target', imgui.ImVec2(-1, 25)) then imgui.OpenPopup('dailyt') end
				if imgui.BeginPopup('dailyt') then
					imgui.BeginChild("##4", imgui.ImVec2(270, 90), true)
						imgui.SetCursorPos(imgui.ImVec2(65, 5))
						if imgui.Checkbox(u8("Enable Daily Targets"), new.bool(fmd.main.daily)) then fmd.main.daily = not fmd.main.daily if fmd.main.mdate == 0 then fmd.main.mdate = tonumber(os.date("%d%m%Y")) end saveIni() end
						imgui.Separator()
						target = new.int(fmd.main.dtarget)
						imgui.Text("Set daily target: ") imgui.SameLine() imgui.PushItemWidth(50)
						if imgui.DragInt("##dailyt", target, imgui.InputTextFlags.EnterReturnsTrue) then fmd.main.dtarget = target[0] applyfont() saveIni() end
						imgui.PushFont(font2)
						imgui.TextDisabled("Note: Daily targets can be changed at any point\nof time and won't affect the progress already made.")
						imgui.PopFont()
					imgui.EndChild()
				imgui.EndPopup()
				end
				if imgui.Button('Extras', imgui.ImVec2(-1, 25)) then imgui.OpenPopup('extras') end
				if imgui.BeginPopup('extras') then
					imgui.BeginChild("##5", imgui.ImVec2(185, 55), true)
						if imgui.Checkbox(('Delivery Line'), new.bool(fmd.main.dline)) then fmd.main.dline = not fmd.main.dline saveIni() end
						if imgui.IsItemHovered() then imgui.SetTooltip('Sends a fancy roleplay line upon delivering a patient.') end
						if imgui.Checkbox(('Toggle Department Radio'), new.bool(togd)) then togd = not togd end
					imgui.EndChild()
				imgui.EndPopup()
				end
			imgui.EndChild()
			imgui.BeginChild("##69-2", imgui.ImVec2(255, 98), true)
                if imgui.Button(u8'Save Config', imgui.ImVec2(-1, 25)) then saveIni() sampAddChatMessage(string.format("{DFBD68}[%s]{FFFFFF} Config Saved!", script.this.name), -1) end
                if imgui.Button(u8'Reload Script', imgui.ImVec2(-1, 25)) then saveIni() thisScript():reload() end
				if imgui.Button(u8'Commands Info', imgui.ImVec2(-1, 25)) then imgui.OpenPopup('cmdinfo') end
				if imgui.BeginPopup('cmdinfo') then
					imgui.BeginChild("##6", imgui.ImVec2(415, 100), true)
						imgui.Text("/fmd") imgui.SameLine(0, 5) imgui.TextDisabled("- Opens this settings menu.")
						imgui.Text("/saves") imgui.SameLine(0, 5) imgui.TextDisabled("- Displays the total number of patients accepted and delivered.")
						imgui.Text("/daily") imgui.SameLine(0, 5) imgui.TextDisabled("- Displays your daily target and number of patients saved today.")
					imgui.EndChild()
				imgui.EndPopup()
				end
			imgui.EndChild()
        imgui.SetCursorPos(imgui.ImVec2(15, 305))
		imgui.Separator()
		imgui.SetCursorPos(imgui.ImVec2(15, 310))
        imgui.TextDisabled("Revamped by: Visage A.K.A. Ishaan Dunne")
        imgui.EndChild()
    imgui.End()
end)

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
    while not isSampAvailable() do wait(100) end
	applyfont()
	local result, playerId =  sampGetPlayerIdByCharHandle(playerPed)
	if result then
		playerName = sampGetPlayerNickname(playerId):gsub("_", " ")
	end
	sampRegisterChatCommand("fmd", function() _menu = not _menu end)
	if fmd.main.daily and fmd.main.toggled then
		date=tonumber(os.date("%d%m%Y"))
		if fmd.main.mdate ~= date then
			fmd.main.mdate = date
			fmd.main.dsaved = 0
			saveIni()
		end
	end
	while true do
		wait(0)

		if mousepos then 
			if isKeyJustPressed(vkeys.VK_LBUTTON) then 
				mousepos = false
				local x, y = getCursorPos()
				fmd.main.bxpos = x
				fmd.main.bypos = y
			else 
				fpos[1], fpos[2] = getCursorPos() 
			end
		end

		if not (isPauseMenuActive() or sampIsScoreboardOpen()) and fmd.main.sbadge and fmd.main.toggled then 
			x, y =  mousepos and fpos[1] or fmd.main.bxpos, mousepos and fpos[2] or fmd.main.bypos
			result, playerid = sampGetPlayerIdByCharHandle(playerPed)
			if result then
				local text = ''
				local color = sampGetPlayerColor(playerid)
				local r, g, b = explode_rgba(1, color) 
				color = join_argb(255, r, g, b)
				if color == -1 then
					text = 'No Badge'
				elseif color == -32126 then
					text = 'LSFMD'
				else
					text = 'Join FMD!'
				end
				renderfont(x, y, text, color)
			end
		end

		if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and fmd.main.toggled then

			if wasKeyPressed(vkeys.VK_F2) then
				if not isCharStrapped() then
					sampSendChat("/locker")
				else
					sampAddChatMessage("You're already strapped, gang gang.",-1)
				end
			end

			if isKeyDown(vkeys.VK_LMENU) then
				for i = 1, 9 do
					if i <= #currentPatientIds and wasKeyPressed(keys[i]) then
						sampSendChat("/getpt "..currentPatientIds[i],-1)
					elseif i > #currentPatientIds and wasKeyPressed(keys[i]) then
						sampAddChatMessage("There is no patient "..i..".",-1)
					end
				end
			end

			if not isKeyDown(vkeys.VK_LMENU) then
				if wasKeyPressed(vkeys.VK_1) and not isKeyDown(vkeys.VK_RBUTTON) then
					currentPatientIds, currentPatients, currentAcceptedPatients = {}, {}, {}
					getCurrentPatients = true
					sampSendChat("/listpt")
				end

				if wasKeyPressed(vkeys.VK_2) and not isKeyDown(vkeys.VK_RBUTTON) then
					if not isCharInAnyCar(playerPed) then
						local result, patientId = getNearestPlayerId(5)
						if result then
							sampSendChat("/movept "..patientId)
						else
							sampAddChatMessage("Nobody near you can be moved.", -1)
						end
					else
						sampAddChatMessage("You must be outside of your vehicle in order to move a patient.", -1)
					end
				end

				if wasKeyPressed(vkeys.VK_3) and not isKeyDown(vkeys.VK_RBUTTON) then
					if not isCharInAnyCar(playerPed) then
						result, patientId = getNearestPlayerId(5)
						if result then
							if not isLoading then
								isLoading = true
								sampAddChatMessage("Press 3 again to load "..sampGetPlayerNickname(patientId):gsub("_", " ").." into your ambulance.",-1)
								lua_thread.create(function()
									wait(5000)
									if isLoading then isLoading = false end
								end)
							else
								isLoading = false
								loadPatient = 1
								sampSendChat("/loadpt "..patientId.." 2")
							end
						else
							sampAddChatMessage("Nobody near you can be loaded.", -1)
						end
					else
						sampAddChatMessage("You must be outside of your vehicle in order to load a patient.", -1)
					end
				end

				if wasKeyPressed(vkeys.VK_4) and not isKeyDown(vkeys.VK_RBUTTON) then
					local result, patientId = getNearestPlayerId(7)
					if result then
						sampSendChat("/guard "..patientId.." "..fmd.main.bprice)
					else
						sampAddChatMessage("Nobody near you needs a bodyguard.", -1)
					end
				end

				if wasKeyPressed(vkeys.VK_5) and not isKeyDown(vkeys.VK_RBUTTON) then
					local result, patientId = getNearestPlayerId(4)
					if result then
						sampSendChat("/heal "..patientId.." "..fmd.main.hprice)
					else
						sampAddChatMessage("Nobody near you needs healing.", -1)
					end
				end

				if wasKeyPressed(vkeys.VK_6) and not isKeyDown(vkeys.VK_RBUTTON)then
					if isCharInAmbulance(playerPed) then
						local playerVeh = storeCarCharIsInNoSave(playerPed)	
						if isCarPassengerSeatFree(playerVeh, 1) and isCarPassengerSeatFree(playerVeh, 2) then
							sampAddChatMessage("There are no patients in your ambulance.", -1)
						end
						if not isCarPassengerSeatFree(playerVeh, 1) then
							local patientPed = getCharInCarPassengerSeat(playerVeh, 1)
							local result, patientId = sampGetPlayerIdByCharHandle(patientPed)
							if result then
								sampSendChat("/deliverpt "..patientId)
								deliverPatient = true
							end
						end
						if not isCarPassengerSeatFree(playerVeh, 2) then
							local patientPed = getCharInCarPassengerSeat(playerVeh, 2)
							local result, patientId = sampGetPlayerIdByCharHandle(patientPed)
							if result then
								sampSendChat("/deliverpt "..patientId)
								deliverPatient = true
							end
						end
					else
						sampAddChatMessage("You are not in an ambulance.", -1)
					end
				end
			end

			local result, target = getCharPlayerIsTargeting(playerHandle)
			if result then result, patientId = sampGetPlayerIdByCharHandle(target) end
			if result then
				if wasKeyPressed(vkeys.VK_1) then
					sampSendChat("/heal "..patientId.." "..fmd.main.hprice)
				end

				if wasKeyPressed(vkeys.VK_2) then
					sampSendChat("/movept "..patientId)
				end

				if wasKeyPressed(vkeys.VK_3) then
					loadPatient = 1
					sampSendChat("/loadpt "..patientId.." 2")
				end

				if wasKeyPressed(vkeys.VK_4) then
					lua_thread.create(function()
						isCharVesting = true
						wait(40)
						sampSendChat("/guard "..patientId.." "..fmd.main.bprice)
					end)
				end
			end

			if isCharVesting then
				setVirtualKeyDown(vkeys.VK_RBUTTON, false)
			end

		end
	end
end

sampRegisterChatCommand("saves", function()
	printStyledString("~y~~h~Total Patients~n~~r~~h~Accepted:~y~~h~~h~ "..fmd.main.accepted.."~n~~r~~h~Delivered:~y~~h~~h~ "..fmd.main.saved, 3000, 2)
end)

sampRegisterChatCommand("daily", function()
	printStyledString("~r~~h~Daily Target:~y~~h~~h~ "..fmd.main.dtarget.."~n~~r~~h~Saved:~y~~h~~h~ "..fmd.main.dsaved, 3000, 2)
end)

function targetcmte()
	printStyledString("~y~~h~Patients deliverd:~y~~h~~h~ "..fmd.main.dsaved.."~n~~y~~h~You have completed~n~~y~~h~your daily target!", 3000, 2)
	addOneOffSound(0.0, 0.0, 0.0, 1058)
end

function ev.onSendCommand(cinput)
	local cmd = split(cinput, " ")
    if cmd[1] == "/d" and togd then
		sampAddChatMessage("{b30412}Department radio is currently disabled.", -1)
        return false
    end
end

function ev.onServerMessage(c, s)
	if s:find("EMS Driver "..playerName.." has successfully delivered Patient.+to the hospital.") and c == -8224256 then
		pname = s:match(".+")
		pname = pname:gsub('.+Patient', '')
		pname = pname:gsub(' to the hospital.', '')
		local dlinesr = {"/do"..pname.." has been safely delivered and is ready for further treatment.", "/do Nurse rushes towards the stretcher as the ambulance approaches, ready to help"..pname..".", "/do Automatic hospital doors slide open as"..pname.." is rushed towards the intensive care unit."}
		lua_thread.create(function()
			wait(0)
			if fmd.main.dline then sampSendChat(dlinesr[math.random(1, 3)]) end
			fmd.main.saved = fmd.main.saved + 1
			fmd.main.dsaved = fmd.main.dsaved + 1
			if fmd.main.daily and fmd.main.dsaved == fmd.main.dtarget then targetcmte() end
			saveIni()
			deliverPatient = false
		end)
	end
	if s:find("EMS Driver "..playerName.." has accepted the Emergency Dispatch call for") and c == -8224256 then
		lua_thread.create(function()
			fmd.main.accepted = fmd.main.accepted + 1
			saveIni()
		end)
	end
	if fmd.main.toggled then
		if s:find("* You offered protection to") and c == 869072810 and isCharVesting then
			isCharVesting = false
			setVirtualKeyDown(vkeys.VK_RBUTTON, true)
		elseif s:find("seconds before selling another vest") and c == -1347440726 and isCharVesting then
			isCharVesting = false
			setVirtualKeyDown(vkeys.VK_RBUTTON, true)
		end

		if s:find("Your last car needs to be an ambulance and must have a free seat!") then
			if loadPatient == 1 then
				sampSendChat("/loadpt "..patientId.." 3")
				loadPatient = 2
			elseif loadPatient == 2 then
				loadPatient = 0
				sampAddChatMessage(s, -1)
			end
			return false
		elseif s:find("* You loaded patient ") then
			loadPatient = 0
		end

		if  c == -1077886209 and deliverPatient then
			if s:find("That player is not injured!") then
				deliverPatient = false
				return false
			elseif s:find("You are not near a deliver point - look out near the hospitals.") then
				deliverPatient = false
			end
		end

		if s:find("Emergency Dispatch has reported %(%d+") then
			recentPatient = s:match("%d+")
		end

		if togd then
			if s:match("** .**") and c == -2686902 then
				return false
			end
			if s:find(".+is requesting immediate backup at.+.") and c == 641859072 then
				return false
			end
		end

		if getCurrentPatients then
			if s:find("Patients awaiting treatment:") and c == -8224086 then
				lua_thread.create(function()
					wait(50)
					getCurrentPatients = false
					listPatients()
				end)
				return false
			end
			if s:find("%(ID: %d+%)") and s:find("health remaining") then
				if s:find("Accepted:") then
					currentAcceptedPatients[#currentAcceptedPatients+1] = s
				else
					local patientId = s:match("%(ID: %d+%)")
					local patientId = patientId:match("%d+")
					currentPatientIds[#currentPatientIds+1] = patientId
					currentPatients[#currentPatients+1] = #currentPatientIds..": "..s
				end
				return false
			end
		end
		if (c == -1920073729 and fmd.main.cfacrad) then
			if s:match("** ") then
				return {string.format("0x%sFF", colorslid(presettings.facradio)), s}
			end
		end
	end
end

function ev.onShowDialog(id, style, title, button1, button2, text)
	if not isCharStrapped() and fmd.main.toggled then
		if title == "LSFMD" then
			sampSendDialogResponse(id, 1, 2, nil)
			return false
		end
		if title == "What gear do you want?" then
			local strappedInfo = {
				[4] = not hasCharGotWeapon(playerPed, 42),
				[6] = not hasCharGotWeapon(playerPed, 25) and not hasCharGotWeapon(playerPed, 27),
				[7] = getCharArmour(playerPed) < 100,
				[8] = (getCharHealth(playerPed)-5000000) < 100
			}
			for k, v in pairs(strappedInfo) do
				if v then
					sampSendDialogResponse(id, 1, k, nil)
					local _, playerId = sampGetPlayerIdByCharHandle(playerPed)
					local playerPing = sampGetPlayerPing(playerId)
					lua_thread.create(function()
						wait(playerPing+50)
						if not isCharStrapped() then
							sampSendChat("/locker")
						end
					end)
					return false
				end
			end
		end
	end
end

function listPatients()
	if #currentAcceptedPatients > 0 then
		for k, v in pairs(currentAcceptedPatients) do
			currentPatients[#currentPatients+1] = v
		end
	end
	sampAddChatMessage("Patients awaiting treatment:", 0xFF8282)
	if #currentPatients > 0 then
		for k, v in pairs(currentPatients) do
			if v:find("Accepted:") then
				if v:find(playerName) then
					local chatLine = v:find("{") and v:gsub("{%w+}", "") or v
					chatLine = split(chatLine, ":")
					chatLine = chatLine[1]..chatLine[2]..":{FF8282}"..chatLine[3]

					sampAddChatMessage(chatLine, 0x999999)
				else
					sampAddChatMessage(v:gsub("{%w+}", ""), 0x999999)
				end
			else
				sampAddChatMessage(v,-1)
			end
		end
	end
end

function isCharStrapped()
	local strappedInfo = {
				not hasCharGotWeapon(playerPed, 42),
				not hasCharGotWeapon(playerPed, 25) and not hasCharGotWeapon(playerPed, 27),
				getCharArmour(playerPed) < 100,
				(getCharHealth(playerPed)-5000000) < 100
			}
	for k, v in pairs(strappedInfo) do
		if v then
			return false
		end
	end
	return true
end

function isCharInAmbulance(ped)
	local ambulanceVehs = {416, 487, 563, 490}
	for k, v in pairs (ambulanceVehs) do
		if isCharInModel(playerPed, v) then
			return true
		end
	end
	return false
end

function split(str, delim)
	local input = ("([^%s]+)"):format(delim)
	local output = {}
	for k in str:gmatch(input) do
	   table.insert(output, k) 
	end
	return output
end

function explode_rgba(type, rgba)
	local a = bit.band(bit.rshift(rgba, 24), 0xFF)
	local r = bit.band(bit.rshift(rgba, 16), 0xFF)
	local g = bit.band(bit.rshift(rgba, 8),	 0xFF)
	local b = bit.band(rgba, 0xFF)
	if type == 1 then
		return r / 255, g / 255, b / 255
	elseif type == 2 then
		return r / 255, g / 255, b / 255, a / 255
	end
end

function join_argb(a, r, g, b)
	local argb = b * 255
    argb = bit.bor(argb, bit.lshift(g * 255, 8))
    argb = bit.bor(argb, bit.lshift(r * 255, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end

function colorslid(colorvar)
    scolor = string.sub(bit.tohex(join_argb(colorvar[3], colorvar[0], colorvar[1], colorvar[2])), 3, 8)
    return scolor
end

function renderfont(x, y, value, color)
	renderFontDrawText(mfont, value, x, y, color)
end

function applyfont()
	flags, flagids = {}, {flag.BOLD,flag.ITALICS,flag.BORDER,flag.SHADOW}
	for i = 1, 4 do 
		flags[i] = fmd.fontflag[i] and flagids[i] or 0 
	end 
	mfont = renderCreateFont(fmd.main.bfont, fmd.main.bfontsize, flags[1] + flags[2] + flags[3] + flags[4])
end

function getNearestPlayerId(maxDistance)
	local maxPlayerId = sampGetMaxPlayerId(false)
	local closestPlayer, closestPlayerDistance = nil, 9999
	for i = 0, maxPlayerId do
		local result, target = sampGetCharHandleBySampPlayerId(i)
		if result then
			local targetX, targetY, targetZ = getCharCoordinates(target);
			local myX, myY, myZ = getCharCoordinates(playerPed)
			local distance = getDistanceBetweenCoords3d(targetX, targetY, targetZ, myX, myY, myZ)
			local playerId = i
			if distance <= maxDistance then
				if maxDistance == 5 then
					if isCharPlayingAnim(target, "KILL_KNIFE_PED_DIE") or isCharPlayingAnim(target, "gnstwall_injurd") then
						if closestPlayerDistance > distance and not isCharInAnyCar(target) then
							closestPlayerDistance = distance
							closestPlayer = i
						end
					end
				elseif maxDistance == 7 and sampGetPlayerArmor(playerId) < 48 then
					if closestPlayerDistance > distance then
						closestPlayerDistance = distance
						closestPlayer = i
					end
				elseif maxDistance == 4 and sampGetPlayerHealth(playerId) < 90 then
					if closestPlayerDistance > distance then
						closestPlayerDistance = distance
						closestPlayer = i
					end
				end
			end
		end
	end
	if closestPlayer then
		return true, closestPlayer
	end
	return false
end

function imgui.BeginCustomTitle(title, titleSizeY, var, flags)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
    imgui.Begin(title, var, imgui.WindowFlags.NoTitleBar + (flags or 0))
    imgui.SetCursorPos(imgui.ImVec2(0, 0))
    local p = imgui.GetCursorScreenPos()
    imgui.GetWindowDrawList():AddRectFilled(p, imgui.ImVec2(p.x + imgui.GetWindowSize().x, p.y + titleSizeY), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.TitleBgActive]), imgui.GetStyle().WindowRounding, 1 + 2)
    imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowSize().x / 2 - imgui.CalcTextSize(title).x / 2, titleSizeY / 2 - imgui.CalcTextSize(title).y / 2))
    imgui.Text(title)
    imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowSize().x - (titleSizeY - 10) - 5, 5))
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, imgui.GetStyle().WindowRounding)
    if imgui.Button('X##CLOSEBUTTON.WINDOW.'..title, imgui.ImVec2(titleSizeY - 10, titleSizeY - 10)) then _menu = false end
    imgui.SetCursorPos(imgui.ImVec2(5, titleSizeY + 5))
    imgui.PopStyleVar(3)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(5, 5))
end

function saveIni() 
	inicfg.save(fmd, 'fmdV2.ini')
	fmd.facradio.r, fmd.facradio.g, fmd.facradio.b, fmd.facradio.a = presettings.facradio[0], presettings.facradio[1], presettings.facradio[2], presettings.facradio[3]
end

function style()
    imgui.SwitchContext()
    --==[ STYLE ]==--
    imgui.GetStyle().WindowPadding = imgui.ImVec2(8, 8)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 2)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(4, 4)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().IndentSpacing = 5
    imgui.GetStyle().ScrollbarSize = 10
    imgui.GetStyle().GrabMinSize = 10

    --==[ BORDER ]==--
    imgui.GetStyle().WindowBorderSize = 0
    imgui.GetStyle().ChildBorderSize = 1
    imgui.GetStyle().PopupBorderSize = 0
    imgui.GetStyle().FrameBorderSize = 0
    imgui.GetStyle().TabBorderSize = 0

    --==[ ROUNDING ]==--
    imgui.GetStyle().WindowRounding = 5
    imgui.GetStyle().ChildRounding = 5
    imgui.GetStyle().FrameRounding = 5
    imgui.GetStyle().PopupRounding = 5
    imgui.GetStyle().ScrollbarRounding = 5
    imgui.GetStyle().GrabRounding = 5
    imgui.GetStyle().TabRounding = 5

    --==[ ALIGN ]==--
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    
    --==[ COLORS ]==--
    imgui.GetStyle().Colors[imgui.Col.Text]                   = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    imgui.GetStyle().Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Border]                 = imgui.ImVec4(0.25, 0.25, 0.26, 0.54)
    imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.51, 0.51, 0.51, 1.00)
    imgui.GetStyle().Colors[imgui.Col.CheckMark]              = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Button]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Header]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Separator]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
    imgui.GetStyle().Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = imgui.ImVec4(0.07, 0.10, 0.15, 0.97)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = imgui.ImVec4(0.14, 0.26, 0.42, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(1.00, 0.00, 0.00, 0.35)
    imgui.GetStyle().Colors[imgui.Col.DragDropTarget]         = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
    imgui.GetStyle().Colors[imgui.Col.NavHighlight]           = imgui.ImVec4(0.26, 0.59, 0.98, 1.00)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight]  = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg]      = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
    imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
end
