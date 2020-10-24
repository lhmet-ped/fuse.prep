utils::globalVariables(
  c(
    "qnat_posto",
    "codONS",
    "info",
    "nome",
    "area_frac",
    "band",
    "count",
    "head",
    "hist",
    "inf",
    "mean_elev",
    "prec_frac",
    "sup",
    "zone",
    ".",
    "X",
    "Y",
    "name",
    "posto",
    "pr",
    "pet"
  )
)


.check_user <- function(user = "hidrometeorologista"){
  Sys.info()[["login"]] == user
}

# ------------------------------------------------------------------------------
#' Convert between units of flow volume
#'
#'This function converts between units of flow (volumetric throughput),
#'designed mainly for hydrology applications. As a special case, this function
#' can also convert units of volume or units of depth (length).
#'
#' @param x a numeric vector or time series.
#' @param from units to convert from (see Details).
#' @param to units to convert into (see Details).
#' @param area.km2 area (in square kilometres) that flow volume is averaged over.
#' This must be given when converting between measures of depth and measures of volume.
#' @param timestep.default the time step if not specified in from or to.
#' @details This function can convert flow rates between different volume units,
#' or different timestep units, or both. Volume can be specified directly, or
#' as a depth and area combination. The unit specifications from and to can
#' include a time step, like "volume / timestep". A multiplier may also be
#' included with the time step, like "volume / N timesteps".
#' If no time step is specified in from and to, then it is taken to be
#' timestep.default.
#' The volume units supported are: (these can be abbreviated)
#' mL, cL, dL, L, daL, hL, kL, ML, GL, TL
#' cm^3, dm^3, m^3, km^3, ft^3
#' The depth units supported are: (these can be abbreviated)
#' mm, cm, metres, km, inches, feet
#' The time units supported are: (these can be abbreviated)
#' ms, seconds, minutes, hours, days, weeks, months, years / annum
#' Additionally, the value "cumecs" (cubic metres per second) is equivalent to
#' "m^3/sec".
#' @source hydromad r package
#' @author Felix Andrews felix@nfrac.org
#' @return numeric vector with flow in the new units
#' @export
#'
#' @examples
#' convert_flow(300, from = "m^3/sec", to = "mm/day", area.km2 = 10^4)
convert_flow <- function(x,
                         from = "mm",
                         to = "mm",
                         area.km2 = -1,
                         timestep.default = "days") {
  if (from == "cumecs") {
    from <- "m^3/sec"
  }
  if (to == "cumecs") {
    to <- "m^3/sec"
  }
  from.step <- to.step <- timestep.default
  if (any(grep("/", from))) {
    from.step <- sub("^.*/ *", "", from)
    from <- sub(" */.*$", "", from)
  }
  if (any(grep("/", to))) {
    to.step <- sub("^.*/ *", "", to)
    to <- sub(" */.*$", "", to)
  }
  from.mult <- gsub("[^0-9\\.]", "", from.step)
  from.step <- gsub("[0-9\\. ]", "", from.step)
  to.mult <- gsub("[^0-9\\.]", "", to.step)
  to.step <- gsub("[0-9\\. ]", "", to.step)
  timefactors <- alist(
    millisecond = , ms = 0.001, seconds = ,
    second = , sec = , s = 1, minutes = , minute = , min = 60,
    hours = , hour = , hr = , h = 60 * 60, days = , day = ,
    d = 24 * 60 * 60, weeks = , week = 7 * 24 * 60 * 60,
    months = , month = , mon = 30.4375 * 24 * 60 * 60, annum = ,
    anna = , a = , years = , year = , yr = , y = 365.25 *
      24 * 60 * 60
  )
  from.secs <- do.call(switch, c(from.step, timefactors))
  to.secs <- do.call(switch, c(to.step, timefactors))
  if (is.null(from.secs) || is.null(to.secs)) {
    stop("unrecognised time unit")
  }
  if (nchar(from.mult) > 0) {
    from.secs <- from.secs * as.numeric(from.mult)
  }
  if (nchar(to.mult) > 0) {
    to.secs <- to.secs * as.numeric(to.mult)
  }
  depthUnits <- c(
    "mm", "cm", "metres", "km", "inches", "feet",
    "ft"
  )
  volUnits <- c(
    "mL", "cL", "dL", "L", "daL", "hL", "kL", "ML",
    "GL", "TL", "cm3", "dm3", "m3", "km3", "ft3", "cm^3",
    "dm^3", "m^3", "km^3", "ft^3"
  )
  allUnits <- c(depthUnits, volUnits)
  from <- match.arg(from, allUnits)
  to <- match.arg(to, allUnits)
  if ((from %in% depthUnits) != (to %in% depthUnits)) {
    if (missing(area.km2)) {
      stop("need to give 'area.km2'")
    }
  }
  Litres <- (1 / area.km2) / 1e+06
  vfactors <- alist(
    mm = 1, cm = 10, metres = , metre = , m = 1000,
    km = 1000 * 1000, inches = , inch = , `in` = 25.4, feet = ,
    ft = 304.8, mL = , cm3 = , `cm^3` = 0.001 * Litres, cL = 0.01 *
      Litres, dL = 0.1 * Litres, L = , dm3 = , `dm^3` = Litres,
    daL = 10 * Litres, hL = 100 * Litres, kL = , m3 = , `m^3` = 1000 *
      Litres, ML = 1e+06 * Litres, GL = 1e+09 * Litres,
    TL = , km3 = , `km^3` = 1e+12 * Litres, ft3 = , `ft^3` = 1 / 0.0353146667 *
      Litres, stop("unrecognised volume unit")
  )
  x <- x * do.call(switch, c(from, vfactors))
  x <- x / do.call(switch, c(to, vfactors))
  x <- x * (to.secs / from.secs)
  x
}
