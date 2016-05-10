#####################
# Unit tests
#####################

facts("DeltaDistribution unit tests") do
    context("DeltaDistribution() should initialize a delta distribution") do
        @fact DeltaDistribution().m --> 1.0
        @fact DeltaDistribution(2.0).m --> 2.0
        @fact typeof(DeltaDistribution()) --> DeltaDistribution{Float64}
    end

    context("DeltaDistribution can be sampled") do
        @fact sample(DeltaDistribution(2.0)) --> 2.0
    end

    context("There should be no such thing as vague(DeltaDistribution)") do
        @fact_throws vague(DeltaDistribution)
        @fact_throws vague(DeltaDistribution{Float64})
    end

    context("prod! involving DeltaDistributions") do
        @fact DeltaDistribution(2.0) * DeltaDistribution(2.0) --> DeltaDistribution(2.0)
        @fact_throws DeltaDistribution(1.0) * DeltaDistribution(2.0)
    end

    context("Numbers should convert to DeltaDistribution") do
        @fact convert(ProbabilityDistribution, 3.0) --> DeltaDistribution(3.0)
    end
end
