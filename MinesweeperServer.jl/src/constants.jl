using RAI

engine = "nhd-s"
database = "nhd-minesweeper"

function __init__()
    global ctx = Context(load_config());
end

