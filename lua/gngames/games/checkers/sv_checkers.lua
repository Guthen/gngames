local GAME = {
    settings = {
        min_players = 1,
        max_players = 2,
        countdown = 5,
    }
}

local PAWN = {
    WHITE = 1,
    BLACK = 2,
}

local DIRECTION = {
    TOP_LEFT = 1,
    TOP_RIGHT = 2,
    BOTTOM_LEFT = 3,
    BOTTOM_RIGHT = 4,
}

--  > Game related functions
function GAME:getWinner()
    local whites, blacks = 0, 0

    for id, pawn in pairs( self.pions ) do
        if pawn.team == PAWN.WHITE then
            whites = whites + 1
        else
            blacks = blacks + 1
        end
    end

    if whites == 0 and blacks == 0 then return end
    if whites == 0 or blacks == 0 then return whites > blacks and PAWN.WHITE or PAWN.BLACK end
end

function GAME:getPawnAt( x, y )
    for id, pawn in pairs( self.pions ) do
        if pawn.x == x and pawn.y == y then return pawn, id end
    end
end

function GAME:getPawnTeam( ply )
    return self.party.owner == ply and PAWN.WHITE or PAWN.BLACK
end

function GAME:getPosFromDirection( dir, x, y, pawn )
    local new_x, new_y = x or pawn.x, y or pawn.y

    if dir == DIRECTION.TOP_LEFT then
        if pawn and not pawn.queen and not ( pawn.team == PAWN.BLACK ) then return end --  > can't move opposite side (must be a queen)
        new_x = new_x - 1
        new_y = new_y - 1
    elseif dir == DIRECTION.TOP_RIGHT then
        if pawn and not pawn.queen and not ( pawn.team == PAWN.BLACK ) then return end --  > can't move opposite side (must be a queen)
        new_x = new_x + 1
        new_y = new_y - 1
    elseif dir == DIRECTION.BOTTOM_LEFT then
        if pawn and not pawn.queen and not ( pawn.team == PAWN.WHITE ) then return end --  > can't move opposite side (must be a queen)
        new_x = new_x - 1
        new_y = new_y + 1
    elseif dir == DIRECTION.BOTTOM_RIGHT then
        if pawn and not pawn.queen and not ( pawn.team == PAWN.WHITE ) then return end --  > can't move opposite side (must be a queen)
        new_x = new_x + 1
        new_y = new_y + 1
    else 
        return
    end

    if new_x < 0 or new_x > 7 then return end --  > checking grid x size
    if new_y < 0 or new_y > 7 then return end --  > checking grid y size

    return new_x, new_y
end

function GAME:createPions()
    --  > init pions
    self.pions = {}

    --  > create pions by team
    local lines, pions_per_line = 3, 4    
    for k, pawn_team in pairs( PAWN ) do
        for line = 0, lines - 1 do
            for n = 0, pions_per_line - 1 do
                local id = #self.pions + 1

                self.pions[id] = {
                    x = ( ( n % pions_per_line ) + ( line % 2 ) / 2 ) * 2 + ( pawn_team == PAWN.BLACK and ( line % 2 == 0 and 1 or -1 ) or 0 ),
                    y = ( pawn_team == PAWN.WHITE ) and line or 7 - line,
                    id = id,
                    team = pawn_team,
                    queen = false,
                }
            end
        end
    end
end

function GAME:setWin( winner )
    self:send( self.players, { event = "win " .. winner } )
            
    --  > update wins
    self.wins[winner] = self.wins[winner] + 1
    self:sendWins()

    --  > reload countdown
    timer.Create( "CheckersWin" .. self.party.owner:SteamID64(), self.settings.countdown, 1, function()
        if not self then return end
        self:createPions()

        for i, v in pairs( self.pions ) do
            self:sendPawn( nil, v )
        end
    end )

    self:sendCountdown()
end

--  > Game events
function GAME:load()
    --  > init player turn
    self.player_turn = PAWN.WHITE

    --  > init wins
    self.wins = { 
        [PAWN.WHITE] = 0, 
        [PAWN.BLACK] = 0 
    }

    --  > init pions
    self:createPions()
end

function GAME:onPlayerConnect( ply )
    for i, v in pairs( self.pions ) do
        self:sendPawn( ply, v )
    end

    self:sendTurn( ply )
    self:sendWins( ply )

    if timer.Exists( "CheckersWin" .. self.party.owner:SteamID64() ) then
        self:sendCountdown( ply, timer.TimeLeft( "CheckersWin" .. self.party.owner:SteamID64() ) )
    end
end


--  > Communication
--  > Receiving
function GAME:receive( ply, payload )
    local event = payload.event
    if not event then return end

    if event:StartWith( "pawn" ) then
        local id, dir = event:match( "^%w+ (%d+) (%d+)" )
        id, dir = tonumber( id ), tonumber( dir )
        if not id or not dir then return end

        --  > freeze on win
        if timer.Exists( "CheckerWin" .. self.party.owner:SteamID64() ) then return end

        --  > check pawn
        local pawn = self.pions[id]
        if not pawn then return end --  > don't change if pawn don't exists
        if #self.players > 1 and not ( pawn.team == self:getPawnTeam( ply ) ) then return end --  > dont change if it's not his own pawn
        if not ( pawn.team == self.player_turn ) then return end --  > don't change if it's not his turn

        --  > calculate new pos
        local new_x, new_y = self:getPosFromDirection( dir, pawn.x, pawn.y, pawn )
        if not new_x or not new_y then return end
        
        --  > check if we can attack
        local pos_pawn, eaten = self:getPawnAt( new_x, new_y ), false
        if pos_pawn then
            --  > can't capture a pawn with same team
            if pos_pawn.team == pawn.team then return end
            
            --  > check if we can capture pawn
            local capture_x, capture_y = self:getPosFromDirection( dir, new_x, new_y, pawn )
            if not capture_x or not capture_y then return end --  > check if pos exists
            if self:getPawnAt( capture_x, capture_y ) then return end --  > don't continue if there is already someone

            --  > change new position
            new_x = capture_x
            new_y = capture_y

            --  > delete captured pawn
            self.pions[pos_pawn.id] = nil
            self:send( self.players, { event = "eat " .. pos_pawn.id } )

            eaten = true
        end 

        --  > change pos
        pawn.x = new_x
        pawn.y = new_y

        --  > check if can become a queen
        if not pawn.queen then
            pawn.queen = pawn.team == PAWN.WHITE and pawn.y == 7 or pawn.y == 0
        end

        --  > change turn
        if not eaten then
            self.player_turn = self.player_turn == PAWN.WHITE and PAWN.BLACK or PAWN.WHITE
            self:sendTurn()
        end

        --  > check victory
        local winner = self:getWinner()
        if winner then
            self:setWin( winner )
        end

        --  > send it to clients
        self:sendPawn( self.players, pawn )
    elseif event:StartWith( "surrender" ) then
        if timer.Exists( "CheckersWin" .. self.party.owner:SteamID64() ) then return end
        
        self:setWin( self:getPawnTeam( ply ) == PAWN.BLACK and PAWN.WHITE or PAWN.BLACK )
    end
end
    
--  > Sending
function GAME:sendPawn( ply, pawn )
    self:send( ply or self.players, { event = ( "pawn %d %d %d %d %d" ):format( pawn.id, pawn.x, pawn.y, pawn.team, pawn.queen and 1 or 0 ) } )
end

function GAME:sendTurn( ply )
    self:send( ply or self.players, { event = "turn " .. self.player_turn } )
end

function GAME:sendWins( ply )
    self:send( ply or self.players, { event = ( "wins %d %d" ):format( unpack( self.wins ) ) } )
end

function GAME:sendCountdown( ply, time )
    self:send( ply or self.players, { event = ( "countdown %d" ):format( time or self.settings.countdown ) } )
end

GNGames.CreateGame( "Checkers", GAME )