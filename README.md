# auto-abs

This repository is dedicated to exploring the world of data disclosures around auto loan asset-backed securities published on the U.S. Securities and Exchange Commision's (SEC) data portal, [EDGAR](https://www.sec.gov/edgar.shtml).

Tens of billions of dollars of these securities are issued annually, backed up by consumer and commercial auto loans. There is a huge amount of transparency in these issuances thanks to Dodd-Frank regulations that went into effect in early 2017 requiring *asset-level* data disclosures on the securities. This means monthly data disclosures for each individual auto loan in the pool that makes up these $1+ billion deals, including the loan payment, the expected payment and information on the borrower (income, state, car type, credit score, etc.).

With upwards of 50,000 receivables pooled in a single deal, and dozens of deals each year, this is a wealth of data to be explored, which I am doing here through individual analyses; ETL pipelines to make data more usable; and automated report generation. My work here is done through a mix of R, R-Shiny, RMarkdown, Amazon AWS, Docker and d3.js scripts, programs and workflows.
 
