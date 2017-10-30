export
ruleVBGaussianMeanPrecisionM, 
ruleVBGaussianMeanPrecisionW, 
ruleVBGaussianMeanPrecisionOut

ruleVBGaussianMeanPrecisionM(   dist_out::Univariate,
                                dist_mean::Any,
                                dist_prec::Univariate) =
    Message(Univariate(Gaussian, m=unsafeMean(dist_out), w=unsafeMean(dist_prec)))

ruleVBGaussianMeanPrecisionW(   dist_out::Univariate,
                                dist_mean::Univariate,
                                dist_prec::Any) =
    Message(Univariate(Gamma, a=1.5, b=0.5*(unsafeVar(dist_mean) + unsafeVar(dist_out) + (unsafeMean(dist_mean) - unsafeMean(dist_out))^2)))

ruleVBGaussianMeanPrecisionOut( dist_out::Any,
                                dist_mean::Univariate,
                                dist_prec::Univariate) =
    Message(Univariate(Gaussian, m=unsafeMean(dist_mean), w=unsafeMean(dist_prec)))
