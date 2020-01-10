library(rvest); library(data.table); library(feedeR)


###
### Get data from 10-D monthly servicer reports of CarMax asset-backed securities
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


ciks <- comp[grepl("CarMax ", Company), unique(cik)]
comp[grepl("CarMax ", Company), unique(Company)]
all <- list()


#Find sources and extract data:

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
    
    
    period <- as.Date(strsplit(x1[grepl("Collection Period", X1)]$X3, "-")[[1]][1], format="%m/%d/%y")
    
    t1 <- data.table(data.frame(cbind(
      tbls[[2]][, paste(X1, X2)],
      tbls[[2]][, paste(X3, X4, X5)],
      tbls[[2]][, paste( X7, X8, X9)]
    )))
    
    
    #Which table has distribution data?
    dist <- lapply(tbls, function(x){
      "Note Payment Account Activity" %in% unlist(x)
    })
    
    dist <- min(which(unlist(dist)))
    
    t2 <- tbls[[dist]]
    
    
    
    #For t1, find row that starts with "8. Note balances"
    r1 <- which(grepl("8. Note Balances", t1$X1))
    r2 <- which(grepl("9. Pool Factors", t1$X1))-1
    
    
    #BeginningNotePrincipalBalance & EndingNotePrincipalBalance
    t1[r1:r2, c(1, 2)][, variable:="BeginningNotePrincipalBalance"][]
    t1[r1:r2, c(1, 3)][, variable:="EndingNotePrincipalBalance"][]
    
    #NoteRate
    #no
    
    
    #For t2, find row that starts with "
    r1 <- which(grepl("Class A-1 Interest Distribution", t2$X2))
    r2 <- which(grepl("a. Class A-1 Distribution", t2$X2))-2
    
    
    
    
    t3 <- t2[r1:r2][!grepl("Total", X2)]
    t3$X2 <- substr(
      t3$X2,
      regexpr("Class", t3$X2)+ 6,
      stop = 100
    )
    
    t3$Class <- substr(
      t3$X2,
      0,
      stop = regexpr(" ", t3$X2)-1
    )
    
    t3$variable <- gsub("[[:space:]]", "", substr(
      t3$X2,
      regexpr(" ", t3$X2)+1,
      100
    ))
    
    t3$value <- t3$X6
    
    t3 <- t3[, c('Class', 'value', 'variable')]
    
    # #InterestDistribution
    # t2[33:39, c(2, 6)][, variable:="InterestDistribution"][]
    # 
    # #PrincipalDistribution
    # t2[40:46, c(2, 6)][, variable:="PrincipalDistribution"][]
    
    
    
    #Combine and clean
    out <- rbind(
      setNames(t1[14:20, c(1, 2)][, variable:="BeginningNotePrincipalBalance"][], c("Class","value","variable")),
      setNames(t1[14:20, c(1, 3)][, variable:="EndingNotePrincipalBalance"][], c("Class","value","variable"))
    )
    
    
    out$Class <- substr(
      out$Class,
      regexpr("Class", out$Class)+ 6,
      stop = 100
    )
    out$Class <- substr(
      out$Class,
      0,
      stop = regexpr(" ", out$Class)-1
    )
    
    out <- rbind(out, t3)
    
    out[, value:=as.numeric(gsub("[[:space:]]", "", gsub("[\\$,]", "", value)))]
    out[, period:=period][, company:=comp[cik==ciks[j]]$Company]
    
    l[[i]] <- out
    print(i)
    
    
    
  }; rm(t1, tbls, x1, page,i, period, page, tbls, x1)
  
  all[[j]] <- rbindlist(l)
  
}; rm(links, srv_rep, l, j, t2, t3, out, dist, r1, r2)



carmax10d <- unique(rbindlist(all))

carmax10d[, .N, by=.(company, period)]
setnames(carmax10d, "Class", "class")

fwrite(carmax10d, "carmax10d.csv")












