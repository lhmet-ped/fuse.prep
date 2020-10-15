#' Check inputs
#' @noRd
.check_inputs_meteo_forc <- function(variab_list, ctrd, dts, file) {
  all_vars <- c("temp", "pr", "pet", "q_obs")
  vnames <- names(variab_list)
  checkmate::assert_subset(vnames, all_vars)
  identical_lengths <- any(diff(unlist(lapply(variab_list, length))) != 0)
  # checkmate::assert_true(identical_lengths)
  checkmate::assert_subset(class(dts), c("Date", "POSIXct", "POSIXt"))
  checkmate::assert_subset(c("lon", "lat"), names(ctrd))
  checkmate::assert_class(ctrd, "data.frame")
  checkmate::assert_directory_exists(dirname(file))
  all_vars
}



#' Create NetCDF file of Meteorological forcings
#' @export
meteo_forcing_nc <- function(...,
                             dates,
                             ccoords,
                             file_nc = "inst/extdata/74_input.nc",
                             na = -9999,
                             force_v4 = TRUE) {


  data_list <- list(...)
  # data_list = list(pr= forcdata74$pr, pet = forcdata74$pet); dates = forcdata74$date; ccoords = centroids(poly_station = poly74); na = -9999; file_nc = "inst/extdata/74_input.nc"
  var_names <- names(data_list)

  #check inputs and def all_vars
  all_vars <- .check_inputs_meteo_forc(
    variab_list = data_list,
    dts = dates,
    ctrd = ccoords,
    file = file_nc
  )


  # define dimensions
  dim_atts_l <- tibble::tibble(
    name = c("longitude", "latitude", "time"),
    units = c("degreesE", "degreesN", "days since 1970-01-01"),
    vals = list(
      ccoords[["lon"]],
      ccoords[["lat"]],
      as.numeric(dates)
    )
  ) %>%
    purrr::pmap(., ncdf4::ncdim_def)

  spatial_mode <- "Catchment"

  # define variables
  long_names <- c(
    paste0(spatial_mode, "-averaged daily temperature"),
    paste0(spatial_mode, "-averaged daily precipitation"),
    paste0(spatial_mode, "-averaged daily potential evapotranspiration"),
    "Daily discharge"
  )
  names(long_names) <- all_vars

  var_units <- c("degC", rep("mm/day", 3))
  names(var_units) <- names(long_names)

  # define variables attributes
  vars_atts_l <- tibble::tibble(
    name = var_names,
    units = var_units[names(var_units) %in% var_names],
    dim = lapply(1:length(name), function(i) dim_atts_l),
    missval = rep(na, length(name)),
    longname = long_names[names(long_names) %in% var_names]
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
        vals = data_list[[ivar]]
      )
    }
  )
  ncdf4::nc_close(nc_conn)
  checkmate::assert_file_exists(file_nc)
  file_nc
}

# !TESTAR
#meteo_forcing_nc()
