## Auto Asset-back Security Data Pipeline: 10-D Monthly Servicer Reports

These reports are published monthly for each publicly-issued auto ABS deal. They contain data on distributions to noteholders, the status of the pool of receivables and other required disclosures regarding the security.

There is not a standardized format for these disclosures, so they are published in different HTML formats by each issuer with a variety of tables and unstructured data. See two examples from Ally Auto and Santander Drive Auto:
* https://www.sec.gov/Archives/edgar/data/1477336/000167973119000072/aart2017-1_exx99xnovemberx.htm
* https://www.sec.gov/Archives/edgar/data/1383094/000095013119004139/d846098dex991.htm

Extracting data from these is a challenge of identifing where in the document data points are published and how to grab them efficiently. The same key data points can be found in each report.

Deals issued by the same issuer use the same HTML templates, so a program to extract data from Ally Auto Receivables Trust 2017-1 and Ally Auto Receivables Trust 2018-1 reports can be replicated, as well as across new months for the same deal.

The [data_collect folder](/10-d/data_collect) contains R programs to extract data from these monthly reports. Extracted data is available in the [data folder](/10-d/data) for a number of deals.

### Data updating

Data is updated via a deployment pipeline on Amazon AWS. The program checks for new reports each week for specified deal issuers; extracts data from those reports, if found, using the R scripts in [data_collect](/10-d/data_collect); and appends new data to the files in [data](/10-d/data).


### Report generation

Using the standardized data for different deals extracted by the update pipeline, I am also generating monthly reports displaying and analyzing the data. These currently look at every deal across a single issuer in a single report. They are generated in the same Amazon AWS pipeline, triggered if a new 10-D report is scraped.

These reports are generated using R and RMarkdown to create an interactive HTML document, available in the [reports folder](/10-d/reports)
