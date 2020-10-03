
<!-- README.md is generated from README.Rmd. Please edit that file -->

# fuse.prep

<!-- badges: start -->

<!-- badges: end -->

The goal of **`{fuse.prep}`** is to prepare the input data for the
Framework for Understanding Structural Errors
([FUSE](https://naddor.github.io/fuse/)).

## Installation

You can install the development version of **{`fuse.prep`}** from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("lhmet-ped/fuse.prep")
```

## Dados

This is a basic example which shows you how to create the elevation
bands NetCDF file.

Os dados de exemplo necessários são disponibilizados com os pacotes
**`{HEgis}`** (`poly74` e `condem74`) e **`{fuse.prep}`**
(`precclim74`):

  - polígono da bacia hidrográfica do posto do ONS (Simple Feature,
    `sf`)

  - os dados de elevação do terreno (`raster`) hidrologicamente
    condicionados

  - precipitação climatológica anual (`raster`)

<!-- end list -->

``` r
library(fuse.prep)
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
precclim74
#> class      : RasterLayer 
#> dimensions : 8, 13, 104  (nrow, ncol, ncell)
#> resolution : 0.25, 0.25  (x, y)
#> extent     : -52, -48.75, -27, -25  (xmin, xmax, ymin, ymax)
#> crs        : +proj=longlat +datum=WGS84 +no_defs 
#> source     : memory
#> names      : layer 
#> values     : 1449.61, 2070.507  (min, max)
```

# Bandas de elevação

<https://github.com/naddor/tofu/blob/master/input_output_settings/create_elev_bands_nc.R>

``` r
elev_tab_format <- elev_bands(con_dem = condem74, meteo_raster = precclim74, dz = 100)
#>   |                                                                              |                                                                      |   0%  |                                                                              |==================                                                    |  25%  |                                                                              |===================================                                   |  50%  |                                                                              |====================================================                  |  75%  |                                                                              |======================================================================| 100%
#> 
#>   |                                                                              |                                                                      |   0%  |                                                                              |===================================                                   |  50%
#> Warning: Unknown or uninitialised column: `area_frac`.
elev_tab_format
#> # A tibble: 10 x 6
#>     band   inf   sup mean_elev   area_frac prec_frac
#>    <dbl> <dbl> <dbl>     <dbl>       <dbl>     <dbl>
#>  1     1   588   688       638 0.000276    0.0000591
#>  2     2   688   788       738 0.133       0.135    
#>  3     3   788   888       838 0.394       0.389    
#>  4     4   888   988       938 0.259       0.255    
#>  5     5   988  1088      1038 0.104       0.109    
#>  6     6  1088  1188      1138 0.0789      0.0819   
#>  7     7  1188  1288      1238 0.0284      0.0266   
#>  8     8  1288  1388      1338 0.00330     0.00296  
#>  9     9  1388  1488      1438 0.000104    0.0000155
#> 10    10  1488  1588      1538 0.000000765 0
```
