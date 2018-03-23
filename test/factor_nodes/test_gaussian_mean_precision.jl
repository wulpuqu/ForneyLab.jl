module GaussianMeanPrecisionTest

using Base.Test
using ForneyLab
import ForneyLab: outboundType, isApplicable
import ForneyLab: SPGaussianMeanPrecisionOutVPP, SPGaussianMeanPrecisionMPVP, SPGaussianMeanPrecisionOutVGP, SPGaussianMeanPrecisionMGVP, VBGaussianMeanPrecisionOut, VBGaussianMeanPrecisionM, VBGaussianMeanPrecisionW, SVBGaussianMeanPrecisionOutVGD, SVBGaussianMeanPrecisionMGVD, SVBGaussianMeanPrecisionW, MGaussianMeanPrecisionGGD


#-------------
# Update rules
#-------------

@testset "SPGaussianMeanPrecisionOutVPP" begin
    @test SPGaussianMeanPrecisionOutVPP <: SumProductRule{GaussianMeanPrecision}
    @test outboundType(SPGaussianMeanPrecisionOutVPP) == Message{Gaussian}
    @test isApplicable(SPGaussianMeanPrecisionOutVPP, [Void, Message{PointMass}, Message{PointMass}]) 
    @test !isApplicable(SPGaussianMeanPrecisionOutVPP, [Message{PointMass}, Void, Message{PointMass}]) 

    @test ruleSPGaussianMeanPrecisionOutVPP(nothing, Message(Univariate, PointMass, m=1.0), Message(Univariate, PointMass, m=2.0)) == Message(Univariate, Gaussian, m=1.0, w=2.0)
    @test ruleSPGaussianMeanPrecisionOutVPP(nothing, Message(Multivariate, PointMass, m=[1.0]), Message(MatrixVariate, PointMass, m=mat(2.0))) == Message(Multivariate, Gaussian, m=[1.0], w=mat(2.0))
end

@testset "SPGaussianMeanPrecisionMPVP" begin
    @test SPGaussianMeanPrecisionMPVP <: SumProductRule{GaussianMeanPrecision}
    @test outboundType(SPGaussianMeanPrecisionMPVP) == Message{Gaussian}
    @test !isApplicable(SPGaussianMeanPrecisionMPVP, [Void, Message{PointMass}, Message{PointMass}]) 
    @test isApplicable(SPGaussianMeanPrecisionMPVP, [Message{PointMass}, Void, Message{PointMass}]) 

    @test ruleSPGaussianMeanPrecisionMPVP(Message(Univariate, PointMass, m=1.0), nothing, Message(Univariate, PointMass, m=2.0)) == Message(Univariate, Gaussian, m=1.0, w=2.0)
    @test ruleSPGaussianMeanPrecisionMPVP(Message(Multivariate, PointMass, m=[1.0]), nothing, Message(MatrixVariate, PointMass, m=mat(2.0))) == Message(Multivariate, Gaussian, m=[1.0], w=mat(2.0))
end

@testset "SPGaussianMeanPrecisionOutVGP" begin
    @test SPGaussianMeanPrecisionOutVGP <: SumProductRule{GaussianMeanPrecision}
    @test outboundType(SPGaussianMeanPrecisionOutVGP) == Message{Gaussian}
    @test isApplicable(SPGaussianMeanPrecisionOutVGP, [Void, Message{Gaussian}, Message{PointMass}]) 
    @test !isApplicable(SPGaussianMeanPrecisionOutVGP, [Message{Gaussian}, Void, Message{PointMass}]) 

    @test ruleSPGaussianMeanPrecisionOutVGP(nothing, Message(Univariate, Gaussian, m=1.0, v=1.0), Message(Univariate, PointMass, m=2.0)) == Message(Univariate, Gaussian, m=1.0, v=1.5)
    @test ruleSPGaussianMeanPrecisionOutVGP(nothing, Message(Multivariate, Gaussian, m=[1.0], v=mat(1.0)), Message(MatrixVariate, PointMass, m=mat(2.0))) == Message(Multivariate, Gaussian, m=[1.0], v=mat(1.5))
end

@testset "SPGaussianMeanPrecisionMGVP" begin
    @test SPGaussianMeanPrecisionMGVP <: SumProductRule{GaussianMeanPrecision}
    @test outboundType(SPGaussianMeanPrecisionMGVP) == Message{Gaussian}
    @test !isApplicable(SPGaussianMeanPrecisionMGVP, [Void, Message{Gaussian}, Message{PointMass}]) 
    @test isApplicable(SPGaussianMeanPrecisionMGVP, [Message{Gaussian}, Void, Message{PointMass}]) 

    @test ruleSPGaussianMeanPrecisionMGVP(Message(Univariate, Gaussian, m=1.0, v=1.0), nothing, Message(Univariate, PointMass, m=2.0)) == Message(Univariate, Gaussian, m=1.0, v=1.5)
    @test ruleSPGaussianMeanPrecisionMGVP(Message(Multivariate, Gaussian, m=[1.0], v=mat(1.0)), nothing, Message(MatrixVariate, PointMass, m=mat(2.0))) == Message(Multivariate, Gaussian, m=[1.0], v=mat(1.5))
end

@testset "VBGaussianMeanPrecisionM" begin
    @test VBGaussianMeanPrecisionM <: NaiveVariationalRule{GaussianMeanPrecision}
    @test outboundType(VBGaussianMeanPrecisionM) == Message{Gaussian}
    @test isApplicable(VBGaussianMeanPrecisionM, [ProbabilityDistribution, Void, ProbabilityDistribution]) 
    @test !isApplicable(VBGaussianMeanPrecisionM, [ProbabilityDistribution, ProbabilityDistribution, Void]) 

    @test ruleVBGaussianMeanPrecisionM(ProbabilityDistribution(Univariate, Gaussian, m=3.0, v=4.0), nothing, ProbabilityDistribution(Univariate, Gamma, a=1.0, b=2.0)) == Message(Univariate, Gaussian, m=3.0, w=0.5)
    @test ruleVBGaussianMeanPrecisionM(ProbabilityDistribution(Multivariate, Gaussian, m=[3.0], v=mat(4.0)), nothing, ProbabilityDistribution(MatrixVariate, Wishart, v=mat(0.25), nu=2.0)) == Message(Multivariate, Gaussian, m=[3.0], w=mat(0.5))
end

@testset "VBGaussianMeanPrecisionW" begin
    @test VBGaussianMeanPrecisionW <: NaiveVariationalRule{GaussianMeanPrecision}
    @test outboundType(VBGaussianMeanPrecisionW) == Message{Union{Gamma, Wishart}}
    @test isApplicable(VBGaussianMeanPrecisionW, [ProbabilityDistribution, ProbabilityDistribution, Void]) 

    @test ruleVBGaussianMeanPrecisionW(ProbabilityDistribution(Univariate, Gaussian, m=3.0, v=4.0), ProbabilityDistribution(Univariate, Gaussian, m=1.0, v=2.0), nothing) == Message(Univariate, Gamma, a=1.5, b=0.5*(2.0 + 4.0 + (3.0 - 1.0)^2))
    @test ruleVBGaussianMeanPrecisionW(ProbabilityDistribution(Multivariate, Gaussian, m=[3.0], v=mat(4.0)), ProbabilityDistribution(Multivariate, Gaussian, m=[1.0], v=mat(2.0)), nothing) == Message(MatrixVariate, Wishart, v=mat(1.0/(2.0 + 4.0 + (3.0 - 1.0)^2)), nu=3.0)
end

@testset "VBGaussianMeanPrecisionOut" begin
    @test VBGaussianMeanPrecisionOut <: NaiveVariationalRule{GaussianMeanPrecision}
    @test outboundType(VBGaussianMeanPrecisionOut) == Message{Gaussian}
    @test isApplicable(VBGaussianMeanPrecisionOut, [Void, ProbabilityDistribution, ProbabilityDistribution]) 

    @test ruleVBGaussianMeanPrecisionOut(nothing, ProbabilityDistribution(Univariate, Gaussian, m=3.0, v=4.0), ProbabilityDistribution(Univariate, Gamma, a=1.0, b=2.0)) == Message(Univariate, Gaussian, m=3.0, w=0.5)
    @test ruleVBGaussianMeanPrecisionOut(nothing, ProbabilityDistribution(Multivariate, Gaussian, m=[3.0], v=mat(4.0)), ProbabilityDistribution(MatrixVariate, Wishart, v=mat(0.25), nu=2.0)) == Message(Multivariate, Gaussian, m=[3.0], w=mat(0.5))
end

@testset "SVBGaussianMeanPrecisionMGVD" begin
    @test SVBGaussianMeanPrecisionMGVD <: StructuredVariationalRule{GaussianMeanPrecision}
    @test outboundType(SVBGaussianMeanPrecisionMGVD) == Message{Gaussian}
    @test isApplicable(SVBGaussianMeanPrecisionMGVD, [Message{Gaussian}, Void, ProbabilityDistribution]) 

    @test ruleSVBGaussianMeanPrecisionMGVD(Message(Univariate, Gaussian, m=3.0, v=4.0), nothing, ProbabilityDistribution(Univariate, Gamma, a=1.0, b=2.0)) == Message(Univariate, Gaussian, m=3.0, v=6.0)
    @test ruleSVBGaussianMeanPrecisionMGVD(Message(Multivariate, Gaussian, m=[3.0], v=mat(4.0)), nothing, ProbabilityDistribution(MatrixVariate, Wishart, v=mat(0.25), nu=2.0)) == Message(Multivariate, Gaussian, m=[3.0], v=mat(6.0))
end

@testset "SVBGaussianMeanPrecisionW" begin
    @test SVBGaussianMeanPrecisionW <: StructuredVariationalRule{GaussianMeanPrecision}
    @test outboundType(SVBGaussianMeanPrecisionW) == Message{Union{Gamma, Wishart}}
    @test isApplicable(SVBGaussianMeanPrecisionW, [ProbabilityDistribution, Void]) 

    @test ruleSVBGaussianMeanPrecisionW(ProbabilityDistribution(Multivariate, Gaussian, m=[2.0, 3.0], v=[5.0 1.0; 1.0 4.0]), nothing) == Message(Univariate, Gamma, a=1.5, b=0.5*(5.0 - 2*1.0 + 4.0 + (3.0 - 2.0)^2))
    @test ruleSVBGaussianMeanPrecisionW(ProbabilityDistribution(Multivariate, Gaussian, m=[1.0, 2.0, 3.0, 4.0], v=[5.0 1.0 0.5 0.0; 1.0 4.0 2.0 0.5; 0.5 2.0 3.0 1.0; 0.0 0.5 1.0 2.0]), nothing) == Message(MatrixVariate, Wishart, v=cholinv([5.0 1.0; 1.0 4.0] - [0.5 0.0; 2.0 0.5] - [0.5 2.0; 0.0 0.5] + [3.0 1.0; 1.0 2.0] + ([1.0, 2.0] - [3.0, 4.0])*([1.0, 2.0] - [3.0, 4.0])'), nu=4.0)
end

@testset "SVBGaussianMeanPrecisionOutVGD" begin
    @test SVBGaussianMeanPrecisionOutVGD <: StructuredVariationalRule{GaussianMeanPrecision}
    @test outboundType(SVBGaussianMeanPrecisionOutVGD) == Message{Gaussian}
    @test isApplicable(SVBGaussianMeanPrecisionOutVGD, [Void, Message{Gaussian}, ProbabilityDistribution]) 

    @test ruleSVBGaussianMeanPrecisionOutVGD(nothing, Message(Univariate, Gaussian, m=3.0, v=4.0), ProbabilityDistribution(Univariate, Gamma, a=1.0, b=2.0)) == Message(Univariate, Gaussian, m=3.0, v=6.0)
    @test ruleSVBGaussianMeanPrecisionOutVGD(nothing, Message(Multivariate, Gaussian, m=[3.0], v=mat(4.0)), ProbabilityDistribution(MatrixVariate, Wishart, v=mat(0.25), nu=2.0)) == Message(Multivariate, Gaussian, m=[3.0], v=mat(6.0))
end

@testset "MGaussianMeanPrecisionGGD" begin
    @test MGaussianMeanPrecisionGGD <: MarginalRule{GaussianMeanPrecision}
    @test isApplicable(MGaussianMeanPrecisionGGD, [Message{Gaussian}, Message{Gaussian}, ProbabilityDistribution]) 

    @test ruleMGaussianMeanPrecisionGGD(Message(Univariate, Gaussian, m=1.0, w=2.0), Message(Univariate, Gaussian, m=3.0, w=4.0), ProbabilityDistribution(Univariate, Gamma, a=1.0, b=2.0)) == ProbabilityDistribution(Multivariate, Gaussian, m=[1.3636363636363638, 2.8181818181818175], v=[0.4090909090909091 0.04545454545454545; 0.04545454545454545 0.22727272727272724])
    @test ruleMGaussianMeanPrecisionGGD(Message(Multivariate, Gaussian, m=[1.0], w=mat(2.0)), Message(Multivariate, Gaussian, m=[3.0], w=mat(4.0)), ProbabilityDistribution(MatrixVariate, Wishart, v=mat(0.25), nu=2.0)) == ProbabilityDistribution(Multivariate, Gaussian, m=[1.3636363636363638, 2.8181818181818175], v=[0.4090909090909091 0.04545454545454545; 0.04545454545454545 0.22727272727272724])
end

@testset "averageEnergy and differentialEntropy" begin
    @test differentialEntropy(ProbabilityDistribution(Univariate, Gaussian, m=0.0, w=2.0)) == averageEnergy(GaussianMeanPrecision, ProbabilityDistribution(Univariate, Gaussian, m=0.0, w=2.0), ProbabilityDistribution(Univariate, PointMass, m=0.0), ProbabilityDistribution(Univariate, PointMass, m=2.0))
    @test differentialEntropy(ProbabilityDistribution(Univariate, Gaussian, m=0.0, w=2.0)) == differentialEntropy(ProbabilityDistribution(Multivariate, Gaussian, m=[0.0], w=mat(2.0)))
    @test averageEnergy(GaussianMeanPrecision, ProbabilityDistribution(Univariate, Gaussian, m=0.0, w=2.0), ProbabilityDistribution(Univariate, PointMass, m=0.0), ProbabilityDistribution(Univariate, PointMass, m=2.0)) == averageEnergy(GaussianMeanPrecision, ProbabilityDistribution(Multivariate, Gaussian, m=[0.0], w=mat(2.0)), ProbabilityDistribution(Multivariate, PointMass, m=[0.0]), ProbabilityDistribution(MatrixVariate, PointMass, m=mat(2.0)))
    @test averageEnergy(GaussianMeanPrecision, ProbabilityDistribution(Multivariate, Gaussian, m=[0.0, 1.0], v=[3.0 1.0; 1.0 2.0]), ProbabilityDistribution(Univariate, PointMass, m=2.0)) == averageEnergy(GaussianMeanPrecision, ProbabilityDistribution(Multivariate, Gaussian, m=[0.0, 1.0], v=[3.0 1.0; 1.0 2.0]), ProbabilityDistribution(MatrixVariate, PointMass, m=mat(2.0)))
end

end #module