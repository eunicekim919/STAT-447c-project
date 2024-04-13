library(ggplot2)
library(sf)
library(dplyr)
library(rstan)
library(tidybayes)
library(magrittr)

#all the data things
set.seed(123)  # For reproducibility

crime_data <- read.csv("VanCrimeDataDensity.csv")
crime_data <- crime_data[-c(201:nrow(crime_data)),] #for now

# Assuming crime_data is your dataframe
ggplot(crime_data, aes(x = X_Coord, y = Y_Coord, fill = COUNT)) +
  geom_tile() +  # creates the grid cells
  scale_fill_gradient(low = "blue", high = "red") +
  labs(title = "Crime Density in Vancouver", fill = "Number of Crimes") +
  coord_fixed(ratio = 1)  # keeps the aspect ratio of 1:1

#OMG OMG OMG OMG IT WORKEEDDDDDDDDD 

# Set seed for reproducibility
set.seed(123)

# Sample 80% of the data to keep
train_indices <- sample(nrow(crime_data), size = 0.8 * nrow(crime_data))
train_data <- crime_data[train_indices, ]
test_data <- crime_data[-train_indices, ]



fit = stan(file = 'geo_model.stan', 
               data = list(N = nrow(train_data),
                           x = train_data$X_Coord,
                           y = train_data$Y_Coord,
                           crimes = train_data$COUNT,
                           N_new = nrow(test_data),
                           x_new = test_data$X_Coord,
                           y_new = test_data$Y_Coord),
               chains = 1,
               refresh = 0, 
               iter = 2000)


samples = rstan::extract(fit)

predicted_crimes <- samples$pred_crimes

mean_predicted_crimes <- apply(predicted_crimes, 2, mean)

predicted_data <- data.frame(lon = test_data$X_Coord,
                             lat = test_data$Y_Coord,
                             crime_count = mean_predicted_crimes)


train <- data.frame(
  lon = train_data$X_Coord,
  lat = train_data$Y_Coord,
  crime_count = train_data$COUNT
)

# Combine both datasets
full_data <- rbind(
  train[, c("lon", "lat", "crime_count")],
  predicted_data[, c("lon", "lat", "crime_count")]
)

full_data <- na.omit(full)

ggplot(full_data, aes(x = lon, y = lat, fill = crime_count)) +
  geom_tile() + 
  scale_fill_gradient(low = "blue", high = "red")+
  coord_fixed(ratio = 1)
