function GNGames.OpenGame( party )
    if not party or not party.game then return error( "Invalid party object!", 2 ) end
    if IsValid( GNGames.GameUI ) then GNGames.GameUI:Remove() end

    --  > Get game infos
    local GAME = GNGames.InstantiateGame( party.game.name )
    if not GAME then return error( "Invalid game object!", 2 ) end

    GNGames.Party = party
    GNGames.Game = GAME

    --  > Main frame
    local frame = GNLib.CreateFrame( party.game.name, nil, nil, GNLib.Colors.WetAsphalt, GNLib.Colors.MidnightBlue )
        GNGames.GameUI = frame
        function frame:OnRemove()
            GNGames.OpenMatchmaking()
        end

    GAME:start( frame, party )
end

hook.Add( "GNGames:OnDisbandParty", "GNGames:CloseGame", function( owner_id_64 )
    if not GNGames.Party or not IsValid( GNGames.GameUI ) then return end
    if not ( GNGames.Party.owner:SteamID64() == owner_id_64 ) then return end

    GNGames.GameUI:Remove()
end )