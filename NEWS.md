# fuse.prep (development version)


- [ ] incluir vinheta para gerar dados processados usados na `meteo_forcing_nc()`

- [ ] incluir testes para `spatial_average`, `annual_climatology`, `annual_summary`

# fuse.prep 0.0.4

- [x] adicionar `join_netcdfs.R` ao `data-raw`

- [x] `annual_climatology` tem um novo argumento `cutoff` para excluir valores
menores ou iguais a este limiar.

# fuse.prep 0.0.3

- [x] documentar função `meteo_forcing_nc()`

- [x] incluir testing da função `meteo_forcing_nc()`

# fuse.prep 0.0.2

- [x] Adicionar função para gerar arquivo de NetCDF das forçantes meteorológicas.

# fuse.prep 0.0.1

- [x] Adicionada função para gerar arquivo de NetCDF de bandas de elevação 
(`elev_bands_nc`).
