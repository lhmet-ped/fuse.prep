context("meteo_forcing_nc()")

library(HEgis)

test_that("Produces the correct output.", {
  # arquivo de saída
  forcings_nc <- tempfile(fileext = ".nc")
  # exporta dados para netcdf
  meteo_forcing_nc(
    forc_tbl = forcdata74,
    ccoords = centroids(poly_station = poly74),
    file_nc = forcings_nc
  )
  expect_equal(file.exists(forcings_nc), TRUE)
})

test_that("Produces the correct errors.", {
  # wrong names
  x <- dplyr::rename(forcdata74, "prec" = pr)
  expect_error(
    meteo_forcing_nc(x,
      ccoords = centroids(poly_station = poly74),
      file_nc = forcings_nc
    )
  )
  # wrong class
  x <- dplyr::mutate(forcdata74, date = as.character(date))
  expect_error(
    meteo_forcing_nc(x,
      ccoords = centroids(poly_station = poly74),
      file_nc = forcings_nc
    )
  )

  # all missing os
  x <- dplyr::mutate(forcdata74, temp = NA)
  expect_error(
    meteo_forcing_nc(
      x,
      ccoords = poly74,
      file_nc = forcings_nc
    )
  )

 # wrong centroids
  expect_error(
    meteo_forcing_nc(
      forcdata74,
      ccoords = sf::st_coordinates(poly74),
      file_nc = forcings_nc
    )
  )

  # file not existent
  expect_error(
    meteo_forcing_nc(
      forcdata74,
      ccoords = centroids(poly_station = poly74),
      file_nc = "crazy/path"
    )
  )

  # using previous version
  expect_error(
  meteo_forcing_nc(
    pr = forcdata74[["pr"]],
    pet = forcdata74[["pet"]],
    q_obs = forcdata74[["q_obs"]],
    dates = forcdata74[["date"]],
    ccoords = centroids(poly_station = poly74),
    file_nc = forcings_nc
  ))

})
