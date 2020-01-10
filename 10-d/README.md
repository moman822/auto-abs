## Auto Asset-back Security Data Pipeline: 10-D Monthly Servicer Reports

These reports are published monthly for each publicly-issued auto ABS deal. They contain data on distributions to noteholders, the status of the pool of receivables and other required disclosures regarding the security.

There is not a standardized format for these disclosures, so they are published in different HTML formats by each issuer with a variety of tables and unstructured data. See two examples from Ally Auto and Santander Drive Auto:
* https://www.sec.gov/Archives/edgar/data/1477336/000167973119000072/aart2017-1_exx99xnovemberx.htm
* https://www.sec.gov/Archives/edgar/data/1383094/000095013119004139/d846098dex991.htm

Extracting data from these is a challenge of identifing where in the document data points are published and how to grab them efficiently. The same key data points can be found in each report.

Deals issued by the same issuer use the same HTML templates, so a program to extract data from Ally Auto Receivables Trust 2017-1 and Ally Auto Receivables Trust 2018-1 reports can be replicated, as well as across new months for the same deal.

This repository contains R programs to extract data from these monthly reports as well as the extracted data in the [data folder](/10-d/data) for a number of deals.

#### Data updating

Data is updated via a deployment pipeline on Amazon AWS. The program checks for new reports each week for specified deal issuers; extracts data from those reports, if found, using the R scripts here; and appends new data to the files in [data](/10-d/data).
