#Define Instance Details
instanceName = "yourinstanceid"
apiKey = "yourapikey"

# Define Report details
reportID = "6"
reportRunID = "143"
csvEncoding <- "UTF-8" # For Unicode byte translation issues in Power BI, try using ISO-8859-1 as the value for csvEncoding

# Define Proxy Details
proxyAddress <- NULL # "127.0.0.1" - location of proxy
proxyPort <- NULL # 8080 - proxy port
proxyUsername <- NULL # login details for proxy, if needed
proxyPassword <- NULL # login details for proxy, if needed
proxyAuth <- NULL # "any" - type of HTTP authentication to use. Should be one of the following: basic, digest, digest_ie, gssnegotiate, ntlm, any.

# Import dependencies
library('httr')

# Set httr default timeout, defaults to 10 seconds
set_config( config( connecttimeout = 60 ) )

# Get Endpoint
responseFromFiles <- GET(paste("https://files.hornbill.com/instances", instanceName, "zoneinfo",sep="/"), 
                         use_proxy(proxyAddress, proxyPort, auth = proxyAuth, username = proxyUsername, password = proxyPassword),
                         add_headers('Content-Type'='application/json',Accept='application/json'))

xmlmcURL <-  content(responseFromFiles, as = "parsed", type = "application/json", encoding="UTF-8")$zoneinfo$endpoint

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
  apiUrl = paste(xmlmcURL, "xmlmc/", service, "?method=", xmethod, sep="")
  responseFromURL <- POST(apiUrl,
                          add_headers('Content-Type'='text/xmlmc',Accept='application/json', Authorization=paste('ESP-APIKEY', apiKey, sep=" ")),
                          use_proxy(proxyAddress, proxyPort, auth = proxyAuth, username = proxyUsername, password = proxyPassword),
                          body=paste(arrRequest, collapse=""))
  return(responseFromURL)
}

# Get CSV filename from report ID and run ID 
reportRunResponse = invokeXmlmc("reporting", "reportRunGetStatus", paste("<runId>", reportRunID, "</runId>"))
runOutput <- content(reportRunResponse, encoding="UTF-8")
runStatus <- runOutput$"@status"

if (runStatus == FALSE || runStatus == "fail") {
  stop(runOutput$state$error)
} else {
  reportCSVLink = runOutput$params$reportRun$csvLink
  
  # GET request for report CSV content
  reportContent <- GET(paste(xmlmcURL, "dav","reports", reportID, reportCSVLink, sep="/"),
                       use_proxy(proxyAddress, proxyPort, auth = proxyAuth, username = proxyUsername, password = proxyPassword),
                       add_headers('Content-Type'='text/xmlmc', Authorization=paste('ESP-APIKEY ', apiKey, sep="")))
  
  # CSV vector in to data frame object
  dataframe <- content(reportContent, as = "parsed", type = "text/csv", encoding = csvEncoding)
}