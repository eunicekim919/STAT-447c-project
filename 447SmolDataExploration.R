## General Data Exploration
#install.packages(“ape”) 
library(ape)

crime2022 <- read.csv("VanCrimeData2022.csv")
crime2023 <- read.csv("VanCrimeData2023.csv")

#almost the same amount of crime occurring each month
hist(crime2022$MONTH)

#less crime overall compared to 2022, but still very similar
#almost same amount of crime occuring each month
hist(crime2023$MONTH)

#getting Moran I
#I'm going to get it in R cuz this is taking forever LOL

