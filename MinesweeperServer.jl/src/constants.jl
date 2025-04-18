using RAI

engine = "nhd-m-2"
# engine = "nhd-xs-3"
# database = "nhd-minesweeper"
database = "nhd-minesweeper-2"

function __init__()
    global ctx = Context(load_config());
end

