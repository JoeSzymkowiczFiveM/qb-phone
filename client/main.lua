local QBCore = exports['qb-core']:GetCoreObject()

-- Code
local PlayerData = {}
local PlayerJob = {}
local playerHasVPN = false

--phoneProp = 0
local phoneModel = `prop_npc_phone_02`

PhoneData = {
    MetaData = {},
    isOpen = false,
    PlayerData = nil,
    Contacts = {},
    Tweets = {},
    MentionedTweets = {},
    Hashtags = {},
    Chats = {},
    --Invoices = {},
    CallData = {},
    RecentCalls = {},
    Garage = {},
    Mails = {},
    Notes = {},
    Auctions = {},
    Adverts = {},
    Gang = {},
    GarageVehicles = {},
    AnimationData = {
        lib = nil,
        anim = nil,
    },
    SuggestedContacts = {},
    CryptoTransactions = {},
}

local phoneProp = 0

local ANIMS = {
	['cellphone@'] = {
		['out'] = {
			['text'] = 'cellphone_text_in',
			['call'] = 'cellphone_call_listen_base',
		},
		['text'] = {
			['out'] = 'cellphone_text_out',
			['text'] = 'cellphone_text_in',
			['call'] = 'cellphone_text_to_call',
		},
		['call'] = {
			['out'] = 'cellphone_call_out',
			['text'] = 'cellphone_call_to_text',
			['call'] = 'cellphone_text_to_call',
		}
	},
	['anim@cellphone@in_car@ps'] = {
		['out'] = {
			['text'] = 'cellphone_text_in',
			['call'] = 'cellphone_call_in',
		},
		['text'] = {
			['out'] = 'cellphone_text_out',
			['text'] = 'cellphone_text_in',
			['call'] = 'cellphone_text_to_call',
		},
		['call'] = {
			['out'] = 'cellphone_horizontal_exit',
			['text'] = 'cellphone_call_to_text',
			['call'] = 'cellphone_text_to_call',
		}
	}
}

local function deletePhone()
	if phoneProp ~= 0 then
		Citizen.InvokeNative(0xAE3CBE5BF394C9C9 , Citizen.PointerValueIntInitialized(phoneProp))
		phoneProp = 0
	end
end

local function newPhoneProp()
	deletePhone()
	RequestModel(phoneModel)
	while not HasModelLoaded(phoneModel) do
		Wait(1)
	end
	phoneProp = CreateObject(phoneModel, 1.0, 1.0, 1.0, 1, 1, 0)

	local bone = GetPedBoneIndex(PlayerPedId(), 28422)
	if phoneModel == `prop_cs_phone_01` then
		AttachEntityToEntity(phoneProp, PlayerPedId(), bone, 0.0, 0.0, 0.0, 50.0, 320.0, 50.0, 1, 1, 0, 0, 2, 1)
	else
		AttachEntityToEntity(phoneProp, PlayerPedId(), bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
	end
end

local function CancelPhoneAnim()
    local ped = PlayerPedId()
    local AnimationLib = 'cellphone@'
    local AnimationStatus = "cellphone_call_listen_base"

    if IsPedInAnyVehicle(ped, false) then
        AnimationLib = 'anim@cellphone@in_car@ps'
    end

    if PhoneData.isOpen then
        AnimationStatus = "cellphone_call_to_text"
    end

    --LoadAnimation(AnimationLib)
    lib.requestAnimDict(AnimationLib)
    TaskPlayAnim(ped, AnimationLib, AnimationStatus, 3.0, 3.0, -1, 50, 0, false, false, false)

    if not PhoneData.isOpen then
        deletePhone()
    end
end

local function CheckAnimLoop()
    CreateThread(function()
        while PhoneData.AnimationData.lib ~= nil and PhoneData.AnimationData.anim ~= nil do
            local ped = PlayerPedId()

            if not IsEntityPlayingAnim(ped, PhoneData.AnimationData.lib, PhoneData.AnimationData.anim, 3) then
                --LoadAnimation(PhoneData.AnimationData.lib)
                lib.requestAnimDict(PhoneData.AnimationData.lib)
                TaskPlayAnim(ped, PhoneData.AnimationData.lib, PhoneData.AnimationData.anim, 3.0, 3.0, -1, 50, 0, false, false, false)
            end

            Wait(500)
        end
    end)
end

local function DoPhoneAnimation(anim)
    local ped = PlayerPedId()
    local AnimationLib = 'cellphone@'
    local AnimationStatus = anim

    if IsPedInAnyVehicle(ped, false) then
        AnimationLib = 'anim@cellphone@in_car@ps'
    end

    --LoadAnimation(AnimationLib)
    lib.requestAnimDict(AnimationLib)
    TaskPlayAnim(ped, AnimationLib, AnimationStatus, 3.0, 3.0, -1, 50, 0, false, false, false)

    PhoneData.AnimationData.lib = AnimationLib
    PhoneData.AnimationData.anim = AnimationStatus

    CheckAnimLoop(AnimationLib, AnimationStatus)
end

local function IsNumberInContacts(num)
    local retval = num
    for _, v in pairs(PhoneData.Contacts) do
        if num == v.number then
            retval = v.name
        end
    end
    return retval
end

local function CalculateTimeToDisplay()
	hour = GetClockHours()
    minute = GetClockMinutes()
    
    local obj = {}
    
	if minute <= 9 then
		minute = "0" .. minute
    end
    
    obj.hour = hour
    obj.minute = minute

    return obj
end

local function GetFirstAvailableSlot()
    local retval = 0
    for k, v in pairs(Config.PhoneApplications) do
        retval = retval + 1
    end
    return (retval + 1)
end

local CanDownloadApps = false

-- Disables GTA controls when display is active
-- this allows for NUI input with ingame input
local function DisableDisplayControlActions()
    DisableControlAction(0, 1, true) -- disable mouse look
    DisableControlAction(0, 2, true) -- disable mouse look
    DisableControlAction(0, 3, true) -- disable mouse look
    DisableControlAction(0, 4, true) -- disable mouse look
    DisableControlAction(0, 5, true) -- disable mouse look
    DisableControlAction(0, 6, true) -- disable mouse look

    DisableControlAction(0, 263, true) -- disable melee
    DisableControlAction(0, 264, true) -- disable melee
    DisableControlAction(0, 257, true) -- disable melee
    DisableControlAction(0, 140, true) -- disable melee
    DisableControlAction(0, 141, true) -- disable melee
    DisableControlAction(0, 142, true) -- disable melee
    DisableControlAction(0, 143, true) -- disable melee

    DisableControlAction(0, 177, true) -- disable backspace
    DisableControlAction(0, 200, true) -- disable escape
    DisableControlAction(0, 202, true) -- disable escape
    DisableControlAction(0, 322, true) -- disable escape
    --DisableControlAction(0, Config.OpenPhone, true) -- disable chat 

    DisableControlAction(0, 245, true) -- disable chat  
end

local function OpenPhone()
    local HasPhone = QBCore.Functions.HasItem('phone')
    if HasPhone then
        QBCore.Functions.GetPlayerData(function(PlayerData)
            if not PlayerData.metadata["isdead"] and not PlayerData.metadata["ishandcuffed"] then
                PhoneData.PlayerData = PlayerData
                SetNuiFocus(true, true)
                SendNUIMessage({
                    action = "open",
                    Tweets = PhoneData.Tweets,
                    AppData = Config.PhoneApplications,
                    CallData = PhoneData.CallData,
                    PlayerData = PhoneData.PlayerData,
                    hasVPN = playerHasVPN,
                })
                PhoneData.isOpen = true

                CreateThread(function()
                    while PhoneData.isOpen do
                        SendNUIMessage({
                            action = "UpdateTime",
                            InGameTime = CalculateTimeToDisplay(),
                        })
                        Wait(5000)
                    end
                end)

                CreateThread(function()
                    while PhoneData.isOpen do
                        DisableDisplayControlActions()
                        Wait(1)
                    end
                end)

                if not PhoneData.CallData.InCall then
                    DoPhoneAnimation('cellphone_text_in')
                else
                    DoPhoneAnimation('cellphone_call_to_text')
                end

                SetTimeout(250, function()
                    newPhoneProp()
                end)
        
                --[[ QBCore.Functions.TriggerCallback('qb-phone:server:GetGarageVehicles', function(vehicles)
                    PhoneData.GarageVehicles = vehicles
                end) ]]
            end
        end)
    else
        QBCore.Functions.Notify("You do not have a Phone", "error")
    end
end

local function GetKeyByDate(Number, Date)
    local retval = nil
    if PhoneData.Chats[Number] ~= nil then
        if PhoneData.Chats[Number].messages ~= nil then
            for key, chat in pairs(PhoneData.Chats[Number].messages) do
                if chat.date == Date then
                    retval = key
                    break
                end
            end
        end
    end
    return retval
end

local function GetKeyByNumber(Number)
    local retval = nil
    if PhoneData.Chats then
        for k, v in pairs(PhoneData.Chats) do
            if v.number == Number then
                retval = k
            end
        end
    end
    return retval
end

local function ReorganizeChats(key)
    local ReorganizedChats = {}
    ReorganizedChats[1] = PhoneData.Chats[key]
    for k, chat in pairs(PhoneData.Chats) do
        if k ~= key then
            table.insert(ReorganizedChats, chat)
        end
    end
    PhoneData.Chats = ReorganizedChats
end

local function GenerateCallId(caller, target)
    local CallId = math.ceil(((tonumber(caller) + tonumber(target)) / 100 * 1))
    return CallId
end

local function CallContact(CallData, AnonymousCall)
    local RepeatCount = 0
    PhoneData.CallData.CallType = "outgoing"
    PhoneData.CallData.InCall = true
    PhoneData.CallData.TargetData = CallData
    PhoneData.CallData.AnsweredCall = false
    PhoneData.CallData.CallId = GenerateCallId(PhoneData.PlayerData.charinfo.phone, CallData.number)

    TriggerServerEvent('qb-phone:server:CallContact', PhoneData.CallData.TargetData, PhoneData.CallData.CallId, AnonymousCall)
    TriggerServerEvent('qb-phone:server:SetCallState', true)
    
    for i = 1, Config.CallRepeats + 1, 1 do
        if not PhoneData.CallData.AnsweredCall then
            if RepeatCount + 1 ~= Config.CallRepeats + 1 then
                if PhoneData.CallData.InCall then
                    RepeatCount = RepeatCount + 1
                    TriggerServerEvent("InteractSound_SV:PlayOnSource", "demo", 0.1)
                else
                    break
                end
                Wait(Config.RepeatTimeout)
            else
                CancelCall()
                break
            end
        else
            break
        end
    end
end

local function CallContactPayphone(CallData, AnonymousCall)
    local RepeatCount = 0
    PhoneData.CallData.CallType = "outgoing"
    PhoneData.CallData.InCall = true
    PhoneData.CallData.TargetData = CallData
    PhoneData.CallData.AnsweredCall = false
    PhoneData.CallData.CallId = GenerateCallId(PhoneData.PlayerData.charinfo.phone, CallData.number)

    TriggerServerEvent('qb-phone:server:CallContact', PhoneData.CallData.TargetData, PhoneData.CallData.CallId, AnonymousCall, true)
    TriggerServerEvent('qb-phone:server:SetCallState', true)
    
    for i = 1, Config.CallRepeats + 1, 1 do
        if not PhoneData.CallData.AnsweredCall then
            if RepeatCount + 1 ~= Config.CallRepeats + 1 then
                if PhoneData.CallData.InCall then
                    RepeatCount = RepeatCount + 1
                    TriggerServerEvent("InteractSound_SV:PlayOnSource", "demo", 0.1)
                else
                    break
                end
                Wait(Config.RepeatTimeout)
            else
                CancelCall()
                break
            end
        else
            break
        end
    end
end

local function LoadPhone()
    local pData = lib.callback.await('qb-phone:server:GetPhoneData', false)
    --PlayerJob = QBCore.Functions.GetPlayerData().job
    --PhoneData.PlayerData = QBCore.Functions.GetPlayerData()
    --local PhoneMeta = PhoneData.PlayerData.metadata["phone"]
    --PhoneData.MetaData = PhoneMeta
    --hasVPN = playerHasVPN

    -- if pData.installedapps ~= nil and next(pData.installedapps) ~= nil then
    --     for k, v in pairs(pData.installedapps) do
    --         local AppData = Config.StoreApps[v.app]
    --         Config.PhoneApplications[v.app] = {
    --             app = v.app,
    --             color = AppData.color,
    --             icon = AppData.icon,
    --             tooltipText = AppData.title,
    --             tooltipPos = "right",
    --             job = AppData.job,
    --             blockedjobs = AppData.blockedjobs,
    --             slot = AppData.slot,
    --             Alerts = 0,
    --         }
    --     end
    -- end

    if pData.Applications ~= nil and next(pData.Applications) ~= nil then
        for k, v in pairs(pData.Applications) do 
            Config.PhoneApplications[k].Alerts = v 
        end
    end

    if pData.MentionedTweets ~= nil and next(pData.MentionedTweets) ~= nil then 
        PhoneData.MentionedTweets = pData.MentionedTweets 
    end

    if pData.PlayerContacts ~= nil and next(pData.PlayerContacts) ~= nil then 
        PhoneData.Contacts = pData.PlayerContacts
    end

    if pData.Notes ~= nil and next(pData.Notes) ~= nil then 
        PhoneData.Notes = pData.Notes
    end

    if pData.Chats ~= nil and next(pData.Chats) ~= nil then
        local Chats = {}
        for k, v in pairs(pData.Chats) do
            Chats[v.number] = {
                name = IsNumberInContacts(v.number),
                number = v.number,
                messages = v.messages
            }
        end

        PhoneData.Chats = Chats
    end

    if pData.Invoices ~= nil and next(pData.Invoices) ~= nil then
        for _, invoice in pairs(pData.Invoices) do
            invoice.name = IsNumberInContacts(invoice.number)
        end
        PhoneData.Invoices = pData.Invoices
    end

    if pData.Hashtags ~= nil and next(pData.Hashtags) ~= nil then
        PhoneData.Hashtags = pData.Hashtags
    end

    if pData.Tweets ~= nil and next(pData.Tweets) ~= nil then
        PhoneData.Tweets = pData.Tweets
    end

    if pData.Mails ~= nil and next(pData.Mails) ~= nil then
        PhoneData.Mails = pData.Mails
    end

    if pData.Adverts ~= nil and next(pData.Adverts) ~= nil then
        PhoneData.Adverts = pData.Adverts
    end

    if pData.DarkWeb ~= nil and next(pData.DarkWeb) ~= nil then
        PhoneData.DarkWeb = pData.DarkWeb
    end

    if pData.CryptoTransactions ~= nil and next(pData.CryptoTransactions) ~= nil then
        PhoneData.CryptoTransactions = pData.CryptoTransactions
    end

    PhoneData.MetaData.profilepicture = PhoneData.MetaData.profilepicture ~= nil and PhoneData.MetaData.profilepicture or "default"
    PhoneData.MetaData.background = PhoneData.MetaData.background ~= nil and PhoneData.MetaData.background or "stars"

    SendNUIMessage({
        action = "LoadPhoneData",
        PhoneData = PhoneData,
        PlayerData = PhoneData.PlayerData,
        PlayerJob = PhoneData.PlayerData.job,
        applications = Config.PhoneApplications,
        hasVPN = playerHasVPN,
    })
end

local function SetVPN(bool)
    print(bool)
    playerHasVPN = bool
    SendNUIMessage({
        action = "SetVPN",
        hasVPN = playerHasVPN,
    })

    SendNUIMessage({
        action = "UpdateApplications",
        JobData = PlayerJob,
        applications = Config.PhoneApplications,
        hasVPN = playerHasVPN,
    })
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    PhoneData.PlayerData = PlayerData
    PlayerJob = PlayerData.job
    PhoneData.MetaData = PhoneData.PlayerData.metadata["phone"]

    local HasItem = QBCore.Functions.HasItem('vpn')
    if HasItem then
        SetVPN(true)
    else
        SetVPN(false)
    end

    Wait(500)
    LoadPhone()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    PlayerData = QBCore.Functions.GetPlayerData()
    PhoneData.PlayerData = PlayerData

    Wait(500)
    LoadPhone()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    while QBCore == nil do Wait(200) end
    if LocalPlayer.state.isLoggedIn then
        PlayerData = QBCore.Functions.GetPlayerData()
        PhoneData.PlayerData = PlayerData
        PlayerJob = PlayerData.job
        PhoneData.MetaData = PhoneData.PlayerData.metadata["phone"]

        local HasItem = QBCore.Functions.HasItem('vpn')
        if HasItem then
            SetVPN(true)
        else
            SetVPN(false)
        end
        Wait(500)
        LoadPhone()
    end
end)

RegisterNetEvent('qb-phone:client:RaceNotify', function(message)
    if PhoneData.isOpen then
        SendNUIMessage({
            action = "PhoneNotification",
            PhoneNotify = {
                title = "Racing",
                text = message,
                icon = "fas fa-flag-checkered",
                color = "#353b48",
                timeout = 1500,
            },
        })
    else
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "Racing",
                content = message,
                icon = "fas fa-flag-checkered",
                timeout = 3500,
                color = "#353b48",
            },
        })
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    if GetInvokingResource() then return end
    QBCore.PlayerData = val
end)

RegisterNetEvent('qb-phone:client:AddRecentCall', function(data, time, type)
    table.insert(PhoneData.RecentCalls, {
        name = IsNumberInContacts(data.number),
        time = time,
        type = type,
        number = data.number,
        anonymous = data.anonymous
    })
    TriggerServerEvent('qb-phone:server:SetPhoneAlerts', "phone")
    Config.PhoneApplications["phone"].Alerts = Config.PhoneApplications["phone"].Alerts + 1
    SendNUIMessage({
        action = "RefreshAppAlerts",
        AppData = Config.PhoneApplications
    })
end)

RegisterNUICallback('ClearRecentAlerts', function(_, cb)
    TriggerServerEvent('qb-phone:server:SetPhoneAlerts', "phone", 0)
    Config.PhoneApplications["phone"].Alerts = 0
    SendNUIMessage({ action = "RefreshAppAlerts", AppData = Config.PhoneApplications })
    cb('ok')
end)

RegisterNUICallback('SetBackground', function(data, cb)
    local background = data.background

    PhoneData.MetaData.background = background
    TriggerServerEvent('qb-phone:server:SaveMetaData', PhoneData.MetaData)
    cb('ok')
end)

RegisterNUICallback('GetMissedCalls', function(_, cb)
    cb(PhoneData.RecentCalls)
end)

RegisterNUICallback('GetSuggestedContacts', function(_, cb)
    cb(PhoneData.SuggestedContacts)
end)

--[[ CreateThread(function()
    while true do
        if IsControlJustPressed(0, Config.OpenPhone) then
            if not PhoneData.isOpen then
                local IsHandcuffed = exports['police']:IsHandcuffed()
                if not IsHandcuffed then
                    SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
                    DisablePlayerFiring(PlayerId(), true)
                    OpenPhone()
                else
                    QBCore.Functions.Notify("Action not possible at this time..", "error")
                end
            end
        end
        
        if IsDisabledControlJustReleased(0, Config.OpenPhone) then
            if PhoneData.isOpen then
                PhoneData.isOpen = false
            end
        end
        Wait(5)
    end
end) ]]

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local pData = lib.callback.await('qb-phone:server:GetPhoneContacts', false)
            if pData.PlayerContacts ~= nil and next(pData.PlayerContacts) ~= nil then 
                PhoneData.Contacts = pData.PlayerContacts
            end

            SendNUIMessage({
                action = "RefreshContacts",
                Contacts = PhoneData.Contacts
            })
            --end)
            Wait(60000)
        end
        Wait(5000)
    end
end)

RegisterNetEvent('qb-phone:client:ContactsUpdate', function()
end)

--[[ CreateThread(function()
    Wait(1500)
    LoadPhone()
end) ]]

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PhoneData = {
        MetaData = {},
        isOpen = false,
        PlayerData = nil,
        Contacts = {},
        Tweets = {},
        MentionedTweets = {},
        Hashtags = {},
        Chats = {},
        Invoices = {},
        CallData = {},
        RecentCalls = {},
        Garage = {},
        Notes = {},
        Mails = {},
        Adverts = {},
        GarageVehicles = {},
        AnimationData = {
            lib = nil,
            anim = nil,
        },
        SuggestedContacts = {},
        CryptoTransactions = {},
    }
end)

RegisterNUICallback('HasPhone', function(_, cb)
    local HasPhone = QBCore.Functions.HasItem('phone')
    cb(HasPhone)
end)

RegisterKeyMapping('phone', 'Open Phone', 'keyboard', 'F1')

RegisterCommand('phone', function()
    OpenPhone()
end, false)

RegisterNUICallback('SetupGarageVehicles', function(_, cb)
    --cb(PhoneData.GarageVehicles)
    QBCore.Functions.TriggerCallback('qb-phone:server:GetGarageVehicles', function(garageVehicles)
        cb(garageVehicles)
    end)
end)

RegisterNUICallback('SetupAvailableGroups', function(data, cb)
    local request = promise.new()
    QBCore.Functions.TriggerCallback("groups:getActiveGroups", function(result)
        request:resolve(result)
    end)
    local data = Citizen.Await(request)
    cb(data)
end)

local function InPhone()
    return PhoneData.isOpen
end

RegisterNUICallback('Close', function(_, cb)
    if InPhone() then
        if not PhoneData.CallData.InCall then
            DoPhoneAnimation('cellphone_text_out')
            SetTimeout(400, function()
                StopAnimTask(PlayerPedId(), PhoneData.AnimationData.lib, PhoneData.AnimationData.anim, 2.5)
                deletePhone()
                PhoneData.AnimationData.lib = nil
                PhoneData.AnimationData.anim = nil
            end)
        else
            PhoneData.AnimationData.lib = nil
            PhoneData.AnimationData.anim = nil
            DoPhoneAnimation('cellphone_text_to_call')
        end
        SetNuiFocus(false, false)
        --SetNuiFocusKeepInput(false)
        SetTimeout(125, function()
            PhoneData.isOpen = false
        end)
    end
    cb('ok')
end)

-- RegisterNetEvent("client:fixnui")
-- AddEventHandler("client:fixnui", function()
--     SetNuiFocus(false, false)
--     SetNuiFocusKeepInput(false)
--     SetTimeout(125, function()
--         PhoneData.isOpen = false
--     end)
--     SendNUIMessage({
--         action = "close",
--     })
-- end)

RegisterNUICallback('RemoveMail', function(data, cb)
    local MailId = data.mailId

    TriggerServerEvent('qb-phone:server:RemoveMail', MailId)
    cb('ok')
end)

RegisterNetEvent('qb-phone:client:UpdateMails')
AddEventHandler('qb-phone:client:UpdateMails', function(NewMails)
    SendNUIMessage({
        action = "UpdateMails",
        Mails = NewMails
    })
    PhoneData.Mails = NewMails
end)

RegisterNUICallback('AcceptMailButton', function(data, cb)
    TriggerEvent(data.buttonEvent, data.buttonData)
    TriggerServerEvent('qb-phone:server:ClearButtonData', data.mailId)
    cb('ok')
end)

RegisterNUICallback('AddNewContact', function(data, cb)
    table.insert(PhoneData.Contacts, {
        name = data.ContactName,
        number = data.ContactNumber,
        iban = data.ContactIban
    })
    Wait(100)
    cb(PhoneData.Contacts)
    if PhoneData.Chats[data.ContactNumber] ~= nil and next(PhoneData.Chats[data.ContactNumber]) ~= nil then
        PhoneData.Chats[data.ContactNumber].name = data.ContactName
    end
    TriggerServerEvent('qb-phone:server:AddNewContact', data.ContactName, data.ContactNumber, data.ContactIban)
end)

RegisterNUICallback('GetMails', function(_, cb)
    cb(PhoneData.Mails)
end)

RegisterNUICallback('GetWhatsappChat', function(data, cb)
    if PhoneData.Chats[data.phone] ~= nil then
        cb(PhoneData.Chats[data.phone])
    else
        cb(false)
    end
end)

RegisterNUICallback('GetProfilePicture', function(data, cb)
    local number = data.number

    QBCore.Functions.TriggerCallback('qb-phone:server:GetPicture', function(picture)
        cb(picture)
    end, number)
end)

RegisterNUICallback('GetBankContacts', function(_, cb)
    cb(PhoneData.Contacts)
end)

RegisterNUICallback('GetInvoices', function(_, cb)
    --[[ if PhoneData.Invoices ~= nil and next(PhoneData.Invoices) ~= nil then
        cb(PhoneData.Invoices)
    else
        cb(nil)
    end ]]
    QBCore.Functions.TriggerCallback('qb-phone:server:GetInvoices', function(invoices)
        cb(invoices)
    end)
end)

RegisterNUICallback('GetPaychecks', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-phone:server:GetPaychecks', function(paychecks)
        cb(paychecks)
    end)
end)

RegisterNUICallback('SendMessage', function(data, cb)
    local ChatMessage = exports['qb-smallresources']:CleanseString(data.ChatMessage)
    local ChatDate = data.ChatDate
    local ChatNumber = data.ChatNumber
    local ChatTime = data.ChatTime
    local ChatType = data.ChatType

    local Ped = PlayerPedId()
    local Pos = GetEntityCoords(Ped)
    local NumberKey = GetKeyByNumber(ChatNumber)
    local ChatKey = GetKeyByDate(NumberKey, ChatDate)
    local messaagePayload = {}
    if PhoneData.Chats[NumberKey] ~= nil then
        if(PhoneData.Chats[NumberKey].messages == nil) then
            PhoneData.Chats[NumberKey].messages = {}
        end
        if PhoneData.Chats[NumberKey].messages[ChatKey] ~= nil then
            if ChatType == "message" then
                messaagePayload = {
                    message = ChatMessage,
                    time = ChatTime,
                    sender = PhoneData.PlayerData.citizenid,
                    type = ChatType,
                    data = {},
                }
                table.insert(PhoneData.Chats[NumberKey].messages[ChatKey].messages, messaagePayload)
            elseif ChatType == "location" then
                messaagePayload = {
                    message = ChatMessage,
                    time = ChatTime,
                    sender = PhoneData.PlayerData.citizenid,
                    type = ChatType,
                    data = {
                        x = Pos.x,
                        y = Pos.y,
                    },
                }
                table.insert(PhoneData.Chats[NumberKey].messages[ChatKey].messages, messaagePayload)
            end
            TriggerServerEvent('qb-phone:server:UpdateMessages', PhoneData.Chats[NumberKey].messages, ChatNumber, false)
            NumberKey = GetKeyByNumber(ChatNumber)
            ReorganizeChats(NumberKey)
        else
            table.insert(PhoneData.Chats[NumberKey].messages, {
                date = ChatDate,
                messages = {},
            })
            ChatKey = GetKeyByDate(NumberKey, ChatDate)
            if ChatType == "message" then
                messaagePayload = {
                    message = ChatMessage,
                    time = ChatTime,
                    sender = PhoneData.PlayerData.citizenid,
                    type = ChatType,
                    data = {},
                }
                table.insert(PhoneData.Chats[NumberKey].messages[ChatKey].messages, messaagePayload)
            elseif ChatType == "location" then
                messaagePayload = {
                    message = "Shared Location",
                    time = ChatTime,
                    sender = PhoneData.PlayerData.citizenid,
                    type = ChatType,
                    data = {
                        x = Pos.x,
                        y = Pos.y,
                    },
                }
                table.insert(PhoneData.Chats[NumberKey].messages[ChatDate].messages, messaagePayload)
            end
            TriggerServerEvent('qb-phone:server:UpdateMessages', messaagePayload, ChatNumber, true)
            NumberKey = GetKeyByNumber(ChatNumber)
            ReorganizeChats(NumberKey)
        end
    else
        table.insert(PhoneData.Chats, {
            name = IsNumberInContacts(ChatNumber),
            number = ChatNumber,
            messages = {},
        })
        NumberKey = GetKeyByNumber(ChatNumber)
        table.insert(PhoneData.Chats[NumberKey].messages, {
            date = ChatDate,
            messages = {},
        })
        ChatKey = GetKeyByDate(NumberKey, ChatDate)
        if ChatType == "message" then
            message = {
                message = ChatMessage,
                time = ChatTime,
                sender = PhoneData.PlayerData.citizenid,
                type = ChatType,
                data = {},
            }
            table.insert(PhoneData.Chats[NumberKey].messages[ChatKey].messages, message)
        elseif ChatType == "location" then
            message = {
                message = "Shared Location",
                time = ChatTime,
                sender = PhoneData.PlayerData.citizenid,
                type = ChatType,
                data = {
                    x = Pos.x,
                    y = Pos.y,
                },
            }
            table.insert(PhoneData.Chats[NumberKey].messages[ChatKey].messages, message)
        end
        TriggerServerEvent('qb-phone:server:UpdateMessages', PhoneData.Chats[NumberKey].messages, ChatNumber, true)
        NumberKey = GetKeyByNumber(ChatNumber)
        ReorganizeChats(NumberKey)
    end

    QBCore.Functions.TriggerCallback('qb-phone:server:GetContactPicture', function(Chat)
        SendNUIMessage({
            action = "UpdateChat",
            chatData = Chat,
            chatNumber = ChatNumber,
        })
    end,  PhoneData.Chats[GetKeyByNumber(ChatNumber)])
    cb('ok')
end)

RegisterNUICallback('SharedLocation', function(data, cb)
    local x = data.coords.x
    local y = data.coords.y

    SetNewWaypoint(x, y)
    SendNUIMessage({
        action = "PhoneNotification",
        PhoneNotify = {
            title = "Whatsapp",
            text = "Location set!",
            icon = "fab fa-whatsapp",
            color = "#25D366",
            timeout = 1500,
        },
    })
    cb('ok')
end)

RegisterNetEvent('qb-phone:client:UpdateMessages', function(ChatMessages, SenderNumber, New) --ChatMessages
    local NumberKey = GetKeyByNumber(SenderNumber)

    if New then
        table.insert(PhoneData.Chats, {
            name = IsNumberInContacts(SenderNumber),
            number = SenderNumber,
            messages = {},
        })

        NumberKey = GetKeyByNumber(SenderNumber)

        PhoneData.Chats[NumberKey] = {
            name = IsNumberInContacts(SenderNumber),
            number = SenderNumber,
            messages = ChatMessages
        }

        if PhoneData.Chats[NumberKey].Unread ~= nil then
            PhoneData.Chats[NumberKey].Unread = PhoneData.Chats[NumberKey].Unread + 1
        else
            PhoneData.Chats[NumberKey].Unread = 1
        end

        if PhoneData.isOpen then
            if SenderNumber ~= PhoneData.PlayerData.charinfo.phone then
                SendNUIMessage({
                    action = "PhoneNotification",
                    PhoneNotify = {
                        title = "Whatsapp",
                        text = "New message from "..IsNumberInContacts(SenderNumber).."!",
                        icon = "fab fa-whatsapp",
                        color = "#25D366",
                        timeout = 1500,
                    },
                })
            else
                SendNUIMessage({
                    action = "PhoneNotification",
                    PhoneNotify = {
                        title = "Whatsapp",
                        text = "Messaged yourself",
                        icon = "fab fa-whatsapp",
                        color = "#25D366",
                        timeout = 4000,
                    },
                })
            end

            NumberKey = GetKeyByNumber(SenderNumber)
            ReorganizeChats(NumberKey)

            Wait(100)
            QBCore.Functions.TriggerCallback('qb-phone:server:GetContactPictures', function(Chats)
                SendNUIMessage({
                    action = "UpdateChat",
                    chatData = Chats[GetKeyByNumber(SenderNumber)],
                    chatNumber = SenderNumber,
                    Chats = Chats,
                })
            end,  PhoneData.Chats)
        else
            SendNUIMessage({
                action = "Notification",
                NotifyData = {
                    title = "Whatsapp", 
                    content = "You have received a new message from "..IsNumberInContacts(SenderNumber).."!", 
                    icon = "fab fa-whatsapp", 
                    timeout = 3500, 
                    color = "#25D366",
                },
            })
            Config.PhoneApplications['whatsapp'].Alerts = Config.PhoneApplications['whatsapp'].Alerts + 1
            TriggerServerEvent('qb-phone:server:SetPhoneAlerts', "whatsapp")
        end
    else
        PhoneData.Chats[NumberKey].messages = ChatMessages

        if PhoneData.Chats[NumberKey].Unread ~= nil then
            PhoneData.Chats[NumberKey].Unread = PhoneData.Chats[NumberKey].Unread + 1
        else
            PhoneData.Chats[NumberKey].Unread = 1
        end

        if PhoneData.isOpen then
            if SenderNumber ~= PhoneData.PlayerData.charinfo.phone then
                SendNUIMessage({
                    action = "PhoneNotification",
                    PhoneNotify = {
                        title = "Whatsapp",
                        text = "New message from "..IsNumberInContacts(SenderNumber).."!",
                        icon = "fab fa-whatsapp",
                        color = "#25D366",
                        timeout = 1500,
                    },
                })
            else
                SendNUIMessage({
                    action = "PhoneNotification",
                    PhoneNotify = {
                        title = "Whatsapp",
                        text = "Messaged yourself",
                        icon = "fab fa-whatsapp",
                        color = "#25D366",
                        timeout = 4000,
                    },
                })
            end

            NumberKey = GetKeyByNumber(SenderNumber)
            ReorganizeChats(NumberKey)

            Wait(100)
            QBCore.Functions.TriggerCallback('qb-phone:server:GetContactPictures', function(Chats)
                SendNUIMessage({
                    action = "UpdateChat",
                    chatData = Chats[GetKeyByNumber(SenderNumber)],
                    chatNumber = SenderNumber,
                    Chats = Chats,
                })
            end,  PhoneData.Chats)
        else
            SendNUIMessage({
                action = "Notification",
                NotifyData = {
                    title = "Whatsapp", 
                    content = "You have received a new message from "..IsNumberInContacts(SenderNumber).."!", 
                    icon = "fab fa-whatsapp", 
                    timeout = 3500, 
                    color = "#25D366",
                },
            })

            NumberKey = GetKeyByNumber(SenderNumber)
            ReorganizeChats(NumberKey)

            Config.PhoneApplications['whatsapp'].Alerts = Config.PhoneApplications['whatsapp'].Alerts + 1
            TriggerServerEvent('qb-phone:server:SetPhoneAlerts', "whatsapp")
        end
    end
end)

RegisterNetEvent("qb-phone-new:client:BankNotify", function(text)
    SendNUIMessage({
        action = "Notification",
        NotifyData = {
            title = "Bank",
            content = text,
            icon = "fas fa-university",
            timeout = 3500,
            color = "#ff002f",
        },
    })
end)

RegisterNetEvent('qb-phone:client:NewMailNotify', function(MailData)
    if PhoneData.isOpen then
        SendNUIMessage({
            action = "PhoneNotification",
            PhoneNotify = {
                title = "Mail",
                text = "You have received a new mail from "..MailData.sender,
                icon = "fas fa-envelope",
                color = "#D62839",
                timeout = 1500,
            },
        })
    else
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "Mail", 
                content = "You have received a new mail from "..MailData.sender, 
                icon = "fas fa-envelope", 
                timeout = 3500, 
                color = "#D62839",
            },
        })
    end
    Config.PhoneApplications['mail'].Alerts = Config.PhoneApplications['mail'].Alerts + 1
    TriggerServerEvent('qb-phone:server:SetPhoneAlerts', "mail")
end)

RegisterNUICallback('PostAdvert', function(data, cb)
    TriggerServerEvent('qb-phone:server:AddAdvert', data.message)
    cb('ok')
end)

RegisterNUICallback('PostDarkWeb', function(data, cb)
    TriggerServerEvent('qb-phone:server:AddDarkWeb', data)
    cb('ok')
end)

RegisterNUICallback('PostNote', function(data, cb)
    TriggerServerEvent('qb-phone:server:AddNote', data)
    cb('ok')
end)

RegisterNUICallback('EditNote', function(data, cb)
    for k, v in pairs(PhoneData.Notes) do
        if data.id == v.id then
            PhoneData.Notes[k]['title'] = data.title
            PhoneData.Notes[k]['body'] = data.body
            TriggerServerEvent('qb-phone:server:EditNote', data)
        end
    end
    cb('ok')
end)

RegisterNUICallback('DeleteNote', function(data, cb)
    TriggerServerEvent('qb-phone:server:DeleteNote', data)
    cb('ok')
end)

RegisterNUICallback('SendPlayerMail', function(data, cb)
    TriggerServerEvent('qb-phone:server:SendPlayerMail', data)
end)

RegisterNetEvent('qb-phone:client:UpdateAdverts', function(Adverts, LastAd)
    PhoneData.Adverts = Adverts

    if PhoneData.isOpen then
        SendNUIMessage({
            action = "PhoneNotification",
            PhoneNotify = {
                title = "Advertisements",
                text = "A new Ad has been posted by "..LastAd,
                icon = "fas fa-ad",
                color = "#ff8f1a",
                timeout = 2500,
            },
        })
    else
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "Advertisements", 
                content = "A new Ad has been posted by "..LastAd,
                icon = "fas fa-ad", 
                timeout = 2500, 
                color = "#ff8f1a",
            },
        })
    end

    SendNUIMessage({
        action = "RefreshAdverts",
        Adverts = PhoneData.Adverts
    })
end)

RegisterNUICallback('LoadAdverts', function(_, cb)
    SendNUIMessage({
        action = "RefreshAdverts",
        Adverts = PhoneData.Adverts
    })
    cb('ok')
end)

RegisterNetEvent('qb-phone:client:UpdateDarkWeb', function(DarkWeb, LastSender)
    PhoneData.DarkWeb = DarkWeb
    SendNUIMessage({
        action = "RefreshDarkWeb",
        DarkWeb = PhoneData.DarkWeb
    })

    if PhoneData.isOpen then
        SendNUIMessage({
            action = "PhoneNotification",
            PhoneNotify = {
                title = "DarkWeb",
                text = "There's a new message on the DarkWeb from "..LastSender,
                icon = "fas fa-user-secret",
                color = "#191716",
                timeout = 1500,
            },
        })
    else
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "DarkWeb", 
                content = "There's a new message on the DarkWeb from "..LastSender, 
                icon = "fas fa-user-secret", 
                timeout = 3500, 
                color = "#191716",
            },
        })
    end
end)

RegisterNUICallback('LoadNotes', function(_, cb)
    cb(PhoneData.Notes)
end)

RegisterNetEvent('qb-phone:client:UpdateNotes', function(Notes)
    PhoneData.Notes = Notes
    SendNUIMessage({
        action = "RefreshNotes",
        Notes = PhoneData.Notes
    })
end)

RegisterNetEvent('qb-phone:client:AddNote', function(data)
    PhoneData.Notes[#PhoneData.Notes+1] = data
    SendNUIMessage({
        action = "RefreshNotes",
        Notes = PhoneData.Notes
    })
end)

RegisterNUICallback('GetAuctions', function(_, cb)
    lib.callback('qb-auctions:server:GetAuctions', false, function(auctions)
        PhoneData.Auctions = auctions
        cb(auctions)
    end)
end)

RegisterNUICallback('GetGangData', function(_, cb)
	local gang = PhoneData.PlayerData.gang.name
    QBCore.Functions.TriggerCallback('qb-phone:server:GetGangData', function(gang)
        PhoneData.Gang = gang
        cb(gang)
    end, gang)
end)

RegisterNUICallback('AuctionBuyItem', function(data, cb)
    TriggerServerEvent('qb-auctions:server:buyItNowAuction', data.id)
    cb('ok')
end)

RegisterNUICallback('AuctionBidItem', function(data, cb)
    TriggerServerEvent('qb-auctions:server:bidAuction', data.id)
    cb('ok')
end)

RegisterNetEvent('qb-phone:client:removeAuctionItem')
AddEventHandler('qb-phone:client:removeAuctionItem', function(id)
    local newAuctions = {}
    for k, v in pairs(PhoneData.Auctions) do
        if v._id ~= id then
            newAuctions[#newAuctions+1] = v
        end
    end
    PhoneData.Auctions = newAuctions
    SendNUIMessage({
        action = "RefreshAuctions",
        Auctions = PhoneData.Auctions
    })
end)

RegisterNetEvent('qb-phone:client:addAuctionItem')
AddEventHandler('qb-phone:client:addAuctionItem', function(data)
    PhoneData.Auctions[#PhoneData.Auctions+1] = data
    SendNUIMessage({
        action = "RefreshAuctions",
        Auctions = PhoneData.Auctions
    })
end)

RegisterNetEvent('qb-phone:client:updateAuctionItem')
AddEventHandler('qb-phone:client:updateAuctionItem', function(id, price, highBidder)
    local newAuctions = {}
    for k, v in pairs(PhoneData.Auctions) do
        local inc = #newAuctions+1
        newAuctions[inc] = v
        if v._id == id then
            newAuctions[inc]['currentBidPrice'] = price
            newAuctions[inc]['highBidder'] = highBidder
        end
    end
    PhoneData.Auctions = newAuctions
    SendNUIMessage({
        action = "RefreshAuctions",
        Auctions = PhoneData.Auctions
    })
end)

RegisterNetEvent('qb-phone:client:postBuyItNowClose')
AddEventHandler('qb-phone:client:postBuyItNowClose', function()
    SendNUIMessage({
        action = "CloseAuctionPage",
    })
end)

RegisterNUICallback('LoadDarkWeb', function(_, cb)
    SendNUIMessage({
        action = "RefreshDarkWeb",
        DarkWeb = PhoneData.DarkWeb
    })
    cb('ok')
end)

RegisterNUICallback('ClearAlerts', function(data, cb)
    local chat = data.number
    local ChatKey = GetKeyByNumber(chat)

    if PhoneData.Chats[ChatKey].Unread ~= nil then
        local newAlerts = (Config.PhoneApplications['whatsapp'].Alerts - PhoneData.Chats[ChatKey].Unread)
        Config.PhoneApplications['whatsapp'].Alerts = newAlerts
        TriggerServerEvent('qb-phone:server:SetPhoneAlerts', "whatsapp", newAlerts)

        PhoneData.Chats[ChatKey].Unread = 0

        SendNUIMessage({
            action = "RefreshWhatsappAlerts",
            Chats = PhoneData.Chats,
        })
        SendNUIMessage({ action = "RefreshAppAlerts", AppData = Config.PhoneApplications })
    end
    cb('ok')
end)

RegisterNUICallback('PayInvoice', function(data, cb)
    local society = data.society
    local amount = data.amount
    local invoiceId = data.invoiceId

    QBCore.Functions.TriggerCallback('qb-phone:server:PayInvoice', function(CanPay, Invoices)
        if CanPay then PhoneData.Invoices = Invoices end
        cb(CanPay)
    end, society, amount, invoiceId)
end)

RegisterNUICallback('DeclineInvoice', function(data, cb)
    local sender = data.sender
    local amount = data.amount
    local invoiceId = data.invoiceId

    QBCore.Functions.TriggerCallback('qb-phone:server:DeclineInvoice', function(CanPay, Invoices)
        PhoneData.Invoices = Invoices
        cb('ok')
    end, sender, amount, invoiceId)
end)

RegisterNUICallback('EditContact', function(data, cb)
    local NewName = data.CurrentContactName
    local NewNumber = data.CurrentContactNumber
    local NewIban = data.CurrentContactIban
    local OldName = data.OldContactName
    local OldNumber = data.OldContactNumber
    local OldIban = data.OldContactIban

    for k, v in pairs(PhoneData.Contacts) do
        if v.name == OldName and v.number == OldNumber then
            v.name = NewName
            v.number = NewNumber
            v.iban = NewIban
        end
    end
    if PhoneData.Chats[NewNumber] ~= nil and next(PhoneData.Chats[NewNumber]) ~= nil then
        PhoneData.Chats[NewNumber].name = NewName
    end
    Wait(100)
    cb(PhoneData.Contacts)
    TriggerServerEvent('qb-phone:server:EditContact', NewName, NewNumber, NewIban, OldName, OldNumber, OldIban)
end)

local function escape_str(s)
	local in_char  = {'\\', '"', '/', '\b', '\f', '\r', '\t'}
	local out_char = {'\\', '"', '/',  'b',  'f',  'r',  't'}
	for i, c in ipairs(in_char) do
        s = s:gsub(c, '\\' .. out_char[i])
	end
	return s
end

local function GenerateTweetId()
    local tweetId = "TWEET-"..math.random(11111111, 99999999)
    return tweetId
end

RegisterNetEvent('qb-phone:client:UpdateHashtags', function(Handle, msgData)
    if LocalPlayer.state.isLoggedIn then
        if PhoneData.Hashtags[Handle] ~= nil then
            table.insert(PhoneData.Hashtags[Handle].messages, msgData)
        else
            PhoneData.Hashtags[Handle] = {
                hashtag = Handle,
                messages = {}
            }
            table.insert(PhoneData.Hashtags[Handle].messages, msgData)
        end

        SendNUIMessage({
            action = "UpdateHashtags",
            Hashtags = PhoneData.Hashtags,
        })
    end
end)

RegisterNUICallback('GetHashtagMessages', function(data, cb)
    if PhoneData.Hashtags[data.hashtag] ~= nil and next(PhoneData.Hashtags[data.hashtag]) ~= nil then
        cb(PhoneData.Hashtags[data.hashtag])
    else
        cb(nil)
    end
end)

RegisterNUICallback('GetTweets', function(_, cb)
    cb(PhoneData.Tweets)
end)

RegisterNUICallback('UpdateProfilePicture', function(data, cb)
    local pf = data.profilepicture

    PhoneData.MetaData.profilepicture = pf
    
    TriggerServerEvent('qb-phone:server:SaveMetaData', PhoneData.MetaData)
    cb('ok')
end)

local patt = "[?!@#]"

RegisterNUICallback('PostNewTweet', function(data, cb)
    local TweetMessage = {
        firstName = PhoneData.PlayerData.charinfo.firstname,
        lastName = PhoneData.PlayerData.charinfo.lastname,
        citizenid = PhoneData.PlayerData.citizenid,
        message = data.Message,
        time = data.Date,
        tweetId = GenerateTweetId(),
        picture = data.Picture,
        url = data.url
    }

    local TwitterMessage = data.Message
    local MentionTag = TwitterMessage:split("@")
    local Hashtag = TwitterMessage:split("#")

    for i = 2, #Hashtag, 1 do
        local Handle = Hashtag[i]:split(" ")[1]
        if Handle ~= nil or Handle ~= "" then
            local InvalidSymbol = string.match(Handle, patt)
            if InvalidSymbol then
                Handle = Handle:gsub("%"..InvalidSymbol, "")
            end
            TriggerServerEvent('qb-phone:server:UpdateHashtags', Handle, TweetMessage)
        end
    end

    for i = 2, #MentionTag, 1 do
        local Handle = MentionTag[i]:split(" ")[1]
        if Handle ~= nil or Handle ~= "" then
            local Fullname = Handle:split("_")
            local Firstname = Fullname[1]
            table.remove(Fullname, 1)
            local Lastname = table.concat(Fullname, " ")

            if (Firstname ~= nil and Firstname ~= "") and (Lastname ~= nil and Lastname ~= "") then
                if Firstname ~= PhoneData.PlayerData.charinfo.firstname and Lastname ~= PhoneData.PlayerData.charinfo.lastname then
                    TriggerServerEvent('qb-phone:server:MentionedPlayer', Firstname, Lastname, TweetMessage)
                end
            end
        end
    end

    table.insert(PhoneData.Tweets, TweetMessage)
    Wait(100)
    cb(PhoneData.Tweets)

    TriggerServerEvent('qb-phone:server:UpdateTweets', PhoneData.Tweets, TweetMessage)
end)

RegisterNetEvent('qb-phone:client:TransferMoney', function(amount, newmoney)
    PhoneData.PlayerData.money.bank = newmoney
    if PhoneData.isOpen then
        SendNUIMessage({ action = "PhoneNotification", PhoneNotify = { title = "Bank", text = "There is $"..amount.." credited!", icon = "fas fa-university", color = "#8c7ae6", }, })
        SendNUIMessage({ action = "UpdateBank", NewBalance = PhoneData.PlayerData.money.bank })
    else
        SendNUIMessage({ 
            action = "Notification", 
            NotifyData = { 
                title = "Bank", 
                content = "There is $"..amount.." credited!", 
                icon = "fas fa-university", 
                timeout = 2500, color = nil, 
            }, 
        })
    end
end)

RegisterNetEvent('qb-phone:client:UpdateTweets', function(src, Tweets, NewTweetData)
    if LocalPlayer.state.isLoggedIn then
        PhoneData.Tweets = Tweets
        local MyPlayerId = PhoneData.PlayerData.source

        if src ~= MyPlayerId then
            if not PhoneData.isOpen then
                SendNUIMessage({
                    action = "Notification",
                    NotifyData = {
                        title = "New Tweet (@"..NewTweetData.firstName.." "..NewTweetData.lastName..")", 
                        content = NewTweetData.message, 
                        icon = "fab fa-twitter", 
                        timeout = 3500, 
                        color = nil,
                    },
                })
            else
                SendNUIMessage({
                    action = "PhoneNotification",
                    PhoneNotify = {
                        title = "New Tweet (@"..NewTweetData.firstName.." "..NewTweetData.lastName..")", 
                        text = NewTweetData.message, 
                        icon = "fab fa-twitter",
                        color = "#1DA1F2",
                    },
                })
            end
        else
            SendNUIMessage({
                action = "PhoneNotification",
                PhoneNotify = {
                    title = "Twitter", 
                    text = "Tweet has been posted!", 
                    icon = "fab fa-twitter",
                    color = "#1DA1F2",
                    timeout = 1000,
                },
            })
        end
    end
end)

RegisterNUICallback('GetMentionedTweets', function(_, cb)
    cb(PhoneData.MentionedTweets)
end)

RegisterNUICallback('GetHashtags', function(_, cb)
    if PhoneData.Hashtags ~= nil and next(PhoneData.Hashtags) ~= nil then
        cb(PhoneData.Hashtags)
    else
        cb(nil)
    end
end)

RegisterNetEvent('qb-phone:client:GetMentioned')
AddEventHandler('qb-phone:client:GetMentioned', function(TweetMessage, AppAlerts)
    Config.PhoneApplications["twitter"].Alerts = AppAlerts
    if not PhoneData.isOpen then
        SendNUIMessage({ 
            action = "Notification", 
            NotifyData = { 
                title = "You were mentioned in a tweet!", 
                content = TweetMessage.message, 
                icon = "fab fa-twitter", 
                timeout = 3500, 
                color = nil, 
            }, 
        })
    else
        SendNUIMessage({ 
            action = "PhoneNotification", 
            PhoneNotify = { 
                title = "You were mentioned in a tweet!", 
                text = TweetMessage.message, 
                icon = "fab fa-twitter", 
                color = "#1DA1F2", 
            }, 
        })
    end
    local TweetMessage = {firstName = TweetMessage.firstName, lastName = TweetMessage.lastName, message = TweetMessage.message, time = TweetMessage.time, picture = TweetMessage.picture}
    table.insert(PhoneData.MentionedTweets, TweetMessage)
    SendNUIMessage({ action = "RefreshAppAlerts", AppData = Config.PhoneApplications })
    SendNUIMessage({ action = "UpdateMentionedTweets", Tweets = PhoneData.MentionedTweets })
end)

RegisterNUICallback('ClearMentions', function(_, cb)
    Config.PhoneApplications["twitter"].Alerts = 0
    SendNUIMessage({
        action = "RefreshAppAlerts",
        AppData = Config.PhoneApplications
    })
    TriggerServerEvent('qb-phone:server:SetPhoneAlerts', "twitter", 0)
    SendNUIMessage({ action = "RefreshAppAlerts", AppData = Config.PhoneApplications })
    cb('ok')
end)

RegisterNUICallback('ClearGeneralAlerts', function(data, cb)
    SetTimeout(400, function()
        Config.PhoneApplications[data.app].Alerts = 0
        SendNUIMessage({
            action = "RefreshAppAlerts",
            AppData = Config.PhoneApplications
        })
        TriggerServerEvent('qb-phone:server:SetPhoneAlerts', data.app, 0)
        SendNUIMessage({ action = "RefreshAppAlerts", AppData = Config.PhoneApplications })
        cb('ok')
    end)
end)

function string:split(delimiter)
    local result = { }
    local from  = 1
    local delim_from, delim_to = string.find( self, delimiter, from  )
    while delim_from do
        table.insert( result, string.sub( self, from , delim_from-1 ) )
        from  = delim_to + 1
        delim_from, delim_to = string.find( self, delimiter, from  )
    end
    table.insert( result, string.sub( self, from  ) )
    return result
end

RegisterNUICallback('TransferMoney', function(data, cb)
    data.amount = tonumber(data.amount)
    if tonumber(PhoneData.PlayerData.money.bank) >= data.amount then
        local amaountata = PhoneData.PlayerData.money.bank - data.amount
        TriggerServerEvent('qb-phone:server:TransferMoney', data.iban, data.amount, securityToken)
        local cbdata = {
            CanTransfer = true,
            NewAmount = amaountata 
        }
        cb(cbdata)
    else
        local cbdata = {
            CanTransfer = false,
            NewAmount = nil,
        }
        cb(cbdata)
    end
end)

RegisterNUICallback('CanTransferMoney', function(data, cb)
    local amount = tonumber(data.amountOf)
    local iban = data.sendTo
    local PlayerData = QBCore.Functions.GetPlayerData()

    if (PlayerData.money.bank - amount) >= 0 then
        QBCore.Functions.TriggerCallback('qb-phone:server:CanTransferMoney', function(Transferd)
            if Transferd then
                cb({TransferedMoney = true, NewBalance = (PlayerData.money.bank - amount)})
            else
                cb({TransferedMoney = false})
            end
        end, amount, iban)
    else
        cb({TransferedMoney = false})
    end
end)

RegisterNUICallback('GetWhatsappChats', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-phone:server:GetContactPictures', function(Chats)
        cb(Chats)
    end, PhoneData.Chats)
end)

RegisterNUICallback('DeleteWhatsappMessage', function(data, cb)
    local ChatNumber = data.ChatNumber
    QBCore.Functions.TriggerCallback('qb-phone:server:DeleteWhatsappMessage', function()
        cb('ok')
    end, ChatNumber)
end)

RegisterNUICallback('CallContact', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-phone:server:GetCallState', function(CanCall, IsOnline)
        local status = {
            CanCall = CanCall,
            IsOnline = IsOnline,
            InCall = PhoneData.CallData.InCall,
        }
        cb(status)
        if CanCall and not status.InCall and (data.ContactData.number ~= PhoneData.PlayerData.charinfo.phone) then
            CallContact(data.ContactData, data.Anonymous)
        end
    end, data.ContactData)
end)

RegisterNUICallback('CallContactPayphone', function(data, cb)
    QBCore.Functions.TriggerCallback('QBCore:HasMoney', function(hasMoney)
        if hasMoney then
            QBCore.Functions.TriggerCallback('qb-phone:server:GetCallState', function(CanCall, IsOnline)
                local status = { 
                    CanCall = CanCall,
                    IsOnline = IsOnline,
                    InCall = PhoneData.CallData.InCall,
                }
                cb(status)
                if CanCall and not status.InCall and (data.ContactData.number ~= PhoneData.PlayerData.charinfo.phone) then
                    CallContactPayphone(data.ContactData, data.Anonymous)
                end
            end, data.ContactData)
        else
            QBCore.Functions.Notify("You need $5 cash to make a call..", "error")
        end
    end, 5, "cash")
end)

function CancelCall()
    TriggerServerEvent('qb-phone:server:CancelCall', PhoneData.CallData)
    if PhoneData.CallData.CallType == "ongoing" then
        exports['pma-voice']:removePlayerFromCall(PhoneData.CallData.CallId)
    end
    PhoneData.CallData.CallType = nil
    PhoneData.CallData.InCall = false
    PhoneData.CallData.AnsweredCall = false
    PhoneData.CallData.TargetData = {}
    PhoneData.CallData.CallId = nil

    if not PhoneData.isOpen then
        StopAnimTask(PlayerPedId(), PhoneData.AnimationData.lib, PhoneData.AnimationData.anim, 2.5)
        deletePhone()
        PhoneData.AnimationData.lib = nil
        PhoneData.AnimationData.anim = nil
    else
        PhoneData.AnimationData.lib = nil
        PhoneData.AnimationData.anim = nil
    end

    TriggerServerEvent('qb-phone:server:SetCallState', false)

    if not PhoneData.isOpen then
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "Phone",
                content = "The call has ended",
                icon = "fas fa-phone",
                timeout = 3500,
                color = "#e84118",
            },
        })
    else
        SendNUIMessage({ 
            action = "PhoneNotification", 
            PhoneNotify = { 
                title = "Phone", 
                text = "The call has ended", 
                icon = "fas fa-phone", 
                color = "#e84118", 
            }, 
        })
    end

    SendNUIMessage({
        action = "SetupHomeCall",
        CallData = PhoneData.CallData,
    })

    SendNUIMessage({
        action = "CancelOutgoingCall",
    })
end

function CancelPayphoneCall()
    TriggerServerEvent('qb-phone:server:CancelCall', PhoneData.CallData)
    if PhoneData.CallData.CallType == "ongoing" then
        exports['pma-voice']:removePlayerFromCall(PhoneData.CallData.CallId)
    end
    PhoneData.CallData.CallType = nil
    PhoneData.CallData.InCall = false
    PhoneData.CallData.AnsweredCall = false
    PhoneData.CallData.TargetData = {}
    PhoneData.CallData.CallId = nil

    if not PhoneData.isOpen then
        StopAnimTask(PlayerPedId(), PhoneData.AnimationData.lib, PhoneData.AnimationData.anim, 2.5)
        deletePhone()
        PhoneData.AnimationData.lib = nil
        PhoneData.AnimationData.anim = nil
    else
        PhoneData.AnimationData.lib = nil
        PhoneData.AnimationData.anim = nil
    end

    TriggerServerEvent('qb-phone:server:SetCallState', false)
    SendNUIMessage({ 
        action = "PhoneNotification", 
        PhoneNotify = { 
            title = "Phone", 
            text = "The call has ended", 
            icon = "fas fa-phone", 
            color = "#e84118", 
        }, 
    })

    -- SendNUIMessage({ --look into what this does
    --     action = "SetupHomeCall",
    --     CallData = PhoneData.CallData,
    -- })
    SendNUIMessage({
        action = "CancelOutgoingPayphoneCall",
    })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

RegisterNetEvent('qb-phone:client:CancelCall')
AddEventHandler('qb-phone:client:CancelCall', function()
    if PhoneData.CallData.CallType == "ongoing" then
        SendNUIMessage({
            action = "CancelOngoingCall"
        })
        exports['pma-voice']:removePlayerFromCall(PhoneData.CallData.CallId)
    end
    PhoneData.CallData.CallType = nil
    PhoneData.CallData.InCall = false
    PhoneData.CallData.AnsweredCall = false
    PhoneData.CallData.TargetData = {}

    if not PhoneData.isOpen then
        StopAnimTask(PlayerPedId(), PhoneData.AnimationData.lib, PhoneData.AnimationData.anim, 2.5)
        deletePhone()
        PhoneData.AnimationData.lib = nil
        PhoneData.AnimationData.anim = nil
    else
        PhoneData.AnimationData.lib = nil
        PhoneData.AnimationData.anim = nil
    end

    TriggerServerEvent('qb-phone:server:SetCallState', false)

    if not PhoneData.isOpen then
        SendNUIMessage({ 
            action = "Notification", 
            NotifyData = { 
                title = "Phone",
                content = "The call has ended", 
                icon = "fas fa-phone", 
                timeout = 3500, 
                color = "#e84118",
            }, 
        })            
    else
        SendNUIMessage({ 
            action = "PhoneNotification", 
            PhoneNotify = { 
                title = "Phone", 
                text = "The call has ended", 
                icon = "fas fa-phone", 
                color = "#e84118", 
            }, 
        })

        SendNUIMessage({
            action = "SetupHomeCall",
            CallData = PhoneData.CallData,
        })

        SendNUIMessage({
            action = "CancelOutgoingCall",
        })
    end
end)

RegisterNetEvent('qb-phone:client:GetCalled', function(CallerNumber, CallId, AnonymousCall, Payphone)
    local RepeatCount = 0
    local CallData = {
        number = CallerNumber,
        name = IsNumberInContacts(CallerNumber),
        anonymous = AnonymousCall
    }

    if AnonymousCall then
        CallData.name = "Anonymous"
    end

    PhoneData.CallData.CallType = "incoming"
    PhoneData.CallData.InCall = true
    PhoneData.CallData.AnsweredCall = false
    PhoneData.CallData.TargetData = CallData
    PhoneData.CallData.CallId = CallId

    TriggerServerEvent('qb-phone:server:SetCallState', true)

    SendNUIMessage({
        action = "SetupHomeCall",
        CallData = PhoneData.CallData,
    })

    for i = 1, Config.CallRepeats + 1, 1 do
        if not PhoneData.CallData.AnsweredCall then
            if RepeatCount + 1 ~= Config.CallRepeats + 1 then
                if PhoneData.CallData.InCall then
                    local HasPhone = QBCore.Functions.HasItem('phone')
                    if HasPhone then
                        RepeatCount = RepeatCount + 1
                        --TriggerServerEvent("InteractSound_SV:PlayOnSource", "ringing", 0.2)
                        local netId = NetworkGetNetworkIdFromEntity(PlayerPedId())
                        TriggerServerEvent('chHyperSound:playOnEntity', netId, 1, 'ringing', false, 15, -1)
                        
                        if not PhoneData.isOpen then
                            SendNUIMessage({
                                action = "IncomingCallAlert",
                                CallData = PhoneData.CallData.TargetData,
                                Canceled = false,
                                AnonymousCall = AnonymousCall,
                            })
                        end
                    end
                else
                    SendNUIMessage({
                        action = "IncomingCallAlert",
                        CallData = PhoneData.CallData.TargetData,
                        Canceled = true,
                        AnonymousCall = AnonymousCall,
                    })
                    TriggerServerEvent('qb-phone:server:AddRecentCall', "missed", CallData, AnonymousCall, Payphone)
                    break
                end
                Wait(Config.RepeatTimeout)
            else
                SendNUIMessage({
                    action = "IncomingCallAlert",
                    CallData = PhoneData.CallData.TargetData,
                    Canceled = true,
                    AnonymousCall = AnonymousCall,
                })
                TriggerServerEvent('qb-phone:server:AddRecentCall', "missed", CallData, AnonymousCall, Payphone)
                break
            end
        else
            TriggerServerEvent('qb-phone:server:AddRecentCall', "missed", CallData, AnonymousCall, Payphone)
            break
        end
    end
end)

RegisterNUICallback('CancelOutgoingCall', function(_, cb)
    CancelCall()
    cb('ok')
end)

RegisterNUICallback('CancelOutgoingPayphoneCall', function(_, cb)
    CancelPayphoneCall()
    cb('ok')
end)

RegisterNUICallback('DenyIncomingCall', function(_, cb)
    CancelCall()
    cb('ok')
end)

RegisterNUICallback('CancelOngoingCall', function(_, cb)
    CancelCall()
    cb('ok')
end)

RegisterNUICallback('AnswerCall', function(_, cb)
    AnswerCall()
    cb('ok')
end)

function AnswerCall()
    if (PhoneData.CallData.CallType == "incoming" or PhoneData.CallData.CallType == "outgoing") and PhoneData.CallData.InCall and not PhoneData.CallData.AnsweredCall then
        PhoneData.CallData.CallType = "ongoing"
        PhoneData.CallData.AnsweredCall = true
        PhoneData.CallData.CallTime = 0

        SendNUIMessage({ action = "AnswerCall", CallData = PhoneData.CallData})
        SendNUIMessage({ action = "SetupHomeCall", CallData = PhoneData.CallData})

        TriggerServerEvent('qb-phone:server:SetCallState', true)

        if PhoneData.isOpen then
            DoPhoneAnimation('cellphone_text_to_call')
        else
            DoPhoneAnimation('cellphone_call_listen_base')
        end

        CreateThread(function()
            while true do
                if PhoneData.CallData.AnsweredCall then
                    PhoneData.CallData.CallTime = PhoneData.CallData.CallTime + 1
                    SendNUIMessage({
                        action = "UpdateCallTime",
                        Time = PhoneData.CallData.CallTime,
                        Name = PhoneData.CallData.TargetData.name,
                    })
                else
                    break
                end

                Wait(1000)
            end
        end)

        TriggerServerEvent('qb-phone:server:AnswerCall', PhoneData.CallData)

        exports['pma-voice']:addPlayerToCall(PhoneData.CallData.CallId)
    else
        PhoneData.CallData.InCall = false
        PhoneData.CallData.CallType = nil
        PhoneData.CallData.AnsweredCall = false

        SendNUIMessage({ 
            action = "PhoneNotification", 
            PhoneNotify = { 
                title = "Phone", 
                text = "You have no incoming call...", 
                icon = "fas fa-phone", 
                color = "#e84118", 
            }, 
        })
    end
end

RegisterNetEvent('qb-phone:client:AnswerCall', function()
    if (PhoneData.CallData.CallType == "incoming" or PhoneData.CallData.CallType == "outgoing") and PhoneData.CallData.InCall and not PhoneData.CallData.AnsweredCall then
        PhoneData.CallData.CallType = "ongoing"
        PhoneData.CallData.AnsweredCall = true
        PhoneData.CallData.CallTime = 0

        SendNUIMessage({ action = "AnswerCall", CallData = PhoneData.CallData})
        SendNUIMessage({ action = "SetupHomeCall", CallData = PhoneData.CallData})

        TriggerServerEvent('qb-phone:server:SetCallState', true)

        if PhoneData.isOpen then
            DoPhoneAnimation('cellphone_text_to_call')
        else
            DoPhoneAnimation('cellphone_call_listen_base')
        end

        CreateThread(function()
            while true do
                if PhoneData.CallData.AnsweredCall then
                    PhoneData.CallData.CallTime = PhoneData.CallData.CallTime + 1
                    SendNUIMessage({
                        action = "UpdateCallTime",
                        Time = PhoneData.CallData.CallTime,
                        Name = PhoneData.CallData.TargetData.name,
                    })
                else
                    break
                end

                Wait(1000)
            end
        end)

        exports['pma-voice']:addPlayerToCall(PhoneData.CallData.CallId)
    else
        PhoneData.CallData.InCall = false
        PhoneData.CallData.CallType = nil
        PhoneData.CallData.AnsweredCall = false

        SendNUIMessage({ 
            action = "PhoneNotification", 
            PhoneNotify = { 
                title = "Phone", 
                text = "You have no incoming call...", 
                icon = "fas fa-phone", 
                color = "#e84118", 
            }, 
        })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    deletePhone()
end)

--[[ RegisterNUICallback('FetchSearchResults', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-phone:server:FetchResult', function(result)
        cb(result)
    end, data.input)
end) ]]

--[[ RegisterNUICallback('FetchVehicleResults', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-phone:server:GetVehicleSearchResults', function(result)
        if result ~= nil then 
            for k, v in pairs(result) do
                QBCore.Functions.TriggerCallback('police:IsPlateFlagged', function(flagged)
                    result[k].isFlagged = flagged
                end, result[k].plate)
                Wait(50)
            end
        end
        cb(result)
    end, data.input)
end) ]]

RegisterNUICallback('FetchVehicleScan', function(data, cb)
    local vehicle = QBCore.Functions.GetClosestVehicle()
    local plate = GetVehicleNumberPlateText(vehicle)
    local model = GetEntityModel(vehicle)
    --local VehicleData = QBCore.Shared.VehicleHashes[model]
    local VehicleData = QBCore.Functions.GetSharedVehicleHashes(model)

    QBCore.Functions.TriggerCallback('qb-phone:server:ScanPlate', function(result)
        QBCore.Functions.TriggerCallback('police:IsPlateFlagged', function(flagged)
            result.isFlagged = flagged
            local vehicleInfo = VehicleData["model"] ~= nil and VehicleData["model"] or {["brand"] = "Unknown brand..", ["name"] = ""}
            result.label = vehicleInfo["name"]
            cb(result)
        end, plate)
    end, plate)
end)

RegisterNetEvent('qb-phone:client:addPoliceAlert')
AddEventHandler('qb-phone:client:addPoliceAlert', function(alertData)
    PlayerJob = QBCore.Functions.GetPlayerData().job
    if PlayerJob.name == 'police' and PlayerJob.onduty then
        SendNUIMessage({
            action = "AddPoliceAlert",
            alert = alertData,
        })
    end
end)

RegisterNUICallback('SetAlertWaypoint', function(data, cb)
    local coords = data.alert.coords

    QBCore.Functions.Notify('GPS Location set: '..data.alert.title)
    SetNewWaypoint(coords.x, coords.y)
    cb('ok')
end)

RegisterNUICallback('RemoveSuggestion', function(data, cb)
    local data = data.data

    if PhoneData.SuggestedContacts ~= nil and next(PhoneData.SuggestedContacts) ~= nil then
        for k, v in pairs(PhoneData.SuggestedContacts) do
            if (data.name[1] == v.name[1] and data.name[2] == v.name[2]) and data.number == v.number and data.bank == v.bank then
                table.remove(PhoneData.SuggestedContacts, k)
            end
        end
    end
    cb('ok')
end)

function GetClosestPlayer()
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(PlayerPedId())

    for i=1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
	end

	return closestPlayer, closestDistance
end

RegisterNetEvent('qb-phone:client:GiveContactDetails')
AddEventHandler('qb-phone:client:GiveContactDetails', function()
    local ped = PlayerPedId()

    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local PlayerId = GetPlayerServerId(player)
        TriggerServerEvent('qb-phone:server:GiveContactDetails', PlayerId)
    else
        QBCore.Functions.Notify("Nobody nearby!", "error")
    end
end)

-- CreateThread(function()
--     Wait(1000)
--     TriggerServerEvent('qb-phone:server:GiveContactDetails', 1)
-- end)

RegisterNUICallback('DeleteContact', function(data, cb)
    local Name = data.CurrentContactName
    local Number = data.CurrentContactNumber
    local Account = data.CurrentContactIban

    for k, v in pairs(PhoneData.Contacts) do
        if v.name == Name and v.number == Number then
            table.remove(PhoneData.Contacts, k)
            if PhoneData.isOpen then
                SendNUIMessage({
                    action = "PhoneNotification",
                    PhoneNotify = {
                        title = "Phone",
                        text = "You have deleted a contact!", 
                        icon = "fa fa-phone-alt",
                        color = "#04b543",
                        timeout = 1500,
                    },
                })
            else
                SendNUIMessage({
                    action = "Notification",
                    NotifyData = {
                        title = "Phone", 
                        content = "You have deleted a contact!", 
                        icon = "fa fa-phone-alt", 
                        timeout = 3500, 
                        color = "#04b543",
                    },
                })
            end
            break
        end
    end
    Wait(100)
    cb(PhoneData.Contacts)
    if PhoneData.Chats[Number] ~= nil and next(PhoneData.Chats[Number]) ~= nil then
        PhoneData.Chats[Number].name = Number
    end
    TriggerServerEvent('qb-phone:server:RemoveContact', Name, Number)
end)

RegisterNetEvent('qb-phone:client:AddNewSuggestion')
AddEventHandler('qb-phone:client:AddNewSuggestion', function(SuggestionData)
    table.insert(PhoneData.SuggestedContacts, SuggestionData)

    if PhoneData.isOpen then
        SendNUIMessage({
            action = "PhoneNotification",
            PhoneNotify = {
                title = "Phone",
                text = "You have a new proposed contact!", 
                icon = "fa fa-phone-alt",
                color = "#04b543",
                timeout = 1500,
            },
        })
    else
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "Phone", 
                content = "You have a new proposed contact!", 
                icon = "fa fa-phone-alt", 
                timeout = 3500, 
                color = "#04b543",
            },
        })
    end

    Config.PhoneApplications["phone"].Alerts = Config.PhoneApplications["phone"].Alerts + 1
    TriggerServerEvent('qb-phone:server:SetPhoneAlerts', "phone", Config.PhoneApplications["phone"].Alerts)
end)

RegisterNUICallback('GetCryptoData', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-crypto:server:GetCryptoData', function(CryptoData)
        cb(CryptoData)
    end, data.crypto)
end)

RegisterNUICallback('BuyCrypto', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-crypto:server:BuyCrypto', function(CryptoData)
        cb(CryptoData)
    end, data)
end)

RegisterNUICallback('SellCrypto', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-crypto:server:SellCrypto', function(CryptoData)
        cb(CryptoData)
    end, data)
end)

RegisterNUICallback('TransferCrypto', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-crypto:server:TransferCrypto', function(CryptoData)
        cb(CryptoData)
    end, data)
end)

RegisterNetEvent('qb-phone:client:RemoveBankMoney', function(amount)
    if PhoneData.isOpen then
        SendNUIMessage({
            action = "PhoneNotification",
            PhoneNotify = {
                title = "Bank",
                text = "$"..amount..",- removed from your account!", 
                icon = "fas fa-university", 
                color = "#ff002f",
                timeout = 3500,
            },
        })
    else
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "Bank",
                content = "$"..amount..",- removed from your account!", 
                icon = "fas fa-university",
                timeout = 3500, 
                color = "#ff002f",
            },
        })
    end
end)

RegisterNetEvent('qb-phone:client:AddTransaction', function(SenderData, TransactionData, Message, Title, Type)
    local Data = {
        TransactionTitle = Title,
        TransactionMessage = Message,
        TransactionType = Type,
    }
    
    table.insert(PhoneData.CryptoTransactions, Data)

    if PhoneData.isOpen then
        SendNUIMessage({
            action = "PhoneNotification",
            PhoneNotify = {
                title = "Crypto",
                text = Message, 
                icon = "fas fa-chart-pie",
                color = "#04b543",
                timeout = 1500,
            },
        })
    else
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "Crypto",
                content = Message, 
                icon = "fas fa-chart-pie",
                timeout = 3500, 
                color = "#04b543",
            },
        })
    end

    SendNUIMessage({
        action = "UpdateTransactions",
        CryptoTransactions = PhoneData.CryptoTransactions
    })

    TriggerServerEvent('qb-phone:server:AddTransaction', Data)
end)

RegisterNUICallback('GetCryptoTransactions', function(_, cb)
    local Data = {
        CryptoTransactions = PhoneData.CryptoTransactions
    }
    cb(Data)
end)

RegisterNUICallback('GetAvailableRaces', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-lapraces:server:GetRaces', function(Races)
        cb(Races)
    end)
end)

RegisterNUICallback('JoinRace', function(data, cb)
    TriggerServerEvent('qb-lapraces:server:JoinRace', data.RaceData)
    cb('ok')
end)

RegisterNUICallback('LeaveRace', function(data, cb)
    TriggerServerEvent('qb-lapraces:server:LeaveRace', data.RaceData)
    cb('ok')
end)

RegisterNUICallback('StartRace', function(data, cb)
    TriggerServerEvent('qb-lapraces:server:StartRace', data.RaceData.RaceId)
    cb('ok')
end)

RegisterNetEvent('qb-phone:client:UpdateLapraces', function()
    SendNUIMessage({
        action = "UpdateRacingApp",
    })
end)

RegisterNUICallback('GetRaces', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-lapraces:server:GetListedRaces', function(Races)
        cb(Races)
    end)
end)

RegisterNUICallback('GetTrackData', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-lapraces:server:GetTrackData', function(TrackData, CreatorData)
        TrackData.CreatorData = CreatorData
        cb(TrackData)
    end, data.RaceId)
end)

RegisterNUICallback('SetupRace', function(data, cb)
    TriggerServerEvent('qb-lapraces:server:SetupRace', data.RaceId, tonumber(data.AmountOfLaps))
    cb('ok')
end)

RegisterNUICallback('HasCreatedRace', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-lapraces:server:HasCreatedRace', function(HasCreated)
        cb(HasCreated)
    end)
end)

RegisterNUICallback('IsInRace', function(_, cb)
    local InRace = exports['qb-lapraces']:IsInRace()
    cb(InRace)
end)

RegisterNUICallback('IsAuthorizedToCreateRaces', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-lapraces:server:IsAuthorizedToCreateRaces', function(IsAuthorized, NameAvailable)
        local data = {
            IsAuthorized = IsAuthorized,
            IsBusy = exports['qb-lapraces']:IsInEditor(),
            IsNameAvailable = NameAvailable,
        }
        cb(data)
    end, data.TrackName)
end)

RegisterNUICallback('StartTrackEditor', function(data, cb)
    TriggerServerEvent('qb-lapraces:server:CreateLapRace', data.TrackName)
    cb('ok')
end)

RegisterNUICallback('GetRacingLeaderboards', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-lapraces:server:GetRacingLeaderboards', function(Races)
        cb(Races)
    end)
end)

RegisterNUICallback('RaceDistanceCheck', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-lapraces:server:GetRacingData', function(RaceData)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local checkpointcoords = RaceData.Checkpoints[1].coords
        local dist = #(coords - vector3(checkpointcoords.x, checkpointcoords.y, checkpointcoords.z))
        if dist <= 115.0 then
            if data.Joined then
                TriggerEvent('qb-lapraces:client:WaitingDistanceCheck')
            end
            cb(true)
        else
            QBCore.Functions.Notify('You\'re too far from the race. Your navigation is set to the starting line.', 'error', 5000)
            SetNewWaypoint(checkpointcoords.x, checkpointcoords.y)
            cb(false)
        end
    end, data.RaceId)
end)

RegisterNUICallback('IsBusyCheck', function(data, cb)
    if data.check == "editor" then
        cb(exports['qb-lapraces']:IsInEditor())
    else
        cb(exports['qb-lapraces']:IsInRace())
    end
end)

RegisterNUICallback('CanRaceSetup', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-lapraces:server:CanRaceSetup', function(CanSetup)
        cb(CanSetup)
    end)
end)

RegisterNUICallback('GetPlayerHouses', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-phone:server:GetPlayerHouses', function(Houses)
        cb(Houses)
    end)
end)

RegisterNUICallback('GetPlayerKeys', function(_, cb)
    -- QBCore.Functions.TriggerCallback('qb-phone:server:GetHouseKeys', function(Keys)
    --     cb(Keys)
    -- end)
    lib.callback('qb-phone:server:GetHouseKeys', false, function(Keys)
        cb(Keys)
    end)
end)

RegisterNUICallback('SetHouseLocation', function(data, cb)
    SetNewWaypoint(data.HouseData.HouseData.coords.enter.x, data.HouseData.HouseData.coords.enter.y)
    QBCore.Functions.Notify("Your GPS is set to " .. data.HouseData.HouseData.adress .. "!", "success")
    cb('ok')
end)

RegisterNUICallback('RemoveKeyholder', function(data, cb)
    TriggerServerEvent('qb-houses:server:removeHouseKey', data.HouseData.name, {
        citizenid = data.HolderData.citizenid,
        firstname = data.HolderData.charinfo.firstname,
        lastname = data.HolderData.charinfo.lastname,
    })
    cb('ok')
end)

RegisterNUICallback('TransferCid', function(data, cb)
    local TransferedCid = data.newBsn

    QBCore.Functions.TriggerCallback('qb-phone:server:TransferCid', function(CanTransfer)
        cb(CanTransfer)
    end, TransferedCid, data.HouseData)
end)

RegisterNUICallback('FetchPlayerHouses', function(data, cb)
    QBCore.Functions.TriggerCallback('qb-phone:server:MeosGetPlayerHouses', function(result)
        cb(result)
    end, data.input)
end)

RegisterNUICallback('SetGPSLocation', function(data, cb)
    local ped = PlayerPedId()

    SetNewWaypoint(data.coords.x, data.coords.y)
    QBCore.Functions.Notify('GPS is set!', 'success')
    cb('ok')
end)

RegisterNUICallback('SetApartmentLocation', function(data, cb)
    local ApartmentData = data.data.appartmentdata
    local TypeData = Apartments.Locations[ApartmentData.type]

    SetNewWaypoint(TypeData.coords.enter.x, TypeData.coords.enter.y)
    QBCore.Functions.Notify('GPS is set!', 'success')
    cb('ok')
end)

RegisterNUICallback('GetCurrentLawyers', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-phone:server:GetCurrentLawyers', function(lawyers)
        cb(lawyers)
    end)
end)

RegisterNUICallback('GetCurrentPlants', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-phone:server:GetCurrentPlants', function(plants)
        cb(plants)
    end)
end)

RegisterNUICallback('GetCurrentDeliveries', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-deliveryjob:server:GetDeliveries', function(deliveries)
        cb(deliveries)
    end)
end)

RegisterNetEvent('qb-phone:client:UpdateDeliveries')
AddEventHandler('qb-phone:client:UpdateDeliveries', function()
    Wait(300)
    SendNUIMessage({
        action = "UpdateDeliveries",
    })
end)

RegisterNUICallback('GetCurrentLoans', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-phone:server:GetCurrentLoans', function(loans)
        cb(loans)
    end)
end)

RegisterNUICallback('GetCurrentBoosts', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-carboost:server:GetCarboosts', function(carboosts)
        cb(carboosts)
    end)
end)

RegisterNUICallback('GetSilkRoad', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-blackmarket:server:GetList', function(itemTable)
        cb(itemTable)
    end)
end)

RegisterNetEvent('qb-phone:client:UpdateCarBoosts', function(carboosts)
    Wait(300)
    SendNUIMessage({
        action = "UpdateCarboosts",
        carBoosts = carboosts,
    })
end)

RegisterNUICallback('StartBoost', function(data, cb)
    TriggerEvent('qb-carboost:client:getMission', data)
    cb('ok')
end)

RegisterNUICallback('SilkRoadBuyItem', function(data, cb)
    local item = data.item
    local label = data.label

    QBCore.Functions.TriggerCallback('qb-blackmarket:server:BuyStuff', function(response)
        if response then
            SendNUIMessage({
                action = "PhoneNotification",
                PhoneNotify = {
                    title = "QMarket",
                    text = label .. " purchased",
                    icon = "fas fa-atom",
                    color = "#338FFF",
                    timeout = 1500,
                },
            })
        else
            SendNUIMessage({
                action = "PhoneNotification",
                PhoneNotify = {
                    title = "QMarket",
                    text = "Not enough Qbits..",
                    icon = "fas fa-atom",
                    color = "#338FFF",
                    timeout = 1500,
                },
            })
        end
        cb('ok')
    end, item)
end)

RegisterNUICallback('DeclineCancelBoost', function(data, cb)
    TriggerEvent('qb-carboost:client:declineCancelMission', data)
    cb('ok')
end)

RegisterNUICallback('SetupStoreApps', function(_, cb)
    local PlayerData = QBCore.Functions.GetPlayerData()
    local data = {
        StoreApps = Config.StoreApps,
        PhoneData = PlayerData.metadata["phonedata"]
    }
    cb(data)
end)

RegisterNUICallback('InstallApplication', function(data, cb)
    local ApplicationData = Config.StoreApps[data.app]
    local NewSlot = GetFirstAvailableSlot()

    if not CanDownloadApps then
        return
    end
    
    if NewSlot <= Config.MaxSlots then
        TriggerServerEvent('qb-phone:server:InstallApplication', {
            app = data.app,
        })
        cb({
            app = data.app,
            data = ApplicationData
        })
    else
        cb(false)
    end
end)

RegisterNUICallback('RemoveApplication', function(data, cb)
    TriggerServerEvent('qb-phone:server:RemoveInstallation', data.app)
    cb('ok')
end)

RegisterNetEvent('qb-phone:RefreshPhone', function()
    LoadPhone()
    SetTimeout(500, function()
        SendNUIMessage({
            action = "RefreshAlerts",
            AppData = Config.PhoneApplications,
        })
    end)
end)

RegisterNUICallback('GetTruckerData', function(_, cb)
    local TruckerMeta = QBCore.Functions.GetPlayerData().metadata["jobrep"]["trucker"]
    local TierData = exports['qb-truckingjob']:GetTier(TruckerMeta)
    cb(TierData)
end)

RegisterNetEvent('qb-phone:client:CarboostNotification', function(CarboostMessage)
    Config.PhoneApplications["carboosts"].Alerts = Config.PhoneApplications["carboosts"].Alerts + 1

    if PhoneData.isOpen then
        SendNUIMessage({
            action = "PhoneNotification",
            PhoneNotify = {
                title = "Car Boost",
                text = CarboostMessage.message,
                icon = "fas fa-car-side",
                color = "#290628",
                timeout = 1500,
            },
        })
    else
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "Car Boost", 
                content = CarboostMessage.message, 
                icon = "fas fa-car-side",
                timeout = 3500, 
                color = "#290628",
            },
        })
    end
end)

RegisterNetEvent('qb-phone:client:DeliveriesNotification', function(Deliveries)
    Config.PhoneApplications["deliveries"].Alerts = Config.PhoneApplications["deliveries"].Alerts + 1

    if PhoneData.isOpen then
        SendNUIMessage({
            action = "PhoneNotification",
            PhoneNotify = {
                title = "QBer Eats",
                text = Deliveries.message,
                icon = "fas fa-car-side",
                color = "#5EB1BF",
                timeout = 1500,
            },
        })
    else
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "QBer Eats", 
                content = Deliveries.message, 
                icon = "fas fa-car-side",
                timeout = 3500, 
                color = "#5EB1BF",
            },
        })
    end
end)

RegisterNetEvent('qb-phone:client:AuctionNotification', function(AuctionMessage)
    Config.PhoneApplications["auctions"].Alerts = Config.PhoneApplications["auctions"].Alerts + 1

    if PhoneData.isOpen then
        SendNUIMessage({
            action = "PhoneNotification",
            PhoneNotify = {
                title = "Auctions",
                text = AuctionMessage.message,
                icon = "fa-regular fa-gem",
                color = "#DE6B48",
                timeout = 1500,
            },
        })
    else
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "Auctions", 
                content = AuctionMessage.message, 
                icon = "fa-regular fa-gem",
                timeout = 3500, 
                color = "#DE6B48",
            },
        })
    end
end)

exports("SetVPN", SetVPN)

RegisterNetEvent('qb-phone:client:AtPayPhone', function()
    SendNUIMessage({
        action = "OpenPayPhone"
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('closePayPhone', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('CallPayPhone', function(data, cb)
    TriggerServerEvent('qb-phone:server:PayPayPhone', tostring(data.number))
    cb('ok')
end)

RegisterNetEvent('qb-phone:client:CallPayPhoneYes', function(num)
    for k, v in pairs(Config.PhoneCells) do
        local closestObj = GetClosestObjectOfType(plyCoords.x, plyCoords.y, plyCoords.z, 3.0, v, false, 0, 0)
        local objCoords = GetEntityCoords(closestObj)
        if closestObj ~= 0 then
            local dist = GetDistanceBetweenCoords(plyCoords.x, plyCoords.y, plyCoords.z, objCoords.x, objCoords.y, objCoords.z, true)
            if dist <= 10 then
                if not IsPedInAnyVehicle(ply) then
                    inPayPhoneRange = true
                    local objHealth = GetObjectFragmentDamageHealth(closestObj, true)
                    if objHealth > 0.95 then
                        if dist <= 1.5 then
                            CallContact(CallData, AnonymousCall)
                        end
                    end
                end
            end
        end
    end

    if inPayPhoneRange then
        local RepeatCount = 0
        PhoneData.CallData.CallType = "outgoing"
        PhoneData.CallData.InCall = true
        PhoneData.CallData.TargetData = CallData
        PhoneData.CallData.AnsweredCall = false
        PhoneData.CallData.CallId = GenerateCallId(PhoneData.PlayerData.charinfo.phone, CallData.number)

        TriggerServerEvent('qb-phone:server:CallContact', PhoneData.CallData.TargetData, PhoneData.CallData.CallId, AnonymousCall)
        TriggerServerEvent('qb-phone:server:SetCallState', true)
        
        for i = 1, Config.CallRepeats + 1, 1 do
            if not PhoneData.CallData.AnsweredCall then
                if RepeatCount + 1 ~= Config.CallRepeats + 1 then
                    if PhoneData.CallData.InCall then
                        RepeatCount = RepeatCount + 1
                        TriggerServerEvent("InteractSound_SV:PlayOnSource", "demo", 0.1)
                    else
                        break
                    end
                    Wait(Config.RepeatTimeout)
                else
                    CancelCall()
                    break
                end
            else
                break
            end
        end
        TriggerServerEvent('qb-phone:server:CallContact', callData, "06"..math.random(11111111, 99999999), true)
    else
        QBCore.Functions.Notify('You are not near a pay phone..', 'error', 2500)
    end
end)

RegisterNUICallback('DoPing', function(data, cb)
    local playerNumber = tonumber(data.PlayerNumber)
    TriggerEvent('qb-pings:client:DoPing', playerNumber)
    cb('ok')
end)

RegisterNUICallback('GetTaxiPlayers', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-phone:server:GetTaxiPlayers', function(taxiPlayers)
        cb(taxiPlayers)
    end)
end)

RegisterNUICallback('CallNPCTaxi', function(_, cb)
    TriggerEvent('rpbase-interact:calltaxi')
    cb('ok')
end)

RegisterNUICallback('ToggleDeliveries', function(_, cb)
    TriggerServerEvent('qb-deliveryjob:server:toggleDeliveries')
    cb('ok')
end)

RegisterNetEvent('qb-phone:client:NewTaxiNotify', function(message)
    if PhoneData.isOpen then
        SendNUIMessage({
            action = "PhoneNotification",
            PhoneNotify = {
                title = "Taxi",
                text = message,
                icon = "fa-solid fa-taxi",
                color = "#FFC857",
                timeout = 1500,
            },
        })
    else
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "Taxi", 
                content = message,
                icon = "fa-solid fa-taxi", 
                timeout = 3500, 
                color = "#FFC857",
            },
        })
    end
end)

RegisterNetEvent("groups:UpdateGroupData", function(data)
    SendNUIMessage({ 
        action = "UpdateGroups",
        type = "update",
        data = data,
    })
end)

RegisterNetEvent("groups:JoinGroup", function(id)
    SendNUIMessage({ 
        action = "JoinGroup",
        groupID = id,
    })
end)

RegisterNetEvent("groups:groupUpdate", function(id)
    SendNUIMessage({ 
        action = "UpdateGroups",
        type = "groupDestroy",
    })
end)

local DarkLogEntries = {}

RegisterNetEvent('qb-phone:client:AddDarkLogEntry', function(data)
    Wait(300)
    DarkLogEntries[#DarkLogEntries+1] = data
    SendNUIMessage({
        action = "AddDarkLogEntry",
        data = DarkLogEntries,
    })
end)

RegisterNUICallback('GetDarkLog', function(_, cb)
    cb(DarkLogEntries)
end) 

RegisterNUICallback('AcceptDarkLogButton', function(data, cb)
    local id = tonumber(data.id) + 1
    if data.buttonData == 'vector3' then
        data.buttonData = vector3(data.buttonData)
    end
    TriggerEvent(data.buttonEvent, data.buttonData)
    DarkLogEntries[id]['button'] = {}
    cb(DarkLogEntries)
end)

RegisterNUICallback('DeleteDarkLogButton', function(data, cb)
    local id = tonumber(data.id) + 1
    local newDarkLogEntries = {}
    for k, v in pairs(DarkLogEntries) do
        if k ~= id then
            table.insert(newDarkLogEntries, v)
        end
    end
    DarkLogEntries = newDarkLogEntries
    cb(DarkLogEntries)
end)

RegisterNetEvent('qb-phone:client:DarklogNotification', function(DarkLog)
    Config.PhoneApplications["darklogs"].Alerts = Config.PhoneApplications["darklogs"].Alerts + 1

    if PhoneData.isOpen then
        SendNUIMessage({
            action = "PhoneNotification",
            PhoneNotify = {
                title = "DarkLogs",
                text = DarkLog.message,
                icon = "fa-solid fa-book-skull",
                color = "#191716",
                timeout = 1500,
            },
        })
    else
        SendNUIMessage({
            action = "Notification",
            NotifyData = {
                title = "DarkLogs", 
                content = DarkLog.message, 
                icon = "fa-solid fa-book-skull",
                timeout = 3500, 
                color = "#191716",
            },
        })
    end
end)

RegisterNUICallback('GetAvailableRaces', function(_, cb)
    QBCore.Functions.TriggerCallback('qb-lapraces:server:GetRaces', function(Races)
        cb(Races)
    end)
end)

RegisterNUICallback('GetPrinters', function(_, cb)
    lib.callback('qb-smallresources:server:GetListedPrinters', source, function(Printers)
        cb(Printers)
    end)
end)

RegisterNUICallback('PrintDocument', function(data, cb)
    lib.callback('qb-smallresources:server:PrintDocument', source, function(Print)
        cb(Print)
    end, data)
end)

RegisterNetEvent("inventory:client:CheckPickupItem", function(itemName)
    if playerHasVPN then return end
    if itemName ~= 'vpn' then return end
    if LocalPlayer.state.hasVPN then return end
    local HasItem = QBCore.Functions.HasItem('vpn')
    if HasItem then
        SetVPN(true)
        LocalPlayer.state:set('hasVPN', true, false)
    end
end)

RegisterNetEvent("inventory:client:CheckDroppedItem", function(item)
    if item ~= 'vpn' then return end
    local HasItem = QBCore.Functions.HasItem('vpn')
    if not HasItem then
        SetVPN(false)
        LocalPlayer.state:set('hasVPN', false, false)
    end
end)