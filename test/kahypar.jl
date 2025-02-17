using OMEinsum
using LightGraphs
using Test, Random
using SparseArrays
using OMEinsumContractionOrders

@testset "kahypar" begin
    Random.seed!(2)
    function random_regular_eincode(n, k)
        g = LightGraphs.random_regular_graph(n, k)
        ixs = [minmax(e.src,e.dst) for e in LightGraphs.edges(g)]
        return EinCode((ixs..., [(i,) for i in LightGraphs.vertices(g)]...), ())
    end

    g = random_regular_graph(220, 3)
    rows = Int[]
    cols = Int[]
    for (i,edge) in enumerate(edges(g))
        push!(rows, edge.src, edge.dst)
        push!(cols, i, i)
    end
    graph = sparse(rows, cols, ones(Int, length(rows)))
    sc_target = 28.0
    group1, group2 = OMEinsumContractionOrders.kahypar_partitions_sc(graph, collect(1:size(graph, 1)); log2_sizes=fill(1, size(graph, 2)), sc_target=sc_target, imbalances=[0.0:0.02:0.8...])
    @test OMEinsumContractionOrders.group_sc(graph, group1) <= sc_target
    @test OMEinsumContractionOrders.group_sc(graph, group2) <= sc_target
    sc_target = 27.0
    group11, group12 = OMEinsumContractionOrders.kahypar_partitions_sc(graph, group1; log2_sizes=fill(1, size(graph, 2)), sc_target=37.0, imbalances=[0.0:0.02:1.0...])
    @test OMEinsumContractionOrders.group_sc(graph, group11) <= sc_target
    @test OMEinsumContractionOrders.group_sc(graph, group12) <= sc_target

    code = random_regular_eincode(220, 3)
    res = optimize_kahypar(code,uniformsize(code, 2); max_group_size=50, sc_target=30)
    tc, sc = OMEinsum.timespace_complexity(res, uniformsize(code, 1))
    @test sc <= 30

    # contraction test
    code = random_regular_eincode(50, 3)
    codeg = optimize_kahypar(code, uniformsize(code, 2); max_group_size=10, sc_target=12)
    codek = optimize_greedy(code, uniformsize(code, 2))
    tc, sc = OMEinsum.timespace_complexity(codek, uniformsize(code, 1))
    @test sc <= 12
    xs = [[2*randn(2, 2) for i=1:75]..., [randn(2) for i=1:50]...]
    resg = codeg(xs...)
    resk = codek(xs...)
    @test resg ≈ resk
end