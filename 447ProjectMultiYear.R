library(ggplot2)
library(sf)
library(dplyr)
library(rstan)
library(tidybayes)
library(magrittr)

#all the data things
set.seed(123)  # For reproducibility

crime_data_2022 <- read.csv("CrimeDensity2022fixed2.csv")

crime_data_2023 <- read.csv("CrimeDensity2023fixed2.csv")

ggplot(crime_data_2022, aes(x = X_Coord, y = Y_Coord, fill = Point_Count)) +
  geom_tile() +  # creates the grid cells
  scale_fill_gradient(low = "blue", high = "red") +
  labs(title = "Crime Density in Vancouver", fill = "Number of Crimes") +
  coord_fixed(ratio = 1)  # keeps the aspect ratio of 1:1

ggplot(crime_data_2023, aes(x = X_Coord, y = Y_Coord, fill = Point_Count)) +
  geom_tile() +  # creates the grid cells
  scale_fill_gradient(low = "blue", high = "red") +
  labs(title = "Crime Density in Vancouver", fill = "Number of Crimes") +
  coord_fixed(ratio = 1)  # keeps the aspect ratio of 1:1

#OMG OMG OMG OMG IT WORKEEDDDDDDDDD 

crime_data_2022 <- crime_data_2022[-c(201:nrow(crime_data_2022)),] #for now
crime_data_2023 <- crime_data_2023[-c(201:nrow(crime_data_2023)),] #for now

train_data <- crime_data_2022
test_data <- crime_data_2023



fit = stan(file = 'bayes_geo_model.stan', 
           data = list(N = nrow(train_data),
                       x = train_data$X_Coord,
                       y = train_data$Y_Coord,
                       crimes = train_data$Point_Count,
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


real_data <- data.frame(
  lon = test_data$X_Coord,
  lat = test_data$Y_Coord,
  crime_count = test_data$Point_Count
)


ggplot(real_data, aes(x = lon, y = lat, fill = crime_count)) +
  geom_tile() +  # creates the grid cells
  scale_fill_gradient(low = "blue", high = "red") +
  labs(title = "Crime Density in Vancouver", fill = "Number of Crimes") +
  coord_fixed(ratio = 1)  # keeps the aspect ratio of 1:1

ggplot(predicted_data, aes(x = lon, y = lat, fill = crime_count)) +
  geom_tile() + 
  scale_fill_gradient(low = "blue", high = "red")+
  coord_fixed(ratio = 1)

traceplot(fit)


# Calculate RMSE
rmse <- sqrt(mean((predicted_data$crime_count - real_data$crime_count)^2))
# Calculate MAE
mae <- mean(abs(predicted_data$crime_count - real_data$crime_count))

# Print the metrics
print(paste("Root Mean Squared Error:", rmse))
print(paste("Mean Absolute Error:", mae))

library(ggplot2)

# Combine test data and predicted data for plotting
comparison_data <- cbind(test_data, predicted_data)

ggplot(comparison_data, aes(x = lon, y = lat)) +
  geom_tile(aes(fill = COUNT), alpha = 0.5) +  # Actual counts
  geom_tile(aes(fill = crime_count), color = "grey", alpha = 0.5) +  # Predicted counts
  scale_fill_gradient(low = "blue", high = "red") +
  labs(title = "Comparison of Actual and Predicted Crime Counts",
       subtitle = paste("RMSE:", round(rmse, 2), "MAE:", round(mae, 2))) +
  theme_minimal() +
  theme(legend.position = "none")
