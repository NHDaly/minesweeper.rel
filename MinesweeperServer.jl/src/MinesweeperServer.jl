module MinesweeperServer

include("constants.jl")
include("setup.jl")
include("ui.jl")

function main()
    setup_database()
    up(port=8001)
end

end # module
