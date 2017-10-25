#Define Instance Details
instanceName = "Instance Name Goes Here"
instanceZone = "eur"

# Define API Key
apiKey = "API key goes here"

# Define Report details
reportID = "Report primary key (INT) goes here"
reportRunID = "Run ID (INT) of historic report run goes here"

# Build XMLMC URL
arrUrl = c("https://", 
           instanceZone, 
           "api.hornbill.com/", 
           instanceName)

xmlmcURL = paste(arrUrl, collapse="")

# Import dependencies
library('RCurl')
library('XML')

# invokeXmlmc - take params, fire off XMLMC call
invokeXmlmc = function(url, key, service, xmethod, params)
{
  # Build Methodcall
  paramsrequest = paste(params , collapse="")
  arrRequest = c(	"<methodCall service=\"",
                  service, 
                  "\" method=\"",
                  xmethod,
                  "\">",
                  paramsrequest,
                  "</methodCall>")
  
  request = paste(arrRequest, collapse="")
  
  # Build Invoke URL
  invokeURL = paste(url, "/xmlmc/", service, "/?method=", xmethod, sep="")
  
  # Build Headers
  espKeyAuth = paste('ESP-APIKEY ', key, sep="")
  requestHeaders = c('Content-Type'='text/xmlmc',
                     'Cache-control'='no-cache',
                     'Accept'='text/xml',
                     'Authorization'=espKeyAuth)
  
	data = getURL(	url = invokeURL,
                  postfields=request,
		      httpheader=requestHeaders,
        		verbose=TRUE)
	return(data)
}

# Get CSV filename from report ID and run ID 
arrXmlmcRequest = c(	"<params>",
                        "<runId>", reportRunID, "</runId>",
                        "</params>")
xml.request = paste(arrXmlmcRequest , collapse="")

reportRunStatus = invokeXmlmc(xmlmcURL, apiKey, "reporting", "reportRunGetStatus", xml.request)
xmlRunStatus  = xmlTreeParse(reportRunStatus, asText = TRUE,useInternalNodes=T)
reportCSVLink = unlist(xpathApply(xmlRunStatus,'//methodCallResult/params/reportRun/csvLink',xmlValue))

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