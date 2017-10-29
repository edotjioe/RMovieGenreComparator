  library(tidyr)
  library(RMySQL)
  library(jsonlite)
  library(stringi)
  library(dplyr)
  library(stringr)

# Getting the data from external sources
#--------------------------------------------------------------------------------------------------------------------
#Getting the data from the database
con <-
  dbConnect(
    RMySQL::MySQL(),
    dbname = "imdb",
    password = "root",
    user = "root"
  )
tmdb <- dbGetQuery(con, "SELECT * FROM tmdb_movies")
on.exit(dbDisconnect(con))

#Getting movies.csv
file  <- "/movies"
fname <- paste(file, ".csv", sep = "")

downloadpath <- "ml-latest-small"
source <- paste(downloadpath, fname, sep = "")
movielens <-
  read.csv(
    source,
    header = TRUE,
    sep = ",",
    row.names = NULL,
    stringsAsFactors = FALSE
  )

#Getting ratings.csv
file  <- "/ratings"
fname <- paste(file, ".csv", sep = "")

source <- paste(downloadpath, fname, sep = "")
movielens.ratings <-
  read.csv(
    source,
    header = TRUE,
    sep = ",",
    row.names = NULL,
    stringsAsFactors = FALSE
  )

# Here we set up some data frames before processing the datasets
#--------------------------------------------------------------------------------------------------------------------

#Creating a data frame to store all the genre's with their movie and scores
genre.movies <-
  data.frame(
    title = character(),
    year = numeric(),
    rating = numeric(),
    votes = numeric(),
    genre = character(),
    dataset = character(),
    stringsAsFactors = FALSE
  )

# Processing the data from the TMDB
#--------------------------------------------------------------------------------------------------------------------

#Removing all the movies with no votes
tmdb <- tmdb[!(tmdb$vote_count == 0 | tmdb$genres == "[]"), ]

#Getting all the genres from tmdb
temp.genres <- lapply(tmdb$genres, fromJSON)
genre.amount <- c(sapply(temp.genres, nrow))
genre.amount <-
  do.call(rbind,
          lapply(genre.amount, data.frame, stringsAsFactors = FALSE))
colnames(genre.amount) <- "genre_count"

#Changing list to data frame
library(plyr)
temp.genres <-
  ldply(temp.genres, function(x)
    data.frame(x, stringsAsFactors = FALSE))
#Unloading plyr because it will conflict with dplyr when using summarise/summarize
detach("package:plyr", unload = TRUE)

#Creating multiple instances of each movie by the amount of genres
tmdb.shrinked <-
  tmdb[, c("id", "title", "release_date", "vote_average", "vote_count")]
tmdb.shrinked <- cbind(tmdb.shrinked, genre.amount)
tmdb.shrinked <-
  transform(tmdb.shrinked, year = data.frame(
    year = sapply(tmdb.shrinked$release_date,
                  function(x)
                    stri_sub(str = x, from = 1, to = 4)),
    stringsAsFactors = FALSE
  ))
tmdb.shrinked <- tmdb.shrinked[, c(1, 2, 7, 4, 5, 3, 6)]

#Adding the changed data to tmdb.expanded data frame
tmdb.expanded <-
  tmdb.shrinked[rep(row.names(tmdb.shrinked), tmdb.shrinked$genre_count), 2:5]

#Adding the genres to the movielens.expanded list
tmdb.expanded$genre <- ""
tmdb.expanded <- transform(tmdb.expanded, genre = temp.genres$name)
#Added dataset column with tmdb
tmdb.expanded$dataset <- "tmdb"
#Changed columns names like genre.movies
colnames(tmdb.expanded) <- colnames(genre.movies)
#Changing the format of rating to match movielens ratings
tmdb.expanded$rating <- tmdb.expanded$rating / 2
#Added tmdb.expanded to genre.movies
genre.movies <- rbind(genre.movies, tmdb.expanded)

#Remove unneeded variables
rm(genre.amount, temp.genres)

# Processing the data from the MovieLens
#--------------------------------------------------------------------------------------------------------------------

#Creating avg rating of each movie
movielens.ratings <- cbind(movielens.ratings, count = 1)
movielens.ratings.temp <- aggregate(
  x = movielens.ratings$rating,
  FUN = mean,
  by = list(movielens.ratings$movieId)
)
names(movielens.ratings.temp)[names(movielens.ratings.temp) == "Group.1"] <-
  "movieId"
names(movielens.ratings.temp)[names(movielens.ratings.temp) == "x"] <-
  "rating"

#Adding the new columns to movielens.ratings: votes
movielens.ratings <-
  cbind(movielens.ratings.temp,
        votes = aggregate(
          x = movielens.ratings$count,
          FUN = sum,
          by = list(movielens.ratings$movieId)
        )$x)

#Joining dataframes
movielens <-
  inner_join(movielens, movielens.ratings, by = "movieId")

#Getting the year from the title with regex: \\([0-9]{4}\\)
year <- data.frame(year = sapply(movielens$title, function(x) str_extract(x, "\\([0-9]{4}\\)")))
#Removing the year from the title
movielens$title <- gsub("\\([0-9]{4}\\)", "", movielens$title)
#Adding year to movielens in separate column
movielens$year <- as.numeric(sapply(year, function(x) stri_sub(str = x, from = 2, to = 5)))

#Creating multiple instances of each movie by the amount of genres
movielens <-
  transform(movielens, genre_count = sapply(strsplit(movielens$genres, "\\|"), length))
movielens.expanded <-
  movielens[rep(row.names(movielens), movielens$genre_count), 2:6]

#Creating one big list with all genres in order
temp.genres <- unlist(strsplit(movielens$genres, "\\|"))
#Adding the genres to the movielens.expanded list
movielens.expanded <-
  transform(movielens.expanded, genres = temp.genres)
#Reorder the columns to fit genre_list
movielens.expanded <- movielens.expanded[, c(1, 5, 3, 4, 2)]
#Added dataset column with ml
movielens.expanded$dataset <- "ml"
#Changed columns names like genre.movies
colnames(movielens.expanded) <- colnames(genre.movies)
#Added movielens.expanded to genre.movies
genre.movies <- rbind(genre.movies, movielens.expanded)

#Removing unneeded variables
rm(temp.genres, year, movielens.ratings, movielens.ratings.temp)

# Last bit needed to be done
#--------------------------------------------------------------------------------------------------------------------

#Setting up data frame for all the genres
genres <- data.frame(name = unique(genre.movies$genre))

#Setting up data frame for all the datasets
datasets <- data.frame(name = unique(genre.movies$dataset))
