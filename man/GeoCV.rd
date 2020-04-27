\name{GeoCV}  
\alias{GeoCV}
\encoding{UTF-8}
\title{n-fold  kriging Cross-validation}
\description{The procedure use the \code{\link{GeoKrig}} function to compute n-fold  kriging cross-validation 
  using informations from a \code{\link{GeoFit}} object.}
\usage{GeoCV(fit, K=100, n.fold=0.05,local=FALSE,
                    maxdist=NULL,maxtime=NULL,sparse=FALSE, which=1,seed=1)}
\arguments{
  \item{fit}{An object of class
    \code{\link{GeoFit}}.}
     \item{K}{The number of iterations in cross-validation.}
       \item{n.fold}{Numeric; the percentage of data to be deleted (and predicted) in the cross-validation procedure.}
       \item{local}{Logical; If local is TRUE, then local kriging is performed. The default is FALSE.}
         \item{maxdist}{Numeric; an optional positive value indicating the distance in the spatial neighborhood.}
       \item{maxtime}{Numeric; an optional positive value indicating the distance in the temporal neighborhood.}
       \item{sparse}{Logical; if \code{TRUE} kriging is computed with sparse matrices algorithms 
          using spam package. Default is FALSE. It should be used with compactly supported covariances.} 
      \item{which}{Numeric; In the case of bivariate (tapered) cokriging it indicates which variable to predict.
           It can be 1 or 2}
     \item{seed}{Numeric; The seed used in the  n-fold  kriging cross-validation. Default is 1. Comparison between
     different models in terms  of n-fold  kriging cross-validation must be performed using the same seed}
}

\value{  
  Returns numeric vectors of root mean squared error (RMSE) and 
  mean absolute errror (MAE) 
}


\seealso{\code{\link{GeoKrig}}.}

\author{Moreno Bevilacqua, \email{moreno.bevilacqua@uv.cl},\url{https://sites.google.com/a/uv.cl/moreno-bevilacqua/home},
Víctor Morales Oñate, \email{victor.morales@uv.cl}, \url{https://sites.google.com/site/moralesonatevictor/}
}




\keyword{Composite}
