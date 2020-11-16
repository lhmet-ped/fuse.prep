
<!-- README.md is generated from README.Rmd. Please edit that file -->

# fuse.prep

<!-- badges: start -->

<!-- badges: end -->

O pacote **`{fuse.prep}`** tem o objetivo de gerar os dados de entrada
para aplicação do *Framework for Understanding Structural Errors*
([FUSE](https://naddor.github.io/fuse/)) na escala de bacia hidrográfica
(*catchment scale*). São necessários dois arquivos NetCDF de entrada
para o FUSE:

  - bandas de elevação do terreno: armazena as frações de área da bacia
    hidrográfica e da precipitação anual por banda de elevação;

  - forçantes meteorológicas: armazena as séries temporais da média
    diárias na área da bacia hidrográfica das variáveis: temperatura do
    ar (°C), precipitação (mm dia<sup>-1</sup>), evapotranspiração
    potencial (mm dia<sup>-1</sup>) e opcionalmente de vazão observada
    (ou deflúvio, mm dia<sup>-1</sup>);

## Instalação

O **{`fuse.prep`}** pode ser instalado do [GitHub](https://github.com/)
com:

``` r
# install.packages("devtools")
devtools::install_github("lhmet-ped/fuse.prep", build_vignettes = TRUE)
```

A opção `build_vignettes = TRUE` instalará o pacote incluindo as
vinhetas do pacote que apresentam as etapas de pré-processamento dos
dados necessários para criação dos arquivos NetCDF.

### NetCDF de bandas de elevação

Os dados de exemplo são da Bacia Hidrográfica associada ao posto 74 (UHE
G.B. MUNHOZ). Os dados necessários para geração do arquivo NetCDF de
bandas de elevação:

  - raster da precipitação climatológica anual

  - raster da elevação do terreno hidrologicamente condicionado

  - polígono da bacia hidrográfica (*Simple Feature*, `sf`)

Estes dados são disponibilizados com este pacote (`precclim74`) e com o
pacote **`{HEgis}`** (`poly74` e `condem74`).

``` r
library(HEgis)
poly74
#> Simple feature collection with 1 feature and 9 fields
#> geometry type:  POLYGON
#> dimension:      XY
#> bbox:           xmin: -51.72274 ymin: -26.85503 xmax: -48.94853 ymax: -25.22428
#> geographic CRS: SIRGAS 2000
#>   codONS codANA       nome                                   nomeOri    adkm2
#> 1     74   7659 G_B_MUNHOZ UHE Governador Bento Munhoz da Rocha Neto 30207.57
#>   volhm3        rio cobacia        tpopera                       geometry
#> 1   5779 Rio Iguaçu 8625591 Regulariza_ONS POLYGON ((-51.56304 -26.259...
condem74
#> class      : RasterLayer 
#> dimensions : 1957, 3329, 6514853  (nrow, ncol, ncell)
#> resolution : 0.0008333333, 0.0008333333  (x, y)
#> extent     : -51.7225, -48.94833, -26.855, -25.22417  (xmin, xmax, ymin, ymax)
#> crs        : +proj=longlat +datum=WGS84 +no_defs 
#> source     : memory
#> names      : layer 
#> values     : 588, 1506  (min, max)
library(fuse.prep)
precclim74
#> class      : RasterLayer 
#> dimensions : 8, 13, 104  (nrow, ncol, ncell)
#> resolution : 0.25, 0.25  (x, y)
#> extent     : -52, -48.75, -27, -25  (xmin, xmax, ymin, ymax)
#> crs        : +proj=longlat +datum=WGS84 +no_defs 
#> source     : memory
#> names      : layer 
#> values     : 1444.804, 2400.077  (min, max)
```

Para saber como estes 3 arquivos foram gerados consulte a vinheta de
*Pré-processamento dos dados de bandas de elevação* digitando
`vignette('pp-elevbands', package = "fuse.prep")`.

O arquivo NetCDF de bandas de elevação é gerado com a função
`elev_bands_nc()` que requer como entrada os dados carregados acima e o
centróide do polígono. O centróide do polígono da bacia hidrográfica é
obtido com a função `centroids()`.

``` r
(poly_ctrd <- centroids(poly_station = poly74))
#> # A tibble: 1 x 3
#>     lon   lat id   
#>   <dbl> <dbl> <chr>
#> 1 -50.3 -26.0 74
```

``` r
# arquivo de saída - altere o caminho para o local desejado
 elevbands_nc <- file.path(tempdir(), "posto74_elevation_bands.nc")

elev_bands_file <- elev_bands_nc(
  con_dem = condem74, 
  meteo_raster = precclim74, 
  nbands = 14,
  ccoords = poly_ctrd,
  file_nc = elevbands_nc,
  na = -9999
)
#>   |                                                                              |                                                                      |   0%  |                                                                              |========                                                              |  11%  |                                                                              |================                                                      |  22%  |                                                                              |=======================                                               |  33%  |                                                                              |===============================                                       |  44%  |                                                                              |=======================================                               |  56%  |                                                                              |===============================================                       |  67%  |                                                                              |======================================================                |  78%  |                                                                              |==============================================================        |  89%  |                                                                              |======================================================================| 100%
#> 
#>   |                                                                              |                                                                      |   0%  |                                                                              |===================================                                   |  50%
elev_bands_file
#> [1] "/tmp/Rtmpb5Fbaa/posto74_elevation_bands.nc"
file.exists(elev_bands_file)
#> [1] TRUE
```

## NetCDF das forçantes meteorológicas

Para gerar o arquivo NetCDF com as séries temporais das forçantes
hidrometeorológicas médias na área da BH, utilizaremos o conjunto de
dados `forcdata74` disponibilizado com este pacote.

``` r
forcdata74
#> # A tibble: 13,149 x 5
#>    date          id      pr   pet q_obs
#>    <date>     <dbl>   <dbl> <dbl> <dbl>
#>  1 1980-01-01    74  0.363   5.37  1.81
#>  2 1980-01-02    74  0.214   5.01  1.64
#>  3 1980-01-03    74  0.169   5.38  1.43
#>  4 1980-01-04    74  0.226   5.53  1.34
#>  5 1980-01-05    74  0.0616  5.51  1.22
#>  6 1980-01-06    74  1.36    4.67  1.17
#>  7 1980-01-07    74 28.1     3.55  1.27
#>  8 1980-01-08    74  6.70    3.57  1.44
#>  9 1980-01-09    74 12.4     3.40  1.43
#> 10 1980-01-10    74 12.2     4.99  1.38
#> # … with 13,139 more rows
```

Para saber como gerar estes dados consulte a vinheta de
*Pré-processamento dos dados das forçantes meteorológicas* digitando
`vignette('pp-forcmets', package = "fuse.prep")`.

Cada variável é passada como um vetor conforme código abaixo. Os nomes
dos vetores devem seguir este padrão: `pr` para precipitação, `pet` para
evapotranspiração potencial e `q_obs` para vazão observada. Além das
séries temporais das variáveis precisamos das datas, as coordenadas da
bacia hidrográfica do posto e o arquivo NetCDF que será salvo.

``` r
# arquivo de saída - altere o caminho para o local desejado
forcings_nc <- "inst/extdata/posto74_input.nc"
# exporta dados para netcdf
meteo_forcing_nc(
  pr = forcdata74[["pr"]],
  pet = forcdata74[["pet"]],
  q_obs = forcdata74[["q_obs"]],
  dates = forcdata74[["date"]],
  ccoords = centroids(poly_station = poly74),
  file_nc = forcings_nc 
)
#> [1] "inst/extdata/posto74_input.nc"
file.exists(forcings_nc)
#> [1] TRUE
```
