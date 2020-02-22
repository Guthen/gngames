function GNGames.Invite( friend )
    net.Start( "GNGames:Invite" )
        net.WriteString( "invite" )
        net.WriteEntity( friend )
    net.SendToServer()
end

function create_invite( friend )
    if IsValid( GNGames.GameInvitationUI ) then GNGames.GameInvitationUI:Remove() end

    if friend:GetFriendStatus() ~= "friend" then return end

    local frame, header, close = GNLib.CreateFrame( "Game invitation", 400, 100 )
        close:Remove()
        GNGames.GameInvitationUI = frame

    local text = frame:Add( "DLabel" )
        text:SetText( friend:Name() .. " invited you to join his party.")
        text:SetFontInternal( "GNLFontB17" )
        text:SizeToContents()
        text:SetPos( frame:GetWide() / 2 - text:GetWide() / 2, header:GetTall() + 10 )

    local accept = frame:Add( "GNButton" )
        accept:SetText( "Accept" )
        accept:SetPos( frame:GetWide() * 0.25 - accept:GetWide() / 2, header:GetTall() + ( frame:GetTall() - header:GetTall() ) / 2 )
        accept:SetColor( GNLib.Colors.Turquoise )
        accept:SetHoveredColor( GNLib.Colors.GreenSea )
        function accept:DoClick()
            frame:Remove()

            net.Start( "GNGames:Invite" )
                net.WriteString( "accept" )
                net.WriteEntity( friend )
            net.SendToServer()
        end

    local decline = frame:Add( "GNButton" )
        decline:SetText( "Decline" )
        decline:SetPos( frame:GetWide() * 0.75 - decline:GetWide() / 2, header:GetTall() + ( frame:GetTall() - header:GetTall() ) / 2 )
        decline:SetColor( GNLib.Colors.Alizarin )
        decline:SetHoveredColor( GNLib.Colors.Pomegranate )
        function decline:DoClick()
            frame:Remove()

            net.Start( "GNGames:Invite" )
                net.WriteString( "decline" )
                net.WriteEntity( friend )
            net.SendToServer()
        end
end

net.Receive( "GNGames:Invite", function()
    create_invite( net.ReadEntity() )
end )