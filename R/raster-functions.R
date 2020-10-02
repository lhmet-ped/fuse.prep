# projeção das bacias assumida ser 4618 (mesma das ottobacias da ANA)
#s <- "~/Dropbox/datasets/GIS/ANA/Ottobacias_Nivel1/Ottobacias_Nivel1.shp"
# s <- "~/Dropbox/datasets/GIS/ANA/base_dados_hidrograficos/hidrog_ana_mpr.shp"
#pol <- sf::st_read(s)
#st_crs(pol)
# ID["EPSG",4618]

# From https://developers.arcgis.com/javascript/3/jshelp/gcs.html and
# 4618	GCS_South_American_1969
# GEOGCS["GCS_South_American_1969",DATUM["D_South_American_1969",SPHEROID["GRS_1967_Truncated",6378160.0,298.25]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]]
# and
# https://spatialreference.org/ref/epsg/4618/html/
# GEOGCS["SAD69",
#        DATUM["South_American_Datum_1969",
#              SPHEROID["GRS 1967 (SAD69)",6378160,298.25,
#                       AUTHORITY["EPSG","7050"]],
#              AUTHORITY["EPSG","6618"]],
#        PRIMEM["Greenwich",0,
#               AUTHORITY["EPSG","8901"]],
#        UNIT["degree",0.01745329251994328,
#             AUTHORITY["EPSG","9122"]],
#        AUTHORITY["EPSG","4618"]]

# -----------------------------------------------------------------------------
#' Save average precipitation or evapotranspiration over upstream drainage
#' area of a ONS station
#'
#' @param meteo_brick \code{\link[raster]{brick}} of meteorological field
#' (e.g.: precipitation, evapotranspiration, etc).
#' @param poly_station object of class \code{\link[sf]{sf}} and geometry
#' type polygon of station catchment.
#' @param fun function to apply. Default: mean.
#'
#' @return a character path to the RDS file with a \code{\link[tibble]{tibble}}
#' @export
#'
spatial_average <- function(meteo_brick,
                            poly_station,
                            fun = mean
                            #save = TRUE,
                            #dest_dir = "output"
                            ){

  checkmate::assert_set_equal(c(class(meteo_brick)), "RasterBrick")
  #plot(posto_poly)
  #plot(poly_posto, add = TRUE, bg = 2)
  posto_poly_b <- HEgis::prep_poly_posto(poly_station)
  rm(poly_station)
  cb <- raster::crop(meteo_brick, posto_poly_b)

  # need improvement
  varnc_guess <- ifelse(max(raster::maxValue(meteo_brick)) > 20, "prec", "et0")

  # média ponderada pela área da células dentro do polígono
  # não é a forma mais eficiente, mas faz o que precisa ser feito usando
  # o raster. Outra alternativa mais rápida, mas menos clara:
  # https://gis.stackexchange.com/questions/213493/area-weighted-average-raster-values-within-each-spatialpolygonsdataframe-polygon
  meteo_avg <- c(t(raster::extract(
    cb,
    posto_poly_b,
    weights = TRUE,
    normalizeWeights = TRUE,
    fun
  )))
  # plot(prec_avg, type = "h")
  # range(prec_avg)

  meteo_tbl <- tibble::tibble(date = raster::getZ(meteo_brick),
                              posto = as.integer(posto_poly_b$codONS),
                              meteovar = meteo_avg
  )
  meteo_tbl <- stats::setNames(meteo_tbl, c("date", "posto", varnc_guess))


  #meteo_posto_file <- paste0(gsub("meteo", varnc_guess, "meteo-posto-"),
  #                           posto_poly$codONS, ".RDS"
  #)

  # meteo_posto_file <- file.path("output", meteo_posto_file)
  # saveRDS(meteo_tbl, file = meteo_posto_file)
  # checkmate::assert_file_exists(meteo_posto_file)
  # meteo_posto_file

  # if(save){
  #   save_data(
  #     data_posto = meteo_tbl,
  #     .prefix = gsub("meteo", varnc_guess, "meteo-posto-"),
  #     .posto_id = posto_poly_b$codONS[1],
  #     .dest_dir = dest_dir
  #   )
  # }
  meteo_tbl
}

#-------------------------------------------------------------------------------
#' Summarize a brick by year
#'@inheritParams spatial_average
annual_summary <- function(meteo_brick, fun){

  zdates <- raster::getZ(meteo_brick)
  checkmate::assert_class(zdates, "Date")

  ann_summary <- raster::stackApply(
    x = meteo_brick,
    indices = lubridate::year(zdates),
    fun,
    na.rm = TRUE
  )
  ann_summary
}


#' Mean annual climatology of meteorological field
#'@inheritParams spatial_average
#' @param fun function to apply. Default: sum.
#' @param ref_crs character, coordinate reference system.
#' @return \code{\link[raster]{raster}} with the Mean annual climatology of
#' meteorological field.
#' @export
annual_climatology <- function(meteo_brick = import_nc(varnc = "prec", dest_dir = "input"),
                         poly_station,
                         fun = sum,
                         #save = TRUE,
                         #dest_dir = "output",
                         ref_crs = "+proj=longlat +datum=WGS84") {

  # meteo_brick = b_prec; poly_station = poly74; ref_crs = "+proj=longlat +datum=WGS84"

  is_extent <- "Extent" %in% class(poly_station)

  if(!is_extent) {
    checkmate::assert_true(sf::st_is(poly_station, "POLYGON"))
    if(is.null(ref_crs)) ref_crs <- raster::projection(meteo_brick)
    poly_station <- sf::st_transform(poly_station, as.character(ref_crs))
  }

  cb <- raster::crop(meteo_brick, poly_station)
  ann_summary <- annual_summary(cb, fun)
  clim_summary <- raster::mean(ann_summary, na.rm = TRUE)

  if(is_extent) return(clim_summary)

  #plot(clim_summary)

  clim_summary <- raster::mask(clim_summary, sf::as_Spatial(poly_station))
  clim_summary
}


