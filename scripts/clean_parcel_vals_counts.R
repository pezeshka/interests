## script for cleaning the parcel valuations and counts


## Packages
library(tidyverse)

# parcel_counts
data_path <- "../../../Library/CloudStorage/GoogleDrive-pezeshka@gmail.com/My Drive/R/interests_github/data/"

parcel_df <- readr::read_csv(file = paste0(data_path, "parcel_counts.csv")) |> 
  rename_with(tolower) |> 
  rename_with(~str_replace_all(., " ", "_"))
