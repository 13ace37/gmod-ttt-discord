--[[
	Copyright 2022 Riccardo "ace" H.

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]] --[[
	Convars
]] --
CreateConVar("discordbot_host", "localhost", FCVAR_ARCHIVE, "Webserver endpoint address")
CreateConVar("discordbot_port", "31008", FCVAR_ARCHIVE, "Webserver endpoint port")
CreateConVar("discordbot_name", "Discord Sync", FCVAR_ARCHIVE, "Plugin Prefix")

--[[
	GET request to server
]]

function GET(req, params, callback)

    requestAddress = ("http://" .. GetConVar("discordbot_host"):GetString() .. ":" ..
                         GetConVar("discordbot_port"):GetString())

    -- Create web get request to web server
    http.Fetch(requestAddress, -- got data from server
    function(result)

        callback(util.JSONToTable(result))

    end, -- request to server failed
    function(error)

        print("[" .. GetConVar("discordbot_name"):GetString() .. "] Failed to send data to server!")
        print("Error: " .. error)

    end, -- request headers
    {
        req = req,
        params = util.TableToJSON(params)
    })

end

--[[
	Util Functions
]]

function commonRoundState()
    if gmod.GetGamemode().Name == "Trouble in Terrorist Town" or gmod.GetGamemode().Name == "TTT2 (Advanced Update)" then
        -- Round state 3 => Game is running
        return ((GetRoundState() == 3) and 1 or 0)
    end

    if gmod.GetGamemode().Name == "Murder" then
        -- Round state 1 => Game is running
        return ((gmod.GetGamemode():GetRound() == 1) and 1 or 0)
    end

    -- Round state could not be determined
    return -1
end

--[[
	Logic Functions
]]

tempMutedPlayers = {}
function isPlayerMuted(player)
    return tempMutedPlayers[player]
end

-- Mute Player
function mutePlayer(player)

    if not player then
        return
    end
    if not player:GetPData("discord_id") then
        return
    end
    if isPlayerMuted(player) then
        return
    end

    GET("mute", {
        mute = true,
        id = player:GetPData("discord_id")
    }, function(result)

        if not result then
            return
        end

        if result.success then
            player:PrintMessage(HUD_PRINTCENTER, "[" .. GetConVar("discordbot_name"):GetString() ..
                "] Stell dir vor man stirbt an Traitorfallen - Du bist jetzt im Discord mute :^) - also psst")
            tempMutedPlayers[player] = true
        end

    end)

end

-- Unmute Player
function unmutePlayer(player)

    -- if unmutePlayer() => loop for each user and check if one is note muted => unmute
    if not player then
        for player, muted in pairs(tempMutedPlayers) do
            if muted then
                unmutePlayer(player)
            end
        end
        return
    end

    if not IsValid(player) then
        return
    end

    if not player:GetPData("discord_id") then
        return
    end
    if not isPlayerMuted(player) then
        return
    end

    GET("mute", {
        mute = false,
        id = player:GetPData("discord_id")
    }, function(result)

        if not result then
            return
        end

        if result.success then
            player:PrintMessage(HUD_PRINTCENTER, "[" .. GetConVar("discordbot_name"):GetString() ..
                "] Leider kann man jetzt deine drecks Stimme wieder hören ._.")
            tempMutedPlayers[player] = false
        end

    end)

end

-- Move Player to channel
function movePlayer(player)

    if not player:GetPData("discord_id") then
        return
    end

    GET("move", {
        id = player:GetPData("discord_id")
    }, function(result)
    end)

end

-- Link Player - Steam <=> Discord
function linkPlayer(player, tag)

    GET("connect", {
        tag = tag
    }, function(result)

        -- error can't link - either too many users found with same "tag" or no user found
        if result.answer == 0 then
            player:PrintMessage(HUD_PRINTTALK, "[" .. GetConVar("discordbot_name"):GetString() ..
                "] Keine User mit dem eingegebenen Tag gefunden!")
        elseif result.answer == 1 then
            player:PrintMessage(HUD_PRINTTALK, "[" .. GetConVar("discordbot_name"):GetString() ..
                "] Mehrere User mit dem eingegebenen Tag gefunden!")
        end

        -- success can link - found only one user with provided tag
        if (result.tag and result.id) then
            player:PrintMessage(HUD_PRINTTALK, "[" .. GetConVar("discordbot_name"):GetString() .. "] Cringe wer [" ..
                result.tag .. "]? Als Discord tag hat XD")
            player:SetPData("discord_id", result.id)
            saveDiscordIds()
        end
    end)

end

--[[
	Event Hooks
]]

-- player chat message
hook.Add("PlayerSay", "ttt_discord_bot_PlayerSay", function(player, message)

    if not string.find(message, "^%!discord ") then
        return
    end
    rawMessageTag = string.gsub(message, "^%!discord ", "")

    rawMessageTagUTF8 = ""
    for _, code in utf8.codes(rawMessageTag) do
        rawMessageTagUTF8 = string.Trim(rawMessageTagUTF8 .. " " .. code)
    end

    linkPlayer(player, rawMessageTagUTF8)

end)

-- player spawned for first time
hook.Add("PlayerInitialSpawn", "ttt_discord_bot_PlayerInitialSpawn", function(player)
    if (player:GetPData("discord_id")) then
        player:PrintMessage(HUD_PRINTTALK, "[" .. GetConVar("discordbot_name"):GetString() .. "] " .. "OK")
    else
        player:PrintMessage(HUD_PRINTTALK, "[" .. GetConVar("discordbot_name"):GetString() .. "] " ..
            "Mach hier weißt schon, ja hier dings '!discord name' also sowas wie '!discord ace#1337'")
    end
    if (not player:GetPData("steamid")) then
        player:SetPData("steamid", player:SteamID())
    end
end)

-- unmute single hooks

-- spawn of player
hook.Add("PlayerSpawn", "ttt_discord_bot_PlayerSpawn", function(player)
    unmutePlayer(player)
    if not GetConVar("ttt_debug_preventwin"):GetBool() then
        movePlayer(player)
    end
end)

-- disconnect of player
hook.Add("PlayerDisconnected", "ttt_discord_bot_PlayerDisconnected", function(player)
    unmutePlayer(player)
end)

-- unmute all hooks

hook.Add("ShutDown", "ttt_discord_bot_ShutDown", function()
    unmutePlayer()
end)

hook.Add("TTTEndRound", "ttt_discord_bot_TTTEndRound", function()
    timer.Simple(0.5, function()
        unmutePlayer()
    end)
end)

hook.Add("TTTBeginRound", "ttt_discord_bot_TTTBeginRound", function()
    unmutePlayer()
end)

hook.Add("TTTPrepareRound", "ttt_discord_bot_TTTPrepareRound", function()
    unmutePlayer()
end)

hook.Add("OnEndRound", "ttt_discord_bot_OnEndRound", function()
    timer.Simple(0.5, function()
        unmutePlayer()
    end)
end)

hook.Add("OnStartRound", "ttt_discord_bot_OnStartRound", function()
    unmutePlayer()
end)

-- mute player hook
hook.Add("PostPlayerDeath", "ttt_discord_bot_PostPlayerDeath", function(player)
    if (commonRoundState() == 1) then
        mutePlayer(player)
    end
end)
