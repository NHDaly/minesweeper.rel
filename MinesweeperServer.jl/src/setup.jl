using RAI

MODEL_DIR = joinpath(dirname(dirname(@__DIR__)), "model")
files = [
    joinpath(MODEL_DIR, file)
    for file in [
        "mines.rel",
        "init.rel",
        "display.rel",
        "coords.rel",
        "actions.rel",
        #"multiplayer.rel",
    ]
]

function setup_database()

    try create_engine(ctx, engine, size="m") catch e; @info(e) end
    try RAI.delete_database(ctx, database) catch end
    RAI.create_database(ctx, database)

    # Dummy warmup
    exec(ctx, database, engine, "def output { 2+2+2 }")

    RAI.load_models(ctx, "nhd-minesweeper", engine, Dict(
        "minesweeper/model/"*basename(path) => read(path, String)
        for path in files
    ))
    let f = files, str = join((
            """
                def delete[:rel, :catalog, :model, "minesweeper/model/$(basename(path))"]:
                    rel[:catalog, :model, "minesweeper/model/$(basename(path))"]
                def insert[:rel, :catalog, :model, "minesweeper/model/$(basename(path))"]:
                    { input_$(splitext(basename(path))[1]) }
            """
            for path in f
        ), "\n")
        inputs = Dict(
            "input_$(splitext(basename(path))[1])" => read(path, String)
            for path in f
        )
        println(str)
        println(inputs)
        exec(ctx, database, engine, str, readonly=false, inputs=inputs)
    end

    # Finish the initialization
    exec(ctx, database, engine, "def insert[:reset]: true", readonly=false)

    exec(ctx, database, engine, """
        def output { screen_grid }
    """ , readonly=true)

    # Warm up some transactions
    exec(ctx, database, engine, """
        def insert[:test]: { ^Coord[5, 5] }
    """ , readonly=false)
    exec(ctx, database, engine, """
        def output { screen_grid }
    """ , readonly=true)
    exec(ctx, database, engine, """
        def insert_test { 3, 3 }
    """ , readonly=false)
    exec(ctx, database, engine, """
        def insert[:reset]: { true }
    """ , readonly=false)

end
