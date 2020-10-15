context("meteo_forcing_nc()")

library(HEgis)

test_that("Produces the correct output.", {
  # arquivo de saída
  forcings_nc <- tempfile(fileext = ".nc")
  # exporta dados para netcdf
  meteo_forcing_nc(
    pr = forcdata74[["pr"]],
    pet = forcdata74[["pet"]],
    q_obs = forcdata74[["q_obs"]],
    dates = forcdata74[["date"]],
    ccoords = centroids(poly_station = poly74),
    file_nc = forcings_nc
  )
  expect_equal(file.exists(forcings_nc), TRUE)
})

test_that("Produces the correct errors.", {
  expect_error(
    meteo_forcing_nc(
      prec = forcdata74[["pr"]],
      pet = forcdata74[["pet"]],
      q_obs = forcdata74[["q_obs"]],
      dates = forcdata74[["date"]],
      ccoords = centroids(poly_station = poly74),
      file_nc = forcings_nc
    )
  )

  expect_error(
    meteo_forcing_nc(
      forcdata74[["pr"]],
      pet = forcdata74[["pet"]],
      q_obs = forcdata74[["q_obs"]],
      dates = forcdata74[["date"]],
      ccoords = centroids(poly_station = poly74),
      file_nc = forcings_nc
    )
  )

  expect_error(
    meteo_forcing_nc(
      pr = forcdata74[["pr"]],
      pet = forcdata74[["pet"]],
      q_obs = forcdata74[["q_obs"]],
      dates = forcdata74[["date"]],
      ccoords = sf::st_coordinates(poly74),
      file_nc = forcings_nc
    )
  )
 # different lenghts
  expect_error(
    meteo_forcing_nc(
      pr = forcdata74[["pr"]][1:10],
      pet = forcdata74[["pet"]],
      q_obs = forcdata74[["q_obs"]],
      dates = forcdata74[["date"]],
      ccoords = centroids(poly_station = poly74),
      file_nc = forcings_nc
    )
  )

  # file not existent
  expect_error(
    meteo_forcing_nc(
      pr = forcdata74[["pr"]],
      pet = forcdata74[["pet"]],
      q_obs = forcdata74[["q_obs"]],
      dates = forcdata74[["date"]],
      ccoords = centroids(poly_station = poly74),
      file_nc = "crazy/path"
    )
  )

})
