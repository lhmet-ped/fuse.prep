
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

  - forçantes meteorológicas: armazena dados diários de temperatura do
    ar, precipitação, evapotranspiração potencial e opcionalmente de
    vazão observada;

## Instalação

O **{`fuse.prep`}** pode ser instalado do [GitHub](https://github.com/)
com:

``` r
# install.packages("devtools")
devtools::install_github("lhmet-ped/fuse.prep")
```

### Arquivo NetCDF de bandas de elevação

Os dados de exemplo são da Bacia Hidrográfica associada ao posto 74 (UHE
G.B. MUNHOZ). Os dados necessários para geração dos arquivos NetCDF são:

  - raster da precipitação climatológica anual

  - raster da elevação do terreno hidrologicamente condicionado

  - polígono da bacia hidrográfica (*Simple Feature*, `sf`)

Estes dados são disponibilizados neste pacote (`precclim74`) e com o
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

Para saber como estes 3 arquivos foram gerados veja a vinheta do pacote
(`vignette(asd)`).

O arquivo NetCDF de bandas de elevação é gerado com a função
`elev_bands_nc()` que requer a tabela de bandas de elevação e o
centróide do polígono.

A tabela de bandas de elevação é obtida com a função `elev_bands()`:

``` r
elev_bands_tab <- elev_bands(
  con_dem = condem74, 
  meteo_raster = precclim74, 
  nbands = 14
)
#>   |                                                                              |                                                                      |   0%  |                                                                              |==============                                                        |  20%  |                                                                              |============================                                          |  40%  |                                                                              |==========================================                            |  60%  |                                                                              |========================================================              |  80%  |                                                                              |======================================================================| 100%
#> 
#>   |                                                                              |                                                                      |   0%  |                                                                              |===================================                                   |  50%
elev_bands_tab
#> # A tibble: 14 x 6
#>     zone   inf   sup mean_elev area_frac prec_frac
#>    <dbl> <dbl> <dbl>     <dbl>     <dbl>     <dbl>
#>  1     1  588   654.      621. 0.000195  0.000240 
#>  2     2  654.  719.      686. 0.00367   0.00427  
#>  3     3  719.  785.      752. 0.113     0.112    
#>  4     4  785.  850.      818. 0.277     0.271    
#>  5     5  850.  916.      883. 0.236     0.230    
#>  6     6  916.  981.      949. 0.147     0.146    
#>  7     7  981. 1047      1014. 0.0717    0.0752   
#>  8     8 1047  1113.     1080. 0.0632    0.0672   
#>  9     9 1113. 1178.     1145. 0.0507    0.0541   
#> 10    10 1178. 1244.     1211. 0.0271    0.0287   
#> 11    11 1244. 1309.     1276. 0.00842   0.00901  
#> 12    12 1309. 1375.     1342. 0.00177   0.00194  
#> 13    13 1375. 1440.     1408. 0.000146  0.000178 
#> 14    14 1440. 1506      1473. 0.0000150 0.0000193
```

O centróide do polígono da bacia hidrográfica é obtido com a função
`centroids()`.

``` r
(poly_ctrd <- centroids(poly_station = poly74)  )
#> # A tibble: 1 x 2
#>     lon   lat
#>   <dbl> <dbl>
#> 1 -50.3 -26.0
```

Com aquelas informações podemos então passá-las à `elev_bands_nc()` que
as salva no arquivo NetCDF.

``` r
elev_bands_file <- elev_bands_nc(
  elev_tab = elev_bands_tab,
  ccoords = poly_ctrd,
  file_nc = file.path(tempdir(), "elevation_bands_74.nc"),
  na = -9999
)
elev_bands_file
#> [1] "/tmp/RtmpYHZBnz/elevation_bands_74.nc"
file.exists(elev_bands_file)
#> [1] TRUE
```

## Arquivo NetCDF de forçantes meteorológicas

<https://github.com/naddor/tofu/blob/master/input_output_settings/write_forcing.R>
