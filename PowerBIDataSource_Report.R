#Define Instance Details
instanceName = "yourinstanceid"
apiKey = "yourapikey"

# Define Report details
reportID = "6"
reportComment = "A comment to add to the report run"
deleteReportInstance <- FALSE
useXLSX <- FALSE # FALSE = the script will use the CSV output from your report; TRUE = the script will use the XLSX output from your report

# Settings for using XLSX report output
# You must have XLSX output enabled against the target report in your Hornbill instance to use these settings
deleteLocalXLSX <- FALSE  # FALSE = the downloaded XLSX file will remain on disk once the extract is complete; TRUE = the local XLSX file is deleted upon completion
xlsxLocalFolder <- "/Users/steveg/R/rPowerBIHornbillDataSources/" # Can be left blank, or specify a local folder to store the downloaded XLSX file into. Requires the postfixed / or \ depending on your OS

# Settings for using CSV report output, or character encoding conversion for XLSX repost output
csvEncoding <- "UTF-8"    # For Unicode byte translation issues in Power BI, try using ISO-8859-1 as the value for csvEncoding

# Suspend for X amount of seconds between checks to see if the report is complete
suspendSeconds <- 1

# Define Proxy Details
proxyAddress <- NULL # "127.0.0.1" - location of proxy
proxyPort <- NULL # 8080 - proxy port
proxyUsername = NULL # login details for proxy, if needed
proxyPassword = NULL # login details for proxy, if needed
proxyAuth = NULL # "any" - type of HTTP authentication to use. Should be one of the following: basic, digest, digest_ie, gssnegotiate, ntlm, any.

# Import dependencies
library(httr)

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
  responseFromURL <- POST(paste(xmlmcURL, "xmlmc/", service, "?method=", xmethod, sep=""),
                          add_headers('Content-Type'='text/xmlmc',Accept='application/json', Authorization=paste('ESP-APIKEY', apiKey, sep=" ")),
                          use_proxy(proxyAddress, proxyPort, auth = proxyAuth, username = proxyUsername, password = proxyPassword),
                          body=paste(arrRequest, collapse=""))
  return(responseFromURL)
}

# Kick off report run, get job ID
runOutput <- content(invokeXmlmc("reporting", "reportRun", paste("<reportId>", reportID, "</reportId>","<comment>", reportComment, "</comment>")), encoding="UTF-8")
runStatus <- runOutput$"@status"

if (runStatus == FALSE || runStatus == "fail") {
  stop(runOutput$state$error)
} else {
  
  runID <- runOutput$params$runId
  
  reportSuccess <- FALSE
  reportComplete <- FALSE
  
  if (runID > 0) {
    repeat {
      Sys.sleep(suspendSeconds)
      
      # Check status of report
      reportRunStatus <- invokeXmlmc("reporting", "reportRunGetStatus", paste("<runId>", runID, "</runId>"))
      runStatus <- content(reportRunStatus)$params$reportRun$status
      runComp <- grepl(runStatus, "completed")
      
      if (runComp == TRUE) {
        if (useXLSX == TRUE) {
          for (file in content(reportRunStatus)$params$files) {
            if (file$type == "xlsx") {
              reportLink = file$name
            }
          }
        } else {
          reportLink <- content(reportRunStatus)$params$reportRun$csvLink
        }
        reportSuccess <- TRUE
        reportComplete <- TRUE
        break;
      } else if (runStatus == "failed") {	
        reportSuccess <- FALSE
        reportComplete <- TRUE
        break;
      }
    }
  }
  
  if (reportSuccess == FALSE) {	
    stop()
  }
  
  # GET request for report CSV content
  if (useXLSX == TRUE) {
    reportLinkLocal <- paste(xlsxLocalFolder, reportLink, sep="")
    reportContent <- GET(paste(xmlmcURL, "dav","reports", reportID, URLencode(reportLink), sep="/"),
                         write_disk(reportLinkLocal, overwrite=TRUE),
                         use_proxy(proxyAddress, proxyPort, auth = proxyAuth, username = proxyUsername, password = proxyPassword),
                         add_headers('Content-Type'='text/xmlmc', Authorization=paste('ESP-APIKEY ', apiKey, sep="")))
  } else {
    reportContent <- GET(paste(xmlmcURL, "dav","reports", reportID, URLencode(reportLink), sep="/"),
                         use_proxy(proxyAddress, proxyPort, auth = proxyAuth, username = proxyUsername, password = proxyPassword),
                         add_headers('Content-Type'='text/xmlmc', Authorization=paste('ESP-APIKEY ', apiKey, sep="")))
  }
  # Delete the report run instance  
  if (deleteReportInstance == TRUE) {
    reportDeleteHist <- invokeXmlmc("reporting", "reportRunDelete", paste("<runId>", runID, "</runId>"))
  }
  
  # vector into data frame object
  if (useXLSX == TRUE) {
    library(readxl)
    write.csv(read_excel(reportLinkLocal),paste(reportLinkLocal, "csv", sep="."), row.names = FALSE)
    output <-read.csv(paste(reportLinkLocal, "csv", sep="."), encoding = csvEncoding, stringsAsFactors=FALSE)
    if (deleteLocalXLSX == TRUE && file.exists(reportLinkLocal)) {
      file.remove(reportLinkLocal)
    }
    if (file.exists(paste(reportLinkLocal, "csv", sep="."))) {
      file.remove(paste(reportLinkLocal, "csv", sep="."))
    }
  } else {
    output <- content(reportContent, as = "parsed", type = "text/csv", encoding = csvEncoding)
  }
}
