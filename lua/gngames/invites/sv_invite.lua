util.AddNetworkString( "GNGames:Invite" )

local invites = {}

net.Receive( "GNGames:Invite", function( _, ply )
    local method = net.ReadString()
    local friend = net.ReadEntity()

    if not friend or not IsValid( friend ) then GNGames.Notify( ply, "Game invitation", "Player is not online." ) return end

    if method == "invite" then
        if not GNGames.Parties[ply:SteamID64()] then GNGames.Notify( ply, "Game invitation", "You need to have a party to invite someone." ) return end
        if GNGames.FindParty( friend ) then GNGames.Notify( ply, "Game invitation", friend:GetName() .. " is already in a party." ) return end

        GNGames.Invite( ply, friend )
    elseif method == "decline" then
        if not IsValid( friend ) then return end

        GNGames.Notify( ply, "Game invitation", "You declined the invitation of " .. friend:GetName() .. "." )
        GNGames.Notify( friend, "Game invitation", ply:GetName() .. " declined your invitation." )
    elseif method == "accept" then
        if not invites[ friend:SteamID64() ] and not ( invites[ friend:SteamID64() ] == ply:SteamID64() ) then return end

        GNGames.JoinParty( ply, friend:SteamID64(), GNGames.GetPassword( friend:SteamID64() ) )

        invites[ ply:SteamID64() ] = nil
    end
end )

function GNGames.Invite( ply, friend )
    invites[ ply:SteamID64() ] = friend:SteamID64()
    
    net.Start( "GNGames:Invite" )
        net.WriteEntity( ply )
    net.Send( friend )

    GNGames.Notify( ply, "Game invitation", "You invited " .. friend:GetName() .. " to your party." )
end