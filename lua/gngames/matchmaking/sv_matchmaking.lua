GNGames.Parties = GNGames.Parties or {}
local protected = {}

function GNGames.GetPassword( owner_id_64 )
    return protected and protected[ owner_id_64 ]
end

util.AddNetworkString( "GNGames:Matchmaking" )

net.Receive( "GNGames:Matchmaking", function( _, ply )
    local method = net.ReadString()

    if method == "open" then
        GNGames.OpenMatchmaking( ply )
    elseif method == "host" then
        GNGames.CreateParty( ply, net.ReadString(), net.ReadString(), net.ReadString() )
    elseif method == "join" then
        GNGames.JoinParty( ply, net.ReadString(), net.ReadString() )
    elseif method == "disband" then
        GNGames.DisbandParty( ply )
    elseif method == "quit" then
        GNGames.QuitParty( ply, net.ReadString() )
    end
end )

function GNGames.CreateParty( ply, party_name, game_name, password )
    if GNGames.GetParty( ply ) then GNGames.Notify( ply, "Party failed", "You already own a party." ) return false end
    if GNGames.FindParty( ply ) then GNGames.Notify( ply, "Party failed", "You already are in a party." ) return false end
    if not GNGames.Games[game_name] then GNGames.Notify( ply, "Incorrect game", ( game_name or "nil" ) .. " is not a valid game." ) return false end

    GNGames.Parties[ply:SteamID64()] = { 
        name = party_name or ( "%s's party" ):format( ply:GetName() ),
        protected = #password > 0 and true or false,
        game = GNGames.Games[game_name],
        id = ply:SteamID64(),
        players = { ply },
        owner = ply,
    }

    --  > Declaring the password in a local table to avoid stealing
    if #password > 0 and true or false then
        protected[ ply:SteamID64() ] = password
    end

    local party = GNGames.GetParty( ply )
    GNGames.Notify( ply, party.name, "You created a party on " .. game_name )

    GNGames.UpdateMatchmaking()

    hook.Run( "GNGames:OnCreateParty", ply, party )
    return true
end

function GNGames.JoinParty( ply, owner_id_64, password )
    local party = GNGames.GetParty( owner_id_64 )
    if not party then GNGames.Notify( ply, "Error", "This party doesn't exists." ) return false end
    if owner_id_64 == ply:SteamID64() then GNGames.Notify( ply, party.name, "You can't join your own party." ) return false end
    if GNGames.Parties[ ply:SteamID64() ] then GNGames.Notify( ply, party.name, "You can't join a party while having yours." ) return false end
    if GNGames.FindParty( ply ) == party then GNGames.Notify( ply, party.name, "You can't join this party because you are already in." ) return false end
    if #party.players >= ( party.game.settings.max_players or 2 ) then GNGames.Notify( ply, party.name, "This party is full." ) return false end

    --  > Password protection
    if party.protected and ( not password or #password == 0 ) then GNGames.Notify( ply, party.name, "Please specify a password." ) return false end
    if party.protected and not ( protected[ owner_id_64 ] == password ) then GNGames.Notify( ply, party.name, "Wrong password." ) return false end

    --  > Add player to table
    party.players[ #party.players + 1 ] = ply

    GNGames.Notify( ply, party.name, "You joined a party on " .. party.game.name .. "\nHosted by " .. party.owner:GetName() )
    GNGames.Notify( party.owner, party.name, ply:GetName() .. " joined your party." )

    GNGames.UpdateMatchmaking()

    hook.Run( "GNGames:OnJoinParty", ply, party )
    return true
end

function GNGames.QuitParty( ply, owner_id_64 )
    local party = GNGames.GetParty( owner_id_64 )
    if not party then GNGames.Notify( ply, "Error", "This party doesn't exists." ) return false end
    if owner_id_64 == ply:SteamID64() then GNGames.Notify( ply, party.name, "You can't quit your own party." ) return false end
    if not ( select( 2, GNGames.FindParty( ply ) ) == party ) then GNGames.Notify( ply, party.name, "You can't quit this party because you're not in." ) return false end
    
    table.RemoveByValue( GNGames.Parties[ owner_id_64 ].players, ply )

    GNGames.Notify( party.owner, party.name, ply:Name() .. " left your party." )
    GNGames.Notify( ply, party.name, "You left the party." )

    GNGames.UpdateMatchmaking()

    hook.Run( "GNGames:OnQuitParty", ply, GNGames.Parties[ owner_id_64 ] )
    return true
end

function GNGames.DisbandParty( ply )
    local party = GNGames.GetParty( ply )
    if not party then GNGames.Notify( ply, "Error", "You don't own a party." ) return false end

    GNGames.Notify( ply, "Party disbanded", "You disbanded " .. party.name )

    if #party.players > 1 then
        for i, opponent in ipairs( party.players ) do
            if opponent == ply then continue end
            GNGames.Notify( opponent, "Party disbanded", ply:Name() .. " disbanded " .. party.name )
        end
    end

    GNGames.Parties[ply:SteamID64()] = nil

    GNGames.UpdateMatchmaking()

    GNLib.SendHook( nil, "GNGames:OnDisbandParty", ply:SteamID64() )
    hook.Run( "GNGames:OnDisbandParty", ply )
    return true
end

function GNGames.GetParty( ply )
    return GNGames.Parties[isstring( ply ) and ply or ply:SteamID64()]
end

function GNGames.FindParty( ply )
    for owner_id_64, party in pairs( GNGames.Parties ) do
        for i, opponent in ipairs( party.players ) do
            if opponent == ply then return owner_id_64, party end
        end
    end
end

function GNGames.UpdateMatchmaking( ply )
    local parties = table.Copy( GNGames.Parties )

    for id, party in pairs( parties ) do
        party.game = { settings = party.game.settings, name = party.game.name }
    end

    net.Start( "GNGames:Matchmaking" ) 
        net.WriteString( "update" )
        net.WriteTable( parties )
    net.Send( ply or player.GetAll() )
end

function GNGames.OpenMatchmaking( ply )
    local parties = table.Copy( GNGames.Parties )

    for id, party in pairs( parties ) do
        party.game = { settings = party.game.settings, name = party.game.name }
    end

    net.Start( "GNGames:Matchmaking" ) 
        net.WriteString( "open" )
        net.WriteTable( parties )
    net.Send( ply )
end

--  > Concommands

concommand.Add( "gngames_get_all_parties", function()
    for k, v in pairs( GNGames.Parties ) do
        print( "Name: " .. v.name, "Game: " .. v.game, "Password: " .. ( protected[ k ] or "N/A" ), "Owner: " .. v.owner:GetName() )
    end
end )
concommand.Add( "gngames_reset_parties", function()
    GNGames.Parties = {}
end )

concommand.Add( "gngames_force_create_party", function( ply, cmd, args ) 
    for i, v in ipairs( args ) do
        local ent = Entity( v )
        if not ent then continue end

        GNGames.CreateParty( ent, nil, "Battleship", "" )
    end
end )

--  > Hooks
hook.Add( "PlayerDisconnected", "GNGames:PlayerDisconnected", function( ply )
    local party_id = GNGames.FindParty( ply )

    if party_id then
        GNGames.QuitParty( ply, party_id )
    end
end )