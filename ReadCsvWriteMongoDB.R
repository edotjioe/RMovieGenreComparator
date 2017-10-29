# read in csv

getwd()
# setwd ("")

movies <- read.csv2("ml-20m/movies.csv", sep=",")
ratings <- read.csv2("ml-20m/ratings.csv", sep=",")
# head(ratings$timestamp,5)
# ratings$date <- as.POSIXct(as.numeric(as.character(ratings$timestamp)), origin="1970-01-01", tz="UTC")
# head(ratings$date, 5)

# moviesRatings <- merge(movies, ratings, by="movieId")

# write MongoDB

#install.packages("mongolite")
library(mongolite)

mcon_movies <- mongo(collection="movies", db="movielensdb", url="mongodb://localhost")

mcon_movies$insert(movies)

mcon_ratings <- mongo(collection="ratings", db="movielensdb", url="mongodb://localhost")

mcon_ratings$insert(ratings)