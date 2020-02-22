local GAME = {
    settings = {
        min_players = 2,
        max_players = 2,
        countdown = 3,
    }
}

--  > Tick enum
local TICKS = {
    EMPTY = 0,
    CIRCLE = 1,
    CROSS = 2,
}

local function is_vertical_win( grid, x, y, tick_id )
    return  ( grid[ x ][ y ] and grid[ x ][ y ] == tick_id )
        and ( grid[ x ][ y + 1 ] and grid[ x ][ y + 1 ] == tick_id )
        and ( grid[ x ][ y - 1 ] and grid[ x ][ y - 1 ] == tick_id ),
        { { x, y }, { x, y + 1 }, { x, y - 1 } }
end

local function is_horizontal_win( grid, x, y, tick_id )
    return  ( grid[ x ][ y ] and grid[ x ][ y ] == tick_id )
        and ( grid[ x + 1 ][ y ] and grid[ x + 1 ][ y ] == tick_id )
        and ( grid[ x - 1 ][ y ] and grid[ x - 1 ][ y ] == tick_id ),
        { { x, y }, { x + 1, y }, { x - 1, y } }
end

local function intern_diagonal( grid, tick_id, inverted )
    return  ( grid[ 2 ][ 2 ] and grid[ 2 ][ 2 ] == tick_id )
        and ( grid[ 1 ][ inverted and 1 or 3 ] and grid[ 1 ][ inverted and 1 or 3 ] == tick_id )
        and ( grid[ 3 ][ inverted and 3 or 1 ] and grid[ 3 ][ inverted and 3 or 1 ] == tick_id ),
        { { 2, 2 }, { 1, inverted and 1 or 3 }, { 3, inverted and 3 or 1 } }
end

local function is_diagonal_win( grid, tick_id )
    return intern_diagonal( grid, tick_id ) or intern_diagonal( grid, tick_id, true )
end

local function get_winner( grid )
    for k, tick_id in pairs( TICKS ) do
        if tick_id == TICKS.EMPTY then continue end

         -- > if win on center
        if is_horizontal_win( grid, 2, 2, tick_id ) or is_vertical_win( grid, 2, 2, tick_id ) or is_diagonal_win( grid, tick_id ) then return tick_id end
        --  > if win on top or bottom
        if is_horizontal_win( grid, 2, 1, tick_id ) or is_horizontal_win( grid, 2, 3, tick_id ) then return tick_id end
        --  > if win on left or right
        if is_vertical_win( grid, 1, 2, tick_id ) or is_vertical_win( grid, 3, 2, tick_id ) then return tick_id end
    end

    return TICKS.EMPTY
end

local function get_winning( grid )
    local tick_id = get_winner( grid )

    for i = 1, 3 do
        local horizontal_condition, horizontal_cases = is_horizontal_win( grid, 2, i, tick_id )
        if horizontal_condition then return horizontal_cases end

        local vertical_condition, vertical_cases = is_vertical_win( grid, i, 2, tick_id )
        if vertical_condition then return vertical_cases end
    end

    local diag1_condition, diag1_cases = intern_diagonal( grid, tick_id )
    if diag1_condition then return diag1_cases end

    local diag2_condition, diag2_cases = intern_diagonal( grid, tick_id, true )
    if diag2_condition then return diag2_cases end
end

function GAME:sendTick( ply, x, y )
    self:send( ply, { event = ( "tick %d %d %d" ):format( x, y, self.grid[x][y] ) } )
end

function GAME:sendTurn( ply )
    self:send( ply, { event = ( "turn %d" ):format( self.player_turn ) } )
end

function GAME:sendWins( ply )
    self:send( ply, { event = GNLib.FormatWithTable( "wins {1} {2}", self.wins ) } )
end

function GAME:sendWinning( ply )
    self:send( ply, { event = "winning", data = get_winning( self.grid ) } )
end

function GAME:sendDraw( ply )
    self:send( ply, { event = "draw" } )
end

function GAME:sendCountdown( ply, time )
    self:send( ply, { event = ( "countdown %d" ):format( time ) } )
end

function GAME:resetGrid()
    self:broadcast( { event = "reset" } )
    self:initGrid()
end

function GAME:initGrid()
    self.grid = {}
    self.ticked = 0
    
    for x = 1, 3 do
        self.grid[x] = {}
        for y = 1, 3 do
            self.grid[x][y] = TICKS.EMPTY
        end
    end
end

function GAME:load()
    --  > init grid
    self:initGrid()

    --  > init player turn
    self.player_turn = TICKS.CIRCLE

    --  > Create wins
    self.wins = { 0, 0 }
end

function GAME:receive( ply, payload )
    local event = payload.event
    if not event then return end

    if event:StartWith( "tick" ) then
        local x, y = event:match( "^tick (%d+) (%d+)" )
        x, y = tonumber( x ), tonumber( y )
        if not x or not y then return end
        
        --  > be sure grid pos is good
        if not self.grid[x] or not self.grid[x][y] then return end
        if not ( self.grid[x][y] == TICKS.EMPTY ) then return end

        --  > freeze on win
        if timer.Exists( "TicTacToeWin" .. self.party.owner:SteamID64() ) then return end

        --  > do the change
        local tick = ply == self.party.owner and TICKS.CIRCLE or TICKS.CROSS
        if not ( tick == self.player_turn ) then return end

        self.grid[x][y] = tick
        self.player_turn = ( self.player_turn == TICKS.CIRCLE ) and TICKS.CROSS or TICKS.CIRCLE
        self.ticked = self.ticked + 1

        --  > send it to clients
        for i, v in ipairs( self.players ) do
            self:sendTick( v, x, y )
            self:sendTurn( v )
        end

        local winner = get_winner( self.grid )
        if winner ~= 0 then
            self.wins[ winner ] = self.wins[ winner ] + 1
            self.player_turn = ( self.player_turn == TICKS.CIRCLE ) and TICKS.CROSS or TICKS.CIRCLE

            for i, v in ipairs( self.players ) do
                self:sendTurn( v )
                self:sendWins( v )
                self:sendWinning( v )
                self:sendCountdown( v, self.settings.countdown )
            end

            timer.Create( "TicTacToeWin" .. self.party.owner:SteamID64(), self.settings.countdown, 1, function()
                self:resetGrid()
            end )
        return end

        if self.ticked == 9 then
            for i, v in ipairs( self.players ) do
                self:sendDraw( v )
                self:sendCountdown( v, self.settings.countdown )
            end

            timer.Create( "TicTacToeWin" .. self.party.owner:SteamID64(), self.settings.countdown, 1, function()
                if not self then return end
                self:resetGrid()
            end )
        end
    end
end

function GAME:onPlayerConnect( ply )
    for x, xv in ipairs( self.grid ) do
        for y, yv in ipairs( xv ) do
            if yv == TICKS.EMPTY then continue end
            self:sendTick( ply, x, y )
        end
    end

    self:sendTurn( ply )
    self:sendWins( ply )

    if timer.Exists( "TicTacToeWin" .. self.party.owner:SteamID64() ) then
        self:sendCountdown( ply, timer.TimeLeft( "TicTacToeWin" .. self.party.owner:SteamID64() ) )
    end
end

GNGames.CreateGame( "Tic-Tac-Toe", GAME )