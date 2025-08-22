# packages
library(tidyverse)
library(httr)
library(jsonlite)

## Get yearly ac dataset

get_ucdp_data <- function() {
  base_url <- "https://ucdpapi.pcr.uu.se/api/"
  dataset <- "ucdpprioconflict"
  version <- "/25.1?pagesize=1000"
  all_data <- list()
  page <- 1
  
  while (TRUE) {
    url <- paste0(base_url, dataset, version, "&page=", page)
    response <- GET(url)
    if (status_code(response) != 200) {
      stop("Failed to fetch data from UCDP API")
    }
    data <- fromJSON(content(response, "text", encoding = "UTF-8"))
    if (length(data$Result) == 0) {
      break
    }
    all_data <- c(all_data, list(data$Result))
    page <- page + 1
  }
  bind_rows(all_data)
}

# Fetch and process the data
df_prio <- get_ucdp_data()

## write data
data_path <- "../../../Library/CloudStorage/GoogleDrive-pezeshka@gmail.com/My Drive/R/interests_github/data/"

write_csv(df_prio, file = paste0(data_path, "armed_conflict_yearly.csv"))

## get's dyadic version of the UCDP Battle-Related Deaths Dataset. 

get_ucdp_data <- function() {
  base_url <- "https://ucdpapi.pcr.uu.se/api/"
  dataset <- "battledeaths"
  version <- "/25.1?pagesize=1000"
  all_data <- list()
  page <- 1
  
  while (TRUE) {
    url <- paste0(base_url, dataset, version, "&page=", page)
    response <- GET(url)
    if (status_code(response) != 200) {
      stop("Failed to fetch data from UCDP API")
    }
    data <- fromJSON(content(response, "text", encoding = "UTF-8"))
    if (length(data$Result) == 0) {
      break
    }
    all_data <- c(all_data, list(data$Result))
    page <- page + 1
  }
  bind_rows(all_data)
}

# Fetch and process the data
df_bd <- get_ucdp_data()

write_csv(df_bd, file = paste0(data_path, "battle_deaths_dyad.csv"))