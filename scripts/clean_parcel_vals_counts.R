## script for cleaning the parcel valuations and counts

## Packages
library(tidyverse)
library(glue)

# parcel_counts
data_path <- "../../../Library/CloudStorage/GoogleDrive-pezeshka@gmail.com/My Drive/R/interests_github/data/"

parcel_df <- readr::read_csv(file = paste0(data_path, "parcel_counts.csv")) |> 
  rename_with(tolower) |> 
  rename_with(~str_replace_all(., " ", "_")) |>
  mutate(county = str_to_title(county))

fig <- parcel_df |> 
  pivot_longer(!c(dor_code, municipality, county, fiscal_year), 
               names_to = "parcel_type", 
               values_to = "count") |> 
  group_by(dor_code, parcel_type) |> 
  arrange(dor_code, parcel_type, fiscal_year) |> 
  mutate(change = count - lag(count), 
         percent_change = change/lag(count)) |> 
  ungroup() |> 
  filter(municipality=="Northampton", 
         str_detect(parcel_type, "family|apartment")) |> 
  mutate(
    tooltip_text = glue(
      "Parcel Type: {parcel_type}
       Fiscal Year: {fiscal_year}
       Percent Change: {scales::percent(percent_change, accuracy = 0.01)}
       Parcels: {scales::comma(count, accuracy = 1)}
       Change in Count: {change}")) |> 
  ggplot(aes(x = fiscal_year, y = percent_change, color = parcel_type, text = tooltip_text, group = parcel_type)) + 
  geom_point() + 
  geom_line()
  
  ggplot(aes(x = fiscal_year, y = single_family_101)) + 
  geom_point() + 
  geom_line()

sales_yoy <- sales_data %>%
  arrange(year) %>% # Ensure data is sorted by year
  mutate(
    previous_year_sales = lag(sales, n = 1), # Get sales from the previous year
    yoy_change = sales - previous_year_sales,
    yoy_pct_change = (sales - lag(sales, n = 1)) / lag(sales, n = 1)
  )

plotly::ggplotly(fig, tooltip = "text")