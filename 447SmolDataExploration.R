## General Data Exploration
#install.packages(“ape”) 
library(ape)
library(geoR)
library(dplyr)

crime2023 <- read.csv("VanCrimeData2023.csv")
crimedensity2023 <- read.csv("CrimeDensity2023fixed2.csv")
crime_data <- read.csv("VanCrimeDataDensity.csv")

#almost the same amount of crime occurring each month
hist(crime2022$MONTH)

#less crime overall compared to 2022, but still very similar
#almost same amount of crime occuring each month
hist(crime2023$MONTH)
summary(crimedensity2023$Point_Count)

#getting Moran I
#I'm going to get it in R cuz this is taking forever
crime2022 <- read.csv("VanCrimeData2022.csv")
crime2022 <- na.omit(crime2022)
train_indices <- sample(nrow(crime2022), size = 0.8 * nrow(crime2022))
train_data <- crime2022[train_indices, ]
test_data <- crime2022[-train_indices, ]

geocrime <- as.geodata(train_data, coords.col = 9:10, data.col = 5)
geocrimepred <- as.geodata(test_data, coords.col = 9:10, data.col = 5)

model <- krige.bayes(geocrime, locations = geocrimepred$coords)

image(bayesmodel, locations = geocrimepred$coords)
