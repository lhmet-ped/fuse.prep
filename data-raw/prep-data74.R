
easypackages::libraries(c("HEgis", "raster"))

## code to prepare `poly74`
poly74 <- suppressMessages(extract_poly(station = 74))


## code to prepare `condem74`
condem74 <- extract_condem(
  raster("~/Dropbox/datasets/GIS/hydrosheds/sa_con_3s_hydrosheds.grd"),
  poly74,
  dis.buf = 0
)


## code to prepare `precclim74`
b_prec <- import_nc(varnc = "prec", dest_dir = "input")
prec_clim <- spatial_clim(
  b_prec,
  poly_station = raster::extent(
    suppressMessages(
      HEgis::prep_poly_posto(poly_posto, dis.buf = 1)
    )
  )
)

precclim74 <- readRDS("../fusepoc-prep/output/raster-prec-clim-74.RDS")
precclim74[precclim74 == 0] <- NA
#plot(precclim74)
#plot(st_geometry(poly74), add = TRUE)

usethis::use_data(poly74, condem74, precclim74, overwrite = TRUE)



# precclim was created in fusepoc-prep

