\name{plot.bdgraph}
\alias{plot.bdgraph}

\title{ Plot function for \code{S3} class \code{"bdgraph"} }

\description{ Visualizes structure of the selected graphs which could be a graph with links for which their estimated posterior probabilities are greater than 0.5
or graph with the highest posterior probability. }

\usage{ \method{plot}{bdgraph}( x, cut = 0.5, number.g = NULL, layout = layout.circle, ... ) }

\arguments{
  \item{x}{ An object of \code{S3} class \code{"bdgraph"}, from function \code{\link{bdgraph}}. }
  
  \item{cut}{ Threshold for including the links in the selected graph based on the estimated posterior probabilities of the links; See the examples. } 

  \item{number.g}{ The number of graphs with the highest probabilities. This option works for the case running function \code{bdgraph()} with option \code{save = TRUE}; See the examples. }
  
  \item{layout}{The vertex placement algorithm which is according to \code{R} package \code{\link[igraph]{igraph}}. }
  
  \item{\dots}{System reserved (no specific usage).}
}

\references{
Mohammadi, A. and Wit, E. C. (2015). Bayesian Structure Learning in Sparse Gaussian Graphical Models, \emph{Bayesian Analysis}, 10(1):109-138

Mohammadi, A. and Wit, E. C. (2017). \pkg{BDgraph}: An \code{R} Package for Bayesian Structure Learning in Graphical Models, \emph{arXiv preprint arXiv:1501.05108v5} 

Letac, G., Massam, H. and Mohammadi, R. (2018). The Ratio of Normalizing Constants for Bayesian Graphical Gaussian Model Selection, \emph{arXiv preprint arXiv:1706.04416v2} 

Dobra, A. and Mohammadi, R. (2018). Loglinear Model Selection and Human Mobility, \emph{Annals of Applied Statistics}, 12(2):815-845

Mohammadi, A. et al (2017). Bayesian modelling of Dupuytren disease by using Gaussian copula graphical models, \emph{Journal of the Royal Statistical Society: Series C}, 66(3):629-645 
}

\author{ Reza Mohammadi \email{a.mohammadi@uva.nl} and Ernst Wit }

\seealso{ \code{\link{bdgraph}}, \code{\link{bdgraph.mpl}} }

\examples{
\dontrun{
# Generating multivariate normal data from a 'random' graph
data.sim <- bdgraph.sim( n = 50, p = 6, size = 7, vis = TRUE )
   
bdgraph.obj <- bdgraph( data = data.sim )
   
plot( bdgraph.obj )
   
bdgraph.obj <- bdgraph( data = data.sim, save = TRUE )
   
plot( bdgraph.obj, number.g = 4 )
  
plot( bdgraph.obj, cut = 0.4 )
}
}
