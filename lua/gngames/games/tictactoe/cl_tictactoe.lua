local GAME = {
    settings = {
        background_rounded_radius = 0,
        background_color = GNLib.Colors.GreenSea,
        main_color = GNLib.Colors.Turquoise,
        win_color = GNLib.Colors.Pumpkin,
    }
}

--  > Tick enum
local TICKS = {
    EMPTY = 0,
    CIRCLE = 1,
    CROSS = 2,
}

local function init_grid( game )
    game.grid = {}
    for x = 1, 3 do
        game.grid[x] = {}
        game.anims[x] = {}
        for y = 1, 3 do
            game.anims[x][y] = 0
            game.grid[x][y] = TICKS.EMPTY
        end
    end
end

function GAME:isWinning( x, y )
    if not self.winning then return false end

    for i = 1, 3 do
        local win_x, win_y = unpack( self.winning[ i ] )
        if x == win_x and y == win_y then return true end
    end

    return false
end

function GAME:getSelfTick()
    return ( LocalPlayer() == self.party.owner ) and TICKS.CIRCLE or TICKS.CROSS
end

function GAME:load( game_panel )
    local game = self

    --  > Setting up winning system
    game.wins = { 0, 0 }
    game.countdown = 0
    game.anims = {}

    --  > init grid
    init_grid( game )

    self.player_turn = TICKS.CIRCLE

    --  > create grid
    local grid_button = game_panel:Add( "DButton" )
        grid_button:SetSize( game_panel:GetWide() / 3, game_panel:GetWide() / 3 )
        grid_button:Center()

        local grid_size = grid_button:GetWide() / 3
        game.grid_size = grid_size
        function grid_button:Paint( w, h )
            --  > draw grid lines
            for x = grid_size, w, grid_size do
                draw.RoundedBox( 0, x, 0, 5, h, game.settings.main_color )
                for y = grid_size, h, grid_size do
                    draw.RoundedBox( 0, 0, y, w, 5, game.settings.main_color )
                end
            end

            --  > draw ticks
            local box_w, box_h = grid_size * .75, grid_size * .2
            for x, xv in ipairs( game.grid ) do
                for y, yv in ipairs( xv ) do
                    if yv == TICKS.EMPTY then continue end

                    local draw_color = game:isWinning( x, y ) and GNLib.LerpColor( math.abs( math.cos( CurTime() * 4 ) ), game.settings.main_color, game.settings.background_color )
                        or game.settings.main_color
                        
                    game.anims[x][y] = game.anims[x][y] > 0.99 and 1 or Lerp( FrameTime() * ( yv == TICKS.CROSS and 8 or 6 ), game.anims[x][y], 1 )

                    local center_x, center_y = ( x - 1 ) * grid_size + grid_size / 2, ( y - 1 ) * grid_size + grid_size / 2
                    if yv == TICKS.CIRCLE then
                        GNLib.DrawCircle( center_x, center_y, box_w / 2, 0, game.anims[x][y] * 360, draw_color )
                        GNLib.DrawCircle( center_x, center_y, grid_size / 2 / 2, 0, game.anims[x][y] * 360, game.settings.background_color )
                    elseif yv == TICKS.CROSS then
                        draw.RoundedBox( 0, center_x - box_w / 2, center_y - box_h / 2, ( game.anims[x][y] - 0.75 ) * 4 * box_w, box_h, draw_color )
                        draw.RoundedBox( 0, center_x - box_h / 2, center_y - box_w / 2, box_h, game.anims[x][y] * box_w, draw_color )
                    end
                end
            end

            return true
        end
        function grid_button:DoClick()
            local mouse_x, mouse_y = self:LocalCursorPos()
            local grid_x, grid_y = math.ceil( mouse_x / grid_size ), math.ceil( mouse_y / grid_size )

            if not ( game:getSelfTick() == game.player_turn ) then return end
            if game.grid[grid_x] and game.grid[grid_x][grid_y] then
                game:send( { event = ( "tick %d %d" ):format( grid_x, grid_y ) } )
            end
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
end

function GAME:receive( payload )
    local event = payload.event
    if not event then return end

    --  > receive a new tick
    if event:StartWith( "tick" ) then
        local x, y, tick = event:match( "^%w+ (%d+) (%d+) (%d+)" ) -- pos x, pos y, tick type
        if not x or not y or not tick then return end

        --  > convert to number (else index failed cause of string values)
        x, y, tick = tonumber( x ), tonumber( y ), tonumber( tick )

        --  > change value
        self.grid[x][y] = tick
    elseif event:StartWith( "turn" ) then
        self.player_turn = tonumber( event:match( "^%w+ (%d+)" ) )
    elseif event:StartWith( "wins" ) then
        local wins_circle, wins_cross = event:match( "^%w+ (%d+) (%d+)" )

        wins_circle = tonumber( wins_circle )
        wins_cross = tonumber( wins_cross )

        self.wins = { wins_circle, wins_cross }
        self.winner = self.player_turn
    elseif event:StartWith( "winning" ) then
        self.winning = payload.data
    elseif event == "draw" then
        self.draw_end = true
    elseif event == "reset" then
        init_grid( self )

        self.draw_end = false

        self.winning = nil
    elseif event:StartWith( "countdown" ) then
        self.countdown = tonumber( event:match( "^%w+ (%d+)" ) )
    end
end

function GAME:update( dt )
    if self.countdown <= 0 then return end

    self.countdown = self.countdown - dt
end

function GAME:GetCaseCenter( x, y, w, h )
    return (w / 2 - w / 6) + ( x - 1 ) * self.grid_size + self.grid_size / 2, ( h / 2 - w / 6 ) + ( y - 1 ) * self.grid_size + self.grid_size / 2
end

local thickness = 8
function GAME:draw( w, h )
    local self_form = self:getSelfTick()
    local self_turn = self.player_turn == self_form

    local other_form = ( LocalPlayer() == self.party.owner ) and TICKS.CROSS or TICKS.CIRCLE
    local other_name = LocalPlayer() == self.party.owner and self.players_names[2] or self.players_names[1]

    --  > Drawing background + players' names
    local center = 25 + 64
    GNLib.DrawCircle( center, center, 64 + thickness, nil, nil, self_turn and self.settings.main_color or self.settings.background_color )
    GNLib.SimpleTextShadowed( LocalPlayer():Name(), "GNLFontB40", center * 1.9, center * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, 2, nil )
        GNLib.SimpleTextShadowed( self.wins[self_form] .. " wins", "GNLFontB20", center * 2.1, center, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, 2, nil )

    GNLib.DrawCircle( w - 25 - 64, 25 + 64, 64 + thickness, nil, nil, self_turn and self.settings.background_color or self.settings.main_color )
    GNLib.SimpleTextShadowed( other_name, "GNLFontB40", w - center * 1.9, center * 0.5, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 2, 2, nil )
        GNLib.SimpleTextShadowed( self.wins[other_form] .. " wins", "GNLFontB20", w - center * 2.1, center, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 2, 2, nil )

    --  > Draw the countdown
    if self.countdown <= 0 then return end

    GNLib.SimpleTextShadowed( self.draw_end and "Draw" or ( ( self_form == self.winner and LocalPlayer():Name() or other_name ) .. " wins." ), "GNLFontB40", w / 2, 64, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, 2, nil )
    GNLib.SimpleTextShadowed( "Restarting in " .. math.ceil( self.countdown ) .. "s", "GNLFontB20", w / 2, 64 + 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, 2, nil )
end

GNGames.CreateGame( "Tic-Tac-Toe", GAME )