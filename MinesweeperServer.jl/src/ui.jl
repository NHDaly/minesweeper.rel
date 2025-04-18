using Genie
using RAI
using JSON3

index = joinpath(dirname(@__DIR__),"ui/index.html")
route("/") do
   read(index, String)
end
fake_data() = make_json([(rand(0:15),rand(0:15),rand([" ", ".", "1", "2", "!"])) for _ in 1:10])
make_json(data) = join((v for (r,c,v) in data))
function print_grid(data, w, h, x, y)
   foreach(println, ("$(lpad(r-(h÷2 - y),2)) " * join((v for c in 1:w for v in data[r,c]), " ") for r in 1:h))
   print("  ")
   for c in 1:w
      print("$(lpad(c-(w÷2 - x),2))")
   end
   println()
end

function display_data(rsp, w, h, cx, cy)
   @info "Query output"
   @assert length(rsp.results) >= 2
   if length(rsp.results) > 2
      @warn first.(rsp.results)
   end
   score_idx = findfirst(x -> startswith(x[1], "/:output/:score/"), rsp.results)
   grid_idx = 1 + (2 - score_idx) # (The other one)
   table = rsp.results[grid_idx][2]
   data = zip(table[1], table[2], table[3])

   score = rsp.results[score_idx][2][1][1]
   global DATA = data
   print_grid(Dict(((i,j) => v) for (i,j,v) in data), w, h, cx, cy)
   println("Score: ", score)
   return JSON3.write(Dict("grid" => make_json(data), "score" => score))
end

function handle_display(new_w, new_h, x, y)
   @info "Running display query!"

   rsp = exec(ctx, database, engine, """
      def insert[:screen_width]: { $new_w }
      def insert[:screen_height]: { $new_h }
      def insert[:screen_center]: { ^Coord[$x, $y] }
      def delete[:screen_width]: { screen_width }
      def delete[:screen_height]: { screen_height }
      def delete[:screen_center]: { screen_center }

      def output[:grid]: screen_grid
      def output[:score]: score
   """, readonly=true)
   return display_data(rsp, new_w, new_h, x, y)
end
route("/display") do
   new_w, new_h = parse.(Int, (params(:screen_width), params(:screen_height)))
   x, y = parse.(Int, (params(:center_x), params(:center_y)))
   @show new_w, new_h
   @show x, y
   handle_display(new_w, new_h, x, y)
end

function do_insert(type, x, y; delete=false, screen_w=10, screen_h=10, screen_x=0, screen_y=0)
   @assert type in ("flag", "test")

   operation = delete ? "delete" : "insert"
   @show operation
   query = """
      def $(operation)[:$type]: { ^Coord[$x, $y] }

      def insert[:screen_width]: { $screen_w }
      def insert[:screen_height]: { $screen_h }
      def insert[:screen_center]: { ^Coord[$screen_x, $screen_y] }
      def delete[:screen_width]: { screen_width }
      def delete[:screen_height]: { screen_height }
      def delete[:screen_center]: { screen_center }

      def output[:grid]: screen_grid
      def output[:score]: score
   """
   @show query
   rsp = exec(ctx, database, engine, query, readonly=false)

   # exec(ctx, database, engine, """
   #     def current_user = ^Player["nhdaly", "this is my password"]
   #     def insert:test = coords:gc[^ScreenCoord[$row, $col]]
   #     def output:score = player_score
   #     def output:display = screen_grid
   # """ , readonly=false)
   return display_data(rsp, screen_w, screen_h, screen_x, screen_y)

end
route("/test_cell") do
   @info "Test Cell"
   x, y = parse.(Int, (params(:x), params(:y)))
   new_w, new_h = parse.(Int, (params(:screen_width), params(:screen_height)))
   screen_x, screen_y = parse.(Int, (params(:center_x), params(:center_y)))

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
   exec(ctx, database, engine, """
      def insert:reset = true
   """ , readonly=false)
   return
end







