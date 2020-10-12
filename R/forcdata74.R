#' Forcing time series of hydrometeorological variables.
#'
#' As of Oct 2020.
#'
#' @format A tibble with 13,149 rows, and 5 columns columns:
#' \describe{
#' \item{date}{date object, start 1980-01-01, end 2015-12-31}
#' \item{posto}{numeric vector, id of ONS station}
#' \item{prec}{numeric vector, precipitation in mm/day}
#' \item{et0}{numeric vector, potential ET in mm/day}
#' \item{q_obs}{optional, numeric vector, river discharge in mm/day}
#' }
#' @source \url{https://github.com/lhmet-ped/fusepoc-prep}
#' @references https://rmets.onlinelibrary.wiley.com/doi/full/10.1002/joc.4518
"forcdata74"


