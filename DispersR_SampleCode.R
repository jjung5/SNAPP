## DispersR Example Code ## 

install.packages("Rcpp")
install.packages(c("processx", "callr"), type = "source")
devtools::install_github("lhenneman/disperseR", force = TRUE, build_vignettes = TRUE , R_REMOTES_NO_ERRORS_FROM_WARNINGS=TRUE)

library(Rcpp)
library(devtools)
library(disperseR)
library(ncdf4)
library(data.table)
library(tidyverse)
library(parallel)
library(sf)
library(viridis)
library(ggplot2)
library(scales)
library(ggsn)
library(gridExtra)
library(ggmap)
library(ggrepel)
library(fst)
library(USAboundaries)
library(raster)

# create directory #
disperseR::create_dirs(location="C:/Users/clair/Desktop/DEOHS/DispersR")

# read in zipcode and monthly emissions data #
crosswalk <- disperseR::crosswalk
zipcodecoordinate <- disperseR::zipcodecoordinate
zcta <- disperseR::get_data(data = "zctashapefile")

# read in emissions data #

#monthly
PP.units.monthly1995_2017 <- disperseR::PP.units.monthly1995_2017

#annual
unitsrun2005 <- disperseR::units %>% 
  dplyr::filter(year ==2005)%>% 
  dplyr::top_n(2, SOx) 
unitsrun2006 <- disperseR::units %>% 
  dplyr::filter(year ==2006)%>% 
  dplyr::top_n(2, SOx) 

head(unitsrun2005)
unitsrun <- data.table::data.table(rbind(unitsrun2005, unitsrun2006)) 

### reading in PBL data - start of what causes R to crash ###########
directory <- hpbl_dir
file <- file.path(directory, 'hpbl.mon.mean.nc')
url <-'https://www.esrl.noaa.gov/psd/repository/entry/get/hpbl.mon.mean.nc?entryid=synth%3Ae570c8f9-ec09-4e89-93b4-babd5651e7a9%3AL05BUlIvTW9udGhsaWVzL21vbm9sZXZlbC9ocGJsLm1vbi5tZWFuLm5j'
if (!file.exists(file)){
  download.file(url = url, destfile = file)
}
Sys.setenv(TZ = 'UTC')
hpbl_rasterin <- suppressWarnings(raster::brick(x = file, varname = 'hpbl'))
## end of what causes R to crash ##############

# read in met files (example uses reanalysis data) #
disperseR::get_data(data = "metfiles", 
                    start.year = "2005", 
                    start.month = "07", 
                    end.year="2006", 
                    end.month="06")

# set emissions and temporal inputs for HSYPLIT #
input_refs <- disperseR::define_inputs(units = unitsrun,
                                       startday = '2005-11-01',
                                       endday = '2006-02-28',
                                       start.hours =  c(0, 6, 12, 18),
                                       duration = 120)
head(input_refs)

# set final inputs and run dispersion # 
hysp_raw <- disperseR::run_disperser_parallel(input.refs = input_refs_subset,
                                              pbl.height = 100,
                                              species = 'so2',
                                              proc_dir = proc_dir,
                                              overwrite = FALSE, ## FALSE BY DEFAULT
                                              npart = 100,
                                              keep.hysplit.files = FALSE, ## FALSE BY DEFAULT
                                              mc.cores = 1)
