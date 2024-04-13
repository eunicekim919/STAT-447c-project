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
                           crimes = train_data$COUNT),
               chains = 1,
               refresh = 0, 
               iter = 2000)


samples = rstan::extract(fit)

