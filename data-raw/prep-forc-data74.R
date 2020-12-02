
# as forçantes foram preparadas no fusepoc.prep https://github.com/lhmet-ped/fusepoc-prep
# e a descrição da sua geração será inclusa em uma vignette
easypackages::libraries(c("dplyr", "fuse.prep", "HEgis", "raster"))

forcdata74 <- readRDS("~/Dropbox/github/my_reps/lhmet/fusepoc-prep/output/hydrodata-posto-74.RDS")
forcdata74 <- forcdata74 %>%
  dplyr::select(date, station = posto, pr = prec, pet = et0, q_obs = qnat_mm) %>%
  tibble::as_tibble()


# inclusão da temperatura requerida no netcdf pelo FUSE -----------------------

if(!dir.exists("data-raw/wc10")){
  fs::dir_create("wc10")
  link <- "http://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_10m_tavg.zip"
  download.file(link,
                destfile = file.path("data-raw/wc10", basename(link))
  )
  unzip(file.path("data-raw/wc10", basename(link),
                  exdir = "data-raw/wc10"))
}

temp <- stack(fs::dir_ls("data-raw/wc10", glob = "*.tif"))
ctemp <- crop(temp,  prep_poly_posto(poly74, dis.buf = 0))
#plot(ctemp, 1)
#plot(sf::st_geometry(poly74), add = TRUE)
temp_avg <- cellStats(ctemp, 'mean')

clim_dates <- names(temp_avg) %>%
strsplit(., "_") %>%
  lapply(., function(x) x[length(x)]) %>%
  unlist() %>%
  readr::parse_number() %>%
  # pq precisamos de algum ano para usar datas
  paste0(mean(c(1970, 2000)), "-", ., "-", "01") %>%
  lubridate::ymd()

clim_temp <- tibble(
  date = clim_dates, temp = c(t(temp_avg)),
  month = lubridate::month(date)
  ) %>% dplyr::select(-date)

forcdata74 <-
mutate(forcdata74, month = lubridate::month(date)) %>%
  full_join(clim_temp) %>%
  # manter a ordem das vars como nos dados de exemplo do fuse
  dplyr::select(date:station, temp, pr, everything(), -month)

forcdata74

use_data(forcdata74, overwrite = TRUE)
