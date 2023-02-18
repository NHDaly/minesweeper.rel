using RAI

MODEL_DIR = joinpath(dirname(dirname(@__DIR__)), "model")
files = [
    joinpath(MODEL_DIR, file)
    for file in [
        "mines.rel",
        "init.rel",
        "display.rel",
        "coords.rel",
        "multiplayer.rel",
        "actions.rel",
    ]
]

function setup_database()

    try create_engine(ctx, engine, size="m") catch end
    try RAI.delete_database(ctx, database) catch end
    RAI.create_database(ctx, database)

    # Dummy warmup
    exec(ctx, database, engine, "2+2+2")

    RAI.load_models(ctx, "nhd-minesweeper", engine, Dict(
        path => read(path, String)
        for path in files
    ))

    # Finish the initialization
    exec(ctx, database, engine, "", readonly=false)
    exec(ctx, database, engine, "", readonly=false)

    exec(ctx, database, engine, """
        def output = display_cell
    """ , readonly=true)

    exec(ctx, database, engine, """
        def insert:test = ^Coord[-3, -1]
    """ , readonly=true)

    # Commit the compilation
    exec(ctx, database, engine, "", readonly=false)

end
