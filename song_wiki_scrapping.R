#==========================================================================
# Topic : Scrapping Music information from wikipedia
# Date : 2019. 03. 31
# Author : Junmo Nam
# Blog : http://apple-rbox.tistory.com
#==========================================================================



#==========================================================================
# load package
#==========================================================================

pkg = c('dplyr','rvest','foreach','doParallel','magrittr','XML','RCurl','lubridate')
sapply(pkg,require,character.only = T)


#==========================================================================
# Read billboard top 100 songs data and scrapping data
#==========================================================================


# loading scapred data
df = read.csv("billboard_2007-2017.csv",stringsAsFactors = F)

#make cluster for parallel work
cl = makeCluster(detectCores()-1)
registerDoParallel(cl)

#title check
title_df=foreach(i = 2007:2017,.combine = rbind,.packages = pkg) %dopar% {
   paste("http://en.wikipedia.org/wiki/Billboard_Year-End_Hot_100_singles_of_",i,sep="") %>% read_html %>%  #make url and read it
    html_nodes('.wikitable') %>% # grab wiki table nodes from html
    html_table %>% as.data.frame %>% set_colnames(c('x','title','artist')) %>% #get information and rename columns
            cbind(year = i)
}

title_df = title_df[,-1] #remove index


#extract hyperlink of songs
ex.hplink =function(x){ #function for read 'a-href' nodes from html
    foreach(i = 1:length(x),.combine = append,.packages = pkg) %dopar% {
      return((html_nodes(x[i],'a') %>% html_attr("href"))[1])
    }
}


hplink_song = foreach(i = 2007:2017,.combine = append,.packages= pkg) %dopar% {
  idx = (paste("http://en.wikipedia.org/wiki/Billboard_Year-End_Hot_100_singles_of_",i,sep="") %>% read_html %>% 
           html_nodes('.wikitable') %>%html_nodes('tr'))[-1]
 ex.hplink(idx)
}


# released date of songs
released.date = foreach(i = 1:length(hplink_song),.combine =append,.packages = pkg) %dopar% { #check released date of songs
  j = (read_html(paste0("https://en.wikipedia.org",hplink_song[i])) %>% html_nodes('.infobox.vevent') %>%
         html_table(fill=T))[[1]]
  if((j[grep("Released",j[,1]),2] %>% length)==0){
    return(NA)
  }else{
    return(j[grep("Released",j[,1]),2])  
  }
  
}

# genre of songs
genre =  foreach(i = 1:length(hplink_song),.combine =append,.packages = pkg) %dopar% { #check genre information of songs
  j = (read_html(paste0("https://en.wikipedia.org",hplink_song[i])) %>% html_nodes('.infobox.vevent') %>% html_table(fill=T))[[1]]
  if((j[grep("Genre",j[,1]),2] %>% length)==0){
    return(NA)
  }else{
    return(j[grep("Genre",j[,1]),2])  
  }
  
}


#preprocessing for make only 1 date for 1 song
r.date.pp = sub("\n.*","",released.date)
genre.pp = gsub("\n","/",genre)


#find month based on given order : released month
released.month = foreach(i = 1:length(r.date.pp),.combine = append) %dopar% {
  
  grep_rdate = function(x){
    grep(x,r.date.pp[i])
  }
  
  which(sapply(month.name,grep_rdate)!=0)[1] #use only first one
  
}

stopCluster(cl) # done : stop cluster


#add it to dataframe
df$rmonth = released.month
df$genre = genre.pp



