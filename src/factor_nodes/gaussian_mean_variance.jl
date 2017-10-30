export GaussianMeanVariance

"""
Description:

    A Gaussian with mean-variance parameterization:

    f(out,m,v) = 𝒩(out|m,v)

Interfaces:

    1. out
    2. m (mean)
    3. v (covariance)

Construction:

    GaussianMeanVariance(out, m, v, id=:some_id)
"""
type GaussianMeanVariance <: Gaussian
    id::Symbol
    interfaces::Vector{Interface}
    i::Dict{Symbol,Interface}

    function GaussianMeanVariance(out::Variable, m::Variable, v::Variable; id=generateId(Gaussian))
        self = new(id, Array(Interface, 3), Dict{Symbol,Interface}())
        addNode!(currentGraph(), self)
        self.i[:out] = self.interfaces[1] = associate!(Interface(self), out)
        self.i[:m] = self.interfaces[2] = associate!(Interface(self), m)
        self.i[:v] = self.interfaces[3] = associate!(Interface(self), v)

        return self
    end
end

slug(::Type{GaussianMeanVariance}) = "𝒩"

# Average energy functional
function averageEnergy(::Type{GaussianMeanVariance}, marg_out::Univariate, marg_mean::Univariate, marg_var::Univariate)
    0.5*log(2*pi) +
    0.5*unsafeLogMean(marg_var) +
    0.5*unsafeInverseMean(marg_var)*( unsafeCov(marg_out) + unsafeCov(marg_mean) + (unsafeMean(marg_out) - unsafeMean(marg_mean))^2 )
end

function averageEnergy{T<:FactorNode, U<:FactorNode, V<:FactorNode, dims}(::Type{GaussianMeanVariance}, marg_out::Multivariate{T, dims}, marg_mean::Multivariate{U, dims}, marg_var::MatrixVariate{V, dims, dims})
    0.5*dims*log(2*pi) +
    0.5*unsafeDetLogMean(marg_var) +
    0.5*trace( unsafeInverseMean(marg_var)*(unsafeCov(marg_out) + unsafeCov(marg_mean) + (unsafeMean(marg_out) - unsafeMean(marg_mean))*(unsafeMean(marg_out) - unsafeMean(marg_mean))' ))
end