# This script pulls parcel valuation data for all municipalities in Massachusetts. 
# This function only pulls and saves the data. It does not clean the data. It 
# pulls the data on a year basis via excel download. The last part of the code binds
# these temporary files and puts them into a single tibble. 

# USE CASE: relates to property tax info and municipality revenue. 
# towns have limits on how much they can raise property taxes on existing homes/property 
# so new homes and property help the municipality generate more revenue. 

## Packages
library(tidyverse)
library(httr)
library(readxl)

# Define the range of years you want to get data for
# The website appears to have data from 2004 onwards.
years_to_fetch <- 2000:2025

## define final data destination. Saving as csv
write_path <- "../../../Library/CloudStorage/GoogleDrive-pezeshka@gmail.com/My Drive/R/interests_github/data/"

get_parcel_valuations <- function(year) {
  # Print a message to the console to show progress
  message(paste("Fetching parcel valuations for year:", year))
  
  url <- "https://dls-gw.dor.state.ma.us/reports/rdPage.aspx"
  
  # POST request to get the counts data as an Excel file
  resp <- POST(
    url,
    query = list(
      rdReport = "PropertyTaxInformation.LA4.Parcel_counts_vals",
      rdReportFormat = "NativeExcel",
      rdExportTableID = "xtVals",
      rdExportFilename = paste0("ParcelValuationsByUseCode", year),
      rdShowGridlines = "True",
      rdExcelOutputFormat = "Excel2007"
    ),
    body = list(
      islYear = year # This parameter seems to be the key for the POST body
    ),
    encode = "form"
  )
  
  # Check for a successful response. If it fails, return NULL so map_dfr doesn't stop.
  if (status_code(resp) != 200) {
    warning(paste("Failed to download valuations for year", year, "- Status:", status_code(resp)))
    return(NULL)
  }
  
  # Write the raw content to a temporary file and read it
  tmp <- tempfile(fileext = ".xlsx")
  writeBin(content(resp, "raw"), tmp)
  
  # Read the excel file
  read_excel(tmp)
}

parcel_val_df <- purrr::map(years_to_fetch, get_parcel_valuations) |> 
  bind_rows()

readr::write_csv(parcel_val_df, file = paste0(write_path, "parcel_valuations.csv"))