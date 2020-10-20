join_nc_files <- function(data_dir = "../data/v2.1-prec-only",
                          str_var_file = "prec", 
                          var_nc = "",
                          control = FALSE, 
                          sdate = "1980-01-01",
                          edate = "2015-12-31",
                          dest_file = "../output/brick-str_var_file-25km-1980-2017.nc"){
  rasterOptions(progress = "text")
  # string pattern to search in file name
  if (control) {
    str_pat <- "str_var_file_daily.*Control.nc$"
    } else {
      str_pat <- "str_var_file_daily.*[0-9]{8}.nc$"
      #str_pat <- "str_var_file_daily.*[0-9]{8}_rs.nc$"
  }
  # files list
  files <- list.files(data_dir, 
                       gsub("str_var_file", 
                            str_var_file, 
                            str_pat), 
                       full.names = TRUE)
  
  checkmate::assert_file_exists(files)
  
  
  if(var_nc == "" & is_identical_vars_ncs(files)) {
    vnames <- vars_nc(files[1])
    message("Netcdf files with variable(s):", "\n",
            paste(paste("-", vnames), collapse = "\n"), "\n",
            "Using the first variable.")
    var_nc <- vnames[1]
  }
  # output file name
  dest_file <- gsub("str_var_file", 
                    var_nc, 
                    dest_file)
  # date range
  #dates <- seq(as.Date(sdate), as.Date(edate), "days")
  
  
  #brick_l <- purrr::map(files, ~raster::brick(.x, varname = var_nc))
  brick_l <- purrr::map(files, ~raster::brick(.x))
  sbl <- stack(brick_l)
  rm(brick_l)
  gc()
  names(sbl)
  b <- raster::brick(sbl, filename = dest_file)
  rm(sbl)
  gc()
  if(file.exists(dest_file)) {
    out <- dest_file
    } else {
      out <- paste(" It was not possible to generate file:", "\n", dest_file)
      message(out)
    }
  rm(b)
  
  return(out)
}

#' Get variable name in a netcdf file
vars_nc <- function(ncfile = files[1]){
  nc <- ncdf4::nc_open(ncfile)
  varnams <- c(t(purrr::map_chr(nc$var, "name")))
  return(varnams)
}

#' Get variables names from a vector of netcdf files
vars_nc_files <- function(ncfiles = files){
  vnames <- purrr::map(ncfiles, ~vars_nc(.x)) 
  names(vnames) <- basename(ncfiles)
  return(vnames)
}

#' Check if variable names of netcdf files are identical
is_identical_vars_ncs <- function(nc.files = files){
  vnames_len <- unlist(purrr::map(vars_nc_files(nc.files), length))
  identical(vnames_len, vnames_len)
}

# THIS TAKE TIME   ~5min per file ----------------------------------------------
# comb_file_count <- join_netcdfs(data_dir = "../data/v2.1-prec-only",
#                                   str_var_file = "prec",
#                                   var_nc = "count"
# )
# 
 # comb_file_prec <- join_nc_files(data_dir = "../data/v2.1-prec-only",
 #                                  str_var_file = "prec",
 #                                  control = FALSE,
 #                                  dest_file = "../output/brick-str_var_file-25km-1980-2015.nc")
 # 

