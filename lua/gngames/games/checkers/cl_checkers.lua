local GAME = {
    settings = {
        background_rounded_radius = 0,
        background_color = GNLib.Colors.WetAsphalt,
    }
}

local PAWN = {
    WHITE = 1,
    BLACK = 2,
    Colors = {
        GNLib.Colors.Clouds,
        GNLib.Colors.Alizarin,
    },
    ColorsHover = {
        GNLib.Colors.Silver,
        GNLib.Colors.Pomegranate,
    },
}

local DIRECTION = {
    TOP_LEFT = 1,
    TOP_RIGHT = 2,
    BOTTOM_LEFT = 3,
    BOTTOM_RIGHT = 4,
}

--  > Game related functions
function GAME:getPawnAt( x, y )
    if not self.pions then return end
    
    for id, pawn in pairs( self.pions ) do
        if pawn.x == x and pawn.y == y then return pawn, id end
    end
end

function GAME:getDirectionFromPos( start_x, start_y, new_x, new_y )
    if start_x > new_x then
        if start_y > new_y then
            return DIRECTION.TOP_LEFT
        else
            return DIRECTION.BOTTOM_LEFT
        end
    else
        if start_y > new_y then
            return DIRECTION.TOP_RIGHT
        else
            return DIRECTION.BOTTOM_RIGHT
        end
    end
end

function GAME:getPosFromDirection( dir, x, y )
    local new_x, new_y = x or 0, y or 0

    if dir == DIRECTION.TOP_LEFT then
        new_x = new_x - 1
        new_y = new_y - 1
    elseif dir == DIRECTION.TOP_RIGHT then
        new_x = new_x + 1
        new_y = new_y - 1
    elseif dir == DIRECTION.BOTTOM_LEFT then
        new_x = new_x - 1
        new_y = new_y + 1
    elseif dir == DIRECTION.BOTTOM_RIGHT then
        new_x = new_x + 1
        new_y = new_y + 1
    end

    return new_x, new_y
end

function GAME:getSelfTeam()
    return self.party.owner == LocalPlayer() and PAWN.WHITE or PAWN.BLACK
end

function GAME:getOtherTeam()
    return self.party.owner == LocalPlayer() and PAWN.BLACK or PAWN.WHITE
end

function GAME:drawPath( dir )
    --  > don't draw if we didn't selected a pawn
    if not self.selected_pawn then return end

    --  > don't draw if we can't find a valid pawn
    local pawn = self.pions[ self.selected_pawn ]
    if not pawn then return end

    --  > get position from dir
    dx, dy = self:getPosFromDirection( dir )

    --  > check if we can capture a pawn
    local target_pawn = self:getPawnAt( pawn.x + dx, pawn.y + dy )
    if target_pawn and not ( target_pawn.team == pawn.team ) then
        --  > change position to next position
        dx, dy = self:getPosFromDirection( dir, dx, dy )
    end
    
    --  > draw position
    GNLib.DrawCircle( ( pawn.x + 0.5 + dx ) * self.grid_size, ( pawn.y + 0.5 + dy ) * self.grid_size, self.grid_size * 0.355, nil, nil, ColorAlpha( GNLib.Colors.GreenSea, math.abs( math.sin( CurTime() * 1.5 ) ) * 180 + 20 ) )
end

--  > Game events
function GAME:load( game_panel )
    local game = self

    game.countdown = 0
    game.pions = {}
    game.selected_pawn = 0
    game.wins = { 0, 0 }

    local grid_button = game_panel:Add( "DButton" )
        grid_button:SetSize( game_panel:GetWide() / 2.5, game_panel:GetWide() / 2.5 )
        grid_button:Center()

        local color_black = Color( 0, 0, 0 )

        local grid_size = math.ceil( grid_button:GetWide() / 8 )
        game.grid_size = grid_size
        function grid_button:Paint( w, h )
            --  > draw grid
            for x = 0, w, grid_size do
                for y = 0, h, grid_size do
                    draw.RoundedBox( 0, x, y, grid_size, grid_size, ( 1 - ( x - y ) / grid_size % 2 == 0 and GNLib.Colors.Clouds or GNLib.Colors.MidnightBlue ) )
                end
            end

            --  > draw moves
            if game.selected_pawn ~= 0 then
                local pawn = game.pions[ game.selected_pawn ]

                if pawn then
                    local is_black = pawn.team == PAWN.BLACK
                    
                    if pawn.queen then
                        game:drawPath( is_black and DIRECTION.BOTTOM_RIGHT or DIRECTION.TOP_RIGHT ) -- RIGHT
                        game:drawPath( is_black and DIRECTION.BOTTOM_LEFT or DIRECTION.TOP_LEFT ) -- LEFT
                    end
                    
                    game:drawPath( is_black and DIRECTION.TOP_RIGHT or DIRECTION.BOTTOM_RIGHT) -- RIGHT
                    game:drawPath( is_black and DIRECTION.TOP_LEFT or DIRECTION.BOTTOM_LEFT ) -- LEFT
                end
            end

            --  > draw pions
            local anim_speed = 5
            for id, pawn in pairs( game.pions ) do
                --  > update position (move animation)
                pawn.last_x = Lerp( FrameTime() * anim_speed, pawn.last_x, pawn.x )
                pawn.last_y = Lerp( FrameTime() * anim_speed, pawn.last_y, pawn.y )

                --  > die animation
                if pawn.alpha then
                    if pawn.alpha <= 1 then
                        --  > die
                        game.pions[id] = nil
                        continue
                    end 
                    pawn.alpha = Lerp( FrameTime() * anim_speed, pawn.alpha, 0 )
                end

                --  > draw pawn
                GNLib.DrawCircle( ( pawn.last_x + 0.5 ) * grid_size, ( pawn.last_y + 0.5 ) * grid_size, grid_size * 0.4, nil, nil, ColorAlpha( color_black, pawn.alpha or 255 ) )
                GNLib.DrawCircle( ( pawn.last_x + 0.5 ) * grid_size, ( pawn.last_y + 0.5 ) * grid_size, grid_size * 0.355, nil, nil, ColorAlpha( game.selected_pawn == id and GNLib.LerpColor( math.abs( math.cos( CurTime() * 2 ) ), PAWN.Colors[ pawn.team ], PAWN.ColorsHover[ pawn.team ] ) or PAWN.Colors[ pawn.team ], pawn.alpha or 255 ) )
            
                --  > queen draw
                if pawn.queen then
                    GNLib.DrawCircle( ( pawn.last_x + 0.5 ) * grid_size, ( pawn.last_y + 0.5 ) * grid_size, grid_size * 0.2, nil, nil, ColorAlpha( game.selected_pawn == id and GNLib.LerpColor( math.abs( math.cos( CurTime() * 2 ) ), PAWN.ColorsHover[ pawn.team ], PAWN.Colors[ pawn.team ] ) or PAWN.ColorsHover[ pawn.team ], pawn.alpha or 255 ) )
                end
            end

            return true
        end
        function grid_button:DoClick()
            local mouse_x, mouse_y = self:LocalCursorPos()
            local grid_x, grid_y = math.ceil( mouse_x / grid_size ) - 1, math.ceil( mouse_y / grid_size ) - 1

            --  > check if we don't click on a pawn
            local pawn, pawn_id = game:getPawnAt( grid_x, grid_y )
            if not pawn or not pawn_id then 
                --  > if no pawn then, try to move our selected pawn (if exists)
                if game.selected_pawn then
                    local selected_pawn = game.pions[game.selected_pawn]
                    if not selected_pawn then return end

                    local dir = game:getDirectionFromPos( selected_pawn.x, selected_pawn.y, grid_x, grid_y )
                    game:send( { event = ( "pawn %d %d" ):format( game.selected_pawn, dir ) } )

                    game.selected_pawn = 0
                end
                return 
            end

            --  > select a pawn
            if #game.players > 1 and pawn.team == game:getOtherTeam() then return end
            if #game.players > 1 and game.turn == game:getOtherTeam() then return end
            game.selected_pawn = pawn_id
        end

    --  > Players' avatars
    local avatar_self = game_panel:Add( "GNImage" )
        avatar_self:SetAvatar( LocalPlayer(), 128 )
        avatar_self:SetSize( 128, 128 )
        avatar_self:SetPos( 25, 25 )
        avatar_self:SetCircle( true )

    local avatar_opponent = game_panel:Add( "GNImage" )
        avatar_opponent:SetAvatar( LocalPlayer() == self.party.owner and self.players[2] or self.players[1], 128 )
        avatar_opponent:SetSize( 128, 128 )
        avatar_opponent:SetPos( game_panel:GetWide() - avatar_opponent:GetWide() - 25, 25 )
        avatar_opponent:SetCircle( true )

    --  > Surrender
    local surrender = game_panel:Add( "GNButton" )
        surrender:SetText( "Surrender" )
        surrender:SetFont( "GNLFontB20" )
        surrender:SetPos( game_panel:GetWide() / 2 - surrender:GetWide() / 2, game_panel:GetTall() - surrender:GetTall() * 3 )
        surrender:SetColor( PAWN.Colors[ game:getSelfTeam() ] )
        surrender:SetHoveredColor( PAWN.ColorsHover[ game:getSelfTeam() ] )
        function surrender:DoClick()
            game:send( { event = "surrender" } )
        end
end

function GAME:update( dt )
    if self.countdown <= 0 then return end

    self.countdown = self.countdown - dt
end

function GAME:receive( payload )
    local event = payload.event
    if not event then return end

    if event:StartWith( "pawn" ) then
        local id, x, y, team, queen = event:match( "^%w+ (%d+) (%d+) (%d+) (%d+) (%d+)" )

        --  > convert to number (else index failed cause of string values)
        id, x, y, team, queen = tonumber( id ), tonumber( x ), tonumber( y ), tonumber( team ), tobool( queen )
        if not id or not x or not y or not team or queen == nil then return end

        local last_pawn = self.pions[id] or {}
        self.pions[id] = {
            x = x,
            y = y,
            last_x = last_pawn.x or ( x < 7 / 2 and 0 - 3 or 7 + 3 ),
            last_y = last_pawn.y or ( team == PAWN.WHITE and 0 - 3 or 7 + 3 ),
            team = team,
            queen = queen,
        }
    elseif event:StartWith( "eat" ) then
        local id = tonumber( event:match( "^%w+ (%d+)" ) )
        if not id then return end

        --  > start alpha transition (die animation)
        self.pions[id].alpha = 255
    elseif event:StartWith( "turn" ) then
        self.turn = tonumber( event:match( "^%w+ (%d+)" ) )

        self.selected_pawn = 0
    elseif event:StartWith( "wins" ) then
        local win1, win2 = event:match( "^%w+ (%d+) (%d+)")
        win1, win2 = tonumber( win1 ), tonumber( win2 )
        if not win1 or not win2 then return end

        self.wins = { win1, win2 }
    elseif event:StartWith( "countdown" ) then
        self.countdown = tonumber( event:match( "^%w+ (%d+)" ) )
    elseif event:StartWith( "win" ) then
        self.winner = tonumber( event:match( "^%w+ (%d+)" ) )
    end
end

local thickness = 8
function GAME:draw( w, h )
    local other_name = LocalPlayer() == self.party.owner and self.players_names[2] or self.players_names[1]

    --  > Drawing background + players' names
    local center = 25 + 64
    GNLib.DrawCircle( center, center, 64 + thickness, nil, nil, PAWN.Colors[self:getSelfTeam()] )
    GNLib.SimpleTextShadowed( LocalPlayer():Name(), "GNLFontB40", center * 1.9, center * 0.5, PAWN.Colors[self:getSelfTeam()], TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, 2, nil )
        GNLib.SimpleTextShadowed( self.wins[self:getSelfTeam()] .. " wins", "GNLFontB20", center * 2.1, center, PAWN.Colors[self:getSelfTeam()], TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, 2, nil )

    GNLib.DrawCircle( w - 25 - 64, 25 + 64, 64 + thickness, nil, nil, PAWN.Colors[self:getOtherTeam()] )
    GNLib.SimpleTextShadowed( other_name, "GNLFontB40", w - center * 1.9, center * 0.5, PAWN.Colors[self:getOtherTeam()], TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 2, 2, nil )
        GNLib.SimpleTextShadowed( self.wins[self:getOtherTeam()] .. " wins", "GNLFontB20", w - center * 2.1, center, PAWN.Colors[self:getOtherTeam()], TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 2, 2, nil )

    if self.turn and self.countdown <= 0 then
        GNLib.SimpleTextShadowed( "It's " .. ( self.turn == self:getSelfTeam() and LocalPlayer():Name() or other_name ) .. "'s turn", "GNLFontB40", w / 2, center * 0.5, PAWN.Colors[ self.turn ], TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, 2, nil )
    end

    --  > Draw the countdown
    if self.countdown <= 0 or not self.winner then return end

    GNLib.SimpleTextShadowed( self.draw_end and "Draw" or ( ( self.winner == self:getSelfTeam() and LocalPlayer():Name() or other_name ) .. " wins." ), "GNLFontB40", w / 2, 64, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, 2, nil )
    GNLib.SimpleTextShadowed( "Restarting in " .. math.ceil( self.countdown ) .. "s", "GNLFontB20", w / 2, 64 + 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, 2, nil )
end

GNGames.CreateGame( "Checkers", GAME )