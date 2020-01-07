library(data.table); library(feedeR); library(rvest)

# setwd("C:/Users/TRM/Documents/GitHub/moman822.github.io/abs-ee")

get_absee_link <- function(pre_link) {
  y <- read_html(pre_link)
  rvest::html_nodes(y, 'table')
  y_table <- html_table(y)[[1]]
  setDT(y_table)
  paste0(sub("^(.*)[/].*", "\\1", pre_link), "/", y_table[Type=="EX-102"]$Document)
}


rss <- feedeR::feed.extract("https://www.sec.gov/cgi-bin/browse-edgar?action=getcurrent&CIK=&type=abs-ee&company=&dateb=&owner=include&start=0&count=80&output=atom")
rss2 <- feedeR::feed.extract("https://www.sec.gov/cgi-bin/browse-edgar?action=getcurrent&CIK=&type=abs-ee&company=&dateb=&owner=include&start=81&count=80&output=atom")
rss <- as.data.table(rss$items)
rss2 <- as.data.table(rss2$items)





##If rss feed does not return anything, write to log and bail
if(nrow(rss)==0) {
  log_file <- fread("data/log.csv")
  new_log <- rbind(
    log_file,
    data.table(timestamp=as.character(Sys.time()), action="Nothing added", added="")
  )
  write.csv(new_log, file="data/log.csv", row.names=FALSE)
  stop("Exiting script; no new items")
}


rss <- rss[link !="alternate" & link != "text/html"]

##If there are more than 80 filings in one day, combine results from the second rss pull with the first
if(nrow(rss2)>0){
  rss2 <- rss2[link !="alternate" & link != "text/html"]
  rss <- unique(rbind(rss, rss2))
  
}; rm(rss2)




rss_cik <- data.table(
  cik = substr(rss$link, 41, 47),
  compare_cik = as.character(paste0("000", substr(rss$link, 41, 47)))
)#[, cik:=gsub("/", "", cik)][, compare_cik:=gsub("/", "", compare_cik)]



###
#Any new CIK numbers?
companies_current <- fread("data/companies.csv", stringsAsFactors = FALSE)
new_cik <- rss_cik[!compare_cik %in% companies_current$cik]



###
#If there are new companies, find company name and url
if(nrow(new_cik)==0) {
  # stop("No new companies to add") 
} else {
  l <- list()
  
  for(i in 1:nrow(new_cik)){
    cik_in <- new_cik[i]$cik
    cik_in <- gsub("/", "", cik_in)
    
    rss2 <- feedeR::feed.extract(paste0("https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=000", cik_in, "&type=&dateb=&owner=include&start=0&count=40&output=atom"))
    
    comp <- trimws(substr(rss2$title, 0, nchar(rss2$title)-12))
    
    l[[i]] <- data.table(
      Company = comp,
      cik = new_cik[i]$compare_cik,
      deal_url = paste0("https://www.sec.gov/cgi-bin/browse-edgar?CIK=000", cik_in, "&action=getcompany")
    )
    print(i)
  }; rm(comp)
  
  add <- rbindlist(l)
  
  all_comp <- unique(rbind(companies_current, add))
  
  ###
  #Write to data file
  
  write.csv(all_comp, file="data/companies.csv", row.names = FALSE)
  
}


companies_current <- fread("data/companies.csv", stringsAsFactors = FALSE)

####






###
#Any new sources?
all_sources <- fread("data/sources.csv")

new_sources <- copy(rss[!link %in% all_sources$absee_page])

if(nrow(new_sources)>0){
  for(i in 1:nrow(new_sources)){
  
    new_sources[i, absee_link:=get_absee_link(link)]
    new_sources[i, absee_page:=link]
    new_sources[i, cik:=paste0("000", substr(link, 41, 47))]
    new_sources[i, date2:=substr(as.character(date), 0, 10)]
    cp <- companies_current[cik==new_sources[i]$cik]$Company
    new_sources[i, company:=cp]
    print(i)
  }; rm(cp)
  new_sources <- new_sources[, c("company","cik","date2","absee_page","absee_link")]
  setnames(new_sources, "date2","date")
} else {
  new_sources <- data.table("company"=NA, "cik"=NA, "date"=NA, "absee_page"=NA, "absee_link"=NA)
}


#Write back to sources file
sources_add <- unique(rbind(all_sources, new_sources))[!is.na(cik)]

write.csv(sources_add, file = "data/sources.csv", row.names = FALSE)

###
#Update log


log_file <- fread("data/log.csv")

if(nrow(new_sources[!is.na(cik)])>0){
  action1 <- paste0("New sources added: ", nrow(new_sources))
} else {
  action1 <- "No sources added"
}


if(nrow(new_cik)>0){
  action2 <- paste0("New companies added: ", nrow(new_cik))
  new_comps <- paste0(new_cik$compare_cik, collapse = "; ")
} else {
  action2 <- "No companies added"
  new_comps <- ""
}

change_table <- data.table(
  timestamp=as.character(Sys.time()),
  action=paste0(action1, "; ", action2),
  added=new_comps
)

new_log <- rbind(log_file, change_table)
write.csv(new_log, file="data/log.csv", row.names=FALSE)

print(paste0("Added: ", nrow(new_cik)))










