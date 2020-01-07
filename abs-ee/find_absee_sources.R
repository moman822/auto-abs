#Get the ABS-EE filings for each deal
#Run once
library(data.table); library(rvest); library(feedeR)



sources_current <- fread("data/sources.csv", stringsAsFactors = FALSE)
companies <- fread("data/companies.csv")

get_absee_link <- function(pre_link) {
  y <- read_html(pre_link)
  rvest::html_nodes(y, 'table')
  y_table <- html_table(y)[[1]]
  setDT(y_table)
  paste0(sub("^(.*)[/].*", "\\1", pre_link), "/", y_table[Type=="EX-102"]$Document)
}

###
#Loop through every company and pull RSS for ABS-EE filetypes
ciks <- unique(sources_current$cik)
ciks <- unique(companies$cik)



l <- list()
for(i in 1:length(ciks)){
  
  print(paste0("CIK: ", ciks[i]))
  x <- feedeR::feed.extract(
    paste0("https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=", ciks[i],"&type=abs-ee%25&dateb=&owner=exclude&start=0&count=100&output=atom")
  )$items
  setDT(x)
  
  
  
  x <- x[!link %in% c("alternate", "text/html")]
  
  if(nrow(x)>40){next}
  
  x[, date:=substr(date, 0, 10)]
  x[, absee_page:=link]
  x[, company:=sources_current[cik==ciks[i]]$company[1]]
  x[, cik:=ciks[i]]
  #x$absee_link <- get_absee_link(x$absee_page)
  
  for(j in 1:nrow(x)){
    
    x[j, absee_link := get_absee_link(absee_page)]
    print(paste0("absee: ", j, "/", nrow(x)))
  }
  
  l[[i]] <- x[, c("company","cik","date","absee_page","absee_link")]
  
  print(i)
  
}

sources <- rbindlist(l)

#sources_current should already have https links
# sources_current[, absee_page:=gsub("http", "https", absee_page)][, absee_link:=gsub("http", "https", absee_link)]

sources2 <- unique(rbind(sources, sources_current))


##Which are not in our current source file?

sources[!absee_link %in% sources_current$absee_link]



# sources1 <- copy(sources)

write.csv(sources2[, c('company', 'cik', 'date', 'absee_page', 'absee_link')], "C:/Users/TRM/Documents/GitHub/moman822.github.io/abs-ee/data/sources.csv", row.names = FALSE)














































