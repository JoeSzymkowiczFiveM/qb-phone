local QBCore = exports['qb-core']:GetCoreObject()

-- Code
-- MongoDB.ready(function()
--     local result = MongoDB.Sync.delete({collection = 'phone_messages',query = {}})
-- end)

local QBPhone = {}
local Tweets = {}
local AppAlerts = {}
local MentionedTweets = {}
local Hashtags = {}
local Calls = {}
local Adverts = {}
local DarkWeb = {}
local GeneratedPlates = {}

local function SpecialInvoiceHandler(source, invoiceCode, amount, invoiceId)
    if invoiceCode == 'STR' then
        TriggerEvent("qb-storage:server:PayStorageUnitInvoice", source, amount, invoiceId)
    elseif invoiceCode == 'LON' then
        TriggerEvent("qb-loans:server:PayLoanInvoice", source, amount, invoiceId)
    end
end

RegisterServerEvent('qb-phone:server:AddDarkWeb', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    table.insert(DarkWeb, {
        message = data.msg,
        name = "@" .. data.name,
        date = data.date,
        number = Player.PlayerData.charinfo.phone,
    })

    TriggerLatentClientEvent('qb-phone:client:UpdateDarkWeb', -1, 10000, DarkWeb, "@" .. data.name)
end)

RegisterServerEvent('qb-phone:server:AddNote', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    --MySQL.Sync.insert('INSERT INTO phone_notes (citizenid, title, body) VALUES (?, ?, ?)', {citizenid, data.title, data.body})
    local result = MongoDB.Sync.insertOne({collection = 'phone_notes', document = {citizenid = citizenid, title = data.title, body = data.body}})
    --local result = MySQL.query.await('SELECT * FROM phone_notes WHERE citizenid = ?', {citizenid})
    if result.insertedCount then
    TriggerClientEvent('qb-phone:client:AddNote', src, { id = result.insertedIds[1], title = data.title, body = data.body})
    end
end)

RegisterServerEvent('qb-phone:server:SendPlayerMail', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local Recipient = QBCore.Functions.GetPlayerByCitizenId(data.recipient)

    if Recipient ~= nil then
        TriggerEvent('qb-phone:server:sendNewMailToOffline', Recipient.PlayerData.citizenid, {
            sender = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            subject = data.subject,
            message = data.body
        })
    end
end)

RegisterServerEvent('qb-phone:server:EditNote', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local Notes = {}

    --MySQL.Sync.execute('UPDATE phone_notes SET title = ?, body = ? WHERE id = ? AND citizenid = ?', {data.title, data.body, data.id, citizenid})
    MongoDB.Sync.updateOne({collection = 'phone_notes', query = { _id = data.id, citizenid = citizenid }, update = { ["$set"] = { title = data.title, body = data.body } } })
    --local result = MySQL.query.await('SELECT * FROM phone_notes WHERE citizenid = ?', {citizenid})
    -- local result = MongoDB.Sync.find({collection = 'phone_notes', query = { citizenid = citizenid } })
    -- if result[1] ~= nil then
    --     for k, v in pairs(result) do
    --         Notes[#Notes+1] = {
    --             id = v._id,
    --             title = v.title,
    --             body = v.body,
    --         }
    --     end
    -- end
    --TriggerClientEvent('qb-phone:client:UpdateNotes', src, Notes)
    --TriggerClientEvent('qb-phone:client:EditNote', src, { id = data.id, title = v.title, body = v.body, })
end)

RegisterServerEvent('qb-phone:server:DeleteNote', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local Notes = {}

    --MySQL.query.await('DELETE FROM phone_notes WHERE id = ? AND citizenid = ?', {data.id, citizenid})
    MongoDB.Sync.deleteOne({collection = 'phone_notes', query = {citizenid = citizenid, _id = data.id}})
    --local result = MySQL.query.await('SELECT * FROM phone_notes WHERE citizenid = ?', {citizenid})
    local result = MongoDB.Sync.find({collection = 'phone_notes', query = { citizenid = citizenid } })
    if result[1] ~= nil then
        for i=1, #result do
            local v = result[i]
            Notes[#Notes+1] = {
                id = v._id,
                title = v.title,
                body = v.body,
            }
        end
    end
    TriggerClientEvent('qb-phone:client:UpdateNotes', src, Notes)
end)

RegisterServerEvent('qb-phone:server:AddAdvert', function(msg)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local CitizenId = Player.PlayerData.citizenid

    if Adverts[CitizenId] ~= nil then
        Adverts[CitizenId].message = msg
        Adverts[CitizenId].name = "@"..Player.PlayerData.charinfo.firstname..""..Player.PlayerData.charinfo.lastname
        Adverts[CitizenId].number = Player.PlayerData.charinfo.phone
    else
        Adverts[CitizenId] = {
            message = msg,
            name = "@"..Player.PlayerData.charinfo.firstname..""..Player.PlayerData.charinfo.lastname,
            number = Player.PlayerData.charinfo.phone,
        }
    end

    TriggerLatentClientEvent('qb-phone:client:UpdateAdverts', -1, 10000, Adverts, "@"..Player.PlayerData.charinfo.firstname..""..Player.PlayerData.charinfo.lastname)
end)

local function GetOnlineStatus(number)
    local Target = QBCore.Functions.GetPlayerByPhone(number)
    local retval = false
    if Target ~= nil then retval = true end
    return retval
end

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

lib.callback.register('qb-phone:server:GetPhoneContacts', function(source)
	local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local PhoneData = {
        PlayerContacts = {}
    }
    local contacts = MongoDB.Sync.findOne({collection = 'players', query = {citizenid = citizenid }, options = { ["projection"] = {contacts = 1} } })
    if contacts[1].contacts ~= nil then
        for k, v in pairs(contacts[1]['contacts']) do
            v.status = GetOnlineStatus(v.number)
        end
        
        PhoneData.PlayerContacts = contacts[1]['contacts']
    end
    return PhoneData
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    local phoneNumber = Player.PlayerData.charinfo.phone
    TriggerClientEvent('qb-phone:client:ContactsUpdate', -1, phoneNumber, 'logout')
end)

lib.callback.register('qb-phone:server:GetPhoneData', function(source)
	local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    if Player ~= nil then
        local PhoneData = {
            Applications = {},
            PlayerContacts = {},
            MentionedTweets = {},
            Chats = {},
            Hashtags = {},
            Garage = {},
            Mails = {},
            Notes = {},
            Auctions = {},
            Adverts = {},
            DarkWeb = {},
            CryptoTransactions = {},
            Tweets = {},
            Gang = {},
            --InstalledApps = Player.PlayerData.metadata["phonedata"].installedapps,
        }

        PhoneData.Adverts = Adverts
        PhoneData.DarkWeb = DarkWeb

        --local contacts = MySQL.query.await('SELECT * FROM player_contacts WHERE citizenid = ?', {citizenid})
        local contacts = MongoDB.Sync.findOne({collection = 'players', query = {citizenid = citizenid }, options = { ["projection"] = {contacts = 1} } })
        if contacts[1].contacts ~= nil then
            for k, v in pairs(contacts[1]['contacts']) do
                v.status = GetOnlineStatus(v.number)
            end
            
            PhoneData.PlayerContacts = contacts[1]['contacts']
        end
            
        --[[ local garageresult = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ?',{Player.PlayerData.citizenid})
        if garageresult[1] ~= nil then
            for k, v in pairs(garageresult) do

                local vehicleModel = v.vehicle
                if (QBCore.Shared.Vehicles[vehicleModel] ~= nil) and (Garages[v.garage] ~= nil) then
                    v.garage = Garages[v.garage].label
                    v.vehicle = QBCore.Shared.Vehicles[vehicleModel].name
                    v.brand = QBCore.Shared.Vehicles[vehicleModel].brand
                end

            end
            PhoneData.Garage = garageresult
        end ]]
        
        --local messages = MySQL.query.await('SELECT * FROM phone_messages WHERE citizenid = ?', {Player.PlayerData.citizenid})
        local messages = MongoDB.Sync.find({collection = 'phone_messages', query = { citizenid = citizenid } })
        if messages ~= nil and next(messages) ~= nil then
            PhoneData.Chats = messages
        end

        if AppAlerts[citizenid] ~= nil then 
            PhoneData.Applications = AppAlerts[citizenid]
        end

        if MentionedTweets[citizenid] ~= nil then 
            PhoneData.MentionedTweets = MentionedTweets[citizenid]
        end

        if Hashtags ~= nil and next(Hashtags) ~= nil then
            PhoneData.Hashtags = Hashtags
        end

        if Tweets ~= nil and next(Tweets) ~= nil then
            PhoneData.Tweets = Tweets
        end

        --local notes = MySQL.query.await('SELECT * FROM `phone_notes` WHERE `citizenid` = ?', {citizenid})
        local notes = MongoDB.Sync.find({collection = 'phone_notes', query = { citizenid = citizenid } })
        local Notes = {}
        if notes[1] ~= nil then
            for k, v in pairs(notes) do
                Notes[#Notes+1] = {
                    id = v._id,
                    title = v.title,
                    body = v.body,
                }
            end
            PhoneData.Notes = Notes
        end

        --local mails = MySQL.query.await('SELECT * FROM `player_mails` WHERE `citizenid` = ?', {citizenid})
        local mails = MongoDB.Sync.find({collection = 'player_mails', query = { citizenid = citizenid } })
        if mails[1] ~= nil then
            for k, v in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = mails[k].button
                end
            end
            PhoneData.Mails = mails
        end

         --local mails = MySQL.query.await('SELECT * FROM `player_mails` WHERE `citizenid` = ?', {citizenid})
        local auctions = MongoDB.Sync.find({collection = 'auctions', query = { active = true } })
        if auctions[1] ~= nil then
            PhoneData.Auctions = auctions
        end

        --local gang = query players metadata for this 
        -- if gang[1] ~= nil then
        --     PhoneData.Gang = gang
        -- end

        local gang = MongoDB.Sync.find({collection = 'players', query = {["gang.name"] = Player.PlayerData.gang.name}, options = { ["projection"] = {citizenid = 1, gang = 1} } })
        if gang[1] ~= nil then
            PhoneData.Gang = gang
        end

        --local crypto = MySQL.query.await('SELECT * FROM `crypto_transactions` WHERE `citizenid` = ?', {citizenid})
        local crypto = MongoDB.Sync.find({collection = 'crypto_transactions', query = { citizenid = citizenid } })
        if crypto[1] ~= nil then
            for k, v in pairs(crypto) do
                PhoneData.CryptoTransactions[#PhoneData.CryptoTransactions+1] = {
                    TransactionTitle = v.title,
                    TransactionMessage = v.message,
                    TransactionType = v.type,
                }
            end
        end
        return PhoneData
    end
    return nil
end)

-- QBCore.Functions.CreateCallback('qb-phone:server:GetPhoneData', function(source, cb)
--     local src = source
--     local Player = QBCore.Functions.GetPlayer(src)
--     local citizenid = Player.PlayerData.citizenid

--     if Player ~= nil then
--         local PhoneData = {
--             Applications = {},
--             PlayerContacts = {},
--             MentionedTweets = {},
--             Chats = {},
--             Hashtags = {},
--             Garage = {},
--             Mails = {},
--             Notes = {},
--             Adverts = {},
--             DarkWeb = {},
--             CryptoTransactions = {},
--             Tweets = {},
--             InstalledApps = Player.PlayerData.metadata["phonedata"].InstalledApps,
--         }

--         PhoneData.Adverts = Adverts
--         PhoneData.DarkWeb = DarkWeb

--         local contacts = MySQL.query.await('SELECT * FROM player_contacts WHERE citizenid = ?', {citizenid})
--         if contacts[1] ~= nil then
--             for k, v in pairs(contacts) do
--                 v.status = GetOnlineStatus(v.number)
--             end

--             PhoneData.PlayerContacts = contacts
--         end

--         --[[ local garageresult = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ?',{Player.PlayerData.citizenid})
--         if garageresult[1] ~= nil then
--             for k, v in pairs(garageresult) do

--                 local vehicleModel = v.vehicle
--                 if (QBCore.Shared.Vehicles[vehicleModel] ~= nil) and (Garages[v.garage] ~= nil) then
--                     v.garage = Garages[v.garage].label
--                     v.vehicle = QBCore.Shared.Vehicles[vehicleModel].name
--                     v.brand = QBCore.Shared.Vehicles[vehicleModel].brand
--                 end

--             end
--             PhoneData.Garage = garageresult
--         end ]]

--         local messages = MySQL.query.await('SELECT * FROM phone_messages WHERE citizenid = ?',
--             {Player.PlayerData.citizenid})
--         if messages ~= nil and next(messages) ~= nil then
--             PhoneData.Chats = messages
--         end

--         if AppAlerts[citizenid] ~= nil then 
--             PhoneData.Applications = AppAlerts[citizenid]
--         end

--         if MentionedTweets[citizenid] ~= nil then 
--             PhoneData.MentionedTweets = MentionedTweets[citizenid]
--         end

--         if Hashtags ~= nil and next(Hashtags) ~= nil then
--             PhoneData.Hashtags = Hashtags
--         end

--         if Tweets ~= nil and next(Tweets) ~= nil then
--             PhoneData.Tweets = Tweets
--         end

--         local notes = MySQL.query.await('SELECT * FROM `phone_notes` WHERE `citizenid` = ?', {citizenid})
--         local Notes = {}
--         if notes[1] ~= nil then
--             for k, v in pairs(notes) do
--                 table.insert(Notes, {
--                     id = v.id,
--                     title = v.title,
--                     body = v.body,
--                 })
--             end
--             PhoneData.Notes = Notes
--         end

--         local mails = MySQL.query.await('SELECT * FROM `player_mails` WHERE `citizenid` = ?', {citizenid})
--         if mails[1] ~= nil then
--             for k, v in pairs(mails) do
--                 if mails[k].button ~= nil then
--                     mails[k].button = json.decode(mails[k].button)
--                 end
--             end
--             PhoneData.Mails = mails
--         end

--         local crypto = MySQL.query.await('SELECT * FROM `crypto_transactions` WHERE `citizenid` = ?', {citizenid})
--         if crypto[1] ~= nil then
--             for k, v in pairs(crypto) do
--                 table.insert(PhoneData.CryptoTransactions, {
--                     TransactionTitle = v.title,
--                     TransactionMessage = v.message,
--                     TransactionType = v.type,
--                 })
--             end
--         end

--         cb(PhoneData)
--     end
-- end)

QBCore.Functions.CreateCallback('qb-phone:server:GetCallState', function(source, cb, ContactData)
    local Target = QBCore.Functions.GetPlayerByPhone(ContactData.number)

    if Target ~= nil then
        if Calls[Target.PlayerData.citizenid] ~= nil then
            if Calls[Target.PlayerData.citizenid].inCall then
                cb(false, true)
            else
                cb(true, true)
            end
        else
            cb(true, true)
        end
    else
        cb(false, false)
    end
end)

RegisterServerEvent('qb-phone:server:SetCallState', function(bool)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)

    if Calls[Ply.PlayerData.citizenid] ~= nil then
        Calls[Ply.PlayerData.citizenid].inCall = bool
    else
        Calls[Ply.PlayerData.citizenid] = {}
        Calls[Ply.PlayerData.citizenid].inCall = bool
    end
end)

RegisterServerEvent('qb-phone:server:RemoveMail', function(MailId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    --MySQL.query.await('DELETE FROM player_mails WHERE mailid = ? AND citizenid = ?', {MailId, Player.PlayerData.citizenid})
    MongoDB.Sync.deleteOne({collection = 'player_mails', query = {citizenid = Player.PlayerData.citizenid, mailid = MailId}})
    SetTimeout(100, function()
        --local mails = MySQL.query.await('SELECT * FROM player_mails WHERE citizenid = ? ORDER BY date ASC', {Player.PlayerData.citizenid})
        local mails = MongoDB.Sync.find({collection = 'player_mails', query = { citizenid = Player.PlayerData.citizenid }, sort = { datetime = -1 } })
        if mails[1] ~= nil then
            for k, v in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = mails[k].button
                end
            end
        end

        TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
    end)
end)

function GenerateMailId()
    return math.random(111111, 999999)
end

RegisterServerEvent('qb-phone:server:sendNewMail', function(mailData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if mailData.button == nil then
        --read is a reserved word in mysql, and must be quoted
        --MySQL.Async.insert('INSERT INTO player_mails (citizenid, sender, subject, message, mailid, `read`) VALUES (?, ?, ?, ?, ?, ?) ', {Player.PlayerData.citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), '0'})
        MongoDB.Sync.insertOne({collection = 'player_mails', document = {citizenid = Player.PlayerData.citizenid, sender = mailData.sender, subject = mailData.subject, message = mailData.message, mailid = GenerateMailId(), read = 0, date = os.date(), datetime = os.time()*1000}})
    else
        --MySQL.Async.insert('INSERT INTO player_mails (citizenid, sender, subject, message, mailid, `read`, button) VALUES (?, ?, ?, ?, ?, ?, ?) ', {Player.PlayerData.citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button)})
        MongoDB.Sync.insertOne({collection = 'player_mails', document = {citizenid = Player.PlayerData.citizenid, sender = mailData.sender, subject = mailData.subject, message = mailData.message, mailid = GenerateMailId(), read = 0, button = mailData.button, date = os.date(), datetime = os.time()*1000}})
    end
    TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
    --local mails = MySQL.query.await('SELECT * FROM player_mails WHERE citizenid = ? ORDER BY date ASC', {Player.PlayerData.citizenid})
    local mails = MongoDB.Sync.find({collection = 'player_mails', query = { citizenid = Player.PlayerData.citizenid }, sort = { datetime = -1 } })
    if mails[1] ~= nil then
        for k, v in pairs(mails) do
            if mails[k].button ~= nil then
                mails[k].button = mails[k].button
            end
        end
    end

    TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
end)

RegisterServerEvent('qb-phone:server:sendNewMailToOffline', function(citizenid, mailData)
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)

    if Player ~= nil then
        local src = Player.PlayerData.source

        if mailData.button == nil then
            --MySQL.Async.insert('INSERT INTO player_mails (citizenid, sender, subject, message, mailid, `read`) VALUES (?, ?, ?, ?, ?, ?) ', {Player.PlayerData.citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), '0'})
            MongoDB.Async.insertOne({collection = 'player_mails', document = {citizenid = Player.PlayerData.citizenid, sender = mailData.sender, subject = mailData.subject, message = mailData.message, mailid = GenerateMailId(), read = 0, date = os.date(), datetime = os.time()*1000}})
            TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
        else
            --MySQL.Async.insert('INSERT INTO player_mails (citizenid, sender, subject, message, mailid, `read`, button) VALUES (?, ?, ?, ?, ?, ?, ?) ', {Player.PlayerData.citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), '0', json.encode(mailData.button)})
            MongoDB.Async.insertOne({collection = 'player_mails', document = {citizenid = Player.PlayerData.citizenid, sender = mailData.sender, subject = mailData.subject, message = mailData.message, mailid = GenerateMailId(), read = 0, button = mailData.button, date = os.date(), datetime = os.time()*1000}})
            TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
        end

        SetTimeout(200, function()
            --local mails = MySQL.query.await('SELECT * FROM player_mails WHERE citizenid = ? ORDER BY date ASC', {Player.PlayerData.citizenid})
            local mails = MongoDB.Sync.find({collection = 'player_mails', query = { citizenid = Player.PlayerData.citizenid }, sort = { datetime = -1 } })
            if mails[1] ~= nil then
                for k, v in pairs(mails) do
                    if mails[k].button ~= nil then
                        mails[k].button = mails[k].button
                    end
                end
            end
    
            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    else
        if mailData.button == nil then
            --MySQL.Async.insert('INSERT INTO player_mails (citizenid, sender, subject, message, mailid, `read`) VALUES (?, ?, ?, ?, ?, ?) ', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), '0'})
            MongoDB.Async.insertOne({collection = 'player_mails', document = {citizenid = citizenid, sender = mailData.sender, subject = mailData.subject, message = mailData.message, mailid = GenerateMailId(), read = 0, date = os.date(), datetime = os.time()*1000}})
        else
            --MySQL.Async.insert('INSERT INTO player_mails (citizenid, sender, subject, message, mailid, `read`, button) VALUES (?, ?, ?, ?, ?, ?, ?) ', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), '0', json.encode(mailData.button)})
            MongoDB.Async.insertOne({collection = 'player_mails', document = {citizenid = citizenid, sender = mailData.sender, subject = mailData.subject, message = mailData.message, mailid = GenerateMailId(), read = 0, button = mailData.button, date = os.date(), datetime = os.time()*1000}})
        end
    end
end)

RegisterServerEvent('qb-phone:server:sendNewEventMail', function(citizenid, mailData)
    if mailData.button == nil then
        MongoDB.Async.insertOne({collection = 'player_mails', document = {citizenid = citizenid, sender = mailData.sender, subject = mailData.subject, message = mailData.message, mailid = GenerateMailId(), read = 0, date = os.date(), datetime = os.time()*1000}})
        --MySQL.Async.insert('INSERT INTO player_mails (citizenid, sender, subject, message, mailid, `read`) VALUES (?, ?, ?, ?, ?, ?) ', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), '0'})
    else
        MongoDB.Async.insertOne({collection = 'player_mails', document = {citizenid = citizenid, sender = mailData.sender, subject = mailData.subject, message = mailData.message, mailid = GenerateMailId(), read = 0, button = mailData.button, date = os.date(), datetime = os.time()*1000}})
        --MySQL.Async.insert('INSERT INTO player_mails (citizenid, sender, subject, message, mailid, `read`, button) VALUES (?, ?, ?, ?, ?, ?, ?) ', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), '0', json.encode(mailData.button)})
    end
    SetTimeout(200, function()
        --local result = MySQL.query.await('SELECT * FROM player_mails WHERE citizenid = ? ORDER BY date ASC', {Player.PlayerData.citizenid})
        local mails = MongoDB.Sync.find({collection = 'player_mails', query = {citizenid = Player.PlayerData.citizenid}, sort = { datetime = -1 } })
        if mails[1] ~= nil then
            for k, v in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = mails[k].button
                end
            end
        end

        TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
    end)
end)

RegisterServerEvent('qb-phone:server:ClearButtonData')
AddEventHandler('qb-phone:server:ClearButtonData', function(mailId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    --MySQL.Sync.execute('UPDATE player_mails SET button = ? WHERE mailid = ? AND citizenid = ?', {'', mailId, Player.PlayerData.citizenid})
    MongoDB.Sync.updateOne({collection = 'player_mails', query = {mailid = mailId, citizenid = Player.PlayerData.citizenid}, update = { ["$unset"] = { button = '' } }})
    SetTimeout(200, function()
        --local mails = MySQL.query.await('SELECT * FROM player_mails WHERE citizenid = ? ORDER BY date ASC', {Player.PlayerData.citizenid})
        local mails = MongoDB.Sync.find({collection = 'player_mails', query = { citizenid = Player.PlayerData.citizenid }, sort = { datetime = -1 } })
        if mails[1] ~= nil then
            for k, v in pairs(mails) do
                if mails[k].button ~= nil then
                    mails[k].button = mails[k].button
                end
            end
        end

        TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
    end)
end)

RegisterServerEvent('qb-phone:server:MentionedPlayer', function(firstName, lastName, TweetMessage)
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then
            if (Player.PlayerData.charinfo.firstname == firstName and Player.PlayerData.charinfo.lastname == lastName) then
                QBPhone.SetPhoneAlerts(Player.PlayerData.citizenid, "twitter")
                QBPhone.AddMentionedTweet(Player.PlayerData.citizenid, TweetMessage)
                TriggerClientEvent('qb-phone:client:GetMentioned', Player.PlayerData.source, TweetMessage,
                    AppAlerts[Player.PlayerData.citizenid]["twitter"])
            else
                --local query1 = '%' .. firstName .. '%'
                --local query2 = '%' .. lastName .. '%'
                --local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ? AND charinfo LIKE ?', {query1, query2})
                local result = MongoDB.Sync.findOne({collection = 'players', query = {["charinfo.firstname"] = firstName, ["charinfo.lastname"] = lastName }, options = { ["projection"] = {citizenid = 1} } })
                if result[1] ~= nil then
                    local MentionedTarget = result[1].citizenid
                    QBPhone.SetPhoneAlerts(MentionedTarget, "twitter")
                    QBPhone.AddMentionedTweet(MentionedTarget, TweetMessage)
                end
            end
        end
    end
end)

RegisterServerEvent('qb-phone:server:CallContact', function(TargetData, CallId, AnonymousCall, Payphone)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayerByPhone(TargetData.number)

    if Target ~= nil then
        TriggerClientEvent('qb-phone:client:GetCalled', Target.PlayerData.source, Ply.PlayerData.charinfo.phone, CallId, AnonymousCall, Payphone)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:PayInvoice', function(source, cb, society, amount, invoiceId)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local Invoices = {}

    if Ply.Functions.RemoveMoney('bank', amount, "paid-invoice") then
        TriggerClientEvent("qb-bossmenu:client:addAccountMoney", src, society, amount, 'paid invoice')

        local invoiceCode = string.sub(invoiceId, 5, 7)
        SpecialInvoiceHandler(source, invoiceCode, amount, invoiceId)

        --MySQL.Sync.fetchAll('DELETE FROM phone_invoices WHERE invoiceid = ?', {invoiceId})
        MongoDB.Sync.deleteOne({collection = 'phone_invoices', query = {invoiceid = invoiceId}})
        --local invoices = MySQL.Sync.fetchAll('SELECT * FROM phone_invoices WHERE citizenid = ?', {Ply.PlayerData.citizenid})
        local invoices = MongoDB.Sync.find({collection = 'phone_invoices', query = {citizenid = Ply.PlayerData.citizenid} })
        if invoices[1] ~= nil then
            Invoices = invoices
        end
        cb(true, Invoices)
    else
        TriggerClientEvent('QBCore:Notify', src, "Not enough money in your Bank account..", "error")
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:DeclineInvoice', function(source, cb, sender, amount, invoiceId)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local Trgt = QBCore.Functions.GetPlayerByCitizenId(sender)
    --local srcCitizenId = QBCore.Players[src].PlayerData.citizenid
    --local title = "DECLINED " .. Ply.PlayerData.charinfo.lastname
    local Invoices = {}

    local senderCitizenid = 0
    if sender ~= nil then
        senderCitizenid = sender
    end

    --MySQL.Sync.execute('UPDATE `phone_invoices` SET status = "Declined" WHERE `citizenid` = ? AND `invoiceid` = ?', {Ply.PlayerData.citizenid, invoiceId})
    MongoDB.Sync.updateOne({collection = 'phone_invoices', query = {citizenid = Ply.PlayerData.citizenid, invoiceid = invoiceId}, update = { ["$set"] = { status = "Declined" } }})
    --local invoices = MySQL.query.await('SELECT * FROM `phone_invoices` WHERE `citizenid` = ?', {Ply.PlayerData.citizenid})
    local invoices = MongoDB.Sync.find({collection = 'phone_invoices', query = {citizenid = Ply.PlayerData.citizenid} })
    if invoices[1] ~= nil then
        for k, v in pairs(invoices) do
            if v.sender ~= nil then
                local Target = QBCore.Functions.GetPlayerByCitizenId(v.sender)
                if Target ~= nil then
                    v.number = Target.PlayerData.charinfo.phone
                else
                    --local resureslt = MySQL.query.await('SELECT * FROM `players` WHERE `citizenid` = ', {v.sender})
                    local res = MongoDB.Sync.findOne({collection = 'players', query = {citizenid = v.sender}, options = { ["projection"] = {['charinfo.phone'] = 1} } })
                    if res[1] ~= nil then
                        --res[1].charinfo = json.decode(res[1].charinfo)
                        v.number = res[1].charinfo.phone
                    else
                        v.number = nil
                    end
                end
            else
                v.number = nil
            end
        end
        Invoices = invoices
    end
    cb(true, invoices)
end)

RegisterServerEvent('qb-phone:server:UpdateHashtags', function(Handle, messageData)
    if Hashtags[Handle] ~= nil and next(Hashtags[Handle]) ~= nil then
        table.insert(Hashtags[Handle].messages, messageData)
    else
        Hashtags[Handle] = {
            hashtag = Handle,
            messages = {}
        }
        table.insert(Hashtags[Handle].messages, messageData)
    end
    TriggerLatentClientEvent('qb-phone:client:UpdateHashtags', -1, 10000, Handle, messageData)
end)

QBPhone.AddMentionedTweet = function(citizenid, TweetData)
    if MentionedTweets[citizenid] == nil then MentionedTweets[citizenid] = {} end
    --table.insert(MentionedTweets[citizenid], TweetData)
    MentionedTweets[citizenid][#MentionedTweets[citizenid]+1] = TweetData
end

QBPhone.SetPhoneAlerts = function(citizenid, app, alerts)
    if citizenid ~= nil and app ~= nil then
        if AppAlerts[citizenid] == nil then
            AppAlerts[citizenid] = {}
            if AppAlerts[citizenid][app] == nil then
                if alerts == nil then
                    AppAlerts[citizenid][app] = 1
                else
                    AppAlerts[citizenid][app] = alerts
                end
            end
        else
            if AppAlerts[citizenid][app] == nil then
                if alerts == nil then
                    AppAlerts[citizenid][app] = 1
                else
                    AppAlerts[citizenid][app] = 0
                end
            else
                if alerts == nil then
                    AppAlerts[citizenid][app] = AppAlerts[citizenid][app] + 1
                else
                    AppAlerts[citizenid][app] = AppAlerts[citizenid][app] + 0
                end
            end
        end
    end
end

QBCore.Functions.CreateCallback('qb-phone:server:GetContactPictures', function(source, cb, Chats)
    for _, v in pairs(Chats) do
        
        --local Player = QBCore.Functions.GetPlayerByPhone(v.number)

        --local query = '%' .. v.number .. '%'
        --local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', {query})
        local result = MongoDB.Sync.findOne({collection = 'players', query = {["charinfo.phone"] = v.number }, options = { ["projection"] = {metadata = 1} } })
        if result[1] ~= nil then
            local MetaData = result[1].metadata

            if MetaData.phone.profilepicture ~= nil then
                v.picture = MetaData.phone.profilepicture
            else
                v.picture = "default"
            end
        end
    end
    SetTimeout(100, function()
        cb(Chats)
    end)
end)

QBCore.Functions.CreateCallback('qb-phone:server:DeleteWhatsappMessage', function(source, cb, ChatNumber)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    --MySQL.query('DELETE FROM phone_messages WHERE number = ? AND citizenid = ?', {ChatNumber, citizenid})
    MongoDB.Async.deleteOne({collection = 'phone_messages', query = {citizenid = citizenid, number = number}})
    cb()
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetContactPicture', function(source, cb, Chat)
    local Player = QBCore.Functions.GetPlayerByPhone(Chat.number)

    --local query = '%' .. Chat.number .. '%'
    --local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', {query})
    local result = MongoDB.Sync.findOne({collection = 'players', query = {["charinfo.phone"] = Chat.number }, options = { ["projection"] = {metadata = 1} } })
    local MetaData = result[1].metadata

    if MetaData.phone.profilepicture ~= nil then
        Chat.picture = MetaData.phone.profilepicture
    else
        Chat.picture = "default"
    end
    SetTimeout(100, function()
        cb(Chat)
    end)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetPicture', function(source, cb, number)
    local Player = QBCore.Functions.GetPlayerByPhone(number)
    local Picture = nil

    --local query = '%' .. number .. '%'
    --local result = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', {query})
    local result = MongoDB.Sync.findOne({collection = 'players', query = {["charinfo.phone"] = number }, options = { ["projection"] = {metadata = 1} } })
    if result[1] ~= nil then
        local MetaData = result[1].metadata

        if MetaData.phone.profilepicture ~= nil then
            Picture = MetaData.phone.profilepicture
        else
            Picture = "default"
        end
        cb(Picture)
    else
        cb(nil)
    end
end)

RegisterServerEvent('qb-phone:server:SetPhoneAlerts', function(app, alerts)
    local src = source
    local CitizenId = QBCore.Functions.GetPlayer(src).citizenid
    QBPhone.SetPhoneAlerts(CitizenId, app, alerts)
end)

RegisterServerEvent('qb-phone:server:UpdateTweets', function(NewTweets, TweetData)
    Tweets = NewTweets
    local TwtData = TweetData
    local src = source
    TriggerLatentClientEvent('qb-phone:client:UpdateTweets', -1, 10000, src, Tweets, TwtData)
end)

RegisterServerEvent('qb-phone:server:TransferMoney', function(iban, amount, securityToken)
    if not exports['salty_tokenizer']:secureServerEvent(GetCurrentResourceName(), source, securityToken) then
		return false
	end

    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)

    if Player then
        local src = Player.PlayerData.source

        if mailData.button == nil then
            --MySQL.insert('INSERT INTO player_mails (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', {Player.PlayerData.citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0})
            MongoDB.Async.insertOne({collection = 'player_mails', document = {citizenid = Player.PlayerData.citizenid, sender = mailData.sender, subject = mailData.subject, message = mailData.message, mailid = GenerateMailId(), read = 0, date = os.date(), datetime = os.time()*1000}})
            --MongoDB.Async.updateOne({collection = 'players', query = { citizenid = Player.PlayerData.citizenid }, update = { ["$pull"] = { ["contacts"] = { name = Name } } } })

            TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
        else
            --MySQL.insert('INSERT INTO player_mails (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', {Player.PlayerData.citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button)})
            MongoDB.Async.insertOne({collection = 'player_mails', document = {citizenid = Player.PlayerData.citizenid, sender = mailData.sender, subject = mailData.subject, message = mailData.message, mailid = GenerateMailId(), read = 0, button = mailData.button, date = os.date(), datetime = os.time()*1000}})
            TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
        end

        SetTimeout(200, function()
            --local mails = MySQL.query.await('SELECT * FROM player_mails WHERE citizenid = ? ORDER BY `date` ASC', {Player.PlayerData.citizenid})
            local mails = MongoDB.Sync.findOne({collection = 'player_mails', query = { citizenid = Player.PlayerData.citizenid}, sort = { datetime = -1 } }) --need to look into saving as date format, and sorting
            if mails[1] ~= nil then
                for k, v in pairs(mails) do
                    if mails[k].button ~= nil then
                        mails[k].button = mails[k].button
                    end
                end
            end

            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    else
        if mailData.button == nil then
            --MySQL.insert('INSERT INTO player_mails (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0})
            MongoDB.Async.insertOne({collection = 'player_mails', document = {citizenid = citizenid, sender = mailData.sender, subject = mailData.subject, message = mailData.message, mailid = GenerateMailId(), read = 0, date = os.date()}})
        else
            --ySQL.insert('INSERT INTO player_mails (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button)})
            MongoDB.Async.insertOne({collection = 'player_mails', document = {citizenid = citizenid, sender = mailData.sender, subject = mailData.subject, message = mailData.message, mailid = GenerateMailId(), read = 0, button = mailData.button, date = os.date()}})
        end
    end
end)

RegisterServerEvent('qb-phone:server:EditContact', function(newName, newNumber, newIban, oldName, oldNumber, oldIban)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    --MySQL.update('UPDATE player_contacts SET name = ?, number = ?, iban = ? WHERE citizenid = ? AND name = ? AND number = ?', {newName, newNumber, newIban, Player.PlayerData.citizenid, oldName, oldNumber})
    MongoDB.Async.updateOne({collection = 'players', query = {citizenid = Player.PlayerData.citizenid, ["contacts"] = { ["$elemMatch"] = { number = oldNumber, name = oldName } } }, update = { ["$set"] = { ["contacts.$.name"] = newName, ["contacts.$.number"] = newNumber, ["contacts.$.iban"] = newIban } }})
end)

RegisterServerEvent('qb-phone:server:RemoveContact', function(Name, Number)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    --MySQL.update('DELETE FROM player_contacts WHERE name = ? AND number = ? AND citizenid = ?', {Name, Number, Player.PlayerData.citizenid})
    MongoDB.Async.updateOne({collection = 'players', query = { citizenid = Player.PlayerData.citizenid }, update = { ["$pull"] = { ["contacts"] = { name = Name } } } })
end)

RegisterServerEvent('qb-phone:server:AddNewContact', function(name, number, iban)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    --MySQL.insert('INSERT INTO player_contacts (citizenid, name, number, iban) VALUES (?, ?, ?, ?)', {Player.PlayerData.citizenid, tostring(name), tostring(number), tostring(iban)})
    MongoDB.Async.updateOne({collection = 'players', query = { citizenid = Player.PlayerData.citizenid }, update = { ["$push"] = { ["contacts"] = {name = tostring(name), number = tostring(number), iban = tostring(iban)} } } })
end)

RegisterNetEvent('qb-phone:server:UpdateMessages', function(ChatMessages, ChatNumber, New)
    local src = source
    local SenderData = QBCore.Functions.GetPlayer(src)
    --local query = '%' .. ChatNumber .. '%'
    --local Player = MySQL.query.await('SELECT * FROM players WHERE charinfo LIKE ?', {query})
    --Message.time = os.time(os.date("!*t"))
    local Player = MongoDB.Sync.findOne({collection = 'players', query = {["charinfo.phone"] = ChatNumber }, options = { ["projection"] = {citizenid = 1} } })
    if Player[1] ~= nil then
        local TargetData = QBCore.Functions.GetPlayerByCitizenId(Player[1].citizenid)
        if TargetData ~= nil then
            --local Chat = MySQL.query.await('SELECT * FROM phone_messages WHERE citizenid = ? AND number = ?', {SenderData.PlayerData.citizenid, ChatNumber})
            local Chat = MongoDB.Sync.findOne({collection = 'phone_messages', query = {citizenid = SenderData.PlayerData.citizenid, number = ChatNumber } })
            if Chat[1] ~= nil then
                -- Update for target
                --MySQL.Async.execute('UPDATE phone_messages SET messages = ? WHERE citizenid = ? AND number = ?', {json.encode(ChatMessages), TargetData.PlayerData.citizenid, SenderData.PlayerData.charinfo.phone})
                MongoDB.Sync.updateOne({collection = 'phone_messages', query = {citizenid = TargetData.PlayerData.citizenid, number = SenderData.PlayerData.charinfo.phone}, update = { ["$set"] = { citizenid = TargetData.PlayerData.citizenid, number = SenderData.PlayerData.charinfo.phone, messages = ChatMessages} }, options = { upsert = true }})
                -- Update for sender
                --MySQL.Async.execute('UPDATE phone_messages SET messages = ? WHERE citizenid = ? AND number = ?', {json.encode(ChatMessages), SenderData.PlayerData.citizenid, TargetData.PlayerData.charinfo.phone})
                MongoDB.Sync.updateOne({collection = 'phone_messages', query = {citizenid = SenderData.PlayerData.citizenid, number = TargetData.PlayerData.charinfo.phone}, update = { ["$set"] = { citizenid = SenderData.PlayerData.citizenid, number = TargetData.PlayerData.charinfo.phone, messages = ChatMessages} }, options = { upsert = true }})
                -- Send notification & Update messages for target
                TriggerClientEvent('qb-phone:client:UpdateMessages', TargetData.PlayerData.source, ChatMessages, SenderData.PlayerData.charinfo.phone, false)
            else
                -- Insert for target
                --MySQL.Async.insert('INSERT INTO phone_messages (citizenid, number, messages) VALUES (?, ?, ?)', {TargetData.PlayerData.citizenid, SenderData.PlayerData.charinfo.phone, json.encode(ChatMessages)})
                MongoDB.Sync.updateOne({collection = 'phone_messages', query = {citizenid = TargetData.PlayerData.citizenid, number = SenderData.PlayerData.charinfo.phone}, update = { ["$set"] = { citizenid = TargetData.PlayerData.citizenid, number = SenderData.PlayerData.charinfo.phone, messages = ChatMessages} }, options = { upsert = true }})
                -- Insert for sender
                --MySQL.Async.insert('INSERT INTO phone_messages (citizenid, number, messages) VALUES (?, ?, ?)', {SenderData.PlayerData.citizenid, TargetData.PlayerData.charinfo.phone, json.encode(ChatMessages)})
                MongoDB.Sync.updateOne({collection = 'phone_messages', query = {citizenid = SenderData.PlayerData.citizenid, number = TargetData.PlayerData.charinfo.phone}, update = { ["$set"] = { citizenid = SenderData.PlayerData.citizenid, number = TargetData.PlayerData.charinfo.phone, messages = ChatMessages} }, options = { upsert = true }})
                -- Send notification & Update messages for target
                TriggerClientEvent('qb-phone:client:UpdateMessages', TargetData.PlayerData.source, ChatMessages, SenderData.PlayerData.charinfo.phone, true)
            end
        else
            --local Chat = MySQL.query.await('SELECT * FROM phone_messages WHERE citizenid = ? AND number = ?', {SenderData.PlayerData.citizenid, ChatNumber})
            local Chat = MongoDB.Sync.findOne({collection = 'phone_messages', query = {citizenid = SenderData.PlayerData.citizenid, number = ChatNumber } })
            if Chat[1] ~= nil then
                -- Update for target
                --MySQL.Async.execute('UPDATE phone_messages SET messages = ? WHERE citizenid = ? AND number = ?', {json.encode(ChatMessages), Player[1].citizenid, SenderData.PlayerData.charinfo.phone})
                MongoDB.Async.updateOne({collection = 'phone_messages', query = {citizenid = Player[1].citizenid, number = SenderData.PlayerData.charinfo.phone}, update = { ["$set"] = { citizenid = Player[1].citizenid, number = SenderData.PlayerData.charinfo.phone, messages = ChatMessages} }, options = { upsert = true }})
                -- Update for sender
                Player[1].charinfo = Player[1].charinfo
                --MySQL.Async.execute('UPDATE phone_messages SET messages = ? WHERE citizenid = ? AND number = ?', {json.encode(ChatMessages), SenderData.PlayerData.citizenid, Player[1].charinfo.phone})
                MongoDB.Async.updateOne({collection = 'phone_messages', query = {citizenid = SenderData.PlayerData.citizenid, number = Player[1].charinfo.phone}, update = { ["$set"] = { citizenid = TargetData.PlayerData.citizenid, number = Player[1].charinfo.phone, messages = ChatMessages} }, options = { upsert = true }})
            else
                -- Insert for target
                --MySQL.Async.insert('INSERT INTO phone_messages (citizenid, number, messages) VALUES (?, ?, ?)', {Player[1].citizenid, SenderData.PlayerData.charinfo.phone, json.encode(ChatMessages)})
                MongoDB.Async.updateOne({collection = 'phone_messages', query = {citizenid = Player[1].citizenid, number = SenderData.PlayerData.charinfo.phone}, update = { ["$set"] = { citizenid = Player[1].citizenid, number = SenderData.PlayerData.charinfo.phone, messages = ChatMessages} }, options = { upsert = true }})
                -- Insert for sender
                Player[1].charinfo = Player[1].charinfo
                --MySQL.Async.insert('INSERT INTO phone_messages (citizenid, number, messages) VALUES (?, ?, ?)', {SenderData.PlayerData.citizenid, Player[1].charinfo.phone, json.encode(ChatMessages)})
                MongoDB.Async.updateOne({collection = 'phone_messages', query = {citizenid = SenderData.PlayerData.citizenid, number = Player[1].charinfo.phone}, update = { ["$set"] = { citizenid = SenderData.PlayerData.citizenid, number = Player[1].charinfo.phone, messages = ChatMessages} }, options = { upsert = true }})
            end
        end
    end
end)

RegisterServerEvent('qb-phone:server:AddRecentCall', function(type, data, AnonymousCall, Payphone)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)

    local Hour = os.date("%H")
    local Minute = os.date("%M")
    local label = Hour..":"..Minute

    if not Payphone then
        TriggerClientEvent('qb-phone:client:AddRecentCall', src, data, label, type)
    end

    local Trgt = QBCore.Functions.GetPlayerByPhone(data.number)
    if Trgt ~= nil then
        TriggerClientEvent('qb-phone:client:AddRecentCall', Trgt.PlayerData.source, {
            name = Ply.PlayerData.charinfo.firstname .. " " ..Ply.PlayerData.charinfo.lastname,
            number = Ply.PlayerData.charinfo.phone,
            anonymous = AnonymousCall
        }, label, "outgoing")
    end
end)

RegisterNetEvent('qb-phone:server:CancelCall', function(ContactData)
    local Ply = QBCore.Functions.GetPlayerByPhone(ContactData.TargetData.number)

    if Ply ~= nil then
        TriggerClientEvent('qb-phone:client:CancelCall', Ply.PlayerData.source)
    end
end)

RegisterNetEvent('qb-phone:server:AnswerCall', function(CallData)
    local Ply = QBCore.Functions.GetPlayerByPhone(CallData.TargetData.number)

    if Ply ~= nil then
        TriggerClientEvent('qb-phone:client:AnswerCall', Ply.PlayerData.source)
    end
end)

RegisterNetEvent('qb-phone:server:SaveMetaData', function(MData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    --local result = MySQL.single.await('SELECT * FROM players WHERE citizenid = ?', {Player.PlayerData.citizenid})
    --local MetaData = json.decode(result.metadata)
    --MetaData.phone = MData
    --could be async i guess, try later
    --MySQL.Sync.execute('UPDATE players SET metadata = ? WHERE citizenid = ?', {json.encode(MetaData), Player.PlayerData.citizenid})
    MongoDB.Async.updateOne({collection = 'players', query = { citizenid = Player.PlayerData.citizenid }, update = { metadata = MetaData } })

    Player.Functions.SetMetaData("phone", MData)
end)

function escape_sqli(source)
    local replacements = { ['"'] = '\\"', ["'"] = "\\'" }
    return source:gsub( "['\"]", replacements ) -- or string.gsub( source, "['\"]", replacements )
end

--[[ QBCore.Functions.CreateCallback('qb-phone:server:FetchResult', function(source, cb, search)
    local src = source
    local search = escape_sqli(search)
    local searchData = {}
    local ApaData = {}

    local query = 'SELECT * FROM `players` WHERE `citizenid` = "' .. search .. '"'
    -- Split on " " and check each var individual
    local searchParameters = SplitStringToArray(search)

    -- Construct query dynamicly for individual parm check
    if #searchParameters > 1 then
        query = query .. ' OR `charinfo` LIKE "%' .. searchParameters[1] .. '%"'
        for i = 2, #searchParameters do
            query = query .. ' AND `charinfo` LIKE  "%' .. searchParameters[i] .. '%"'
        end
    else
        query = query .. ' OR `charinfo` LIKE "%' .. search .. '%"'
    end

    local ApartmentData = MySQL.Sync.fetchAll('SELECT * FROM apartments', {})
    for k, v in pairs(ApartmentData) do
        ApaData[v.citizenid] = ApartmentData[k]
    end

    local result = MySQL.Sync.fetchAll(query)
    if result[1] ~= nil then
        for k, v in pairs(result) do
            local charinfo = json.decode(v.charinfo)
            local metadata = json.decode(v.metadata)
            local appiepappie = {}
            if ApaData[v.citizenid] ~= nil and next(ApaData[v.citizenid]) ~= nil then
                appiepappie = ApaData[v.citizenid]
            end
            searchData[#searchData+1] = {
                citizenid = v.citizenid,
                firstname = charinfo.firstname,
                lastname = charinfo.lastname,
                birthdate = charinfo.birthdate,
                phone = charinfo.phone,
                nationality = charinfo.nationality,
                gender = charinfo.gender,
                warrant = false,
                driverlicense = metadata["licences"]["driver"],
                appartmentdata = appiepappie
            }
        end
        cb(searchData)
    else
        cb(nil)
    end
end) ]]

-- function SplitStringToArray(string)
--     local retval = {}
--     for i in string.gmatch(string, "%S+") do
--         table.insert(retval, i)
--         retval[#retval+1] = {i}
--     end
--     return retval
-- end

-- QBCore.Functions.CreateCallback('qb-phone:server:GetVehicleSearchResults', function(source, cb, search)
--     local src = source
--     local search = escape_sqli(search)
--     local searchData = {}
--     local query = '%' .. search .. '%'
--     --local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate LIKE ? OR citizenid = ?', {query, search})
--     local result = MongoDB.Sync.findOne({collection = 'vehicles', query = {plate = plate, citizenid = search } })
--     if result[1] ~= nil then
--         for k, v in pairs(result) do
--             local player = MySQL.Sync.fetchAll('SELECT * FROM players WHERE citizenid = ?', {result[k].citizenid})
--             if player[1] ~= nil then
--                 local charinfo = json.decode(player[1].charinfo)
--                 local vehicleInfo = QBCore.Shared.Vehicles[result[k].vehicle]
--                 if vehicleInfo ~= nil then
--                     searchData[#searchData+1] = {
--                         plate = result[k].plate,
--                         status = true,
--                         owner = charinfo.firstname .. " " .. charinfo.lastname,
--                         citizenid = result[k].citizenid,
--                         label = vehicleInfo["name"]
--                     }
--                 else
--                     searchData[#searchData+1] = {
--                         plate = result[k].plate,
--                         status = true,
--                         owner = charinfo.firstname .. " " .. charinfo.lastname,
--                         citizenid = result[k].citizenid,
--                         label = "Name not found.."
--                     }
--                 end
--             end
--         end
--     else
--         if GeneratedPlates[search] ~= nil then
--             searchData[#searchData+1] = {
--                 plate = GeneratedPlates[search].plate,
--                 status = GeneratedPlates[search].status,
--                 owner = GeneratedPlates[search].owner,
--                 citizenid = GeneratedPlates[search].citizenid,
--                 label = "Brand unknown.."
--             }
--         else
--             local ownerInfo = GenerateOwnerName()
--             GeneratedPlates[search] = {
--                 plate = search,
--                 status = true,
--                 owner = ownerInfo.name,
--                 citizenid = ownerInfo.citizenid
--             }
--             searchData[#searchData+1] = {
--                 plate = search,
--                 status = true,
--                 owner = ownerInfo.name,
--                 citizenid = ownerInfo.citizenid,
--                 label = "Brand unknown.."
--             }
--         end
--     end
--     cb(searchData)
-- end)

QBCore.Functions.CreateCallback('qb-phone:server:ScanPlate', function(source, cb, plate)
    local src = source
    local vehicleData = {}
    if plate ~= nil then 
    --local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = ?', {plate})
    local result = MongoDB.Sync.findOne({collection = 'vehicles', query = {plate = plate } })
        if result[1] ~= nil then
            --local player = MySQL.Sync.fetchAll('SELECT * FROM players WHERE citizenid = ?', {result[1].citizenid})
            local player = MongoDB.Sync.findOne({collection = 'players', query = {citizenid = result[1].citizenid }, options = { ["projection"] = {citizenid = 1, charinfo = 1} } })
            local charinfo = player[1].charinfo
            vehicleData = {
                plate = plate,
                status = true,
                owner = charinfo.firstname .. " " .. charinfo.lastname,
                citizenid = result[1].citizenid,
            }
        elseif GeneratedPlates ~= nil and GeneratedPlates[plate] ~= nil then 
            elseif GeneratedPlates ~= nil and GeneratedPlates[plate] ~= nil then 
        elseif GeneratedPlates ~= nil and GeneratedPlates[plate] ~= nil then 
            elseif GeneratedPlates ~= nil and GeneratedPlates[plate] ~= nil then 
        elseif GeneratedPlates ~= nil and GeneratedPlates[plate] ~= nil then 
            elseif GeneratedPlates ~= nil and GeneratedPlates[plate] ~= nil then 
        elseif GeneratedPlates ~= nil and GeneratedPlates[plate] ~= nil then 
            vehicleData = GeneratedPlates[plate]
        else
            local ownerInfo = GenerateOwnerName()
            GeneratedPlates[plate] = {
                plate = plate,
                status = true,
                owner = ownerInfo.name,
                citizenid = ownerInfo.citizenid,
            }
            vehicleData = {
                plate = plate,
                status = true,
                owner = ownerInfo.name,
                citizenid = ownerInfo.citizenid,
            }
        end
        cb(vehicleData)
    else
        TriggerClientEvent('QBCore:Notify', src, "No vehicle nearby..", "error")
        cb(nil)
    end
end)

function GenerateOwnerName()
    local names = {
        [1] = { name = "Jacob Cook", citizenid = "DSH091G93" },
        [2] = { name = "Joseph Walsh", citizenid = "AVH09M193" },
        [3] = { name = "Ryan Stone", citizenid = "DVH091T93" },
        [4] = { name = "Reginald Bishop", citizenid = "GZP091G93" },
        [5] = { name = "Raymond Alexander", citizenid = "DRH09Z193" },
        [6] = { name = "Caylee Munoz", citizenid = "KGV091J93" },
        [7] = { name = "Wendy Vincent", citizenid = "ODF09S193" },
        [8] = { name = "Rosie Simpson", citizenid = "KSD0919H3" },
        [9] = { name = "Megan Boyer", citizenid = "NDX091D93" },
        [10] = { name = "Valentina Hampton", citizenid = "ZAL0919X3" },
        [11] = { name = "Madisyn Brown", citizenid = "ZAK09D193" },
        [12] = { name = "Miles Wood", citizenid = "POL09F193" },
        [13] = { name = "Carson Rojas", citizenid = "TEW0J9193" },
        [14] = { name = "Spencer Nicholson", citizenid = "YOO09H193" },
        [15] = { name = "Patrick Hart", citizenid = "QBC091H93" },
        [16] = { name = "Alexander Ball", citizenid = "YDN091H93" },
        [17] = { name = "Finley Austin", citizenid = "PJD09D193" },
        [18] = { name = "Jase Branch", citizenid = "RND091D93" },
        [19] = { name = "Arlo Gomez", citizenid = "QWE091A93" },
        [20] = { name = "Ella Barrett", citizenid = "KJH0919M3" },
        [21] = { name = "Ellie Nolan", citizenid = "ZXC09D193" },
        [22] = { name = "Zoe Ellis", citizenid = "XYZ0919C3" },
        [23] = { name = "Elizabeth Johnston", citizenid = "ZYX0919F3" },
        [24] = { name = "Allyson Mullins", citizenid = "IOP091O93" },
        [25] = { name = "Noemi Flores", citizenid = "PIO091R93" },
        [26] = { name = "Jude Lane", citizenid = "LEK091X93" },
        [27] = { name = "Brenden Cameron", citizenid = "ALG091Y93" },
        [28] = { name = "Finley Hawkins", citizenid = "YUR09E193" },
        [29] = { name = "Easton Gonzalez", citizenid = "SOM091W93" },
        [30] = { name = "Mark Barber", citizenid = "KAS09193" },
    }
    return names[math.random(1, #names)]
end

QBCore.Functions.CreateCallback('qb-phone:server:GetGarageVehicles', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local Vehicles = {}

    --local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ?', {Player.PlayerData.citizenid})
    local result = MongoDB.Sync.find({collection = 'vehicles', query = {citizenid = Player.PlayerData.citizenid, type = 'automobile'} })
    if result[1] ~= nil then
        for i=1, #result do
            local v = result[i]
            local VehicleData = QBCore.Functions.GetSharedVehicles(v.vehicle)

            local VehicleGarage = "None"
            if v.garage ~= nil then
                if Garages[v.garage] ~= nil then
                    VehicleGarage = Garages[v.garage]["label"]
                elseif v.garage == 'hayesdepot' then
                    VehicleGarage = "Hayes Depot"
                end
            end

            local VehicleState = "In"

            if v.state == 0 then
                VehicleState = "Out"
            elseif v.state == 2 then
                VehicleState = "Impounded"
            end

            local vehdata = {}

            if VehicleData["brand"] ~= nil then
                vehdata = {
                    fullname = VehicleData["brand"] .. " " .. VehicleData["name"],
                    brand = VehicleData["brand"],
                    model = VehicleData["name"],
                    plate = v.plate,
                    garage = VehicleGarage,
                    state = VehicleState,
                    fuel = v.fuel,
                    engine = v.status.engine,
                    body = v.status.body
                }
            else
                vehdata = {
                    fullname = VehicleData["name"],
                    brand = VehicleData["name"],
                    model = VehicleData["name"],
                    plate = v.plate,
                    garage = VehicleGarage,
                    state = VehicleState,
                    fuel = v.fuel,
                    engine = v.status.engine,
                    body = v.status.body
                }
            end
            Vehicles[#Vehicles+1] = vehdata
        end
        cb(Vehicles)
    else
        cb(nil)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:CanTransferMoney', function(source, cb, amount, iban)
    local Player = QBCore.Functions.GetPlayer(source)

    if (Player.PlayerData.money.bank - amount) >= 0 then
        --local query = '%' .. iban .. '%'
        --local result = MySQL.Sync.fetchAll('SELECT * FROM players WHERE charinfo LIKE ?', {query})
        local result = MongoDB.Sync.findOne({collection = 'players', query = {["charinfo.account"] = iban}, options = { ["projection"] = {money = 1, citizenid = 1} } })
        if result[1] ~= nil then
            local Reciever = QBCore.Functions.GetPlayerByCitizenId(result[1].citizenid)

            Player.Functions.RemoveMoney('bank', amount)

            if Reciever ~= nil then
                Reciever.Functions.AddMoney('bank', amount)
            else
                local RecieverMoney = result[1].money
                local sentAmount = (RecieverMoney.bank + amount)
                --MySQL.Async.execute('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(RecieverMoney), result[1].citizenid})
                MongoDB.Sync.updateOne({collection = 'players', query = {citizenid = result[1].citizenid}, update = { ["$set"] = { ["money.bank"] = sentAmount } }})
            end
            cb(true)
        else
            TriggerClientEvent('QBCore:Notify', source, "This account number does not exist!", "error")
            cb(false)
        end
    end
end)

RegisterNetEvent('qb-phone:server:GiveContactDetails', function(PlayerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Player2 = QBCore.Functions.GetPlayer(PlayerId)

    local SuggestionData = {
        name = {
            [1] = Player.PlayerData.charinfo.firstname,
            [2] = Player.PlayerData.charinfo.lastname
        },
        number = Player.PlayerData.charinfo.phone,
        bank = Player.PlayerData.charinfo.account
    }

    TriggerClientEvent('qb-phone:client:AddNewSuggestion', PlayerId, SuggestionData)
    TriggerClientEvent('QBCore:Notify', src, "You shared contact details with " .. Player2.PlayerData.charinfo.firstname .. " " .. Player2.PlayerData.charinfo.lastname, "success", 4000)
end)

RegisterServerEvent('qb-phone:server:AddTransaction', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MongoDB.Sync.findOne({collection = 'crypto_transactions', query = {citizenid = Player.PlayerData.citizenid, title = data.TransactionTitle, message = data.TransactionMessage, type = data.TransactionType} })
    --[[ MySQL.insert('INSERT INTO crypto_transactions (citizenid, title, message, type) VALUES (?, ?, ?, ?)', {
        Player.PlayerData.citizenid,
        data.TransactionTitle,
        data.TransactionMessage,
        data.TransactionType,
    }) ]]
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetCurrentLawyers', function(source, cb)
    local Lawyers = {}
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then
            if Player.PlayerData.job.name == "lawyer" then
                Lawyers[#Lawyers+1] = {
                    name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                    phone = Player.PlayerData.charinfo.phone,
                }
            end
        end
    end
    cb(Lawyers)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetCurrentPlants', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    local result = MongoDB.Sync.find({collection = 'plants', query = {citizenid = Player.PlayerData.citizenid, wireless = 1} })
    local Plants = {}
    if result[1] ~= nil then
        for i=1, #result do
            local v = result[i]
            Plants[#Plants+1] = {
                health = v.health,
                food = v.food,
                sort = v.sort,
                zone = v.zone,
                type = v.type,
                coords = {x = v.coords.x, y = v.coords.y, z = v.coords.z}
            }
        end
    end
    cb(Plants)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetCurrentLoans', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    --local result = MySQL.Sync.fetchAll('SELECT * FROM loans WHERE citizenid = ?', {Player.PlayerData.citizenid})
    local result = MongoDB.Sync.find({collection = 'loans', query = {citizenid = Player.PlayerData.citizenid} })
    local Loans = {}
    if result[1] ~= nil then
        for k, v in pairs(result) do
            Loans[#Loans+1] = {
                id = v._id,
                remaining_amount = v.remaining_amount,
                start_date = v.loan_start_datetime,
                paid = v.paid,
                overdue = v.overdue,
            }
        end
    end
    cb(Loans)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetPaychecks', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Paychecks = {}
    
    local result = MongoDB.Sync.aggregate({
        collection = "paychecks",
        pipeline = {
            {['$match'] = {['citizenid'] = Player.PlayerData.citizenid}},
            {['$unwind'] = {path = '$paychecks' }},
            {['$group'] = {_id = '$paychecks', title = { ['$first'] = '$paychecks.title' }, date = { ['$first'] = '$paychecks.date' }, total = { ['$sum'] = '$paychecks.money' }}},
            {['$project'] = { ['_id'] = 0 } },
            {['$sort'] = {date = -1 }},
        } 
    })
    if #result > 0 then
        for i=1, #result do
            local v = result[i]
            Paychecks[#Paychecks+1] = {
                amount = v["total"],
                title = v["title"],
                date = v["date"],
            }
        end
    end
    cb(Paychecks)
end)

RegisterServerEvent('qb-phone:server:InstallApplication', function(ApplicationData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.PlayerData.metadata["phonedata"].installedapps[ApplicationData.app] = ApplicationData
    Player.Functions.SetMetaData("phonedata", Player.PlayerData.metadata["phonedata"])

    -- TriggerClientEvent('qb-phone:RefreshPhone', src)
end)

RegisterServerEvent('qb-phone:server:RemoveInstallation', function(App)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.PlayerData.metadata["phonedata"].installedapps[App] = nil
    Player.Functions.SetMetaData("phonedata", Player.PlayerData.metadata["phonedata"])

    -- TriggerClientEvent('qb-phone:RefreshPhone', src)
end)

-- QBCore.Commands.Add("setmetadata", "Set metadata", {}, false, function(source, args)
-- 	local Player = QBCore.Functions.GetPlayer(source)
	
-- 	if args[1] ~= nil then
--         if args[2] ~= nil then
--             local newrep = Player.PlayerData.metadata["jobrep"]
--             newrep.trucker = tonumber(args[2])
--             Player.Functions.SetMetaData("jobrep", newrep)
--         end
-- 	end
-- end, "god")

QBCore.Functions.CreateCallback('qb-phone:server:GetInvoices', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Invoices = {}

    --local invoices = MySQL.query.await('SELECT * FROM phone_invoices WHERE citizenid = ? AND status = ?', {Player.PlayerData.citizenid, 'Active'})
    local invoices = MongoDB.Sync.findOne({collection = 'phone_invoices', query = {citizenid = Player.PlayerData.citizenid, status =  'Active'} })
    if invoices[1] ~= nil then
        for k, v in pairs(invoices) do
            if v.sender ~= nil then
                local Target = QBCore.Functions.GetPlayerByCitizenId(v.sender)
                if Target ~= nil then
                    v.number = Target.PlayerData.charinfo.phone
                else
                    --local res = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {v.sender})
                    local res = MongoDB.Sync.findOne({collection = 'players', query = {citizenid = v.sender } })
                    if res[1] ~= nil then
                        --res[1].charinfo = res[1].charinfo
                        v.number = res[1].charinfo.phone
                    else
                        v.number = nil
                    end
                end
            else
                v.number = nil
            end
        end
        Invoices = invoices
    end
    cb(Invoices)
end)

RegisterServerEvent('qb-phone:server:PayPayPhone', function(number)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player ~= nil then
        if Player.Functions.RemoveMoney('cash', 5) then
            TriggerClientEvent('qb-phone:client:CallPayPhoneYes', src, number)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Call costs $5..', 'error')
        end
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetTaxiPlayers', function(source, cb)
    local taxiPlayers = {}
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local playerServerId = v
        local Player = QBCore.Functions.GetPlayer(v)
        if DoesEntityExist(ped) then --fix this
            if Player ~= nil and Player.PlayerData.job.name == 'taxi' then
                taxiPlayers[#taxiPlayers + 1] = {
                    phone = Player.PlayerData.charinfo.phone,
                    name  = Player.PlayerData.charinfo.firstname.. ' '..' '..Player.PlayerData.charinfo.lastname,
                }
            end
        end
    end
    cb(taxiPlayers)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetGangData', function(source, cb, gang)
    local src = source
    local Gang = {}
    local result = MongoDB.Sync.find({collection = 'players', query = {["gang.name"] = gang}, options = { ["projection"] = {citizenid = 1, gang = 1} } })
    if result[1] ~= nil then
        Gang = result
    end
    cb(Gang)
end)

RegisterServerEvent('fs_taxi:payCab', function(meters)
	if meters < 1 then return end
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	
	local CashInHand = Player.PlayerData.money.cash
	local totalPrice = meters / 40.0
	local price = math.floor(totalPrice)
	
	if CashInHand >= tonumber(price)  then
		Player.Functions.RemoveMoney("cash", price, "Taxi-fare-bought")
		TriggerClientEvent('fs_taxi:payment-status', src, true)
	else
		Player.Functions.RemoveMoney("cash", CashInHand, "Taxi-fare-bought")
		TriggerClientEvent('fs_taxi:payment-status', src, false)
	end
end)