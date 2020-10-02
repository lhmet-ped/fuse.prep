
easypackages::libraries(c("HEgis", "raster"))

## code to prepare `poly74`
poly74 <- suppressMessages(HEgis::extract_poly(station = 74))


## code to prepare `condem74`
condem74 <- extract_condem(
  raster("~/Dropbox/datasets/GIS/hydrosheds/sa_con_3s_hydrosheds.grd"),
  poly74,
  dis.buf = 0
)


## code to prepare `precclim74`
b_prec <- fuse.prep::import_nc(varnc = "prec", dest_dir = "input")
precclim74 <- fuse.prep::spatial_clim(
  meteo_brick = b_prec,
  poly_station = prep_poly_posto(poly74, dis.buf = 0.25)
)
plot(precclim74)
precclim74[precclim74 == 0] <- NA
precclim74 <- raster::mask(precclim74, poly74)
#plot(precclim74)
#plot(sf::st_geometry(poly74), add = TRUE)

usethis::use_data(poly74, condem74, precclim74, overwrite = TRUE)

