context("io_nc functions")

test_that("nc file names matches the expected names", {
  if (checkmate::test_directory_exists("input")) {

    files_size <- fs::dir_info("input") %>%
      dplyr::filter(size > "1 G") %>%
      dplyr::pull(size)

    if (all(files_size > "1 G")) {

      testthat::expect_message(
        testthat::expect_true(stringr::str_detect(
          fuse.prep:::.nc_name("et0"),
          fs::path_file(meteo_nc("et0", "input"))
        ))
      )

      testthat::expect_message(
        testthat::expect_true(stringr::str_detect(
          fuse.prep:::.nc_name("prec"),
          fs::path_file(meteo_nc("prec", "input"))
        ))
      )
    }

  }
})



test_that("import_nc() produces the correct output.", {
  if (checkmate::test_directory_exists("input")) {

    files_size <- fs::dir_info("input") %>%
      dplyr::filter(size > "1 G") %>%
      dplyr::pull(size)

    if (all(files_size > "1 G")) {

     testthat::expect_message(
       testthat::expect_is(import_nc("prec", "input"), "RasterBrick")
     )
    }
  }
})
