#------------------------------------------------------------------------------

#' Convert output from hist() to tibble
#' @noRd
#' @family elevation bands functions
#' @seealso \code{\link{hist}}
#' @note Instead of table(cut(x, br)), hist(x, br, plot = FALSE) is more
#' efficient and less memory hungry.
.hist2tab <- function(hist.list){

  brks <- hist.list$breaks
  z_bands <- brks %>%
    tibble::tibble(inf = ., sup = dplyr::lead(.)) %>%
    head(-1) %>%
    dplyr::mutate(.,
                  mean_elev = hist.list$mids,
                  count = hist.list$counts,
                  area_frac = count/sum(count),
                  band = 1:nrow(.))
  z_bands
}


#' Fraction of the catchment covered by each Elevation band
#'
#' @param z raster or numeric vector
#' @inheritParams elev_bands
#' bands).
#' @noRd
#' @family elevation bands functions
#'
z_bands <- function(z, dz = 100, nbands = NULL){
  checkmate::assert_number(dz)
  if(checkmate::test_class(z, "RasterLayer")){
    z <- raster::values(z)
  }

  #z <- values(condem74)
  z <- z[!is.na(z)]
  checkmate::assert_true(length(z) > 0)
  zrange <- range(z)

  # elevation bands using based on nbands
  if(!is.null(nbands)){
    # nbands = 4
    checkmate::assert_number(nbands)
    brks <- seq(zrange[1], zrange[2], length.out = nbands + 1)
    dist <- hist(x = z, breaks = brks, plot = FALSE)
    ftab <- .hist2tab(dist)
    return(ftab)
  }

  # elevation bands using based on a dz m for each band
  # (nbands variable between catchments)
  checkmate::assert_true(diff(zrange) > dz)
  brks <- seq(zrange[1], zrange[2], by = dz)
  if(max(brks) < zrange[2]) brks <- c(brks, brks[length(brks)] + dz)
  #discrete_dist <- table(cut(z, brks, include.lowest = TRUE))
  dist <- graphics::hist(x = z, breaks = brks, plot = FALSE)
  ftab <- .hist2tab(dist) %>%
    dplyr::select(band, dplyr::everything())
  ftab
}


#' Fraction of precipitation and catchment area by elevation bands
#'
#' @param con_dem raster of conditioned elevation of catchment
#' @param meteo_raster raster of meteorological field (precipitation,
#' evapotranspiration, ...).
#' @param dz numeric scalar, interval (m) to elevation bands. Calculates basin
#'  area distributions within 100 m elevation by default.
#' @param nbands numeric scalar. Default: NULL (use `dz` to build elevation
#' bands).
#' @export
#' @return tibble with fraction of precipitation and elevation covered by
#' elevation bands
#' @examples
#' \dontrun{
#'   if(FALSE){
#'    elev_bands(con_dem = condem74, meteo_raster = precclim74, dz = 100)
#'   }
#' }
#' @family elevation bands functions
#' @seealso \code{\link[raster]{cut}}, \code{\link[raster]{resample}},
#' \code{\link[raster]{zonal}}
elev_bands <- function(con_dem, meteo_raster = NULL, dz = 100, nbands = NULL) {
  # con_dem = condem74; meteo_raster = precclim74; dz = 100; nbands = NULL
  bands <- z_bands(z = con_dem, dz, nbands)

  if (is.null(meteo_raster)) {
    return(bands)
  }

  brks <- c(bands$inf, bands$sup[nrow(bands)]) %>%
    unique() %>%
    sort()
  rbands <- raster::cut(con_dem, breaks = brks, include.lowest = TRUE)
  # plot(rbands)
  raster::rasterOptions(progress = "text")
  prec_res <- raster::resample(meteo_raster, rbands)
  rm(meteo_raster, con_dem)

  # plot(prec_clim_res); plot(st_geometry(poly_station), add = TRUE)
  zone_frac <- raster::zonal(prec_res,
    rbands,
    fun = "sum"
  ) %>%
    tibble::as_tibble() %>%
    dplyr::rename("band" = zone, "prec_frac" = sum) %>%
    dplyr::mutate(prec_frac = prec_frac / sum(prec_frac))

  checkmate::assert(
    abs(sum(zone_frac$area_frac) - 1) > 1E-6,
    abs(sum(zone_frac$prec_frac) - 1) > 1E-6
  )

  # sum(zone_frac$frac_prec)
  zone_frac <- dplyr::full_join(zone_frac, bands, by = "band") %>%
    dplyr::select(band, inf, sup, mean_elev, area_frac, prec_frac)
  zone_frac
}



#------------------------------------------------------------------------------

