local GAME = {
    settings = {
        min_players = 1,
        max_players = 8,
    }
}

local CARDS = {
    "entities/npc_fastzombie.png",
    "entities/npc_zombie.png",
    "entities/npc_poisonzombie.png",
    "entities/combineelite.png",
    "entities/combineprison.png",
    "entities/prisonshotgunner.png",
    "entities/npc_metropolice.png",
    "entities/npc_helicopter.png",
    "entities/npc_stalker.png",
    "entities/npc_strider.png",
    "entities/npc_rollermine.png",
    "entities/npc_manhack.png",
    "entities/npc_cscanner.png",
    "entities/npc_clawscanner.png",
    "entities/npc_combinedropship.png",
    "entities/npc_combinegunship.png",
    "entities/npc_crow.png",
    "entities/npc_seagull.png",
    "entities/npc_pigeon.png",
    "entities/medic.png",
    "entities/rebel.png",
    "entities/refugee.png",
    "entities/npc_alyx.png",
    "entities/npc_eli.png",
    "entities/npc_barnacle.png",
    "entities/npc_antlion.png",
    "entities/npc_antlionguard.png",
    "entities/vortigaunturiah.png",
    "entities/vortigauntslave.png",
    "entities/npc_dog.png",
    "entities/npc_kleiner.png",
    "entities/chair_office1.png",
    "entities/chair_office2.png",
    "entities/chair_plastic.png",
    "entities/chair_wood.png",
}

local CARDS_IN_GAME = 64

function GAME:generateCards()
    self.cards = {}
    self.found_cards = {}

    --  > generate cards list
    local cards_used = {}
    for i = 2, CARDS_IN_GAME, 2 do
        --  > select material
        local mat_id
        repeat
            _, mat_id = table.Random( CARDS )
        until not cards_used[mat_id]

        --  > insert it
        cards_used[mat_id] = true
        for j = 0, 1 do 
            self.cards[ #self.cards + 1 ] = mat_id
        end
    end

    --  > shuffle table
    self.cards = GNLib.TableShuffle( self.cards )
end

function GAME:load()
    self:generateCards()

    self.turn = 1
end

function GAME:onPlayerConnect( ply )
    self:sendCards( ply )
    self:sendTurn( ply )
    self:sendFounds( ply )
end

--  > Networking

function GAME:receive( ply, payload )
    local event = payload.event
    if not event then return end

    if event:StartWith( "equal" ) then
        if not ( self.players[ self.turn ] == ply ) then return end
        
        local card1_pos_id, card2_pos_id = event:match( "^%w+ (%d+) (%d+)" )
        card1_pos_id, card2_pos_id = tonumber( card1_pos_id ), tonumber( card2_pos_id )
        if not card1_pos_id or not card2_pos_id then return end

        --  > check if card exists
        local card1_mat_id, card2_mat_id = self.cards[card1_pos_id], self.cards[card2_pos_id]
        if not card1_mat_id or not card2_mat_id then return end

        --  > check if they are equals
        --if not ( card1_mat_id == card2_mat_id ) then return end
        --ply:ChatPrint( tostring( card1_mat_id == card2_mat_id ) )
        local is_equal = card1_mat_id == card2_mat_id
        for i, v in pairs( self.players ) do
            self:send( v, { event = ( "equal %d %d %d %d" ):format( is_equal and 1 or 0, ply == v and 1 or 0, card1_pos_id, card2_pos_id ) } )
        end

        if is_equal then
            self.found_cards[ card1_pos_id ] = true
            self.found_cards[ card2_pos_id ] = true
        else
            self.turn = #self.players == self.turn and 1 or self.turn + 1
        end

        self:sendTurn()
    end
end

function GAME:sendCards( ply )
    for pos_id, mat_id in pairs( self.cards ) do
        self:send( ply or self.players, { event = ( "card %d %d" ):format( pos_id, mat_id ) } )
    end
end

function GAME:sendFounds( ply )
    for pos_id, _ in pairs( self.found_cards ) do
        self:send( ply or self.players, { event = ( "found %d %d" ):format( pos_id ) } )
    end
end

function GAME:sendTurn( ply )
    self:send( ply or self.players, { event = ( "turn %d" ):format( self.turn ) } )
end

GNGames.CreateGame( "Memory", GAME )