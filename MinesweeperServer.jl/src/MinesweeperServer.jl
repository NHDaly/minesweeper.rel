module MinesweeperServer

include("constants.jl")
include("setup.jl")
include("ui.jl")

function main()
    setup_database()
    up(port=8002)
end

end # module
