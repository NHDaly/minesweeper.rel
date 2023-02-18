using Genie
using RAI
using JSON3

index = joinpath(dirname(@__DIR__),"ui/index.html")
route("/") do
   read(index, String)
end
route("/display") do
   #  rsp = exec(ctx, database, engine, """
   #      def output = display_cell
   #  """, readonly=true)
   #  rsp.results[]
   @info "Query output"
   data = [(;row = r, col = c, cell = v) for (r,c,v) in [(0,1,"1"), (2,3,".")]]
   JSON3.write(data)
end
route("/test_cell") do
   @info "Test Cell"
   row, col = parse.(Int, (params(:row), params(:col)))
   @show row,col

   @info "TODO: actual transaction"
   # exec(ctx, database, engine, """
   #     def current_user = ^Player["nhdaly", "this is my password"]
   #     def insert:test = coords:gc[^ScreenCoord[$row, $col]]
   #     def output:score = player_score
   #     def output:display = display
   # """ , readonly=false)

   return ""
end
route("/flag_cell") do
   @info "Flag Cell"
   row, col = parse.(Int, (params(:row), params(:col)))
   @show row,col

   @info "TODO: actual transaction"
   # exec(ctx, database, engine, """
   #     def current_user = ^Player["nhdaly", "this is my password"]
   #     def insert:flag = coords:gc[^ScreenCoord[$row, $col]]
   #     def output:score = player_score
   #     def output:display = display
   # """ , readonly=false)

   return ""

end


