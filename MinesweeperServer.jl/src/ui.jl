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
   @assert length(rsp.results) == 2
   score_idx = findfirst(x -> startswith(x[1], "/:output/:score/"), rsp.results)
   grid_idx = 1 + (2 - score_idx) # (The other one)
   table = rsp.results[grid_idx][2]
   data = zip(table[1], table[2], table[3])

   score = rsp.results[score_idx][2][1][1]
   return JSON3.write(Dict("grid" => make_json(data), "score" => score))
end

route("/set_size") do
   @info "Setting display size"
   new_w, new_h = parse.(Int, (params(:screen_width), params(:screen_height)))
   @show new_w, new_h
    rsp = exec(ctx, database, engine, """
        def insert:screen_width = $new_w
        def delete:screen_width = screen_width
        def insert:screen_height = $new_h
        def delete:screen_height = screen_height
        def output = screen_center.x, screen_center.y
    """, readonly=false)
   # Return the single tuple
   x,y = collect(zip(rsp.results[1][2][1], rsp.results[1][2][2]))[1]
   return JSON3.write(Dict("center_x" => x, "center_y" => y))
end
route("/display") do
   @info "Running display query!"
    rsp = exec(ctx, database, engine, """
        def output:grid = screen_grid
        def output:score = score
    """, readonly=true)
   return display_data(rsp)
end

function do_insert(type, js_row, js_col; delete=false)
   @assert type in ("flag", "test")
   # JS is 1-based
   row, col = js_row + 1, js_col + 1

   operation = delete ? "delete" : "insert"
   @show operation
   query = """
      def $(operation)_$type = $row, $col
      def output:grid = screen_grid
      def output:score = score
   """
   @show query
   rsp = exec(ctx, database, engine, query, readonly=false)

   # exec(ctx, database, engine, """
   #     def current_user = ^Player["nhdaly", "this is my password"]
   #     def insert:test = coords:gc[^ScreenCoord[$row, $col]]
   #     def output:score = player_score
   #     def output:display = screen_grid
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

   rsp = exec(ctx, database, engine, """
      def move_screen_to = $newX, $newY
      def output:grid = screen_grid
      def output:score = score
   """ , readonly=false)

   return display_data(rsp)
end
route("/move_view_center_to") do
   @info "Move View"
   newX, newY = parse.(Int, (params(:x), params(:y)))
   @show newX, newY

   rsp = exec(ctx, database, engine, """
      def move_screen_to = $newX, $newY
      def output:grid = screen_grid
      def output:score = score
   """ , readonly=false)

   return display_data(rsp)
end
route("/reset_game") do
   @info "Reset Game"
   rsp = exec(ctx, database, engine, """
      def insert:reset = true
      def output:grid = screen_grid
      def output:score = score
   """ , readonly=false)
   return display_data(rsp)
end







