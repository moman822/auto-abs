library(rvest); library(data.table); library(feedeR)


###
### Get data from 10-D monthly servicer reports of Ally Auto asset-backed securities
###

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
    links <- data.table(rss$items)[grepl("https", link)]$link
    links
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

for(j in 1:length(ciks)){
  print(paste0("Starting: ", j))
  
  links <- get_10d_links(cik = ciks[j])
  if(is.na(links)){ next }
  srv_rep <- lapply(links, get_servicer_report)
  srv_rep <- unlist(srv_rep)
  print(paste0("Reports to scrape: ", length(srv_rep)))
  l <- list()
  
  for(i in 1:length(srv_rep)){
    page <- read_html(srv_rep[i])
    tbls <- html_table(page, fill = T)
    lapply(tbls, setDT)
    x1 <- tbls[[1]]#download_table(page, "body > document > type > sequence > filename > description > text > div > div:nth-child(5) > div > table")
    period <- as.Date(x1[grepl("Collection Period, Begin", X2)]$X3, format = "%m/%d/%Y")
    
    t1 <- tbls[[2]]
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
    l[[i]] <- t1
    print(i)
  }; rm(t1, tbls, x1, page,i, period)
  
  all[[j]] <- rbindlist(l)
  
}; rm(links, srv_rep, l, j)


ally10d <- rbindlist(all)
ally10d[variable=="CUSIP/CUSIP-RegS", variable:="CUSIP"]
ally10d <- ally10d[variable!="CUSIP"]

fwrite(ally10d, "ally10d.csv")


















