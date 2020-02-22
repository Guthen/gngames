local game_line_tall = 48
local offset = 5

--  > Friends list
local invite_text = "Invite"
local function create_friend_line( friends_list, ply, own_party )
    local invite_y
    local line = friends_list:Add( "DButton" )
        line:Dock( TOP )
        line:SetTall( 32 )
        line:DockMargin( 0, 0, 0, 5 )
        function line:Paint( w, h )
            GNLib.DrawElipse( 0, 0, w, h, GNLib.Colors.MidnightBlue )

            GNLib.SimpleTextShadowed( ply:Name(), "GNLFontB15", h + 5, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, 2, nil )

            if own_party then
                surface.SetFont( "GNLFontB15" )
                local text_w = surface.GetTextSize( invite_text )

                self.invite = Lerp( FrameTime() * 5, self.invite or w + text_w, self:IsHovered() and ( w - h / 2 ) or ( w + text_w + 5 ) )
                draw.SimpleText( invite_text, "GNLFontB15", self.invite, h / 2, GNLib.Colors.Emerald, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
            end

            return true
        end
        function line:DoClick()
            if not own_party then return end
            GNGames.Invite( ply )
        end

    local avatar = line:Add( "GNImage" )
        avatar:SetAvatar( ply, 128 )
        avatar:SetCircle( true )
        avatar:SetSize( line:GetTall(), line:GetTall() )
end

local friends_count = 0
local function populate_friend_list( parties )
    if not IsValid( GNGames.MatchmakingUI ) or not IsValid( GNGames.MatchmakingUI.FriendsList ) then return end
    GNGames.MatchmakingUI.FriendsList:Clear()
    
    local own_party = parties[LocalPlayer():SteamID64()] and true or false

    friends_count = 0
    for _, ply in ipairs( player.GetAll() ) do
        if ply:GetFriendStatus() ~= "friend" then continue end

        friends_count = friends_count + 1
        create_friend_line( GNGames.MatchmakingUI.FriendsList, ply, own_party )
    end
end

local rounded_radius = 6
local function create_friends_list()
    if not IsValid( GNGames.MatchmakingUI ) then return end

    if IsValid( GNGames.MatchmakingUI.FriendsList ) then
        GNGames.MatchmakingUI.FriendsList:Remove()
    end

    local friends_opened = false

    local panel = vgui.Create( "DPanel" )
        panel:SetZPos( GNGames.MatchmakingUI:GetZPos() - 1 )

    local open = panel:Add( "GNButton" )
        open:SetText( "Friends" )
        open:SetTextColor( color_white )
        open:SetHoveredTextColor( color_white )
        open:SetColor( GNLib.Colors.Turquoise )
        open:SetHoveredColor( GNLib.Colors.GreenSea )
        open:SetHideLeft( true )

    --  > First we size the panel to the button's tall and then we set the pos of the button from the panel's width
    panel:SetSize( GNGames.MatchmakingUI:GetWide() / 2, open:GetTall() )
    open:SetPos( panel:GetWide() - open:GetWide(), 0 )

    local init_pos = GNGames.MatchmakingUI.x + GNGames.MatchmakingUI:GetWide() - panel:GetWide() + open:GetWide() - open:GetTall() / 2
        panel:SetPos( init_pos, GNGames.MatchmakingUI.y + 25 )

    function panel:Paint( w, h )
        draw.RoundedBoxEx( rounded_radius, 0, 0, w - open:GetWide() + rounded_radius, h, GNLib.Colors.WetAsphalt, false, true, false, true )
        draw.RoundedBoxEx( rounded_radius, w - open:GetWide(), 0, rounded_radius, h, open:IsHovered() and GNLib.Colors.GreenSea or GNLib.Colors.Turquoise, false, true, false, true )
    
        if friends_count == 0 then
            GNLib.SimpleTextShadowed( "No friend online", "GNLFontB15", ( w - open:GetWide() ) / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, 2, nil )
        end
    end

    function open:DoClick()
        if not IsValid( GNGames.MatchmakingUI ) then return end
        
        panel:SizeTo( panel:GetWide(), friends_opened and open:GetTall() or ( GNGames.MatchmakingUI:GetTall() - 50 ), 0.5 )
        panel:MoveTo( friends_opened and init_pos or ( GNGames.MatchmakingUI.x + GNGames.MatchmakingUI:GetWide() ), panel.y, 0.5 )

        friends_opened = not friends_opened
    end

    --  > Now, the friends
    local friends_list = panel:Add( "DScrollPanel" )
        friends_list:Dock( FILL )
        friends_list:DockMargin( 0, rounded_radius, open:GetWide() + rounded_radius / 2, rounded_radius )
        friends_list:GetVBar():SetWide( 0 )

    return panel, friends_list
end


--  > Matchmaking list
local function create_game_line( parties_list, party )
    --  > Special informations
    local is_owner = party.owner == LocalPlayer()
    local is_opponent = table.HasValue( party.players, LocalPlayer() ) and not is_owner
    local team_color = team.GetColor( party.owner:Team() )

    --  > Get real width of line (cause of Dock)
    local line_w = parties_list:GetParent():GetWide()
    do
        local left, _, right = parties_list:GetDockMargin()
        line_w = line_w - left - right
    end

    --  > Party line
    local line = parties_list:Add( "DPanel" )
        line:Dock( TOP )
        line:DockMargin( 0, offset, 0, 0 )
        line:SetTall( game_line_tall )
        function line:Paint( w, h )
            GNLib.DrawElipse( 0, 0, w, h, GNLib.Colors.WetAsphalt )

            GNLib.SimpleTextShadowed( party.name, "GNLFontB15", game_line_tall + 15, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, 2, nil )
            GNLib.SimpleTextShadowed( party.game.name, "GNLFontB15", w / 2 - game_line_tall, h / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 2, 2, nil )
            GNLib.SimpleTextShadowed( ( "%d/%d" ):format( #party.players, party.game.settings.max_players ), "GNLFontB15", w / 2 + game_line_tall, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, 2, nil )
        end

    --  > Owner avatar
    local owner_avatar = line:Add( "GNImage" )
        owner_avatar:SetPos( offset, offset )
        owner_avatar:SetSize( game_line_tall - offset * 2, game_line_tall - offset * 2 )
        owner_avatar:SetAvatar( party.owner )
        owner_avatar:SetCircle( true )

    --  > Join/Disband/Quit button
    local join_button = line:Add( "GNButton" )
        join_button:SetSize( line_w / ( ( is_owner or is_opponent ) and 6.5 or 3.4 ) - offset * 2, game_line_tall - offset * 2 )
        join_button:SetPos( line_w - join_button:GetWide() - offset, offset )
        join_button:SetText( is_owner and "Disband" or (is_opponent and "Quit" or "Join") )
        join_button:SetTextColor( color_white )
        join_button:SetHoveredTextColor( GNLib.Colors.Clouds )
        join_button:SetColor( ( is_owner or is_opponent ) and GNLib.Colors.Alizarin or GNLib.Colors.Turquoise )
        join_button:SetHoveredColor( ( is_owner or is_opponent ) and GNLib.Colors.Pomegranate or GNLib.Colors.GreenSea )
        join_button:SetHideLeft( is_owner or is_opponent )
        function join_button:DoClick()
            if is_owner then
                GNGames.DisbandParty()
            else
                if is_opponent then
                    GNGames.QuitParty( party.owner )
                else
                    if party.protected then
                        GNLib.DermaStringRequest( "Enter password to join " .. party.name, nil, nil, function( password )
                            GNGames.JoinParty( party.owner, password )
                        end, "Password" )
                    else
                        GNGames.JoinParty( party.owner )
                    end
                end
            end
        end

    if not (is_owner or is_opponent) then return end

    local play_button = line:Add( "GNButton" )
        play_button:SetSize( line_w / 6.5 - offset * 2, game_line_tall - offset * 2 )
        play_button:SetPos( line_w - play_button:GetWide() - join_button:GetWide() - offset, offset )
        play_button:SetText( ( is_owner or is_opponent ) and "Play" or "Join" )
        play_button:SetTextColor( color_white )
        play_button:SetHoveredTextColor( GNLib.Colors.Clouds )
        play_button:SetColor( ( is_owner or is_opponent ) and GNLib.Colors.PeterRiver or GNLib.Colors.Turquoise )
        play_button:SetHoveredColor( ( is_owner or is_opponent ) and GNLib.Colors.BelizeHole or GNLib.Colors.GreenSea )
        play_button:SetHideRight( true )
        function play_button:DoClick()
            if #party.players < party.game.settings.min_players then GNGames.Notify( party.name, "Not enought players to play" ) return end

            if is_owner or is_opponent then
                GNGames.MatchmakingUI:Remove()
                GNGames.OpenGame( party )

                net.Start( "GNGames:Game" )
                    net.WriteString( "play" )
                net.SendToServer()
            end
        end
end

local function populate_parties_list( parties )
    if not IsValid( GNGames.MatchmakingUI ) or not IsValid( GNGames.MatchmakingUI.PartiesList ) then return end

    GNGames.MatchmakingUI.PartiesList:Clear()

    for id64, party in pairs( parties ) do
        party.owner = party.owner or player.GetBySteamID64( id64 )
        if not party.owner then continue end

        create_game_line( GNGames.MatchmakingUI.PartiesList, party )
    end
end

local function create_matchmaking_ui( parties )
    if IsValid( GNGames.MatchmakingUI ) then 
        GNGames.MatchmakingUI:Remove() 
    end

    --  > Main frame
    local frame, header = GNLib.CreateFrame( "Matchmaking", ScrW() / 2.5, nil, GNLib.Colors.WetAsphalt, GNLib.Colors.MidnightBlue )
        GNGames.MatchmakingUI = frame

        local friend_list, scrollpanel = create_friends_list()
        GNGames.MatchmakingUI.FriendsList = scrollpanel

        populate_friend_list( parties )

        function frame:OnRemove()
            friend_list:Remove()
        end

    --  > Join panel
    local join_panel = frame:Add( "DPanel" )
        join_panel:Dock( TOP )
        join_panel:DockMargin( offset, offset, offset, offset )
        join_panel:SetSize( frame:GetWide() - offset * 2, frame:GetTall() / 1.7 )
        function join_panel:Paint( w, h )
            draw.RoundedBox( rounded_radius, 0, 0, w, h, GNLib.Colors.MidnightBlue )

            GNLib.SimpleTextShadowed( "Current parties", "GNLFontB20", w / 2, offset * 4, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, 2, nil )
        end

    --  > Parties list
    local parties_list = join_panel:Add( "DScrollPanel" )
        parties_list:Dock( FILL )
        parties_list:DockMargin( offset * 3, offset * 7, offset * 3, offset )

    GNGames.MatchmakingUI.PartiesList = parties_list

    populate_parties_list( parties )

    --  > Host panel
    local host_panel = frame:Add( "DPanel" )
        host_panel:Dock( TOP )
        host_panel:DockMargin( offset, 0, offset, offset )
        host_panel:SetSize( frame:GetWide(), frame:GetTall() - join_panel:GetTall() - header:GetTall() * 1.6 )
        function host_panel:Paint( w, h )
            draw.RoundedBox( rounded_radius, 0, 0, w, h, GNLib.Colors.MidnightBlue )
            
            GNLib.SimpleTextShadowed( "Host a party", "GNLFontB20", w / 2, offset * 4, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, 2, nil )
        end

    local name_entry = host_panel:Add( "GNTextEntry" )
        name_entry:SetSize( host_panel:GetWide() / 3, game_line_tall / 1.25 )
        name_entry:CenterVertical( .25 )
        name_entry:CenterHorizontal()
        name_entry:SetTitle( "Party Name" )
        name_entry:SetText( LocalPlayer():GetName() .. "'s party" )
        name_entry:SetColor( GNLib.Colors.Clouds )
        name_entry:SetHoveredColor( GNLib.Colors.Silver )
        
    local password_entry = host_panel:Add( "GNTextEntry" )
        password_entry:CopyBounds( name_entry )
        password_entry:MoveBelow( name_entry, game_line_tall / 2 )
        password_entry:SetTitle( "Party Password" )
        password_entry:SetHideText( true )
        password_entry:SetColor( GNLib.Colors.Clouds )
        password_entry:SetHoveredColor( GNLib.Colors.Silver )
    
    local game_combobox = host_panel:Add( "GNComboBox" )
        game_combobox:CopyBounds( name_entry )
        game_combobox:SetTall( game_line_tall / 1.6 )
        game_combobox:MoveBelow( password_entry, game_line_tall / 2 )
        game_combobox:SetValue( "Select a game.." )
        game_combobox:SetReseter( true )
        --  > Add every game
        for name, tbl in pairs( GNGames.Games ) do
            game_combobox:AddChoice( name )
        end

    local create_button = host_panel:Add( "GNButton" )
        create_button:SetSize( host_panel:GetWide() / 4, game_line_tall - offset * 2 )
        create_button:SetPos( host_panel:GetWide() / 2 - create_button:GetWide() / 2 - offset, host_panel:GetTall() - create_button:GetTall() - offset * 2 )
        create_button:SetText( "Create" )
        create_button:SetTextColor( color_white )
        create_button:SetHoveredTextColor( GNLib.Colors.Clouds )
        create_button:SetColor( GNLib.Colors.Turquoise )
        create_button:SetHoveredColor( GNLib.Colors.GreenSea )
        function create_button:DoClick()
            if not game_combobox:GetSelected() then return end

            GNGames.HostParty( name_entry:GetValue(), game_combobox:GetSelected().text, password_entry:GetValue() )
        end
end

function GNGames.OpenMatchmaking()
    net.Start( "GNGames:Matchmaking" )
        net.WriteString( "open" )
    net.SendToServer()
end
concommand.Add( "gngames_matchmaking", GNGames.OpenMatchmaking )

function GNGames.HostParty( party_name, game_name, password )
    net.Start( "GNGames:Matchmaking" )
        net.WriteString( "host" )
        net.WriteString( party_name )
        net.WriteString( game_name )
        net.WriteString( password )
    net.SendToServer()
end

function GNGames.JoinParty( game_owner, password )
    net.Start( "GNGames:Matchmaking" )
        net.WriteString( "join" )
        net.WriteString( game_owner:SteamID64() )
        net.WriteString( password or "" )
    net.SendToServer()
end

function GNGames.QuitParty( game_owner )
    net.Start( "GNGames:Matchmaking" )
        net.WriteString( "quit" )
        net.WriteString( game_owner:SteamID64() )
    net.SendToServer()
end

function GNGames.DisbandParty()
    net.Start( "GNGames:Matchmaking" )
        net.WriteString( "disband" )
    net.SendToServer()
end

net.Receive( "GNGames:Matchmaking", function( len )
    local method = net.ReadString()
    local parties = net.ReadTable()

    if method == "open" then
        create_matchmaking_ui( parties )
    elseif method == "update" then
        populate_parties_list( parties )
        populate_friend_list( parties )
    end
end )
