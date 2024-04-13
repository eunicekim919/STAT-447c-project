library(ggplot2)
library(sf)
library(dplyr)

#all the data things
set.seed(123)  # For reproducibility

crime_data <- read.csv("VanCrimeData2022.csv")
crime_data <- na.omit(crime_data)
indices <- sample(nrow(crime_data), size = 0.995 * nrow(crime_data))
crime_data <- crime_data[-indices, ]
crime_data$longitude <- crime_data$X
crime_data$latitude <- crime_data$Y
crime_data <- crime_data |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 26710)

#making a grid over the data
grid <- st_make_grid(crime_data, cellsize = 1000) #metres
grid <- st_sf(grid = grid, id = seq(length(grid)))

#count crimes in each grid cell
crime_counts <- st_join(grid, crime_data, join = st_intersects) |>
  group_by(id) |>
  summarise(crime_count = n())

#vancouver shapefile 
#area <- read_sf(dsn = "local-area-boundary/local-area-boundary.shp" )

#trying to plot 
ggplot()
  geom_sf(data = crime_counts, aes(fill = crime_count),  color = NA)+
  scale_fill_viridis_c()