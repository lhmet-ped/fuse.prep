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
                  zone = 1:nrow(.))
  z_bands
}


#' Fraction of the catchment covered by each Elevation band
#'
#' @param z raster or numeric vector
#' @inheritParams elev_bands
#' @noRd
#' @family elevation bands functions
#'
z_bands <- function(z, dz = 100, nbands = NULL){

  checkmate::assert(
    checkmate::check_null(dz),
    checkmate::check_null(nbands)
  )

  if(is.null(nbands)) checkmate::assert_number(dz)
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
    dplyr::select(zone, dplyr::everything())
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
#' @param quiet Hide messages (FALSE, the default), or display them.
#' @export
#' @return a \link[tibble:tibble-package]{tibble} with fraction of precipitation
#' and elevation covered by elevation bands. The output columns in this tibble
#' are:
#' \describe{
#'  \item{zone}{indice elevation zone}
#'  \item{inf}{lower limit of elevation band}
#'  \item{sup}{upper limit of elevation band}
#'  \item{mean_elev}{mid point of elevation band}
#'  \item{area_frac}{fraction of the catchment covered by the elevation band}
#'  \item{prec_frac}{fraction of catchment precipitation that falls on the
#'  elevation band}
#' }
#' @examples
#' \dontrun{
#'   if(FALSE){
#'    elev_bands(con_dem = condem74, meteo_raster = precclim74, dz = 100)
#'   }
#' }
#' @family elevation bands functions
#' @seealso \code{\link[raster]{cut}}, \code{\link[raster]{resample}},
#' \code{\link[raster]{zonal}}
elev_bands <- function(
  con_dem, meteo_raster = NULL, dz = 100, nbands = NULL, quiet = FALSE
  ) {
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
  if(!quiet) raster::rasterOptions(progress = "text")

  prec_res <- raster::resample(meteo_raster, rbands)
  rm(meteo_raster, con_dem)

  # plot(prec_clim_res); plot(st_geometry(poly_station), add = TRUE)
  zone_frac <- raster::zonal(prec_res,
    rbands,
    fun = "sum"
  ) %>%
    tibble::as_tibble() %>%
    #dplyr::rename("band" = zone, "prec_frac" = sum) %>%
    dplyr::rename("prec_frac" = sum) %>%
    dplyr::mutate(prec_frac = prec_frac / sum(prec_frac))

  zone_frac <- dplyr::full_join(zone_frac, bands, by = "zone") %>%
    dplyr::select(zone, inf, sup, mean_elev, area_frac, prec_frac)

  checkmate::assert(
    abs(sum(zone_frac$area_frac) - 1) <= 1E-6,
    abs(sum(zone_frac$prec_frac) - 1) <= 1E-6
  )

  # sum(zone_frac$frac_prec)

  zone_frac
}


#------------------------------------------------------------------------------
#' Check input arguments has expected values and return required vars in z_bands
#' @noRd
#' @family elevation bands functions
.check_input <- function(z_bands, ctrd, file){
  var_names <- c("area_frac", "mean_elev", "prec_frac")
  req_vars <- c("zone", var_names)
  checkmate::assert_subset(req_vars, names(z_bands))
  checkmate::assert_subset(c("lon", "lat"), names(ctrd))
  checkmate::assert_class(ctrd, "data.frame")
  checkmate::assert_directory_exists(dirname(file))
  req_vars
}



#' Select attribute list element of a variable
#' @noRd
#' @family elevation bands functions
.select_attr_var <- function(att_list, var_name){
  att_list[[which(unlist(purrr::map(att_list, "name")) == var_name)]]
}

#' Elevation bands NetCDF file
#'
#' @inheritParams elev_bands
#' @param ccoords a \link[tibble:tibble-package]{tibble} with columns `lon`
#' and `lat`.
#' @param file_nc character, path to NetCDF file
#' @param na scalar numeric, Default: -9999
#' @inheritParams ncdf4::nc_create
#' @return character, path to the NetCDF file.
#' @export
#'
#' @source \url{https://github.com/naddor/tofu/blob/master/input_output_settings/create_elev_bands_nc.R}
#' @examples
#' \dontrun{
#' if (FALSE) {
#'   elev_bands_nc(
#'     con_dem = condem74,
#'     meteo_raster = precclim74,
#'     dz = 100,
#'     ccoords = centroids(poly74),
#'     file_nc = file.path(tempdir(), "elevation_bands_74.nc"),
#'     na = -9999
#'   )
#' }}
#' @family elevation bands functions
elev_bands_nc <- function(con_dem,
                          meteo_raster,
                          dz = 100,
                          nbands = NULL,
                          ccoords,
                          file_nc = "inst/extdata/posto74_elevation_bands.nc",
                          na = -9999,
                          force_v4 = TRUE,
                          quiet = FALSE
                          ) {

  elev_tab <- elev_bands(con_dem, meteo_raster, dz, nbands, quiet)
  req_vars <- .check_input(elev_tab, ccoords, file_nc)
  var_names <- req_vars[req_vars != "zone"]

  elev_tab <- dplyr::select(elev_tab, dplyr::all_of(req_vars))

  # define dimensions
  dim_atts_l <- tibble::tibble(
    name = c("longitude", "latitude", "elevation_band"),
    units = c("degreesE", "degreesN", "-"),
    vals = list(
      ccoords[["lon"]],
      ccoords[["lat"]],
      sort(elev_tab[["zone"]])
    )
  ) %>%
    purrr::pmap(., ncdf4::ncdim_def)

  ## names(dim_atts_l) <- c("dim_lon", "dim_lat", "dim_elev_bands")

  # define variables
  long_names <- c(
    "Fraction of the catchment covered by each elevation band",
    "Mid-point elevation of each elevation band",
    "Fraction of catchment precipitation that falls on each elevation band"
  )
  names(long_names) <- var_names

  # define variables attributes
  vars_atts_l <- tibble::tibble(
    name = names(long_names),
    units = c("-", "m asl", "-"),
    dim = lapply(1:length(name), function(i) dim_atts_l),
    missval = rep(na, length(name)),
    longname = long_names
  ) %>%
    purrr::pmap(ncdf4::ncvar_def)

 # open nc
  nc_conn <- ncdf4::nc_create(
    filename = file_nc,
    vars = vars_atts_l,
    force_v4
  )

  # write variables to file
  lapply(
    var_names,
    function(ivar) {
      ncdf4::ncvar_put(
        nc = nc_conn,
        varid = .select_attr_var(vars_atts_l, ivar),
        vals = elev_tab[[ivar]]
      )

    }
  )

  ncdf4::nc_close(nc_conn)
  checkmate::assert_file_exists(file_nc)
  file_nc
}



#-------------------------------------------------------------------------------
#' Centroids within polygons
#' @noRd
#' @references
#' \url{https://stackoverflow.com/questions/52522872/r-sf-package-centroid-within-polygon}
#' \url{https://stackoverflow.com/users/3609772/mitch}.
#' @family elevation bands functions
st_centroid_within_poly <- function(poly) {
  # poly = poly74
  checkmate::assert_choice("codONS", names(poly))
  poly <- poly["codONS"]
  # check if centroid is in polygon
  ctrd <- suppressWarnings(sf::st_centroid(poly, of_largest_polygon = TRUE))
  in_poly <- diag(suppressMessages(sf::st_within(ctrd, poly, sparse = FALSE)))
  # replace geometries that are not within polygon with st_point_on_surface()
  sf::st_geometry(ctrd[!in_poly, ]) <-
    suppressWarnings(sf::st_geometry(sf::st_point_on_surface(poly[!in_poly, ])))
  ctrd
}

#' Centroid of polygon
#' @inheritParams spatial_average
#' @inheritParams HEgis::prep_poly_posto
#' @return a \link[tibble:tibble-package]{tibble} with columns `lon` and `lat`.
#' @export
#' @family elevation bands functions
#' @seealso \code{\link[HEgis]{prep_poly_posto}}, \code{\link{prep_poly_posto}}
centroids <- function(poly_station, ref_crs = "+proj=longlat +datum=WGS84"){

  if(!is.null(ref_crs)){
    poly_station <- HEgis::prep_poly_posto(poly_station, 0, ref_crs)
  }

  # poly_station = poly74
  cll <- st_centroid_within_poly(poly_station)
  #plot(st_geometry(poly_station))
  #plot(cll, add = TRUE)
  cll <- cll %>%
    sf::st_coordinates() %>%
    tibble::as_tibble() %>%
    dplyr::rename("lon" = X, "lat" = Y) %>%
    dplyr::mutate(id = poly_station[["codONS"]])
  cll
}
