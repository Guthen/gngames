local notif_queue = {}
local offset = 25
local header_h, corner = 35, 10

function GNGames.Notify( title, desc )
    local size = { w = 300, h = header_h + 20 }

    surface.SetFont( "GNLFontB20" )
    local title_w = surface.GetTextSize( title )

    surface.SetFont( "GNLFontB17" )
    local desc_w, desc_h = GNLib.GetLinesSize( desc )

    size.w = math.max( size.w, title_w + 20, desc_w + corner * 2 )
    size.h = math.max( size.h, desc_h + header_h + corner * 2 )
    
    notif_queue[ #notif_queue + 1 ] = { 
        title = title or "No Title", 
        desc = desc or "No Description",
        countdown = ( ( #title or 8 ) + ( #desc or 14 ) ) * .1,
        time = 0,
        size = size,
        pos = { x = -size.w, y = #notif_queue * ( size.h + 5 ) + offset },
    }

    surface.PlaySound( "friends/message.wav" )
end

local function render_notif( notif )
    local x, y = notif.pos.x, notif.pos.y
    local w, h = notif.size.w, notif.size.h
    
    draw.RoundedBoxEx( corner, x, y, w, header_h, GNLib.Colors.MidnightBlue, true, true, false, false )
    draw.RoundedBoxEx( corner, x, y + header_h, w, h - header_h, GNLib.Colors.WetAsphalt, false, false, true, true )

    local percent = math.min( 1, notif.time / notif.countdown )
    surface.SetDrawColor( GNLib.Colors.BelizeHole )
    surface.DrawRect( x + 1, y + header_h, w * ( 1 - percent ) - 2, 2 )

    GNLib.SimpleTextShadowed( notif.title, "GNLFontB17", x + corner, y + header_h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, 2, nil )
    GNLib.DrawLines( notif.desc, x + corner, y + header_h + corner )
end

hook.Add( "HUDPaint", "GNGames:RenderNotifications", function()
    local spd = FrameTime() * 4
    for i, v in ipairs( notif_queue ) do
        --  > Update
        v.time = v.time + FrameTime()
        if v.time >= v.countdown then
            if v.pos.x <= -v.size.w + 1 then
                table.remove( notif_queue, i )
            else
                v.pos.x = Lerp( spd, v.pos.x, -v.size.w - offset )
            end
        else
            v.pos.x = Lerp( spd, v.pos.x, offset )
        end

        local last = notif_queue[ i - 1 ]
        v.pos.y = Lerp( spd, v.pos.y, (i == 1) and offset or ( last.pos.y + last.size.h + 5 ) )

        --  > Draw
        render_notif( v )
    end
end )

--  > Net
net.Receive( "GNGames:Notify", function()
    GNGames.Notify( net.ReadString(), net.ReadString() )
end )