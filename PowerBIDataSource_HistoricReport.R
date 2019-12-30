#Define Instance Details
instanceName = "yourinstanceid"
apiKey = "yourapikey"

# Define Report details
reportID = "12"
reportRunID = "332"
csvEncoding <- "UTF-8" # For Unicode byte translation issues in Power BI, try using ISO-8859-1 as the value for csvEncoding

# Import dependencies
library('httr')
library('jsonlite')
library('readr')

# Get Endpoint
xmlmcURL <- fromJSON(paste("https://files.hornbill.com/instances", instanceName, "zoneinfo",sep="/"))$zoneinfo$endpoint

# invokeXmlmc - take params, fire off XMLMC call
invokeXmlmc = function(service, xmethod, params) {
  paramsrequest = paste(params , collapse="")
  arrRequest = c(	"<methodCall service=\"",
                  service, 
                  "\" method=\"",
                  xmethod,
                  "\">",
                  "<params>",
                  paramsrequest,
                  "</params>",
                  "</methodCall>")
  responseFromURL <- POST(paste(xmlmcURL, "xmlmc/", service, "?method=", xmethod, sep=""),
                          add_headers('Content-Type'='text/xmlmc',Accept='application/json', Authorization=paste('ESP-APIKEY', apiKey, sep=" ")),
                          body=paste(arrRequest, collapse=""))
  return(responseFromURL)
}

# Get CSV filename from report ID and run ID 
reportRunStatus = invokeXmlmc("reporting", "reportRunGetStatus", paste("<runId>", reportRunID, "</runId>"))
reportCSVLink = fromJSON(content(reportRunStatus, "text", encoding = "UTF-8"))$params$reportRun$csvLink

# GET request for report CSV content
reportContent <- GET(paste(xmlmcURL, "dav","reports", reportID, reportCSVLink, sep="/"),
                     add_headers('Content-Type'='text/xmlmc', Authorization=paste('ESP-APIKEY ', apiKey, sep="")))

# CSV vector in to data frame object
dataframe <- content(reportContent, as = "parsed", type = "text/csv", encoding = csvEncoding)