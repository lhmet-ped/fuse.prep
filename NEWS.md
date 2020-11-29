
# fuse.prep (development version)

- [ ] `comb_data` deve receber a tabela de dados e selecionar as variáveis de
interesse, ao invés de receber vetores de cada variável.

- [ ] incluir testes para `spatial_average`, `annual_climatology`, `annual_summary`

# fuse.prep 0.1.5

- [x] resolvida issue #4  (graças à @nelsonvnperu e @andreza-santos). 

# fuse.prep 0.0.4.91

- [x] incluir vinhetas de pré-processamento de dados das forçantes meteorológicas


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
