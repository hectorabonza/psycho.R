% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_contrasts.stanreg.R
\name{get_contrasts.stanreg}
\alias{get_contrasts.stanreg}
\title{Compute estimated marginal means and contrasts from stanreg models.}
\usage{
\method{get_contrasts}{stanreg}(fit, formula, prob = 0.9, ...)
}
\arguments{
\item{fit}{A stanreg model.}

\item{formula}{A character vector (formula like format, i.e., including interactions or nesting terms) specifying the names of the predictors over which EMMs are desired.}

\item{prob}{A numeric scalar in the interval (0,1) giving the target probability content of the intervals. The nominal probability content of the intervals is the multiple of 1/nrow(obj) nearest to prob.}

\item{...}{Arguments passed to or from other methods.}
}
\value{
list with estimated marginal means and contrasts.
}
\description{
Compute estimated marginal means and contrasts from a stanreg models.
}
\examples{
\dontrun{
library(psycho)
require(rstanarm)
fit <- rstanarm::stan_glm(Adjusting ~ Birth_Season * Sex, data=affective)

contrasts <- get_contrasts.stanreg(fit, formula="Birth_Season * Sex")
contrasts$means

contrasts <- get_contrasts.stanreg(fit, formula="Birth_Season")
contrasts$contrasts
}
}
\author{
\href{https://dominiquemakowski.github.io/}{Dominique Makowski}
}
