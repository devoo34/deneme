local QBCore = exports['qb-core']:GetCoreObject()
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

-- Code

local NMPhone = {}
local Tweets = {}
local AppAlerts = {}
local MentionedTweets = {}
local Hashtags = {}
local Calls = {}
local Adverts = {}
local GeneratedPlates = {}

RegisterServerEvent('qb-phone:server:AddAdvert')
AddEventHandler('qb-phone:server:AddAdvert', function(msg, image)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local CitizenId = Player.PlayerData.citizenid

    if Adverts[CitizenId] ~= nil then
        Adverts[CitizenId].message = msg
        Adverts[CitizenId].image = image
        Adverts[CitizenId].name = "@"..Player.PlayerData.charinfo.firstname..""..Player.PlayerData.charinfo.lastname
        Adverts[CitizenId].number = Player.PlayerData.charinfo.phone
    else
        Adverts[CitizenId] = {
            message = msg,
            image = image,
            name = "@"..Player.PlayerData.charinfo.firstname..""..Player.PlayerData.charinfo.lastname,
            number = Player.PlayerData.charinfo.phone,
        }
    end

    TriggerClientEvent('qb-phone:client:UpdateAdverts', -1, Adverts, "@"..Player.PlayerData.charinfo.firstname..""..Player.PlayerData.charinfo.lastname)
end)

function GetOnlineStatus(number)
    local Target = QBCore.Functions.GetPlayerByPhone(number)
    local retval = false
    if Target ~= nil then retval = true end
    return retval
end

QBCore.Functions.CreateCallback('qb-phone:server:GetPhoneData', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player ~= nil then
        local PhoneData = {
            Applications = {},
            PlayerContacts = {},
            MentionedTweets = {},
            Chats = {},
            Hashtags = {},
            Invoices = {},
            Garage = {},
            Mails = {},
            Adverts = {},
            CryptoTransactions = {},
            Tweets = {},
            Photos = {}
            -- InstalledApps = Player.PlayerData.metadata["phonedata"].InstalledApps,
        }

        PhoneData.Adverts = Adverts

        exports.oxmysql:fetch("SELECT * FROM player_contacts WHERE `citizenid` = ? ORDER BY `name` ASC", {Player.PlayerData.citizenid}, function(result)
            local Contacts = {}
            if result[1] ~= nil then
                for k, v in pairs(result) do
                    v.status = GetOnlineStatus(v.number)
                end
                
                PhoneData.PlayerContacts = result
            end
        
            exports.oxmysql:fetch("SELECT * FROM billing WHERE `identifier` = ?", {Player.PlayerData.citizenid}, function(invoices)
                if invoices[1] ~= nil then
                    for k, v in pairs(invoices) do
                        local Ply = QBCore.Functions.GetPlayerByCitizenId(v.sender)
                        if Ply ~= nil then
                            v.number = Ply.PlayerData.charinfo.phone
                        else
                            exports.oxmysql:fetch("SELECT * FROM `players` WHERE `citizenid` = ?", {v.sender}, function(res)
                                if res[1] ~= nil then
                                    res[1].charinfo = json.decode(res[1].charinfo)
                                    v.number = res[1].charinfo.phone
                                else
                                    v.number = nil
                                end
                            end)
                        end
                    end
                    PhoneData.Invoices = invoices
                end
                
                exports.oxmysql:execute("SELECT * FROM player_vehicles WHERE `citizenid` = ?", {Player.PlayerData.citizenid}, function(garageresult)                    
                    -- if garageresult[1] ~= nil then
                    --     for k, v in pairs(garageresult) do
                    --         if (QBCore.Shared.Vehicles[v.vehicle] ~= nil) and (Garages[v.garage] ~= nil) then
                    --             v.garage = Garages[v.garage].label
                    --             v.vehicle = QBCore.Shared.Vehicles[v.vehicle].name
                    --             v.brand = QBCore.Shared.Vehicles[v.vehicle].brand
                    --         end
                    --     end

                    --     PhoneData.Garage = garageresult
                    -- end
                    
                    exports.oxmysql:fetch("SELECT * FROM player_vehicles WHERE `citizenid` = ?", {Player.PlayerData.citizenid}, function(garageresult)
                        -- if garageresult[1] ~= nil then
                        --     for k, v in pairs(garageresult) do
                        --         if (QBCore.Shared.Vehicles[v.vehicle] ~= nil) and (Garages[v.garage] ~= nil) then
                        --             v.garage = Garages[v.garage].label
                        --             v.vehicle = QBCore.Shared.Vehicles[v.vehicle].name
                        --             v.brand = QBCore.Shared.Vehicles[v.vehicle].brand
                        --         end
                        --     end
                    
                        --     PhoneData.Garage = garageresult
                        -- end
                    
                        exports.oxmysql:fetch("SELECT * FROM phone_messages WHERE `citizenid` = ? ORDER BY edited_at DESC", {Player.PlayerData.citizenid}, function(messages)
                            if messages ~= nil and next(messages) ~= nil then 
                                PhoneData.Chats = messages
                            end
                    
                            if AppAlerts[Player.PlayerData.citizenid] ~= nil then 
                                PhoneData.Applications = AppAlerts[Player.PlayerData.citizenid]
                            end
                    
                            if MentionedTweets[Player.PlayerData.citizenid] ~= nil then 
                                PhoneData.MentionedTweets = MentionedTweets[Player.PlayerData.citizenid]
                            end
                    
                            if Hashtags ~= nil and next(Hashtags) ~= nil then
                                PhoneData.Hashtags = Hashtags
                            end
                    
                            if Tweets ~= nil and next(Tweets) ~= nil then
                                PhoneData.Tweets = Tweets
                            end

                            exports.oxmysql:execute('SELECT * FROM `player_mails` WHERE `citizenid` = ? ORDER BY `date` ASC', {Player.PlayerData.citizenid}, function(mails)
                            if mails[1] ~= nil then
                                for k, v in pairs(mails) do
                                    if mails[k].button ~= nil then
                                        mails[k].button = json.decode(mails[k].button)
                                    end
                                end
                                PhoneData.Mails = mails
                            end

                            exports.oxmysql:execute('SELECT * FROM `crypto_transactions` WHERE `citizenid` = ? ORDER BY `date` ASC', {Player.PlayerData.citizenid}, function(transactions)
                                if transactions[1] ~= nil then
                                    for _, v in pairs(transactions) do
                                        table.insert(PhoneData.CryptoTransactions, {
                                            TransactionTitle = v.title,
                                            TransactionMessage = v.message,
                                        })
                                    end
                                end

                                exports.oxmysql:execute('SELECT * FROM `phone_photos` WHERE `citizenid` = ? ORDER BY `created_at` DESC', {Player.PlayerData.citizenid}, function(photos)
                                    if photos[1] ~= nil then
                                        PhoneData.Photos = photos
                                    end

                                    cb(PhoneData)
                                
                            end
                        end)
                    end)
                end)
            end)
        end)
    end
end

    RegisterServerEvent('qb-phone:server:GetBankHistory')
    AddEventHandler('qb-phone:server:GetBankHistory', function(cb)

    exports.oxmysql:execute('SELECT * FROM `bank_transactions` WHERE `citizenid` = ?', {Player.PlayerData.citizenid}, function(result)

    Player = QBCore.Functions.GetPlayer(source)

    exports.oxmysql:execute('SELECT * FROM bank_logs WHERE transmitter=@account OR receiver=@account ORDER BY created_at DESC LIMIT 10;', {
        ['@account'] = Player.PlayerData.charinfo.account
    }, function(result)
        if result[1] ~= nil then
            cb(result)
        else
            cb(nil)
            end
            cb(result)
         end)
    end)
end)

    RegisterServerEvent('qb-phone:server:GetCallState')
    AddEventHandler('qb-phone:server:GetCallState', function(ContactData, cb)
    exports.oxmysql:execute('SELECT * FROM `phone_calls` WHERE `citizenid` = ? AND (`inbound_number` = ? OR `outbound_number` = ?) ORDER BY `call_start` DESC LIMIT 1', {Player.PlayerData.citizenid, ContactData.number, ContactData.number}, function(result)
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
        cb(result[1])
    end)
end)

RegisterServerEvent('qb-phone:server:SetCallState')
AddEventHandler('qb-phone:server:SetCallState', function(bool)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)

    if Calls[Ply.PlayerData.citizenid] ~= nil then
        Calls[Ply.PlayerData.citizenid].inCall = bool
    else
        Calls[Ply.PlayerData.citizenid] = {}
        Calls[Ply.PlayerData.citizenid].inCall = bool
    end
end)

RegisterServerEvent('qb-phone:server:RemoveMail')
AddEventHandler('qb-phone:server:RemoveMail', function(MailId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    exports.oxmysql:execute('DELETE FROM `player_mails` WHERE `mailid` = ? AND `citizenid` = ?', {MailId, Player.PlayerData.citizenid}, function(rowsAffected)    SetTimeout(100, function()
    exports.oxmysql:execute('SELECT * FROM `player_mails` WHERE `citizenid` = ? ORDER BY `date` ASC', {Player.PlayerData.citizenid}, function(mails)            if mails[1] ~= nil then
                for k, v in pairs(mails) do
                    if mails[k].button ~= nil then
                        mails[k].button = json.decode(mails[k].button)
                    end
                end
            end
    
            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    end)
end)
end)

function GenerateMailId()
    return math.random(111111, 999999)
end

RegisterServerEvent('qb-phone:server:sendNewMail')
AddEventHandler('qb-phone:server:sendNewMail', function(mailData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if mailData.button == nil then
        exports.oxmysql:insert('INSERT INTO `player_mails` (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', {
            Player.PlayerData.citizenid,
            mailData.sender,
            mailData.subject,
            mailData.message,
            GenerateMailId(),
            0
        })
    else
        exports.oxmysql:insert('INSERT INTO `player_mails` (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            Player.PlayerData.citizenid,
            mailData.sender,
            mailData.subject,
            mailData.message,
            GenerateMailId(),
            0,
            json.encode(mailData.button)
        })
    end
    TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
    SetTimeout(200, function()
        exports.oxmysql:execute('SELECT * FROM `player_mails` WHERE `citizenid` = ? ORDER BY `date` DESC', {Player.PlayerData.citizenid}, function(mails)
            if mails[1] ~= nil then
                for k, v in pairs(mails) do
                    if mails[k].button ~= nil then
                        mails[k].button = json.decode(mails[k].button)
                    end
                end
            end
    
            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    end)
end)


RegisterServerEvent('qb-phone:server:sendNewMailToOffline')
AddEventHandler('qb-phone:server:sendNewMailToOffline', function(citizenid, mailData)
local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
if Player ~= nil then
    local src = Player.PlayerData.source

    if mailData.button == nil then
        exports.oxmysql:execute('INSERT INTO `player_mails` (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', {Player.PlayerData.citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0})
        TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
    else
        exports.oxmysql:execute('INSERT INTO `player_mails` (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', {Player.PlayerData.citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button)})
        TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
    end

    SetTimeout(200, function()
        exports.oxmysql:execute('SELECT * FROM `player_mails` WHERE `citizenid` = ? ORDER BY `date` DESC', {Player.PlayerData.citizenid}, function(result)
            local mails = {}

            if result[1] ~= nil then
                for k, v in pairs(result) do
                    if result[k].button ~= nil then
                        result[k].button = json.decode(result[k].button)
                    end

                    table.insert(mails, result[k])
                end
            end
    
            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    end)
else
    if mailData.button == nil then
        exports.oxmysql:execute('INSERT INTO `player_mails` (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0})
    else
        exports.oxmysql:execute('INSERT INTO `player_mails` (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button)})
    end
end
end)

RegisterServerEvent('qb-phone:server:sendNewEventMail')
AddEventHandler('qb-phone:server:sendNewEventMail', function(citizenid, mailData)
    if mailData.button == nil then
        exports.oxmysql:execute('INSERT INTO `player_mails` (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES (?, ?, ?, ?, ?, ?)', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0})
    else
        exports.oxmysql:execute('INSERT INTO `player_mails` (`citizenid`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES (?, ?, ?, ?, ?, ?, ?)', {citizenid, mailData.sender, mailData.subject, mailData.message, GenerateMailId(), 0, json.encode(mailData.button)})
    end
    SetTimeout(200, function()
        exports.oxmysql:execute('SELECT * FROM `player_mails` WHERE `citizenid` = ? ORDER BY `date` DESC', {Player.PlayerData.citizenid}, function(mails)
            if mails[1] ~= nil then
                for k, v in pairs(mails) do
                    if mails[k].button ~= nil then
                        mails[k].button = json.decode(mails[k].button)
                    end
                end
            end
    
            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    end)
end)

RegisterServerEvent('qb-phone:server:ClearButtonData')
AddEventHandler('qb-phone:server:ClearButtonData', function(mailId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    exports.oxmysql:execute('UPDATE `player_mails` SET `button` = "" WHERE `mailid` = ? AND `citizenid` = ?', {mailId, Player.PlayerData.citizenid})
    SetTimeout(200, function()
        exports.oxmysql:execute('SELECT * FROM `player_mails` WHERE `citizenid` = ? ORDER BY `date` DESC', {Player.PlayerData.citizenid}, function(mails)
            if mails[1] ~= nil then
                for k, v in pairs(mails) do
                    if mails[k].button ~= nil then
                        mails[k].button = json.decode(mails[k].button)
                    end
                end
            end
    
            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    end)
end)

RegisterServerEvent('qb-phone:server:MentionedPlayer')
AddEventHandler('qb-phone:server:MentionedPlayer', function(firstName, lastName, TweetMessage)
for k, v in pairs(QBCore.Functions.GetPlayers()) do
local Player = QBCore.Functions.GetPlayer(v)
if Player ~= nil then
if (Player.PlayerData.charinfo.firstname == firstName and Player.PlayerData.charinfo.lastname == lastName) then
NMPhone.SetPhoneAlerts(Player.PlayerData.citizenid, "twitter")
NMPhone.AddMentionedTweet(Player.PlayerData.citizenid, TweetMessage)
TriggerClientEvent('qb-phone:client:GetMentioned', Player.PlayerData.source, TweetMessage, AppAlerts[Player.PlayerData.citizenid]["twitter"])
else
exports.oxmysql:execute('SELECT * FROM players WHERE charinfo LIKE ? AND charinfo LIKE ?', { '%'..firstName..'%', '%'..lastName..'%' }, function(result)
if result[1] ~= nil then
local MentionedTarget = result[1].citizenid
NMPhone.SetPhoneAlerts(MentionedTarget, "twitter")
NMPhone.AddMentionedTweet(MentionedTarget, TweetMessage)
end
end)
end
end
end
end)

RegisterServerEvent('qb-phone:server:CallContact')
AddEventHandler('qb-phone:server:CallContact', function(TargetData, CallId, AnonymousCall)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayerByPhone(TargetData.number)

    if Target ~= nil then
        TriggerClientEvent('qb-phone:client:GetCalled', Target.PlayerData.source, Ply.PlayerData.charinfo.phone, CallId, AnonymousCall)
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:PayInvoice', function(source, cb, sender, amount, invoiceId)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local Trgt = QBCore.Functions.GetPlayerByCitizenId(sender)
    local Invoices = {}

    if Trgt ~= nil then
        if Ply.PlayerData.money.bank >= amount then
            Ply.Functions.RemoveMoney('bank', amount, "paid-invoice")
            Trgt.Functions.AddMoney('bank', amount, "paid-invoice")
    
            exports.oxmysql:execute('DELETE FROM billing WHERE id = ?', {invoiceId}, function(affectedRows)
                exports.oxmysql:execute('SELECT * FROM billing WHERE identifier = ?', {Ply.PlayerData.citizenid}, function(invoices)
                    if invoices[1] ~= nil then
                        for k, v in pairs(invoices) do
                            local Target = exports.oxmysql:fetchSync('SELECT * FROM players WHERE citizenid = ?', {v.sender})
                            if Target[1] ~= nil then
                                v.number = json.decode(Target[1].charinfo).phone
                            else
                                v.number = nil
                            end
                        end
                        Invoices = invoices
                    end
                    cb(true, Invoices)
                end)
            end)
        else
            cb(false)
        end
    end
end)    
    else
        exports.oxmysql:execute('SELECT * FROM players WHERE citizenid = ?', {sender}, function(result)
            if result[1] ~= nil then
                local moneyInfo = json.decode(result[1].money)
                moneyInfo.bank = math.ceil((moneyInfo.bank + amount))
                exports.oxmysql:execute('UPDATE players SET money = ? WHERE citizenid = ?', {json.encode(moneyInfo), sender})
                Ply.Functions.RemoveMoney('bank', amount, "paid-invoice")
                exports.oxmysql:execute('DELETE FROM phone_invoices WHERE invoiceid = ?', {invoiceId})
                exports.oxmysql:execute('SELECT * FROM phone_invoices WHERE citizenid = ?', {Ply.PlayerData.citizenid}, function(invoices)
                    if invoices[1] ~= nil then
                        for k, v in pairs(invoices) do
                            local Target = exports.oxmysql:fetchSync('SELECT * FROM players WHERE citizenid = ?', {v.sender})
                            if Target[1] ~= nil then
                                v.number = json.decode(Target[1].charinfo).phone
                            else
                                v.number = nil
                            end
                        end
                        Invoices = invoices
                    end
                    cb(true, Invoices)
                end)
            else
                cb(false)
            end
        end)        

        RegisterServerCallback('qb-phone:server:DeclineInvoice', function(source, cb, sender, amount, invoiceId)
            local src = source
            local Ply = QBCore.Functions.GetPlayer(src)
            local Trgt = QBCore.Functions.GetPlayerByCitizenId(sender)
            local Invoices = {}
        
            exports.oxmysql:execute('DELETE FROM phone_invoices WHERE invoiceid = ?', {invoiceId}, function(affectedRows)
                exports.oxmysql:fetch('SELECT * FROM phone_invoices WHERE citizenid = ?', {Ply.PlayerData.citizenid}, function(invoices)
                    if invoices[1] ~= nil then
                        for k, v in pairs(invoices) do
                            local Target = QBCore.Functions.GetPlayerByCitizenId(v.sender)
                            if Target ~= nil then
                                v.number = Target.PlayerData.charinfo.phone
                            else
                                exports.oxmysql:fetch('SELECT * FROM players WHERE citizenid = ?', {v.sender}, function(res)
                                    if res[1] ~= nil then
                                        res[1].charinfo = json.decode(res[1].charinfo)
                                        v.number = res[1].charinfo.phone
                                    else
                                        v.number = nil
                                    end
                                end)
                            end
                        end
                        Invoices = invoices
                    end
                    cb(true, invoices)
                end)
            end)
        end)
        

RegisterServerEvent('qb-phone:server:UpdateHashtags')
AddEventHandler('qb-phone:server:UpdateHashtags', function(Handle, messageData)
    if Hashtags[Handle] ~= nil and next(Hashtags[Handle]) ~= nil then
        table.insert(Hashtags[Handle].messages, messageData)
    else
        Hashtags[Handle] = {
            hashtag = Handle,
            messages = {}
        }
        table.insert(Hashtags[Handle].messages, messageData)
    end
    TriggerClientEvent('qb-phone:client:UpdateHashtags', -1, Handle, messageData)
end)

NMPhone.AddMentionedTweet = function(citizenid, TweetData)
    if MentionedTweets[citizenid] == nil then MentionedTweets[citizenid] = {} end
    table.insert(MentionedTweets[citizenid], TweetData)
end

NMPhone.SetPhoneAlerts = function(citizenid, app, alerts)
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
    for k, v in pairs(Chats) do
        local Player = QBCore.Functions.GetPlayerByPhone(v.number)
        
        exports.oxmysql:execute('SELECT * FROM `players` WHERE `charinfo` LIKE \'%' .. v.number .. '%\'', function(result)

            if result[1] ~= nil then
                local MetaData = json.decode(result[1].metadata)

                if MetaData.phone.profilepicture ~= nil then
                    v.picture = MetaData.phone.profilepicture
                else
                    v.picture = "default"
                end
            end
        end)
    end
    SetTimeout(100, function()
        cb(Chats)
    end)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetContactPicture', function(source, cb, Chat)
    local Player = QBCore.Functions.GetPlayerByPhone(Chat.number)

    exports.oxmysql:execute('SELECT * FROM `players` WHERE `charinfo` LIKE "%'..Chat.number..'%"', function(result)
        if (MetaData == nil) then 
            Chat.picture = "detault"
        else
            local MetaData = json.decode(result[1].metadata)
            
            if MetaData.phone.profilepicture ~= nil then
                Chat.picture = MetaData.phone.profilepicture
            else
                Chat.picture = "default"
            end
        end
    end)
    SetTimeout(100, function()
        cb(Chat)
    end)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetPicture', function(source, cb, number)
    local Player = QBCore.Functions.GetPlayerByPhone(number)
    local Picture = nil

    exports.oxmysql:execute('SELECT * FROM players WHERE charinfo LIKE ?', {'%'..number..'%'}, function(result)

        if result[1] ~= nil then
            local MetaData = json.decode(result[1].metadata)

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
end)


RegisterServerEvent('qb-phone:server:UpdateAlarms')
AddEventHandler('qb-phone:server:UpdateAlarms', function(data)
    local player = QBCore.Functions.GetPlayer(source)
    player.Functions.SetMetaData("phonealarms", data)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetTime', function(source, cb)
    cb(tonumber(os.date('%w')), tonumber(os.date('%H')), tonumber(os.date('%M')))
end)


RegisterServerEvent('qb-phone:server:SetPhoneAlerts')
AddEventHandler('qb-phone:server:SetPhoneAlerts', function(app, alerts)
    local src = source
    local CitizenId = QBCore.Functions.GetPlayer(src).citizenid
    NMPhone.SetPhoneAlerts(CitizenId, app, alerts)
end)

RegisterServerEvent('qb-phone:server:UpdateTweets')
AddEventHandler('qb-phone:server:UpdateTweets', function(NewTweets, TweetData)
    Tweets = NewTweets
    local TwtData = TweetData
    local src = source
    TriggerClientEvent('qb-phone:client:UpdateTweets', -1, src, Tweets, TwtData)
end)

RegisterServerEvent('qb-phone:server:TransferMoney')
AddEventHandler('qb-phone:server:TransferMoney', function(iban, amount)
    local src = source
    local sender = QBCore.Functions.GetPlayer(src)

    exports.oxmysql:execute('SELECT * FROM players WHERE charinfo LIKE ?', { "%" .. iban .. "%" }, function(result)
        if result[1] ~= nil then
            local recieverSteam = QBCore.Functions.GetPlayerByCitizenId(result[1].citizenid)

            if recieverSteam ~= nil then
                local PhoneItem = recieverSteam.Functions.GetItemByName("phone")
                recieverSteam.Functions.AddMoney('bank', amount, "phone-transfered-from-"..sender.PlayerData.citizenid)
                sender.Functions.RemoveMoney('bank', amount, "phone-transfered-to-"..recieverSteam.PlayerData.citizenid)

                if PhoneItem ~= nil then
                    TriggerClientEvent('qb-phone:client:TransferMoney', recieverSteam.PlayerData.source, amount, recieverSteam.PlayerData.money.bank)
                end
            else
                local moneyInfo = json.decode(result[1].money)
                moneyInfo.bank = round((moneyInfo.bank + amount))
                exports.oxmysql:execute('UPDATE `players` SET `money` = ? WHERE `citizenid` = ?', {json.encode(moneyInfo), result[1].citizenid})
                sender.Functions.RemoveMoney('bank', amount, "phone-transfered")
            end
        else
            TriggerClientEvent('QBCore:Notify', src, "Böyle bir hesap yok", "error")
        end
    end)
end)

RegisterServerEvent('qb-phone:server:EditContact')
AddEventHandler('qb-phone:server:EditContact', function(newName, newNumber, newIban, newImage, oldName, oldNumber, oldIban)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    exports.oxmysql:execute('UPDATE `player_contacts` SET `name` = ?, `number` = ?, `iban` = ?, `image` = ? WHERE `citizenid` = ? AND `name` = ? AND `number` = ?',
    {newName, newNumber, newIban, newImage, Player.PlayerData.citizenid, oldName, oldNumber})
end)

RegisterServerEvent('qb-phone:server:EditContactNote')
AddEventHandler('qb-phone:server:EditContactNote', function(name, number, newNote)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    exports.oxmysql:execute('UPDATE `player_contacts` SET `note` = ? WHERE `citizenid` = ? AND `name` = ? AND `number` = ?', { newNote, Player.PlayerData.citizenid, name, number })
end)

RegisterServerEvent('qb-phone:server:RemoveContact')
AddEventHandler('qb-phone:server:RemoveContact', function(Name, Number)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    exports.oxmysql:execute('DELETE FROM `player_contacts` WHERE `name` = ? AND `number` = ? AND `citizenid` = ?', {Name, Number, Player.PlayerData.citizenid})
end)

RegisterServerEvent('qb-phone:server:AddNewContact')
AddEventHandler('qb-phone:server:AddNewContact', function(name, number, iban, image)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    exports.oxmysql:execute('INSERT INTO `player_contacts` (`citizenid`, `name`, `number`, `iban`, `image`) VALUES (?, ?, ?, ?, ?)', {
        Player.PlayerData.citizenid,
        tostring(name),
        tostring(number),
        tostring(iban),
        tostring(image)
    })
    end)

RegisterServerEvent('qb-phone:server:SendMessageToPlayer')
AddEventHandler('qb-phone:server:SendMessageToPlayer', function(SenderNumber, TargetNumber, Message, MessageType, MessageMetaData)
    if MessageType == nil then MessageType = "message" end
    
    exports.oxmysql:execute('SELECT * FROM `players` WHERE `charinfo` LIKE ?', { '%'..TargetNumber..'%' }, function(data)
        if #data == 0 then return end

        local TargetData = QBCore.Functions.GetPlayerByCitizenId(data[1].citizenid)

        if TargetData ~= nil then
            local MessageData = {
                ChatMessage = Message,
                ChatType = MessageType,
                ChatNumber = SenderNumber
            }

            MessageData.ChatDate = os.date("%d-") .. math.floor((os.date("%m") - 1)).. os.date("-%Y")
            MessageData.ChatTime = os.date("%X"):sub(1, -4)

            if MessageMetaData ~= nil then
                MessageData.Data = MessageMetaData
            end

            TriggerClientEvent('qb-phone:client:ReceiveMessage', TargetData.PlayerData.source, MessageData)
        end
    end)
end)

RegisterServerEvent('qb-phone:server:UpdateMessages')
AddEventHandler('qb-phone:server:UpdateMessages', function(ChatMessages, ChatNumber, New)
    local src = source
    local SenderData = QBCore.Functions.GetPlayer(src)

    exports.oxmysql:fetch('SELECT * FROM `players` WHERE `charinfo` LIKE ?', { ChatNumber }, function(result)
        if Player[1] ~= nil then
            local TargetData = exports.oxmysql:fetchSync('SELECT * FROM players WHERE citizenid = ?', { Player[1].citizenid })
            if TargetData[1] ~= nil then
                exports.oxmysql:fetch('SELECT * FROM phone_messages WHERE citizenid = ? AND number = ? ORDER BY edited_at DESC', { SenderData.PlayerData.citizenid, ChatNumber }, function(Chat)
                    if Chat[1] ~= nil then
                        -- Update for target
                        exports.oxmysql:execute('UPDATE phone_messages SET messages = ? WHERE citizenid = ? AND number = ?', { json.encode(ChatMessages), TargetData[1].citizenid, SenderData.PlayerData.charinfo.phone })
                                        
                        -- Update for sender
                        exports.oxmysql:execute('UPDATE phone_messages SET messages = ? WHERE citizenid = ? AND number = ?', { json.encode(ChatMessages), SenderData.PlayerData.citizenid, TargetData[1].charinfo.phone })
                            
                        -- Send notification & Update messages for target
                        TriggerClientEvent('qb-phone:client:UpdateMessages', TargetData[1].source, ChatMessages, SenderData.PlayerData.charinfo.phone, false)
                    else
                        -- Insert for target
                        exports.oxmysql:execute('INSERT INTO phone_messages (citizenid, number, messages) VALUES (?, ?, ?)', { TargetData[1].citizenid, SenderData.PlayerData.charinfo.phone, json.encode(ChatMessages) })
                                                    
                        -- Insert for sender
                        exports.oxmysql:execute('INSERT INTO phone_messages (citizenid, number, messages) VALUES (?, ?, ?)', { SenderData.PlayerData.citizenid, TargetData[1].charinfo.phone, json.encode(ChatMessages) })
        
                        -- Send notification & Update messages for target
                        TriggerClientEvent('qb-phone:client:UpdateMessages', TargetData[1].source, ChatMessages, SenderData.PlayerData.charinfo.phone, true)
                    end
                end)
            else
                exports.oxmysql:execute('SELECT * FROM `phone_messages` WHERE `citizenid` = ? AND `number` = ? ORDER BY edited_at DESC', {SenderData.PlayerData.citizenid, ChatNumber}, function(Chat)
                    if Chat[1] ~= nil then
                        -- Update for target
                        exports.oxmysql:execute('UPDATE `phone_messages` SET `messages` = ? WHERE `citizenid` = ? AND `number` = ?', {json.encode(ChatMessages), Player[1].citizenid, SenderData.PlayerData.charinfo.phone})
                
                        -- Update for sender
                        Player[1].charinfo = json.decode(Player[1].charinfo)
                        exports.oxmysql:execute('UPDATE `phone_messages` SET `messages` = ? WHERE `citizenid` = ? AND `number` = ?', {json.encode(ChatMessages), SenderData.PlayerData.citizenid, Player[1].charinfo.phone})
                    else
                        -- Insert for target
                        exports.oxmysql:execute('INSERT INTO `phone_messages` (`citizenid`, `number`, `messages`) VALUES (?, ?, ?)', {Player[1].citizenid, SenderData.PlayerData.charinfo.phone, json.encode(ChatMessages)})
                
                        -- Insert for sender
                        Player[1].charinfo = json.decode(Player[1].charinfo)
                        exports.oxmysql:execute('INSERT INTO `phone_messages` (`citizenid`, `number`, `messages`) VALUES (?, ?, ?)', {SenderData.PlayerData.citizenid, Player[1].charinfo.phone, json.encode(ChatMessages)})
                    end
                end)                
            end
        else
            -- If player sends message to unavailable number
            exports.oxmysql:execute('SELECT * FROM `phone_messages` WHERE `citizenid` = ? AND `number` = ? ORDER BY edited_at DESC', { SenderData.PlayerData.citizenid, ChatNumber }, function(Chat)
                if Chat[1] ~= nil then
                    -- Update for sender
                    exports.oxmysql:execute('UPDATE `phone_messages` SET `messages` = ? WHERE `citizenid` = ? AND `number` = ?', { json.encode(ChatMessages), SenderData.PlayerData.citizenid, ChatNumber })
                else
                    -- Insert for sender
                    exports.oxmysql:execute('INSERT INTO `phone_messages` (`citizenid`, `number`, `messages`) VALUES (?, ?, ?)', { SenderData.PlayerData.citizenid, ChatNumber, json.encode(ChatMessages) })
                end
            end)            
        end
    end)
end)

RegisterServerEvent('qb-phone:server:AddRecentCall')
AddEventHandler('qb-phone:server:AddRecentCall', function(type, data)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)

    local Hour = os.date("%H")
    local Minute = os.date("%M")
    local label = Hour..":"..Minute

    TriggerClientEvent('qb-phone:client:AddRecentCall', src, data, label, type)

    local Trgt = QBCore.Functions.GetPlayerByPhone(data.number)
    if Trgt ~= nil then
        TriggerClientEvent('qb-phone:client:AddRecentCall', Trgt.PlayerData.source, {
            name = Ply.PlayerData.charinfo.firstname .. " " ..Ply.PlayerData.charinfo.lastname,
            number = Ply.PlayerData.charinfo.phone,
            anonymous = anonymous
        }, label, "outgoing")
    end
end)

RegisterServerEvent('qb-phone:server:CancelCall')
AddEventHandler('qb-phone:server:CancelCall', function(id,ContactData)
    id = tonumber(id)
    if ContactData.TargetData ~= nil then
        local Ply = QBCore.Functions.GetPlayerByPhone(ContactData.TargetData.number)
        if Ply ~= nil then
            local sourcetarget = QBCore.Functions.GetPlayerByCitizenId(Ply.PlayerData.citizenid)
            exports['saltychat']:EndCall(id, sourcetarget.PlayerData.source)
            TriggerClientEvent('qb-phone:client:CancelCall', sourcetarget.PlayerData.source)
        end
    end
end)

RegisterServerEvent('qb-phone:server:AnswerCall')
AddEventHandler('qb-phone:server:AnswerCall', function(id, CallData)
    id = tonumber(id)
    local Ply = QBCore.Functions.GetPlayerByPhone(CallData.TargetData.number)
    if Ply ~= nil then
        local sourcetarget = QBCore.Functions.GetPlayerByCitizenId(Ply.PlayerData.citizenid)
        exports['saltychat']:EstablishCall(id, sourcetarget.PlayerData.source)
        -- exports["saltychat"]:addPlayerToRadio(id, CallData.CallId, false)
        TriggerClientEvent('qb-phone:client:AnswerCall', Ply.PlayerData.source)
    end
end)

RegisterServerEvent('qb-phone:server:SaveMetaData')
AddEventHandler('qb-phone:server:SaveMetaData', function(MData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    exports.oxmysql:execute('SELECT * FROM `players` WHERE `citizenid` = ? LIMIT 1', { Player.PlayerData.citizenid }, function(result)
        local MetaData = json.decode(result[1].metadata)
        MetaData.phone = MData
        exports.oxmysql:execute('UPDATE `players` SET `metadata` = ? WHERE `citizenid` = ?', { json.encode(MetaData), Player.PlayerData.citizenid })
    end)    

    Player.Functions.SetMetaData("phone", MData)
end)

function escape_sqli(source)
    local replacements = { ['"'] = '\\"', ["'"] = "\\'" }
    return source:gsub( "['\"]", replacements ) -- or string.gsub( source, "['\"]", replacements )
end

QBCore.Functions.CreateCallback('qb-phone:server:FetchResult', function(source, cb, search)
    local src = source
    local search = escape_sqli(search)
    local searchData = {}
    local ApaData = {}

    local query = 'SELECT * FROM `players` WHERE `citizenid` = "'..search..'"'
    -- Split on " " and check each var individual
    local searchParameters = SplitStringToArray(search)
    
    -- Construct query dynamicly for individual parm check
    if #searchParameters > 1 then
        query = query .. ' OR `charinfo` LIKE "%'..searchParameters[1]..'%"'
        for i = 2, #searchParameters do
            query = query .. ' AND `charinfo` LIKE  "%' .. searchParameters[i] ..'%"'
        end
    else
        query = query .. ' OR `charinfo` LIKE "%'..search..'%"'
    end
    
    exports.oxmysql:execute(query, function(result)
        exports.oxmysql:fetch('SELECT * FROM `apartments`', {}, function(ApartmentData)
            for k, v in pairs(ApartmentData) do
                ApaData[v.citizenid] = ApartmentData[k]
            end

            if result[1] ~= nil then
                for k, v in pairs(result) do
                    local charinfo = json.decode(v.charinfo)
                    local metadata = json.decode(v.metadata)
                    local appiepappie = {}
                    if ApaData[v.citizenid] ~= nil and next(ApaData[v.citizenid]) ~= nil then
                        appiepappie = ApaData[v.citizenid]
                    end
                    table.insert(searchData, {
                        citizenid = v.citizenid,
                        firstname = charinfo.firstname,
                        lastname = charinfo.lastname,
                        birthdate = charinfo.birthdate,
                        phone = charinfo.phone,
                        nationality = charinfo.nationality,
                        gender = charinfo.gender,
                        warrant = false,
                        driverlicense = metadata["licences"]["driver"],
                        appartmentdata = appiepappie,
                    })
                end
                cb(searchData)
            else
                cb(nil)
            end
        end)
    end)
end)

function SplitStringToArray(string)
    local retval = {}
    for i in string.gmatch(string, "%S+") do
        table.insert(retval, i)
    end
    return retval
end

QBCore.Functions.CreateCallback('qb-phone:server:GetVehicleSearchResults', function(source, cb, search)
    local src = source
    local search = escape_sqli(search)
    local searchData = {}
    exports.oxmysql:fetch('SELECT * FROM `player_vehicles` WHERE `plate` LIKE "%'..search..'%" OR `citizenid` = "'..search..'"', function(result)
        if result[1] ~= nil then
            for k, v in pairs(result) do
                exports.oxmysql:fetch('SELECT * FROM `players` WHERE `citizenid` = ?', {result[k].citizenid}, function(player)
                    if player[1] ~= nil then 
                        local charinfo = json.decode(player[1].charinfo)
                        local vehicleInfo = QBCore.Shared.Vehicles[result[k].vehicle]
                        if vehicleInfo ~= nil then 
                            table.insert(searchData, {
                                plate = result[k].plate,
                                status = true,
                                owner = charinfo.firstname .. " " .. charinfo.lastname,
                                citizenid = result[k].citizenid,
                                label = vehicleInfo["name"]
                            })
                        else
                            table.insert(searchData, {
                                plate = result[k].plate,
                                status = true,
                                owner = charinfo.firstname .. " " .. charinfo.lastname,
                                citizenid = result[k].citizenid,
                                label = "Name not found.."
                            })
                        end
                    end
                end)
            end
        else
            if GeneratedPlates[search] ~= nil then
                table.insert(searchData, {
                    plate = GeneratedPlates[search].plate,
                    status = GeneratedPlates[search].status,
                    owner = GeneratedPlates[search].owner,
                    citizenid = GeneratedPlates[search].citizenid,
                    label = "Brand unknown.."
                })
            else
                local ownerInfo = GenerateOwnerName()
                GeneratedPlates[search] = {
                    plate = search,
                    status = true,
                    owner = ownerInfo.name,
                    citizenid = ownerInfo.citizenid,
                }
                table.insert(searchData, {
                    plate = search,
                    status = true,
                    owner = ownerInfo.name,
                    citizenid = ownerInfo.citizenid,
                    label = "Brand unknown.."
                })
            end
        end
        cb(searchData)
    end)
end)

QBCore.Functions.CreateCallback('qb-phone:server:ScanPlate', function(source, cb, plate)
    local src = source
    local vehicleData = {}
    if plate ~= nil then 
        exports.oxmysql:fetch('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
            if result[1] ~= nil then
                exports.oxmysql:fetch('SELECT * FROM `players` WHERE `citizenid` = ?', { result[1].citizenid }, function(player)
                    local charinfo = json.decode(player[1].charinfo)
                    vehicleData = {
                        plate = plate,
                        status = true,
                        owner = charinfo.firstname .. " " .. charinfo.lastname,
                        citizenid = result[1].citizenid,
                    }
                end)
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
        end)
    else
        TriggerClientEvent('QBCore:Notify', src, "Yakınlarda bir araç yok", "error")
        cb(nil)
    end
end)

function GenerateOwnerName()
    local names = {
        [1] = { name = "Jan Bloksteen", citizenid = "DSH091G93" },
        [2] = { name = "Jay Dendam", citizenid = "AVH09M193" },
        [3] = { name = "Ben Klaariskees", citizenid = "DVH091T93" },
        [4] = { name = "Karel Bakker", citizenid = "GZP091G93" },
        [5] = { name = "Klaas Adriaan", citizenid = "DRH09Z193" },
        [6] = { name = "Nico Wolters", citizenid = "KGV091J93" },
        [7] = { name = "Mark Hendrickx", citizenid = "ODF09S193" },
        [8] = { name = "Bert Johannes", citizenid = "KSD0919H3" },
        [9] = { name = "Karel de Grote", citizenid = "NDX091D93" },
        [10] = { name = "Jan Pieter", citizenid = "ZAL0919X3" },
        [11] = { name = "Huig Roelink", citizenid = "ZAK09D193" },
        [12] = { name = "Corneel Boerselman", citizenid = "POL09F193" },
        [13] = { name = "Hermen Klein Overmeen", citizenid = "TEW0J9193" },
        [14] = { name = "Bart Rielink", citizenid = "YOO09H193" },
        [15] = { name = "Antoon Henselijn", citizenid = "QBC091H93" },
        [16] = { name = "Aad Keizer", citizenid = "YDN091H93" },
        [17] = { name = "Thijn Kiel", citizenid = "PJD09D193" },
        [18] = { name = "Henkie Krikhaar", citizenid = "RND091D93" },
        [19] = { name = "Teun Blaauwkamp", citizenid = "QWE091A93" },
        [20] = { name = "Dries Stielstra", citizenid = "KJH0919M3" },
        [21] = { name = "Karlijn Hensbergen", citizenid = "ZXC09D193" },
        [22] = { name = "Aafke van Daalen", citizenid = "XYZ0919C3" },
        [23] = { name = "Door Leeferds", citizenid = "ZYX0919F3" },
        [24] = { name = "Nelleke Broedersen", citizenid = "IOP091O93" },
        [25] = { name = "Renske de Raaf", citizenid = "PIO091R93" },
        [26] = { name = "Krisje Moltman", citizenid = "LEK091X93" },
        [27] = { name = "Mirre Steevens", citizenid = "ALG091Y93" },
        [28] = { name = "Joosje Kalvenhaar", citizenid = "YUR09E193" },
        [29] = { name = "Mirte Ellenbroek", citizenid = "SOM091W93" },
        [30] = { name = "Marlieke Meilink", citizenid = "KAS09193" },
    }
    return names[math.random(1, #names)]
end

QBCore.Functions.CreateCallback('qb-phone:server:GetGarageVehicles', function(source, cb)

    local Player = QBCore.Functions.GetPlayer(source)
    local Vehicles = {}

    exports.oxmysql:execute("SELECT * FROM player_vehicles WHERE citizenid = @citizenid", {
        ["@citizenid"] = Player.PlayerData.citizenid
    }, function(result)
        if result[1] ~= nil then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

QBCore.Functions.CreateCallback('qb-phone:server:HasPhone', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if Player ~= nil then
        local HasPhone = Player.Functions.GetItemByName("phone")
        local retval = false

        if HasPhone ~= nil then
            cb(true)
        else
            cb(false)
        end
    end
end)

QBCore.Functions.CreateCallback('qb-phone:server:CanTransferMoney', function(source, cb, amount, iban)
    local Player = QBCore.Functions.GetPlayer(source)

    if (Player.PlayerData.money.bank - amount) >= 0 then
        exports.oxmysql:execute('SELECT * FROM `players` WHERE `charinfo` LIKE "%' .. iban .. '%"', function(result)
            if result[1] ~= nil then
                local Reciever = QBCore.Functions.GetPlayerByCitizenId(result[1].citizenid)

                Player.Functions.RemoveMoney('bank', amount)

                if Reciever ~= nil then
                    Reciever.Functions.AddMoney('bank', amount)
                else
                    local RecieverMoney = json.decode(result[1].money)
                    RecieverMoney.bank = (RecieverMoney.bank + amount)
                    exports.oxmysql:execute('UPDATE `players` SET `money` = "' .. json.encode(RecieverMoney) .. '" WHERE `citizenid` = "' .. result[1].citizenid .. '"')
                end
                cb(true)
            else
                TriggerClientEvent('QBCore:Notify', src, "Böyle bir hesap yok", "error")
                cb(false)
            end
        end)
    end
end)

RegisterServerEvent('qb-phone:server:GiveContactDetailsTest')
AddEventHandler('qb-phone:server:GiveContactDetailsTest', function(PlayerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    local SuggestionData = {
        name = {
            [1] = Player.PlayerData.charinfo.firstname,
            [2] = Player.PlayerData.charinfo.lastname
        },
        number = Player.PlayerData.charinfo.phone,
        bank = Player.PlayerData.charinfo.account
    }

    TriggerClientEvent('qb-phone:client:AddNewSuggestion', sr, SuggestionData)
end)

RegisterServerEvent('qb-phone:server:GiveContactDetails')
AddEventHandler('qb-phone:server:GiveContactDetails', function(PlayerId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    local SuggestionData = {
        name = {
            [1] = Player.PlayerData.charinfo.firstname,
            [2] = Player.PlayerData.charinfo.lastname
        },
        number = Player.PlayerData.charinfo.phone,
        bank = Player.PlayerData.charinfo.account
    }

    TriggerClientEvent('qb-phone:client:AddNewSuggestion', PlayerId, SuggestionData)
end)

RegisterServerEvent('qb-phone:server:AddTransaction')
AddEventHandler('qb-phone:server:AddTransaction', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    exports.oxmysql:execute('INSERT INTO `crypto_transactions` (`citizenid`, `title`, `message`) VALUES ("' .. Player.PlayerData.citizenid .. '", "' .. oxmysql.escape_string(data.TransactionTitle) .. '", "' .. oxmysql.escape_string(data.TransactionMessage) .. '")')
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetCurrentLawyers', function(source, cb)
    local Lawyers = {}
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then
            if Player.PlayerData.job.name == "lawyer" then
                table.insert(Lawyers, {
                    name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                    phone = Player.PlayerData.charinfo.phone,
                })
            end
        end
    end
    cb(Lawyers)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetCurrentTow', function(source, cb)
    local tow = {}
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then
            if Player.PlayerData.job.name == "tow" then
                table.insert(tow, {
                    name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                    phone = Player.PlayerData.charinfo.phone,
                })
            end
        end
    end
    cb(tow)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetCurrentMech', function(source, cb)
    local mech = {}
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then
            if Player.PlayerData.job.name == "mechanic" then
                table.insert(mech, {
                    name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                    phone = Player.PlayerData.charinfo.phone,
                })
            end
        end
    end
    cb(mech)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetCurrentTaxi', function(source, cb)
    local taxi = {}
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then
            if Player.PlayerData.job.name == "taxi" then
                table.insert(taxi, {
                    name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                    phone = Player.PlayerData.charinfo.phone,
                })
            end
        end
    end
    cb(taxi)
end)

RegisterServerCallback('GetCurrentArrests', function(source, cb)
    exports.oxmysql:execute('SELECT * FROM `epc_bolos` ORDER BY `id` ASC', function(result)
        cb(result)
    end)
end)

RegisterServerEvent('qb-phone:server:InstallApplication')
AddEventHandler('qb-phone:server:InstallApplication', function(ApplicationData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.PlayerData.metadata["phonedata"].InstalledApps[ApplicationData.app] = ApplicationData
    Player.Functions.SetMetaData("phonedata", Player.PlayerData.metadata["phonedata"])

    -- TriggerClientEvent('qb-phone:RefreshPhone', src)
end)

RegisterServerEvent('qb-phone:server:RemoveInstallation')
AddEventHandler('qb-phone:server:RemoveInstallation', function(App)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.PlayerData.metadata["phonedata"].InstalledApps[App] = nil
    Player.Functions.SetMetaData("phonedata", Player.PlayerData.metadata["phonedata"])

    -- TriggerClientEvent('qb-phone:RefreshPhone', src)
end)

RegisterServerEvent("vlast-phone:transferVehicle")
AddEventHandler("vlast-phone:transferVehicle", function(data, player)
    xPlayer = QBCore.Functions.GetPlayer(source)
    tPlayer = QBCore.Functions.GetPlayer(player)
    exports.oxmysql:execute("SELECT * FROM player_vehicles WHERE plate = @plate", {
        ["@plate"] = tostring(data)
    }, function(resultssss)
        if resultssss[1] ~= nil then
            if resultssss[1].citizenid ~= xPlayer.PlayerData.citizenid then 
                TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, "Bu aracın sahibi sen değilsin akıllı bıdık!", "error")
            else
                exports.oxmysql:execute("SELECT * FROM players WHERE citizenid = @citizenid", {
                    ["@citizenid"] = tPlayer.PlayerData.citizenid
                }, function(results)
                    if results[1] ~= nil then
                        toPlayer = QBCore.Functions.GetPlayerByCitizenId(results[1].citizenid)
                        exports.oxmysql:execute("UPDATE player_vehicles SET citizenid = @citizenid, steam = @steam WHERE plate = @plate ",{
                            ["@citizenid"] = tostring(results[1].citizenid),
                            ["@steam"] = tostring(results[1].steam),
                            ["@plate"] = tostring(data),
                        }, function(result)
                        if toPlayer ~= nil then
                            TriggerClientEvent('QBCore:Notify', toPlayer.PlayerData.source, data .. " Plakalı araç artık sizin", "inform")
                        end
                         TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, data .. " Plakalı aracı transfer ettiniz", "error")
                         TriggerClientEvent("vlast-phone:refresh", xPlayer.PlayerData.source)
                         end)
                     end
                 end)
            end
        else
            TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, "Bu plakaya sahip bir araç yok!", "error")
        end
    end)
end)



QBCore.Functions.CreateCallback('qb-phone:server:GetPlayerHouses', function(source, cb)
    local player = QBCore.Functions.GetPlayer(source)
    exports.oxmysql:execute("SELECT * FROM players WHERE citizenid = @citizenid", {['@citizenid'] = player.PlayerData.citizenid}, function(result)
        local house = result[1].house
        if house ~= nil then
            local xd = json.decode(house)
            cb(xd.houseId)
        else
            cb(nil)
        end
    end)
end)

QBCore.Functions.CreateCallback('qb-phone:server:GetCurrentFoodWorker', function(source, cb, jobName)
    local workers = {}
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local character = GetCharacter(v)
        local xPlayer = QBCore.Functions.GetPlayer(v)
        if xPlayer ~= nil then
            if xPlayer.PlayerData.job.name == jobName then
                table.insert(workers, {
                    name = character.firstname .. " " ..character.lastname,
                    setjob = jobName,
                    phone = character.phone,
                })
            end
        end
    end
    cb(workers)
end)

QBCore.Functions.CreateCallback('qb-phone:server:SavePhoto', function(source, cb, url, data)
    local source = source
    local player = QBCore.Functions.GetPlayer(source)
    local data = json.encode(data)

    exports.oxmysql:execute("INSERT INTO `phone_photos` (`citizenid`, `url`, `data`) VALUES ('"..player.PlayerData.citizenid.."', '"..url.."', '"..data.."') RETURNING id, created_at;", nil,
    function(result)
        cb(result[1].id, player.PlayerData.citizenid, result[1].created_at)       
    end)
end)

RegisterServerEvent('qb-phone:server:DeletePhoto')
AddEventHandler('qb-phone:server:DeletePhoto', function(id)
    local player = QBCore.Functions.GetPlayer(source)
    exports.oxmysql:execute('DELETE FROM `phone_photos` WHERE `citizenid` = "' .. player.PlayerData.citizenid .. '" AND `id` = ' .. id)
end)