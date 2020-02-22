util.AddNetworkString( "GNGames:Notify" )

function GNGames.Notify( ply, title, desc )
    net.Start( "GNGames:Notify" )
        net.WriteString( title )
        net.WriteString( desc )
    net.Send( ply )
end