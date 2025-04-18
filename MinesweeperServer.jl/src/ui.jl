using Genie
using RAI
using JSON3

index = joinpath(dirname(@__DIR__),"ui/index.html")
route("/") do
   read(index, String)
end
fake_data() = make_json([(rand(0:15),rand(0:15),rand([" ", ".", "1", "2", "!"])) for _ in 1:10])
make_json(data) = join((v for (r,c,v) in data))
function print_grid(grid, flags, mines, w, h, x, y)
   @show flags
   for r in (y - h÷2):(y + h÷2 - 1)
      print("$(lpad(r, 2)) ")
      for c in (x - w÷2):(x + w÷2 - 1)
         if haskey(flags, (c, r))
            print("! ")
         elseif haskey(mines, (c, r))
            print("x ")
         elseif haskey(grid, (c, r))
            v = grid[(c, r)]
            if v == 0
               print("  ")
            else
               print("$(v) ")
            end
         else
            print(". ")
         end
      end
      println()
   end

   print(" ")
   for c in (x - w÷2):(x + w÷2 - 1)
      print("$(lpad(c, 2))")
   end
   println()
end

function get_table_dict(rsp, idx)
   if idx === nothing
      return Dict()
   end
   @assert idx > 0 && idx <= length(rsp.results)
   table = rsp.results[idx][2]
   data = zip(table...)
   return Dict(tup_keys(tup) => tup_val(tup) for tup in data)
end
tup_keys(tup) = tup[1:end-1]
tup_val(tup) = tup[end]

function display_data(rsp, w, h, cx, cy)
   @info "Query output"
   @assert length(rsp.results) >= 1
   if length(rsp.results) > 4
      @warn first.(rsp.results)
   end
   score_idx = findfirst(x -> startswith(x[1], "/:output/:score/"), rsp.results)
   show_cell_idx = findfirst(x -> startswith(x[1], "/:output/:show_cell/"), rsp.results)
   show_flag_idx = findfirst(x -> startswith(x[1], "/:output/:show_flag/"), rsp.results)
   show_mine_idx = findfirst(x -> startswith(x[1], "/:output/:show_mine/"), rsp.results)

   score = rsp.results[score_idx][2][1][1]
   print_grid(
      get_table_dict(rsp, show_cell_idx),
      get_table_dict(rsp, show_flag_idx),
      get_table_dict(rsp, show_mine_idx),
      w, h, cx, cy)
   println("Score: ", score)

   # TODO: JSON
   # data = get_table_dict(rsp, show_cell_idx)
   # return JSON3.write(Dict("grid" => make_json(data), "score" => score))
end

function handle_display(screen_w, screen_h, screen_x, screen_y)
   @info "Running display query!"

   # cells = [(r - screen_h÷2 + screen_y, c - screen_w÷2 + screen_x)
   #          for r in 1:screen_h, c in 1:screen_w]
   # @show cells
   #     $(join((
   #        "def output[:grid, $(r), $(c)]: display_cell[$(r), $(c)]"
   #        for (r,c) in cells
   #     ), "\n"))
   rsp = exec(ctx, database, engine, """
      // keep these all arity-3 for consistency
      def output(:show_cell, x,y,c): { revealed(^Coord[x,y]) and c=mine_count[x,y] }
      def output(:show_flag, x,y,1): { flag(^Coord[x,y]) }
      def output(:show_mine, x,y,1): { exploded_mine(^Coord[x,y]) }

      def output[:score]: score
   """, readonly=true)
   return display_data(rsp, screen_w, screen_h, screen_x, screen_y)
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

      // keep these all arity-3 for consistency
      def output(:show_cell, x,y,c): { revealed(^Coord[x,y]) and c=mine_count[x,y] }
      def output(:show_flag, x,y,1): { flag(^Coord[x,y]) }
      def output(:show_mine, x,y,1): { exploded_mine(^Coord[x,y]) }

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







