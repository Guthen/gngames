local GAME = {
    settings = {
        min_players = 1, --  > minimum players to launch a game
        max_players = 2, --  > maximum players who could join
    }
}

--  > some functions
--[[ 
    0 = empty -> black
    1 = touched void -> attack = red, green
    2 = untouched boat -> attack = black, green
    3 = touched boat -> attack = green, red
    ]]
local function create_grid( w, h )
    local grid = {}

    for x = 0, w do
        grid[x] = {}
        for y = 0, h do
            grid[x][y] = { id = math.random( 0, 2 ) }
        end
    end

    return grid
end

local function get_opponent( players, ply )
    for i, v in ipairs( players ) do
        if v == ply then continue end
        return v
    end
end

--  > GAME main functions

function GAME:load()
    --  > Create grids by players
    self.grids = {}
    for i, ply in ipairs( self.players ) do
        self.grids[ply:SteamID64()] = create_grid( 12, 12 )
    end
end

function GAME:receive( ply, tbl )
    local desc, data = tbl.desc, tbl.data
    if not desc then return end

    --  > handle hit attempt
    if desc:find( "^hit" ) then
        local x, y = desc:match( "^hit (%d+) (%d+)" )
        if not x or not y then return end
        if not isnumber( x ) or not isnumber( y ) then return end

        --  > find opponent
        local opponent = get_opponent( self.players, ply )
        if not opponent then return end

        --  > change grid
        self.grids[opponent:SteamID64()][x][y] = 0
        
        --  > send change to clients
        for i, v in ipairs( self.players ) do
            self:send( v, { desc = ( "grid %s %d %d" ):format( v == opponent and "player" or "opponent", x, y ), data = grid[x][y] } )
        end
    end
end

function GAME:onPlayerConnect( ply )
    print( "GAME: " .. ply:GetName() .. " connect!" )

    --  > Send players grids
    for id, grid in pairs( self.grids ) do
        self:send( ply, { desc = "grid " .. ( id == ply:SteamID64() and "player" or "opponent" ), data = grid } )
    end
end

function GAME:onPlayerDisconnect( ply )
    print( "GAME: " .. ply:GetName() .. " disconnected!" )
end

--GNGames.CreateGame( "Battleship", GAME )