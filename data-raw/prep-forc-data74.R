
# as forçantes foram preparadas no fusepoc.prep https://github.com/lhmet-ped/fusepoc-prep
# e a descrição da sua geração será inclusa em uma vignette
easypackages::libraries(c("dplyr"))

forcdata74 <- readRDS("~/Dropbox/github/my_reps/lhmet/fusepoc-prep/output/hydrodata-posto-74.RDS")
forcdata74 <- forcdata74 %>%
  dplyr::select(date, id = posto, pr = prec, pet = et0, q_obs = qnat_mm) %>%
  tibble::as_tibble()

use_data(forcdata74, overwrite = TRUE)




