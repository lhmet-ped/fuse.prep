# Juntar netcdfs de ET0

#file.edit("~/Dropbox/datasets/climate_datasets/superficie/Daily_grid_met_vars_Brazil_80_13/R/join-netcdfs.R")
# source("~/Dropbox/datasets/climate_datasets/superficie/Daily_grid_met_vars_Brazil_80_13/R/join-netcdfs.R")
# comb_file_eto <- join_nc_files(
#   data_dir = file.path(
#     "~/Dropbox/datasets/climate_datasets/superficie",
#     "Daily_grid_met_vars_Brazil_80_13/data/v2/ETo"
#   ),
#   str_var_file = "ETo",
#   control = FALSE,
#   dest_file = file.path(data_dir ,"brick-str_var_file-25km-1980-2017.nc"),
#   sdate = "1980-01-01",
#   edate = "2017-12-31",
# )

#-----------------------------------------------------------------------------
#' Save data from a ONS station in a RDS file
#'@noRd
save_data <- function(data_posto,# = qnat_posto,
                      .prefix = "qnat-obs-posto-",
                      .posto_id,# = info_posto$posto[1],
                      .dest_dir = "output"){

  data_posto_file <- paste0(.prefix, .posto_id, ".RDS")
  data_posto_file <- file.path(.dest_dir, data_posto_file)

  saveRDS(data_posto, file = data_posto_file)
  checkmate::assert_file_exists(data_posto_file)
  data_posto_file
}


#-----------------------------------------------------------------------------
.find_nc <- function(local = TRUE){

  if(!local){
    lnks <- c(
      prec = "https://www.dropbox.com/s/hj6bu183myfor9y/brick-prec-25km-19800101-20151231.nc?dl=1",
      et0  = "https://www.dropbox.com/s/jfsehx65g0z8yjo/brick-ETo-25km-19800101-20171231.nc?dl=1"
    )
    return(lnks)
  }

  # use local file for tests
  if(.check_user()){
    local_paths <- c(
      prec = file.path(
        "~/Dropbox/datasets/climate_datasets/superficie",
        "Daily_grid_met_vars_Brazil_80_13/output",
        "brick-prec-25km-19800101-20151231.nc"
      ),
      et0 = file.path(
        "~/Dropbox/datasets/climate_datasets/superficie",
        "Daily_grid_met_vars_Brazil_80_13/output",
        "brick-ETo-25km-19800101-20170731.nc"
      )
    )
    return(local_paths)
  }
  return(NULL)
}

.nc_name <- function(varnc){
  unlist(stringr::str_split(basename(.find_nc(FALSE)[varnc]), "\\?"))[c(TRUE, FALSE)]
}

.down_nc <- function(varnc = c("prec", "et0"), dest_dir = "input") {

  checkmate::assert_path_for_output(dest_dir, overwrite = TRUE)

  # dropbox links
  lnks <- .find_nc(local = FALSE)
  lnk_nc <- lnks[varnc]

  # output nc
  nc_fname <- unlist(stringr::str_split(basename(lnk_nc), "\\?"))[c(TRUE, FALSE)]
  dest_file <- file.path(dest_dir, nc_fname)

  # downloading
  for(i in seq_along(dest_file)){
    # i = 1
    message("\ndownlonding file: ", basename(nc_fname[i]), "\n")
    utils::download.file(lnk_nc[i], destfile = dest_file[i], mode = "wb")
  }

  checkmate::assert_file_exists(dest_file)

  dest_file
}


#' Download NetCDF files of daily gridded precipitation and evapotranspiration
#'
#' @param varnc a character with the variable names 'prec' and/or 'et0'.
#' @param dest_dir a character with the name of where the downloaded file is
#' saved. Default: `fusepoc-prep/input`.
#'
#' @return character, path to NetCDF file.
#' @export
#'
#' @examples
#' if(FALSE){
#'  meteo_nc("prec")
#' }
meteo_nc <- function(varnc, dest_dir  = "input") {

  checkmate::assert_subset(varnc, c("prec", "et0"))

  # check data download before in the input directory
  nc_previous <- file.path(dest_dir, .nc_name(varnc))
  if(all(file.exists(nc_previous))){
    message("Loading previously downloaded data available in the 'input' directory.")
    return(nc_previous)
  }

  # use local data to avoid download 2 files of 1.5 GB
  if(.check_user()){
    local_paths <- .find_nc(local = TRUE)
    path_nc <- local_paths[varnc]
    return(path_nc)
  }

  path_nc <- .down_nc(dest_dir, varnc)
  path_nc
}

# -----------------------------------------------------------------------------
#' Import the NetCDF file of daily gridded precipitation in Brazil
#' @param varnc a scalar character with the variable name: 'prec' or 'et0'.
#' @param dest_dir a character with the name of where the downloaded file is
#' saved. Default: `fusepoc-prep/input`.
#' @details Warning: The size of the file is 1.5 GB!!! Make sure you have
#' space available on disk. The download of files can take a while.
#' @source \url{https://utexas.app.box.com/v/Xavier-etal-IJOC-DATA/}
#' @references https://rmets.onlinelibrary.wiley.com/doi/full/10.1002/joc.4518
#' @return a character path to the NetCDF file downloaded.
#' @export
#' @examples
#' if(FALSE) b_prec <- fuse.prep::import_nc(varnc = "prec", dest_dir = "input")
#'
import_nc <- function(varnc = c("prec", "et0"), dest_dir = "input"){
  # varnc = "et0"
  checkmate::assert_choice(varnc, c("prec", "et0"))

  nc_file <- meteo_nc(varnc, dest_dir)
  checkmate::assert_file_exists(nc_file)

  b <- raster::brick(nc_file)
  # não altere o nome do arquivo netcdf, as datas sao extraídas do nome do arquivo
  b_dates <- b %>%
    raster::filename() %>%
    basename() %>%
    stringr::str_extract_all("[0-9]{8}") %>%
    unlist() %>%
    lubridate::as_date()
  checkmate::assert_true(length(b_dates) == 2)
  b <- raster::setZ(x = b,
                    z = seq(min(b_dates), max(b_dates), by = "days")
  )
  b
}


#------------------------------------------------------------------------------
# write_nc
f <- function(info_posto,
              nc_name = "elev_bands.nc",
              nb = 5,
              xy, # = coords_posto,
              long_name = "A long name"
) {
  x <- ncdf4::ncdim_def(
    name = 'latitude',
    units = 'degreesN',
    vals = xy[["longitude"]]
  )
  y <- ncdf4::ncdim_def(
    name = 'longitude',
    units = 'degreesE',
    vals = xy[["longitude"]]
  )

  z_bands <- ncdf4::ncdim_def(
    name = 'elevation_band',
    units = '-',
    vals = as.numeric(1 : nb)
  )
}
