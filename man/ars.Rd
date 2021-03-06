% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ars.R
\name{ars}
\alias{ars}
\title{Adaptive Rejection Sampling}
\usage{
ars(h, start, end, N, k = 3, x1 = NULL, xk = NULL)
}
\arguments{
\item{h}{input the original valid probability density function we want to sample from, the function h should only takes one argument x. i.e. correct: h = function(x) \{dnorm(x,0,1)\}; wrong: h = function(x,mean = 0,sd = 1) \{dnorm(x,mean,sd)\}}

\item{start}{lower bound of the domain of h(x)}

\item{end}{upper bound of the domain of h(x)}

\item{N}{sample size}

\item{k}{number of starting points, the default is 3}

\item{x1}{the right starting point, if NULL, the function will find one}

\item{xk}{the left starting point, if NULL, the function will find one}
}
\value{
a vector of N sampled value from the density h(x)
}
\description{
Adaptive Rejection Sampling from log-concave density functions h(x)
}
\examples{
library(ars)
h = function(x){dnorm(x)}
sample = ars(h = h,start = -Inf , end = Inf,N = 100)
hist(sample)
}
