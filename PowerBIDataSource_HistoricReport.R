#Define Instance Details
instanceName = "Instance Name Goes Here"
instanceZone = "eur"

# Define API Key
apiKey = "API key goes here"

# Define Report details
reportID = "Report primary key (INT) goes here"
reportRunID = "Run ID (INT) of historic report run goes here"

# Import dependencies
library('RCurl')
library('XML')

# Build CSV filename from report ID and run ID 
reportCSVLink = paste(reportID, "_", reportRunID, ".csv", sep="")

# Build XMLMC URL
arrUrl = c("https://", 
           instanceZone, 
           "api.hornbill.com/", 
           instanceName, 
           "/dav/reports/",
           reportID,
           "/",
           reportCSVLink)

# Implode URL array in to string
invokeURL = paste(arrUrl, collapse="",sep="")

# Set Headers
espKeyAuth = paste('ESP-APIKEY ', apiKey, sep="")
requestHeaders = c('Content-Type'='text/xmlmc',
                   'Authorization'=espKeyAuth)

# GET request for report CSV content
reportContent =  getURL(	url = invokeURL, httpheader=requestHeaders)

## Read CSV vector in to data frame object
dataframe <- read.csv(textConnection(reportContent))