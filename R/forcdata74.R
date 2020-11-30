#' Forcing time series of hydrometeorological variables.
#'
#' As of Oct 2020.
#'
#' @format A tibble with 13,149 daily observations, and 6 variables:
#' \describe{
#' \item{date}{date object, start 1980-01-01, end 2015-12-31}
#' \item{id}{numeric vector, id of ONS station}
#' \item{temp}{numeric vector, monthly average temperature in °C}
#' \item{pr}{numeric vector, precipitation in mm/day}
#' \item{pet}{numeric vector, potential ET in mm/day}
#' \item{q_obs}{optional, numeric vector, river discharge in mm/day}
#' }
#' @note Since FUSE require temperature only for the snow model, the daily
#' temperature refers to monthly climatological averages.
#' @source temperature data from \url{https://www.worldclim.org/data/worldclim21.html}
#'
#' @references https://rmets.onlinelibrary.wiley.com/doi/full/10.1002/joc.4518
"forcdata74"


