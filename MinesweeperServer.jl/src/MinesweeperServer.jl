module MinesweeperServer

include("constants.jl")
include("setup.jl")
include("ui.jl")

function main()
    setup_database()
    up()
end

end # module
