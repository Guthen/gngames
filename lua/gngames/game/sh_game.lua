GNGames.Games = GNGames.Games or {}

function GNGames.CreateGame( name, tbl )
    local game_tbl = table.Merge( { 
        name = name, 
        settings = {},
    }, tbl )

    GNGames.Games[name] = game_tbl
end


if SERVER then
    util.AddNetworkString( "GNGames:Game" )

    net.Receive( "GNGames:Game", function( len, ply )
        local method = net.ReadString()

        if method == "play" then
            GNGames.StartGame( select( 2, GNGames.FindParty( ply ) ), ply )
        end
    end )

    local parties_in_game = {}
    function GNGames.GetPartyGame( party )
        return parties_in_game[istable( party ) and party.owner:SteamID64() or party]
    end

    function GNGames.StartGame( party, ply )
        if not party then return false end

        --  > check players numbers
        if #party.players < party.game.settings.min_players then GNGames.Notify( ply, party.name, "Not enought players to play" ) return false end

        --  > don't continue if already exists and started 
        local party_game = GNGames.GetPartyGame( party )
        if party_game and party_game.started then return false end

        --  > if not starteed then connect player
        if party_game and not party_game.started then
            party_game.game:onPlayerConnect( ply )
            return false
        end

        --  > add game to list + launch game
        local game_tbl = {
            party = party,
            game = GNGames.InstantiateGame( party.game.name ),
            started = false,
        }
        game_tbl.game.party = party
        game_tbl.game.players = party.players
        game_tbl.game:load()
        game_tbl.game:onPlayerConnect( ply )

        --  > notify all players that game is ready
        GNGames.Notify( party.players, party.name, "The game is ready to start !" )

        parties_in_game[ party.owner:SteamID64() ] = game_tbl

        return true
    end

    hook.Add( "GNGames:OnDisbandParty", "GNGames:RemovePartiesInGame", function( ply )
        parties_in_game[ply:SteamID64()] = nil
    end )
end

--  > Hooks handle

local function player_disconnect( ply, party )
    local party_id = party or GNGames.FindParty( ply )
    if not party_id then return end
    
    local party_game = GNGames.GetPartyGame( party_id )
    if not party_game then return end

    --  > Handle players of the game
    for i, v in pairs( party_game.game.players ) do
        if v == ply then
            party_game.game.players[ i ] = nil
        else
            GNGames.Notify( v, party.name, ply:Name() .. " disconnected !" )
        end 
    end
        
    --  > Call event 
    party_game.game:onPlayerDisconnect( ply )
end
hook.Add( "PlayerDisconnected", "GNGames:DisconnectOfGame", player_disconnect )
hook.Add( "GNGames:OnQuitParty", "GNGames:DisconnectOfGame", player_disconnect )