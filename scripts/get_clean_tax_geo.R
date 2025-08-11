# This script cleans, merges and writes the cleaned tax and geojson data. 
# The data itself was just downloaded from the website. 

## tax rates found here: 
# https://dls-gw.dor.state.ma.us/reports/rdpage.aspx?rdreport=propertytaxinformation.taxratesbyclass.taxratesbyclass_main
# see function to pull years

## geometry found here: downloaded the geojson file.
# https://gis.data.mass.gov/datasets/43664de869ca4b06a322c429473c65e5_0/explore?location=42.051370%2C-71.715950%2C9.42

# data downloaded and stored at data_path
data_path <- "../../../Library/CloudStorage/GoogleDrive-pezeshka@gmail.com/My Drive/R/interests_github/data/"

## packages
library(tidyverse)
library(readxl)
library(httr)

years_to_fetch <- 2000:2025

get_tax_rates <- function(year) {
  # Print a message to the console to show progress
  message(paste("Fetching parcel valuations for year:", year))
  
  url <- "https://dls-gw.dor.state.ma.us/reports/rdPage.aspx"
  
  # POST request body with only one iclYear
  body <- list(
    rdReport = "PropertyTaxInformation.taxratesbyclass.taxratesbyclass",
    rdReportFormat = "NativeExcel",
    rdExportTableID = "tbl_taxratesbyclass",
    rdExportFilename = paste0("taxratesbyclass_", year),
    rdShowGridlines = "True",
    rdExcelOutputFormat = "Excel2007",
    iclYear = as.character(year)  # Only one year sent here
  )
  
  # Download Excel file to temp location
  tmp <- tempfile(fileext = ".xlsx")
  resp <- POST(url, body = body, encode = "form")
  writeBin(content(resp, "raw"), tmp)
  
  # Check for a successful response. If it fails, return NULL so map_dfr doesn't stop.
  if (status_code(resp) != 200) {
    warning(paste("Failed to download tax data for year", year, "- Status:", status_code(resp)))
    return(NULL)
  }
  
  # Read first sheet
  df <- read_excel(tmp)
  return(df)
}

ma_prop_tax <- purrr::map(years_to_fetch, get_tax_rates) |> 
  bind_rows() |> 
  rename_with(tolower) |> 
  rename_with(~str_replace_all(., " ", "_")) |> 
  mutate(across(c(dor_code, fiscal_year), ~as.numeric(.))) %>% 
  filter(municipality!="Devens")

readr::write_csv(ma_prop_tax, file = paste0(data_path, "ma_municipality_proptax_rates.csv"))


## Geojson data
library(sf)

url <- "https://arcgisserver.digital.mass.gov/arcgisserver/rest/services/AGOL/Towns_survey_polym/FeatureServer/0/query?where=1%3D1&outFields=*&f=geojson"

geojson_data <- st_read(url)

geojson_data <- geojson_data |> 
  rename_with(tolower) %>% 
  mutate(county = str_to_title(county))

sf::st_write(geojson_data, paste0(data_path, "ma_municipalities.geojson"), delete_dsn = TRUE)

## Create merged dataframe so I can get county info and also a map dataframe for the plotly visual
# merge tax with geo data
merged_df <- ma_prop_tax |> 
  left_join(geojson_data, 
            join_by(dor_code==town_id)) 

## writing rds because it contains geo info and much faster than the csv. 
readr::write_rds(merged_df, file = paste0(data_path, "clean_tax_geo_data.R"))

map_df <- merged_df %>% 
  filter(fiscal_year==2025, 
         !is.na(residential)) %>% 
  select(municipality, residential, county, geometry)

map_sf <- st_as_sf(map_df)

sf::st_write(map_sf, paste0(data_path, "clean_ma_geo.geojson"), delete_dsn = TRUE)
