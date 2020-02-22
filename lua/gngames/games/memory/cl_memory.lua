local GAME = {
    settings = {
        --background_rounded_radius = 0,
        background_color = GNLib.Colors.MidnightBlue,
    }
}

local CARDS = {
    Material( "entities/npc_fastzombie.png" ),
    Material( "entities/npc_zombie.png" ),
    Material( "entities/npc_poisonzombie.png" ),
    Material( "entities/combineelite.png" ),
    Material( "entities/combineprison.png" ),
    Material( "entities/prisonshotgunner.png" ),
    Material( "entities/npc_metropolice.png" ),
    Material( "entities/npc_helicopter.png" ),
    Material( "entities/npc_stalker.png" ),
    Material( "entities/npc_strider.png" ),
    Material( "entities/npc_rollermine.png" ),
    Material( "entities/npc_manhack.png" ),
    Material( "entities/npc_cscanner.png" ),
    Material( "entities/npc_clawscanner.png" ),
    Material( "entities/npc_combinedropship.png" ),
    Material( "entities/npc_combinegunship.png" ),
    Material( "entities/npc_crow.png" ),
    Material( "entities/npc_seagull.png" ),
    Material( "entities/npc_pigeon.png" ),
    Material( "entities/medic.png" ),
    Material( "entities/rebel.png" ),
    Material( "entities/refugee.png" ),
    Material( "entities/npc_alyx.png" ),
    Material( "entities/npc_eli.png" ),
    Material( "entities/npc_barnacle.png" ),
    Material( "entities/npc_antlion.png" ),
    Material( "entities/npc_antlionguard.png" ),
    Material( "entities/vortigaunturiah.png" ),
    Material( "entities/vortigauntslave.png" ),
    Material( "entities/npc_dog.png" ),
    Material( "entities/npc_kleiner.png" ),
    Material( "entities/chair_office1.png" ),
    Material( "entities/chair_office2.png" ),
    Material( "entities/chair_plastic.png" ),
    Material( "entities/chair_wood.png" ),
}

local CARDS_IN_GAME = 64

function GAME:getCardIDAt( cards_count_sqr, card_x, card_y )
    local card_id = 1
    for y = 1, cards_count_sqr do
        for x = 1, cards_count_sqr do
            if x == card_x and y == card_y then
                return card_id
            end

            card_id = card_id + 1
        end
    end
end

function GAME:load( game_panel )
    local game = self

    local cards_button = game_panel:Add( "DButton" )
    local button_size = game_panel:GetTall() - 45
    cards_button:SetSize( button_size, button_size )
    cards_button:SetPos( game_panel:GetWide() - button_size - 10, 10 )

    game.cards = {}
    game.found_cards_pairs = {}
    game.selected = {}

    local card_back = Material( "sprites/sent_ball" )
    local cards_count_sqr = math.ceil( math.sqrt( CARDS_IN_GAME ) )

    local cards_size = math.floor( cards_button:GetWide() / cards_count_sqr )
    
    function cards_button:Paint( w, h )
        surface.SetDrawColor( color_white )

        local card_pos_id = 1
        for y = 1, cards_count_sqr do
            for x = 1, cards_count_sqr do
                local pos_x = ( x - 1 ) * cards_size + 5
                local pos_y = ( y - 1 ) * cards_size + 5

                local card_found = game.found_cards_pairs[ card_pos_id ]
                local card_selected = ( game.selected[1] == card_pos_id ) or ( game.selected[2] == card_pos_id )

                GNLib.DrawStencil( function()
                    local radius = ( cards_size - 10 ) / 2
                    GNLib.DrawCircle( pos_x + radius, pos_y + radius, radius, 0, 360, color_white )
                end, function()
                    GNLib.DrawMaterial( ( card_found or card_selected ) and CARDS[ game.cards[ card_pos_id ] ] or card_back, pos_x, pos_y, cards_size - 10, cards_size - 10, color_white )
                end )

                card_pos_id = card_pos_id + 1
            end
        end

        return true
    end

    function cards_button:DoClick()
        if not ( game.players[ game.turn ] == LocalPlayer() ) then return end

        local mouse_x, mouse_y = self:LocalCursorPos()
        local card_x, card_y = math.ceil( mouse_x / cards_size ), math.ceil( mouse_y / cards_size )

        if not game:getCardIDAt( cards_count_sqr, card_x, card_y ) then return end
        if game.selected[1] == game:getCardIDAt( cards_count_sqr, card_x, card_y ) then return end
        if game.found_cards_pairs[ game.selected[1] ] or game.found_cards_pairs[ game.selected[2] ] then return end

        if #game.selected == 0 then
            game.selected[1] = game:getCardIDAt( cards_count_sqr, card_x, card_y )
        elseif #game.selected == 1 then
            game.selected[2] = game:getCardIDAt( cards_count_sqr, card_x, card_y )
            game:send( { event = ( "equal %d %d" ):format( game.selected[1], game.selected[2] ) } )

            if not game.found_cards_pairs[ game.selected[1] ] then
                game.found_cards_pairs[ game.selected[1] ] = true
            end
            if not game.found_cards_pairs[ game.selected[2] ] then
                game.found_cards_pairs[ game.selected[2] ] = true
            end

        end
    end
end

function GAME:draw( w, h )
    if not self.turn then return end

    GNLib.SimpleTextShadowed( "It's " .. self.players_names[ self.turn ] .. "'s turn", "GNLFontB40", 25, 25, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, 2, nil )
end

function GAME:receive( payload )
    local event = payload.event
    if not event then return end

    if event:StartWith( "card" ) then
        local pos_id, mat_id = event:match( "^%w+ (%d+) (%d+)" )
        pos_id, mat_id = tonumber( pos_id ), tonumber( mat_id )
        if not pos_id or not mat_id then return end

        self.cards[pos_id] = mat_id
    elseif event:StartWith( "equal" ) then
        local is_equal, is_localplayer, card1_pos, card2_pos = event:match( "^%w+ (%d+) (%d+) (%d+) (%d+)" )
        is_equal, is_localplayer, card1_pos, card2_pos = tobool( is_equal ), tobool( is_localplayer ), tonumber( card1_pos ), tonumber( card2_pos )
        if is_equal == nil or is_localplayer == nil or not card1_pos or not card2_pos then return end

        self.found_cards_pairs[ card1_pos ] = is_equal
        self.found_cards_pairs[ card2_pos ] = is_equal

        if is_localplayer then 
            timer.Simple( 1, function()
                self.selected = {} 
            end )
        end
    elseif event:StartWith( "turn" ) then
        self.turn = tonumber( event:match( "^%w+ (%d+)" ) )
    end
end

GNGames.CreateGame( "Memory", GAME )