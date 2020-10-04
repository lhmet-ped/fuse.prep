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


#' Elevation bands NetCDF file
#'
#' @param elev_tab data.frame output from \code{\link{elev_bands}}
#' @param ccoords a \link[tibble:tibble-package]{tibble} with columns `lon`
#' and `lat`.
#' @param file_nc character, path to NetCDF file
#' @param na scalar numeric, Default: -9999
#'
#' @return character, path to the NetCDF file.
#' @export
#'
#' @source \url{https://github.com/naddor/tofu/blob/master/input_output_settings/create_elev_bands_nc.R}
#' @examples
#' if (FALSE) {
#'   elevation_tab <- elev_bands(
#'     con_dem = condem74, meteo_raster = precclim74, dz = 100
#'   )
#'   elev_bands_nc(
#'     elev_tab = elevation_tab,
#'     ccoords = centroids(poly74)
#'     file_nc = file.path(tempdir(), "elevation_bands_74.nc"),
#'     na = -9999
#'   )
#' }
elev_bands_nc <- function(elev_tab,
                          ccoords,
                          file_nc = "inst/extdata/elevation_bands_74.nc",
                          na = -9999,
                          force_v4 = TRUE,
                          overwrite = FALSE) {

  # elev_tab = elev_tab_format; ccoords = poly_coords
  var_names <- c("area_frac", "mean_elev", "prec_frac")
  req_vars <- c("zone", var_names)
  checkmate::assert_subset(req_vars, names(elev_tab))
  checkmate::assert_subset(c("lon", "lat"), names(ccoords))
  checkmate::assert_class(ccoords, "data.frame")
  checkmate::assert_directory_exists(dirname(file_nc))

  elev_tab_format <- dplyr::select(
    elev_tab_format,
    dplyr::all_of(req_vars)
  )

  # define dimensions
  dim_elev_bands <- ncdf4::ncdim_def(
    name = "elevation_band",
    units = "-",
    vals = sort(elev_tab_format$zone)
  )

  dim_lon <- ncdf4::ncdim_def(
    name = "longitude",
    units = "degreesE",
    vals = ccoords[["lon"]]
  )

  dim_lat <- ncdf4::ncdim_def(
    name = "latitude",
    units = "degreesN",
    vals = ccoords[["lat"]]
  )

  dim_list <- list(dim_lon, dim_lat, dim_elev_bands)

  # dim_atts <- tibble::tibble(
  #   name = c("longitude", "latitude", "elevation_band"),
  #   units = c("degreesE", "degreesN", "-"),
  #   vals = list(
  #     ccoords[["lon"]],
  #     ccoords[["lat"]],
  #     sort(elev_tab_format[["zone"]])
  #   )
  # ) %>%
  #   purrr::pmap(., ncdf4::ncdim_def)

  ## names(dim_atts) <- c("dim_lon", "dim_lat", "dim_elev_bands")

  ## all.equal(dim_atts,dim_list)


  # define variables
  area_frac_nc <- ncdf4::ncvar_def(
    name = "area_frac",
    units = "-",
    dim = dim_list,
    missval = na,
    longname = "Fraction of the catchment covered by each elevation band"
  )
  mean_elev_nc <- ncdf4::ncvar_def(
    name = "mean_elev",
    units = "m asl",
    dim = dim_list,
    missval = na,
    longname = "Mid-point elevation of each elevation band"
  )

  prec_frac_nc <- ncdf4::ncvar_def(
    name = "prec_frac",
    units = "-",
    dim = dim_list,
    missval = na,
    longname = "Fraction of catchment precipitation that falls on each elevation band"
  )



  # long_names <- c(
  #   "Fraction of the catchment covered by each elevation band",
  #   "Mid-point elevation of each elevation band",
  #   "Fraction of catchment precipitation that falls on each elevation band"
  # )
  # names(long_names) <- var_names
  #
  # vars_atts_l <- tibble::tibble(
  #   name = names(long_names),
  #   units = c("-", "m asl", "-"),
  #   dim = lapply(1:length(name), function(i) dim_atts),
  #   missval = rep(na, length(name)),
  #   longname = long_names
  # ) %>%
  #   purrr::pmap(ncdf4::ncvar_def)

  ## vars_list <- list(area_frac_nc, mean_elev_nc, prec_frac_nc)
  ## all.equal(vars_atts, vars_list)


 # open nc
  nc_conn <- ncdf4::nc_create(
    file_nc,
    list(area_frac_nc,mean_elev_nc,prec_frac_nc)
  )

  # nc_conn <- ncdf4::nc_create(
  #   filename = file_nc,
  #   vars = vars_atts,
  #   force_v4
  # )

  # write variables to file
  ncdf4::ncvar_put(nc_conn, area_frac_nc, vals = elev_tab_format$area_frac)
  ncdf4::ncvar_put(nc_conn, mean_elev_nc, vals = elev_tab_format$mean_elev)
  ncdf4::ncvar_put(nc_conn, prec_frac_nc, vals = elev_tab_format$prec_frac)


  # lapply(
  #   var_names,
  #   function(ivar) {
  #     # ivar = "prec_frac"
  #     vars_att_sel <- vars_atts_l[[which(unlist(map(vars_atts_l, "name")) == ivar)]]
  #     #all.equal(vars_att_sel, prec_frac_nc)
  #     ncdf4::ncvar_put(
  #       nc = nc_conn,
  #       varid = vars_att_sel,
  #       vals = elev_tab_format[[ivar]]
  #     )
  #   }
  # )

  ncdf4::nc_close(nc_conn)
  checkmate::assert_file_exists(file_nc)
  file_nc
}



#-------------------------------------------------------------------------------
#' Centroids
#' @noRd
#' @source
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
#' @return a \link[tibble:tibble-package]{tibble} with columns `lon` and `lat`.
#' @export
centroids <- function(poly_station){
  cll <- st_centroid_within_poly(poly_station)
  #plot(st_geometry(poly_station))
  #plot(cll, add = TRUE)
  cll <- tibble::as_tibble(sf::st_coordinates(cll))
  dplyr::rename(cll, "lon" = X, "lat" = Y)
}
