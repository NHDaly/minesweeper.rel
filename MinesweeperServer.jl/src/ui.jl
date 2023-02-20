using Genie
using RAI
using JSON3

index = joinpath(dirname(@__DIR__),"ui/index.html")
route("/") do
   read(index, String)
end
fake_data() = make_json([(rand(0:15),rand(0:15),rand([" ", ".", "1", "2", "!"])) for _ in 1:10])
make_json(data) = [
   (;row = r, col = c, cell = v)
   for (r,c,v) in data
]

function display_data(rsp)
   @info "Query output"
   @assert length(rsp.results) == 1
   table = rsp.results[1][2]
   data = zip(table[1], table[2], table[3])
   return JSON3.write(make_json(data))
end

route("/display") do
   @info "Running display query!"
    rsp = exec(ctx, database, engine, """
        def output = display_cell
    """, readonly=true)
   return display_data(rsp)
end

function do_insert(type, js_row, js_col; delete=false)
   @assert type in ("flag", "test")
   # JS is 1-based
   row, col = js_row + 1, js_col + 1
   x,y = col, row
   @show x,y

   operation = delete ? "delete" : "insert"
   @show operation
   query = """
       def $operation:$type = ^Coord[$x, $y]
       def output:display = display_cell
   """
   @show query
   rsp = exec(ctx, database, engine, query, readonly=false)

   # exec(ctx, database, engine, """
   #     def current_user = ^Player["nhdaly", "this is my password"]
   #     def insert:test = coords:gc[^ScreenCoord[$row, $col]]
   #     def output:score = player_score
   #     def output:display = display_cell
   # """ , readonly=false)
   return rsp

end
route("/test_cell") do
   @info "Test Cell"
   row, col = parse.(Int, (params(:row), params(:col)))
   rsp = do_insert("test", row, col)
   return display_data(rsp)
end
route("/flag_cell") do
   @info "Flag Cell"
   row, col = parse.(Int, (params(:row), params(:col)))
   delete = parse(Bool, params(:delete, "false"))
   rsp = do_insert("flag", row, col, delete=delete)
   return display_data(rsp)
end
route("/move_view_center") do
   @info "Move View"
   newX, newY = parse.(Int, (params(:x), params(:y)))
   @show newX, newY

   @info "TODO: actual transaction"
   # exec(ctx, database, engine, """
   #     def insert:screen_center = coords:gc[^ScreenCoord[$newX, $newY]]
   # """ , readonly=false)

   return JSON3.write(fake_data())
end
route("/reset_game") do
   @info "Reset Game"
   @info "TODO: actual transaction"
   exec(ctx, database, engine, """
       def insert:reset = true
   """ , readonly=false)
   # DO I need this extra transaction? Or can they be combined?
    rsp = exec(ctx, database, engine, """
        def output = display_cell
    """, readonly=false)
   return display_data(rsp)
end







