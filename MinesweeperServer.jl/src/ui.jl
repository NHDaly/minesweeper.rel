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

route("/display") do
   @info "Running display query!"
   new_w, new_h = parse.(Int, (params(:screen_width), params(:screen_height)))
   x, y = parse.(Int, (params(:center_x), params(:center_y)))
   @show new_w, new_h
   @show x, y

   rsp = exec(ctx, database, engine, """
      def screen_width = $new_w
      def screen_height = $new_h
      def screen_center = ^Coord[$x, $y]

      def output:grid = screen_grid
      def output:score = score
   """, readonly=true)
   return display_data(rsp)
end

function do_insert(type, x, y; delete=false)
   @assert type in ("flag", "test")

   new_w, new_h = parse.(Int, (params(:screen_width), params(:screen_height)))
   screen_x, screen_y = parse.(Int, (params(:center_x), params(:center_y)))

   operation = delete ? "delete" : "insert"
   @show operation
   query = """
      def $(operation):$type = ^Coord[$x, $y]

      def screen_width = $new_w
      def screen_height = $new_h
      def screen_center = ^Coord[$screen_x, $screen_y]

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
   x, y = parse.(Int, (params(:x), params(:y)))
   rsp = do_insert("test", x, y)
   return display_data(rsp)
end
route("/flag_cell") do
   @info "Flag Cell"
   x, y = parse.(Int, (params(:x), params(:y)))
   delete = parse(Bool, params(:delete, "false"))
   rsp = do_insert("flag", x, y, delete=delete)
   return display_data(rsp)
end
route("/reset_game") do
   @info "Reset Game"
   rsp = exec(ctx, database, engine, """
      def insert:reset = true
   """ , readonly=false)
   return display_data(rsp)
end







