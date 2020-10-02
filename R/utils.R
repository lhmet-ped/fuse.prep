utils::globalVariables(
  c(
    "qnat_posto",
    "codONS",
    "info",
    "nome",
    "area_frac",
    "band",
    "count",
    "head",
    "hist",
    "inf",
    "mean_elev",
    "prec_frac",
    "sup",
    "zone",
    "."
  )
)


.check_user <- function(user = "hidrometeorologista"){
  Sys.info()[["login"]] == user
}

