# Scrapping-Billboard-song-info
This R code and csv files are simple practice code for scrapping wikipidea using R
billboard_2007-2017.csv contains target billboard top 100 songs information, and scrap_result is result from code


### You can check required package below

```r
pkg = c('dplyr','rvest','foreach','doParallel','magrittr','XML','RCurl','lubridate')
sapply(pkg,require,character.only = T)

```

### You can check wikipedia website to crawl below

https://en.wikipedia.org/wiki/Billboard_Year-End_Hot_100_singles_of_2007
