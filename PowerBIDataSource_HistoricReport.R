#Define Instance Details
instanceName = "yourinstanceid"
apiKey = "yourapikey"

# Define Report details
reportID = "6"
reportRunID = "172"
useXLSX <- FALSE # FALSE = the script will use the CSV output from your report; TRUE = the script will use the XLSX output from your report

# Settings for using XLSX report output
# You must have XLSX output enabled against the target report in your Hornbill instance to use these settings
deleteLocalXLSX <- FALSE  # FALSE = the downloaded XLSX file will remain on disk once the extract is complete; TRUE = the local XLSX file is deleted upon completion
xlsxLocalFolder <- ""     # Can be left blank, or specify a local folder to store the downloaded XLSX file into. Requires the postfixed / or \ depending on your OS

# Settings for using CSV report output, or character encoding conversion for XLSX repost output
csvEncoding <- "UTF-8"    # For Unicode byte translation issues in Power BI, try using ISO-8859-1 as the value for csvEncoding

# Define Proxy Details
proxyAddress <- NULL  # "127.0.0.1" - location of proxy
proxyPort <- NULL     # 8080 - proxy port
proxyUsername <- NULL # login details for proxy, if needed
proxyPassword <- NULL # login details for proxy, if needed
proxyAuth <- NULL     # "any" - type of HTTP authentication to use. Should be one of the following: basic, digest, digest_ie, gssnegotiate, ntlm, any.

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

# Get filenames from report ID and run ID 
reportRunResponse = invokeXmlmc("reporting", "reportRunGetStatus", paste("<runId>", reportRunID, "</runId>"))
runOutput <- content(reportRunResponse, encoding="UTF-8")
runStatus <- runOutput$"@status"

if (runStatus == FALSE || runStatus == "fail") {
  stop(runOutput$state$error)
} else {
  if (useXLSX == TRUE) {
    # Get data from XLSX
    library(readxl)
    for (file in runOutput$params$files) {
      if (file$type == "xlsx") {
        reportLink = file$name
      }
    }
    reportLinkLocal <- paste(xlsxLocalFolder, reportLink, sep="")
    reportContent <- GET(paste(xmlmcURL, "dav","reports", reportID, URLencode(reportLink), sep="/"),
                         write_disk(reportLinkLocal, overwrite=TRUE),
                         use_proxy(proxyAddress, proxyPort, auth = proxyAuth, username = proxyUsername, password = proxyPassword),
                         add_headers('Content-Type'='text/xmlmc', Authorization=paste('ESP-APIKEY ', apiKey, sep="")))
    
    write.csv(read_excel(reportLinkLocal),paste(reportLinkLocal, "csv", sep="."), row.names = FALSE)
    dataframe <-read.csv(paste(reportLinkLocal, "csv", sep="."), encoding = csvEncoding, stringsAsFactors=FALSE)
    
    if (deleteLocalXLSX == TRUE && file.exists(reportLinkLocal)) {
      file.remove(reportLinkLocal)
    }
    if (file.exists(paste(reportLinkLocal, "csv", sep="."))) {
      file.remove(paste(reportLinkLocal, "csv", sep="."))
    }
  } else {
    # Get data from CSV
    reportLink <- runOutput$params$reportRun$csvLink
    reportContent <- GET(paste(xmlmcURL, "dav","reports", reportID, reportLink, sep="/"),
                         use_proxy(proxyAddress, proxyPort, auth = proxyAuth, username = proxyUsername, password = proxyPassword),
                         add_headers('Content-Type'='text/xmlmc', Authorization=paste('ESP-APIKEY ', apiKey, sep="")))
    dataframe <- content(reportContent, as = "parsed", type = "text/csv", encoding = csvEncoding)
  }
}