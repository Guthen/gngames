local GAME = {}

AccessorFunc( GAME, "name", "Name", FORCE_STRING )
AccessorFunc( GAME, "settings", "Settings" )

function GNGames.InstantiateGame( name )
    local new_game = GNGames.Games[name]
    if not new_game then return end

    return setmetatable( new_game, { __index = GAME } )
end

if CLIENT then
    function GAME:start( frame, party )
        local game = self

        game.party = party
        game.players = party.players

        game.players_names = {}
        for i, ply in ipairs( game.players ) do
            game.players_names[i] = ply:Name()
        end

        local panel = frame:Add( "DPanel" )
            panel:Dock( FILL )
            panel:DockMargin( 5, 5, 5, 5 )
            function panel:Paint( w, h )
                GNLib.DrawStencil( function()
                    GNLib.DrawRoundedRect( game.settings.background_rounded_radius or 6, 0, 0, w, h, color_white )
                end, function()
                    draw.RoundedBox( 0, 0, 0, w, h, game.settings.background_color or Color( 0, 0, 0 ) )

                    game:draw( w, h )
                end )
            end
            function panel:Think()
                game:update( FrameTime() )
            end

            --  > Fix size (cause of Dock)
            local w, h = panel:GetParent():GetSize()
            do 
                local left, top, right, bottom = panel:GetDockMargin()
                w = w - left - right
                h = h - top - bottom
            end
            panel:SetSize( w, h )

        game:load( panel )
    end
end

function GAME:load( panel )
end

function GAME:update( dt )
end

function GAME:draw( w, h )
end

function GAME:onPlayerConnect( ply )
end

function GAME:onPlayerDisconnect( ply )
end

--  > Networking support

if SERVER then
    util.AddNetworkString( "GNGames:SendData" )

    function GAME:send( ply, tbl )
        net.Start( "GNGames:SendData" )
            net.WriteTable( tbl )
        net.Send( ply )
    end

    function GAME:broadcast( tbl )
        self:send( self.party.players, tbl )
    end

    function GAME:receive( ply, data )
        print( "Game data receive by " .. ply:GetName() .. " : " .. #data )
        PrintTable( data )
    end

    net.Receive( "GNGames:SendData", function( len, ply )
        local party = GNGames.GetPartyGame( net.ReadString() )
        if not party then return end

        party.game:receive( ply, net.ReadTable() )
    end )
else
    function GAME:send( tbl )
        net.Start( "GNGames:SendData" )
            net.WriteString( self.party.id )
            net.WriteTable( tbl )
        net.SendToServer()
    end

    function GAME:receive( data )
        print( "Game data receive by server : ", #data )
        PrintTable( data )
    end

    net.Receive( "GNGames:SendData", function( len )
        local GAME = GNGames.Game
        if not GAME then return end

        GAME:receive( net.ReadTable() )
    end )
end

