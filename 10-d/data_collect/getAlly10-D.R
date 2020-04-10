library(rvest); library(data.table); library(feedeR)

###
### Get data from 10-D monthly servicer reports of Ally Auto asset-backed securities
###

##Check for correct files:
if(!file.exists("data/ally10d.csv")){ 
  stop("The file does not exists; you are running this script from the wrong directory!")
}


#Functions to extract links from EDGAR
get_10d_links <- function(cik) {
  rss <- paste0(
    "https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=",
    cik,
    "&type=10-D%25&dateb=&owner=exclude&start=0&count=1000&output=atom"
  )
  rss <- feedeR::feed.extract(rss)
  
  if(nrow(rss$items)==0){
    NA
  } else {
    list(
      links = data.table(rss$items)[grepl("https", link)]$link,
      dates = data.table(rss$items)[grepl("https", link)]$date
    )
  }
}

get_servicer_report <- function(link) {
  html1<- read_html(link)
  tbl1 <- html_table(html1)[[1]]
  tbl2 <- html_node(html1, "#formDiv > div > table")
  tbl1$links <- html_attr(
    html_nodes(tbl2, "a"),
    "href"
  )
  link <- data.table(tbl1)[grepl("ex", tolower(Type))]$links
  link <- paste0("https://www.sec.gov", link)
  cat(link, "\n")
  link
}


#Find links to pull
comp <- fread("https://raw.githubusercontent.com/moman822/auto-abs/gh-pages/abs-ee/data/companies.csv")


ciks <- comp[Company!="Ally Auto Assets LLC"][grepl("Ally", Company), unique(cik)]
all <- list()

dt <- fread("data/ally10d.csv")



for(j in 1:length(ciks)){
  
  d10 <- get_10d_links(cik = ciks[j])
  if(is.na(d10)){ next }
  
  d10 <- as.data.table(d10)
  
  d10$srv_rep <- unlist(lapply(d10$links, get_servicer_report))
  #srv_rep <- unlist(srv_rep)
  d10 <- d10[!srv_rep %in% dt$link]
  
  if(nrow(d10)==0){ 
    print(paste0("All reports scraped for: ", ciks[j]))
    next
  } else { 
    print(paste0("Some report for: ", ciks[j]))
  }
  
  l <- list()
  print(paste0("Reports to scrape: ", nrow(d10)))
  
  l <- list()
  
  for(i in 1:nrow(d10)){
    page <- read_html(d10$srv_rep[i])
    tbls <- html_table(page, fill = T)
    lapply(tbls, setDT)
    x1 <- tbls[[1]]#download_table(page, "body > document > type > sequence > filename > description > text > div > div:nth-child(5) > div > table")
    period <- as.Date(x1[grepl("Collection Period, Begin", X2)]$X3, format = "%m/%d/%Y")
    pub <- d10$dates[i]
    
    if(period %in% as.Date(c("2020-01-01", "2020-02-01"))){
      rc <- tbls[[9]][, c("X2","X7")]
      t1 <- tbls[[3]]
    } else {
      rc <- tbls[[8]][, c("X2","X7")]
      t1 <- tbls[[2]]
    }
    
    names(rc) <- c("variable", "value")
    rc <- rc[variable!=""]
    rc[, variable:=paste0("Ending", gsub(" ", "", variable))]
    rc[, Class:="all"]
    rc[, value:=as.numeric(gsub("[[:space:]]", "", gsub(",", "", value)))]
    rc[, link:=d10$srv_rep[i]]
    rc[, period:=period][, company:=comp[cik==ciks[j]]$Company]
    
    
    names(t1) <- gsub("[[:space:]]", "", paste0(
      as.matrix(t1)[3,],
      as.matrix(t1)[4,]
    ))
      
      #c("class","cusip","initial_principal","begin_principal","note_rate",
      #  "principal_dist","interest_dist","pass_through_dist",
      #  "total_dist","principal_caryyover_shortfall","interest_carryover_shortfall",
      #  "end_principal_balance")
    t1 <- t1[7:14]
    t1 <- data.table(apply(t1, 2, gsub, patt=",", replace=""))
    t1 <- t1[, lapply(.SD, as.numeric), by=.(Class)]
    t1 <- melt(t1, id.vars = c("Class"))[, period:=period][, company:=comp[cik==ciks[j]]$Company]
    t1[, link:=d10$srv_rep[i]]
    t1 <- rbind(t1, rc)[, pub_date:=pub]
    
    l[[i]] <- t1
    print(i)
  }
  
  all[[j]] <- rbindlist(l)
  
}; rm(d10, l, j)


if(length(all)==0){
  print("There is no data scraped")
  
} else {
  print("Writing data")
  ally10d <- rbindlist(all)
  ally10d[variable=="CUSIP/CUSIP-RegS", variable:="CUSIP"]
  ally10d <- ally10d[variable!="CUSIP"]
  setnames(ally10d, "Class", "class")
  setnames(ally10d, "company", "deal")
  ally10d[, pub_date:=as.character(pub_date)]
  ally10d[, period:=as.character(period)]
  
  
  old_data <- fread("data/ally10d.csv")
  
  final_data <- rbind(
    old_data,
    ally10d
  )
  
  fwrite(final_data, "data/ally10d.csv")
  
  
}


























