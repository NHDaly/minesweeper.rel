using RAI

engine = "nhd-xs-3"
database = "nhd-minesweeper"

function __init__()
    global ctx = Context(load_config());
end

