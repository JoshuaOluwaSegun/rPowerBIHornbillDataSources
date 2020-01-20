# Define Instance Details
instanceName = "yourinstanceid"
apiKey = "yourapikey"

# Define Report details
reportID = "12"
reportComment = "A comment to add to the report run"
deleteReportInstance <- TRUE

csvEncoding <- "UTF-8" # For Unicode byte translation issues in Power BI, try using ISO-8859-1 as the value for csvEncoding

# Suspend for X amount of seconds between checks to see if the report is complete
suspendSeconds <- 1

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

# Kick off report run, get job ID
reportRunResponse <- invokeXmlmc("reporting", "reportRun", paste("<reportId>", reportID, "</reportId>","<comment>", reportComment, "</comment>"))
runOutput <- fromJSON(content(reportRunResponse, encoding="UTF-8"))
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
      runStatus <- fromJSON(content(reportRunStatus))$params$reportRun$status
      runComp <- grepl(runStatus, "completed")
      
      if (runComp == TRUE) {
        reportCSVLink <- fromJSON(content(reportRunStatus))$params$reportRun$csvLink
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
  reportContent <- GET(paste(xmlmcURL, "dav","reports", reportID, reportCSVLink, sep="/"),
                       add_headers('Content-Type'='text/xmlmc', Authorization=paste('ESP-APIKEY ', apiKey, sep="")))
  
  # Delete the report run instance  
  if (deleteReportInstance == TRUE) {
    reportDeleteHist <- invokeXmlmc("reporting", "reportRunDelete", paste("<runId>", runID, "</runId>"))
  }
  
  # CSV vector in to data frame object#
  output <- content(reportContent, as = "parsed", type = "text/csv", encoding = csvEncoding)
}
