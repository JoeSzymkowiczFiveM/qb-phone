local IsDestinationSet = false
local parking = false

--taxiBlip = nil
local taxiVeh = nil
local taxiPed = nil
local PlayerEntersTaxi = false
local notifyDisplayed = false

local animations = {
	['cellphone@'] = {
		['out'] = {['text'] = 'cellphone_text_in', ['call'] = 'cellphone_call_listen_base'},
		['text'] = {['out'] = 'cellphone_text_out', ['call'] = 'cellphone_text_to_call'},
		['call'] = {['out'] = 'cellphone_call_out', ['text'] = 'cellphone_call_to_text'}
	},
	['anim@cellphone@in_car@ps'] = {
		['out'] = {['text'] = 'cellphone_text_in', ['call'] = 'cellphone_call_in'},
		['text'] = {['out'] = 'cellphone_text_out',['call'] = 'cellphone_text_to_call'},
		['call'] = {['out'] = 'cellphone_horizontal_exit',['text'] = 'cellphone_call_to_text'}
	}
}
local answered = false

local currentStatus = 'out'

local z= nil

local function DisplayHelpMsg(text)
	BeginTextCommandDisplayHelp("STRING")
	AddTextComponentScaleform(text)
	EndTextCommandDisplayHelp(0, false, 1, -1)
end

--[[ function DisplayNotify(title, text)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	SetNotificationMessage("CHAR_TAXI", "CHAR_TAXI", true, 1, GetLabelText("CELL_E_248"), title, text);
	DrawNotification(true, false)
end ]]

local function getGroundZ(x, y, z)
	local result, groundZ = GetGroundZFor_3dCoord(x+0.0, y+0.0, z+0.0, Citizen.ReturnResultAnyway())
	return groundZ
end

local function CreateTaxiPed(vehicle)
	local model = `a_m_y_stlat_01`

	if DoesEntityExist(vehicle) then
		if IsModelValid(model) then
			RequestModel(model)
			while not HasModelLoaded(model) do
				Wait(1)
			end

			local ped = CreatePedInsideVehicle(vehicle, 26, model, -1, true, false)
			SetAmbientVoiceName(ped, "A_M_M_EASTSA_02_LATINO_FULL_01")
			SetBlockingOfNonTemporaryEvents(ped, true)
			SetEntityAsMissionEntity(ped, true, true)

			SetModelAsNoLongerNeeded(model)
			return ped
		end
	end
end

local currentStatus = 'out'
function PhonePlayAnim(status)
	print(status)
	if currentStatus == status then
	return
	end
	local dict = "cellphone@"
	if IsPedInAnyVehicle(PlayerPedId(), false) then dict = "anim@cellphone@in_car@ps" end
	ClearPedTasks(PlayerPedId())
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do Citizen.Wait(1) end
	
	print(dict)
	local anim = animations[dict][currentStatus][status]
	StopAnimTask(PlayerPedId(), lastDict, lastAnim, 1.0)
	Wait(300)
	TaskPlayAnim(PlayerPedId(), dict, anim, 3.0, -1, -1, 50, 0, false, false, false)
	if status ~= 'out' and currentStatus == 'out' then
		Citizen.Wait(2000)
		--newPhoneProp()
	end
	
	lastDict = dict
	lastAnim = anim
	currentStatus = status
	if status == 'out' then
		Citizen.Wait(180)
		--deletePhone()
		StopAnimTask(PlayerPedId(), lastDict, lastAnim, 1.0)
	end
	Wait(6000)
	ClearPedTasks(PlayerPedId())
end

local function DeleteTaxi(vehicle, driver)
	if DoesEntityExist(vehicle) then
		if IsPedInVehicle(PlayerPedId(), vehicle, false) then
			TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
			Wait(2000)			
		end

		local blip = GetBlipFromEntity(vehicle)

		if DoesBlipExist(blip) then
			RemoveBlip(blip)
		end

		DeleteEntity(driver)
		DeleteEntity(vehicle)
	end

	if not DoesEntityExist(vehicle) and DoesEntityExist(driver) then
		DeleteEntity(driver)
	end
end

local function StartTaxiThread()
	CreateThread(function()
		local player = PlayerId()
		local playerPed = PlayerPedId()
		notifyDisplayed = false
		while DoesEntityExist(taxiVeh) do
			Px, Py, Pz = table.unpack(GetEntityCoords(playerPed))
			vehX, vehY, vehZ = table.unpack(GetEntityCoords(taxiVeh))
			DistanceBetweenTaxi = GetDistanceBetweenCoords(Px, Py, Pz, vehX, vehY, vehZ, true)

			if IsVehicleStuckOnRoof(taxiVeh) or IsEntityUpsidedown(taxiVeh) or IsEntityDead(taxiVeh) or IsEntityDead(taxiPed) then
				DeleteTaxi(taxiVeh, taxiPed)
			end

			SetEntityInvincible(taxiVeh,true)
			if DistanceBetweenTaxi <= 10.0 then
				if not IsPedInAnyVehicle(playerPed, false) then
					if IsControlJustPressed(0, 23) then
						TaskEnterVehicle(playerPed, taxiVeh, -1, 2, 1.0, 1, 0)
						PlayerEntersTaxi = true
						TaxiInfoTimer = GetGameTimer()
					end
				else
					if IsPedInVehicle(playerPed, taxiVeh, false) then
						local blip = GetBlipFromEntity(taxiVeh)
						if DoesBlipExist(blip) then
							RemoveBlip(blip)
						end

						if not DoesBlipExist(GetFirstBlipInfoId(8)) then
							if PlayerEntersTaxi then
								PlayAmbientSpeech1(taxiPed, "TAXID_WHERE_TO", "SPEECH_PARAMS_FORCE_NORMAL")
								PlayerEntersTaxi = false
								if notifyDisplayed == false then
									TriggerEvent('mnm_notify_client:showNotification', '<i class="fa-solid fa-location-dot"></i>', 'Taxi', 'Select your destination on the map and press <span style="color: green;">E</span>', '', true)
									notifyDisplayed = true
								end
							end
							
							if GetGameTimer() > TaxiInfoTimer + 1000 and GetGameTimer() < TaxiInfoTimer + 10000 then
								DisplayHelpMsg("Select your destination on the map, then press ~INPUT_PICKUP~ to start.")
							end
						elseif DoesBlipExist(GetFirstBlipInfoId(8)) then
							dx, dy, dz = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09, GetFirstBlipInfoId(8), Citizen.ResultAsVector()))
							z = getGroundZ(dx, dy, dz)

							if IsControlJustPressed(1, 51) then
								if not IsDestinationSet then
									disttom = CalculateTravelDistanceBetweenPoints(Px, Py, Pz, dx, dy, z)
									IsDestinationSet = true
								end

								PlayAmbientSpeech1(taxiPed, "TAXID_BEGIN_JOURNEY", "SPEECH_PARAMS_FORCE_NORMAL")
								TaskVehicleDriveToCoord(taxiPed, taxiVeh, dx, dy, z, 26.0, 0, GetEntityModel(taxiVeh), 411, 50.0)
								SetDriveTaskDrivingStyle(ped, 262144)

								if notifyDisplayed == true then
									TriggerEvent('mnm_notify_client:removeNotification', false)
									notifyDisplayed = false
								end
								SetPedKeepTask(taxiPed, true)
							elseif IsControlJustPressed(1, 179) then
								if not IsDestinationSet then
									disttom = CalculateTravelDistanceBetweenPoints(Px, Py, Pz, dx, dy, z)
									IsDestinationSet = true
								end

								PlayAmbientSpeech1(taxiPed, "TAXID_SPEED_UP", "SPEECH_PARAMS_FORCE_NORMAL")
								TaskVehicleDriveToCoord(taxiPed, taxiVeh, dx, dy, z, 29.0, 0, GetEntityModel(taxiVeh), 318, 50.0)
								SetDriveTaskDrivingStyle(ped, 262144)
								if notifyDisplayed == true then
									TriggerEvent('mnm_notify_client:removeNotification', false)
									notifyDisplayed = false
								end
								SetPedKeepTask(taxiPed, true)
							elseif GetDistanceBetweenCoords(GetEntityCoords(playerPed, true), dx, dy, z, true) <= 53.0 then
								if not parking then
									ClearPedTasks(taxiPed)
									PlayAmbientSpeech1(taxiPed, "TAXID_CLOSE_AS_POSS", "SPEECH_PARAMS_FORCE_NORMAL")
									TaskVehicleTempAction(taxiPed, taxiVeh, 6, 2000)
									SetVehicleHandbrake(taxiVeh, true)
									SetVehicleEngineOn(taxiVeh, false, true, false)
									SetPedKeepTask(taxiPed, true)
									TaskLeaveVehicle(playerPed, taxiVeh, 512)
									Wait(3000)
									TriggerServerEvent("fs_taxi:payCab", disttom)
									parking = true
								end
							end
						end
					end
				end
			end

			Wait(1)
		end
	end)
end

local function CreateTaxi(x, y, z)
	local taxiModel = `taxi`

	if IsModelValid(taxiModel) then
		if IsThisModelACar(taxiModel) then
			RequestModel(taxiModel)
			while not HasModelLoaded(taxiModel) do
				Wait(1)
			end

			if not DoesEntityExist(taxiVeh) then
				--GetPointOnRoadSide()
				local _, vector = GetNthClosestVehicleNode(x, y + 25, z, math.random(5, 10), 0, 0, 0)
				-- GetClosestVehicleNodeWithHeading(x, y, z, outPosition, outHeading, nodeType, p6, p7)
				local sX, sY, sZ = table.unpack(vector)

				--DisplayNotify("Taxi call", "The taxi cab is on his way.")
				TriggerEvent('qb-phone:client:NewTaxiNotify', "The taxi cab is on his way.")
				--PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
				Wait(2000)

				taxiVeh = CreateVehicle(taxiModel, sX, sY, sZ, 0, true, false)
				SetVehicleHasBeenOwnedByPlayer(taxiVeh, true)

				SetEntityAsMissionEntity(taxiVeh, true, true)
				SetVehicleEngineOn(taxiVeh, true, true, false)

				local blip = AddBlipForEntity(taxiVeh)
				SetBlipSprite(blip, 198)
				SetBlipFlashes(blip, true)
				SetBlipFlashTimer(blip, 5000)

				SetModelAsNoLongerNeeded(taxiModel)

				SetHornEnabled(taxiVeh, true)
				StartVehicleHorn(taxiVeh, 1000, GetHashKey("NORMAL"), false)

				return taxiVeh
			else
				--DisplayNotify("Taxi call", "All our drivers are currently occupied.")
				TriggerEvent('qb-phone:client:NewTaxiNotify', "All our drivers are currently occupied.")
			end
		end
	end	
end

local function IsInTaxi()
    return PlayerEntersTaxi
end

exports('IsInTaxi', IsInTaxi)

RegisterNetEvent('rpbase-interact:calltaxi', function()
	print("HI?")
	PhonePlayAnim('call')
	local playerPed = PlayerPedId()

	if not DoesEntityExist(taxiVeh) then 
		if not IsPedInAnyVehicle(playerPed, false) or not IsPedInAnyTaxi(playerPed) then
			Px, Py, Pz = table.unpack(GetEntityCoords(playerPed))

			taxiVeh = CreateTaxi(Px, Py, Pz)
			while not DoesEntityExist(taxiVeh) do
				Wait(1)
			end

			StartTaxiThread()

			taxiPed = CreateTaxiPed(taxiVeh)
			while not DoesEntityExist(taxiPed) do
				Wait(1)
			end

			TaskVehicleDriveToCoord(taxiPed, taxiVeh, Px, Py, Pz, 26.0, 0, GetEntityModel(taxiVeh), 411, 10.0)
			SetPedKeepTask(taxiPed, true)
		end
	end
end)

RegisterNetEvent("fs_taxi:payment-status")
AddEventHandler("fs_taxi:payment-status", function(state)
	local player = PlayerId()
	Wait(1200)
	
	if state then
		PlayAmbientSpeech1(taxiPed, "THANKS", "SPEECH_PARAMS_FORCE_NORMAL")
	else
		PlayAmbientSpeech1(taxiPed, "TAXID_NO_MONEY", "SPEECH_PARAMS_FORCE_NORMAL")
		Wait(1000)
		if not IsPlayerWantedLevelGreater(player, 0) then
			SetPlayerWantedLevel(player, 3, false)
			SetPlayerWantedLevelNow(player, true)
			SetDispatchCopsForPlayer(player, true)
		end
	end

	TaskVehicleDriveWander(taxiPed, taxiVeh, 20.0, 319)
	Wait(20000)
	DeleteTaxi(taxiVeh, taxiPed)
	parking = false
	PlayerEntersTaxi = false
end)