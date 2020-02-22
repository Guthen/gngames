--  > Init game with settings
local GAME = {
    settings = {
        --  > Editor settings
        background_rounded_radius = 0,
        --background_main_color = Color( 100, 110, 10 ),
        --  > Game settings
        main_color = Color( 15, 200, 15 ),
        failed_color = Color( 200, 15, 15 ),
    }
}

local boats = {
    -- size = amount,
    [1] = 3,
    [2] = 2,
    [3] = 2,
    [4] = 2,
    [5] = 1,
}

--[[ local function create_grid( w, h )
    local grid = {}

    for x = 0, w do
        grid[x] = {}
        for y = 0, h do
            grid[x][y] = { id = 0 }
        end
    end

    return grid
end ]]

function GAME:create_grid_panel( panel, grid_key )
    local grid_size = panel:GetWide() / 14
    local game = self
    
    panel:DockMargin( 0, grid_size, 0, 0 )

    local grid_button
    function panel:Paint( w, h )
        --  > Draw grid letters and numbers
        for x = grid_size, grid_button:GetWide() + grid_size, grid_size do
            draw.SimpleText( string.char( 65 + ( x - grid_size ) / grid_size ), "GNLFontB40", x + grid_size / 2, grid_size / 2, GAME.settings.main_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        end

        for y = grid_size, grid_button:GetTall() + grid_size, grid_size do
            draw.SimpleText( y / grid_size, "GNLFontB40", grid_size / 2 - 2, y + grid_size / 2, GAME.settings.main_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        end
    end

    grid_button = panel:Add( "DButton" )
        grid_button:SetPos( grid_size, grid_size )
        grid_button:SetSize( panel:GetWide() - grid_size * 2, panel:GetWide() - grid_size * 2 )
        function grid_button:Paint( w, h ) 
            --  > Draw grid lines
            surface.SetDrawColor( GAME.settings.main_color )
            for x = 0, w, grid_size do
                surface.DrawLine( x, 0, x, h )
            end
            surface.DrawLine( w - 1, 0, w - 1, h )

            for y = 0, h, grid_size do
                surface.DrawLine( 0, y, w, y )
            end
            surface.DrawLine( 0, h - 1, w, h - 1 )

            --  > Draw things on the grid
            local box_offset = 10
            for x, xv in pairs( game.grids[grid_key] ) do
                for y, yv in pairs( xv ) do
                    if yv.id == 0 then continue end

                    --  > handle offset animation
                    if yv.offset then
                        yv.offset = Lerp( FrameTime() * 7, yv.offset, box_offset )
                    else
                        yv.offset = 0
                    end

                    --  > draw it
                    draw.RoundedBox( 0, x * grid_size + yv.offset, y * grid_size + yv.offset, grid_size - yv.offset * 2, grid_size - yv.offset * 2, yv.id == 1 and GAME.settings.main_color or GAME.settings.failed_color )
                end
            end

            return true 
        end

    --game.grids[grid_key] = create_grid( grid_button:GetWide() / grid_size, grid_button:GetTall() / grid_size )
    function grid_button:DoClick()
        if grid_key == "player" then return end

        local mouse_x, mouse_y = self:LocalCursorPos()
        local grid_x, grid_y = math.ceil( mouse_x / grid_size ) - 1, math.ceil( mouse_y / grid_size ) - 1

        --print( string.char( 64 + grid_x ) .. grid_y )
        game:send( { desc = ( "hit %d %d" ):format( grid_x, grid_y ) } )
        --game.grids[grid_key][grid_x][grid_y].id = math.random( 1, 2 )
    end
end

function GAME:load( game_panel )
    --  > Grids data
    self.grids = {
        player = {},
        opponent = {},
    }

    self.phases = {
        { text = "Place your ships", cooldown = 10 },
        { text = "{1}, attacks {2}", cooldown = 10 },
        { text = "{2}, attacks {1}", cooldown = 10 },
    }

    self.phase = 1
    self.time = 0

    --  > Grids and others panels
    game_panel:DockPadding( 0, game_panel:GetTall() * .05, 0, 0 )

    --  > Separate game in two (two grids because of two players)
    local left = game_panel:Add( "DPanel" )
        left:Dock( LEFT )
        left:SetSize( game_panel:GetWide() / 2, game_panel:GetWide() / 2 )
        left.Paint = function() end
    
    local right = game_panel:Add( "DPanel" )
        right:Dock( RIGHT )
        right:SetSize( game_panel:GetWide() / 2, game_panel:GetWide() / 2 )
        right.Paint = function() end

    self:create_grid_panel( left, "player" )
    self:create_grid_panel( right, "opponent" )

    --  >
end

function GAME:receive( tbl )
    local desc, data = tbl.desc, tbl.data
    if not desc then return end

    --  > Handle grid changes
    if desc:find( "^grid" ) then
        if not data then return end
        
        local key, x, y = desc:match( "^grid (%w+) (%d+) (%d+)" )
        if not key then return end

        if not x or not y then
            self.grids[key] = data
        elseif x or y then
            if x and not y then
                self.grids[key][x] = data
            elseif x and y then
                self.grids[key][x][y] = data
            end
        end
    end
end

function GAME:update( dt )
    self.time = self.time + dt

    if self.time >= self.phases[ self.phase ].cooldown then
        if self.phase == 1 then
            self.phase = 2
        elseif self.phase == 2 then
            self.phase = 3
        elseif self.phase == 3 then
            self.phase = 2
        end

        self.time = 0
    end

    self.fps = 1 / dt
end

local color_background = ColorAlpha( GAME.settings.main_color, 125 )
function GAME:draw( w, h )
        --  > Opponents name
    draw.SimpleText( LocalPlayer():Name(), "GNLFontB20", w * 0.2,  h * 0.025, GAME.settings.main_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    draw.SimpleText( LocalPlayer() == self.party.owner and self.players_names[2] or self.players_names[1], "GNLFontB20", w * 0.8, h * 0.025, GAME.settings.main_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )

    --  > Current phase
    draw.SimpleText( GNLib.FormatWithTable( self.phases[ self.phase ].text, self.players_names ), "GNLFontB20", w * 0.5,  h * 0.025, GAME.settings.main_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

    surface.SetDrawColor( color_background )
    surface.DrawRect( w / 2 - w * 0.1, h * 0.045, w * 0.2, 10 )

    surface.SetDrawColor( GAME.settings.main_color )
    surface.DrawRect( w / 2 - w * 0.1, h * 0.045, w * 0.2 * ( 1 - self.time / self.phases[ self.phase ].cooldown ), 10 )

    draw.SimpleText( math.floor( self.phases[ self.phase ].cooldown - self.time ) .. "s remaining", "GNLFontB20", w * 0.5,  h * 0.075, GAME.settings.main_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

    --  > Draw own boats
    surface.SetDrawColor( GAME.settings.main_color )

    local offset_x, boat_size, y_pos = 25, 16, h * 0.06
    for size, count in ipairs( boats ) do
        for i = 1, size do
            surface.DrawRect( offset_x + i * ( boat_size + 2 ), y_pos, boat_size, boat_size )
        end

        offset_x = offset_x + size * ( boat_size + 2 ) + 50

        draw.SimpleText( "x" .. count, "GNLFontB20", offset_x - 30, y_pos + boat_size / 2, GAME.settings.main_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end

    --  > Draw opponent's boats
    surface.SetDrawColor( GAME.settings.main_color )

    local offset_x = 25
    for size, count in ipairs( boats ) do
        for i = 1, size do
            surface.DrawRect( w * 0.6 + offset_x + i * ( boat_size + 2 ), y_pos, boat_size, boat_size )
        end

        offset_x = offset_x + size * ( boat_size + 2 ) + 50

        draw.SimpleText( "x" .. count, "GNLFontB20", w * 0.6 + offset_x - 30, y_pos + boat_size / 2, GAME.settings.main_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end

    --  > Separation line
    surface.SetDrawColor( GAME.settings.main_color )
    surface.DrawLine( 0, h * 0.1, w, h * 0.1 )

    draw.SimpleText( math.ceil( self.fps ) .. " FPS", "GNLFontB17", w / 2, h * 0.14, GAME.settings.main_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
end

--  > Create game
--GNGames.CreateGame( "Battleship", GAME )