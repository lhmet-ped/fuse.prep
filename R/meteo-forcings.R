#' Check inputs
#' @noRd
#' @family forcings functions
.check_inputs_meteo_forc <- function(variab_list, ctrd, dts, file) {
  vnames <- names(variab_list)
  checkmate::assert_subset(vnames, all_variables())
  identical_lengths <- any(diff(unlist(lapply(variab_list, length))) != 0)
  # checkmate::assert_true(identical_lengths)
  checkmate::assert_subset(class(dts), c("Date", "POSIXct", "POSIXt"))
  checkmate::assert_subset(c("lon", "lat", "id"), names(ctrd))
  checkmate::assert_class(ctrd, "data.frame")
  checkmate::assert_directory_exists(dirname(file))
  return(invisible(NULL))
}

#' Set names of all variables can save in NetCDF
#' @noRd
#' @family forcings functions
all_variables <- function() c("temp", "pr", "pet", "q_obs")


#' Set dimensions attributes tibble
#' @noRd
#' @family forcings functions
dim_atts_tbl <- function(cc, dts) {
  tibble::tibble(
    name = c("longitude", "latitude", "time"),
    units = c("degreesE", "degreesN", "days since 1970-01-01"),
    vals = list(
      cc[["lon"]],
      cc[["lat"]],
      as.numeric(dts)
    )
  )
}

#' Set variables attributes tibble
#' @noRd
#' @family forcings functions
#'
vars_atts_tbl <- function(vnames, dim_atts_list, na_value) {
  spatial_mode <- "Catchment"

  # define variables
  long_names <- c(
    paste0(spatial_mode, "-averaged daily temperature"),
    paste0(spatial_mode, "-averaged daily precipitation"),
    paste0(spatial_mode, "-averaged daily potential evapotranspiration"),
    "Daily discharge"
  )
  # order matters
  names(long_names) <- all_variables()

  var_units <- c("degC", rep("mm/day", 3))
  names(var_units) <- names(long_names)

  tibble::tibble(
    name = vnames,
    units = var_units[names(var_units) %in% vnames],
    dim = lapply(1:length(name), function(i) dim_atts_list),
    missval = rep(na_value, length(name)),
    longname = long_names[names(long_names) %in% vnames]
  )
}


#' Set global attributes tibble
#' @noRd
#' @family forcings functions
#'
glob_atts_tbl <- function(nc_obj, id) {
  tibble::tibble(
    nc = nc_obj,
    varid = rep(0, 3),
    attname = c("title", "instituition", "history"),
    attval = c(
      paste0("FUSE forcing file for catchment ", id),
      "LHMET-UFSM",
      paste0(Sys.info()[["user"]], ": ", Sys.Date())
    )
  )
}


#' Create NetCDF file of Meteorological forcings
#'
#' @param ... numeric vectors with data of variables (e.g, `prec = dataset[['prec']], temp = dataset[['temp']]`, etc)
#' @param dates objects of class "Date" representing calendar dates.
#' @inheritParams elev_bands_nc
#' @export
#' @examples
#' if(FALSE){
#'  # arquivo de saída
#'  forcings_nc <- "inst/extdata/posto74_input.nc"
#'  # exporta dados para netcdf
#'  meteo_forcing_nc(
#'    pr = forcdata74[["pr"]],
#'    pet = forcdata74[["pet"]],
#'    q_obs = forcdata74[["q_obs"]],
#'    dates = forcdata74[["date"]],
#'    ccoords = centroids(poly_station = poly74),
#'    file_nc = forcings_nc
#'  )
#'file.exists(forcings_nc)
#'
#' @family forcings functions
meteo_forcing_nc <- function(...,
                             dates,
                             ccoords,
                             file_nc = "inst/extdata/74_input.nc",
                             na = -9999,
                             force_v4 = TRUE) {
  data_list <- list(...)
  # data_list = list(pr= forcdata74$pr, pet = forcdata74$pet); dates = forcdata74$date; ccoords = centroids(poly_station = poly74); na = -9999; file_nc = "inst/extdata/74_input.nc"; force_v4 = TRUE
  var_names <- names(data_list)

  # check inputs
  .check_inputs_meteo_forc(
    variab_list = data_list,
    dts = dates,
    ctrd = ccoords,
    file = file_nc
  )

  # define dimensions
  dim_atts_l <- dim_atts_tbl(ccoords, dates) %>%
    purrr::pmap(., ncdf4::ncdim_def)

  # define variables attributes
  vars_atts_l <- vars_atts_tbl(var_names, dim_atts_l, na) %>%
    purrr::pmap(ncdf4::ncvar_def)

  # open nc
  nc_conn <- ncdf4::nc_create(
    filename = file_nc,
    vars = vars_atts_l,
    force_v4
  )

  # write global atttributes
  glob_atts_l <-  glob_atts_tbl(list(nc_conn), ccoords[["id"]]) %>%
    purrr::pmap(., ncdf4::ncatt_put)

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
# meteo_forcing_nc()
