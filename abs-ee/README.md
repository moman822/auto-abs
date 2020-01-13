## Auto ABS Data Pipeline: ABS-EE Monthly Asset-level Data Reports

Monthly asset-level reporting is required for publicly-issued auto ABS securities. This filing, called ABS-EE, contains over 50 data points for each loan (a.k.a. *receivable*) that makes up the pool of assets backing the security.

Key data points in these filings include:
 * Month-to-month variables
 	* Payment amount made by borrower (interest and principal)
 	* Expected payment amount 
 	* Outstanding principal balance on loan 
 * Loan characteristics: 
	* Original principal balance
	* Interest rate
	* Loan term
* Demographics of loan and borrower
	* Credit score
	* State
	* Car make/model
	* Payment-to-income ratio
* and more...

### Report tracking

I maintain an automated ETL pipeline via Amazon EC2 that scrapes EDGAR to find new ABS deals and extract links to their ABS-EE filings. This data is stored in the [data folder](/abs-ee/data) along with a log showing when new reports or deals were identified.

### Data extraction

An auto ABS deal is made up of tens of thousands of receivables, meaning these monthly data disclosures are substantial in terms of storage space. Further, they are published to EDGAR as XML files, a bulky format for storing large amounts of data and difficult to use.

I have created a program in R to parse these XML formats into tabular form. It is computationally heavy and can take upwards of minutes to download and convert a single monthly report from the original XML. The resulting CSVs are too large to store on Github. Additionally, it would require a large amount of storage space and computational power to extract all the dozens of reports that are published monthly.

Instead of storing each filing, I have an ETL pipeline on Amazon EC2 that I can deploy (via high CPU spot instances) to download, transform and push the XML filings to a MySQL database on Amazon RDS. I can then easily access this data for analysis.

