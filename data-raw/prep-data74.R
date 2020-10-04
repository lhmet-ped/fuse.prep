
easypackages::libraries(c("fuse.prep", "HEgis", "raster"))

## code to prepare `precclim74`
b_prec <- fuse.prep::import_nc(varnc = "prec", dest_dir = "input")
precclim74 <- fuse.prep::annual_climatology(
  meteo_brick = b_prec,
  poly_station = prep_poly_posto(HEgis::poly74, dis.buf = 0.25)
)
#plot(precclim74)
#! This is acceptable only for annual totals
precclim74[precclim74 == 0] <- NA
#precclim74 <- raster::mask(precclim74, poly74)
#plot(precclim74)
#plot(sf::st_geometry(poly74), add = TRUE)

usethis::use_data(precclim74, overwrite = TRUE)

