#Define Instance Details
instanceName = "Instance Name Goes Here"
instanceZone = "eur"

# Define API Key
apiKey = "API key goes here"

# Define Report details
reportID = "report primary key (INT) goes here"
reportComment = "A comment to add to the report run"
deleteReportInstance <- TRUE

# Suspend for X amount of seconds between checks to see if the report is complete
suspendSeconds <- 10

# Import dependencies
library('RCurl')
library('XML')

# Build XMLMC URL
arrUrl <- c("https://", 
            instanceZone, 
            "api.hornbill.com/", 
            instanceName)

xmlmcURL <- paste(arrUrl, collapse="")
curl <- getCurlHandle(verbose=TRUE)

# invokeXmlmc - take params, fire off XMLMC call
invokeXmlmc = function(service, xmethod, params)
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
  invokeThisURL = paste(xmlmcURL, "/xmlmc/", service, "/?method=", xmethod, sep="")
  
  # Build Headers
  espKeyAuth = paste('ESP-APIKEY ', apiKey, sep="")
  requestHeaders = c('Content-Type'='text/xmlmc',
                     'Cache-control'='no-cache',
                     'Accept'='text/xml',
                     'Authorization'=espKeyAuth)
  
  responseFromURL = getURL(	url <- invokeThisURL,
                         curl = curl,
                         postfields=request,
                         httpheader=requestHeaders,
                         verbose=TRUE,
                         async=FALSE,
                         .opts = list(timeout = 3))
  return(responseFromURL)
}

### Kick off report run, get job ID
# Build XMLMC Request
arrXmlmcParams <- c(	"<params>",
                     "<reportId>", reportID, "</reportId>",
                     "<comment>", reportComment, "</comment>",
                     "</params>")

reportRunResponse <- invokeXmlmc("reporting", "reportRun", arrXmlmcParams)
xmltext  <- xmlTreeParse(reportRunResponse, asText <- TRUE,useInternalNodes=T)
runID <- unlist(xpathApply(xmltext,'//methodCallResult/params/runId',xmlValue))

reportSuccess <- FALSE
reportComplete <- FALSE

if(runID > 0){

  repeat {
    Sys.sleep(suspendSeconds)
    # Check status of report
    arrXmlmcRequest <- c(	"<params>",
                          "<runId>", runID, "</runId>",
                          "</params>")
    xml.request <- paste(arrXmlmcRequest)

    reportRunStatus <- invokeXmlmc("reporting", "reportRunGetStatus", xml.request)
    xmlRunStatus  <- xmlTreeParse(reportRunStatus, asText <- TRUE,useInternalNodes=T)
    runStatus <- unlist(xpathApply(xmlRunStatus,'//methodCallResult/params/reportRun/status',xmlValue))
    runComp <- grepl(runStatus, "completed")
   
    if ( runComp == TRUE ){
      reportCSVLink <- unlist(xpathApply(xmlRunStatus,'//methodCallResult/params/reportRun/csvLink',xmlValue))
      reportSuccess <- TRUE
      reportComplete <- TRUE
      break;
    } else if ( runStatus == "failed" ){	
      reportSuccess <- FALSE
      reportComplete <- TRUE
      break;
    }
  }
}

Sys.sleep(1)

if(reportSuccess == FALSE) {	
  stop()
}
# Now go get CSV 
# Build Invoke URL
getDavUrl = paste(xmlmcURL, "/dav/reports/", reportID, "/", reportCSVLink, sep="")
# GET request for report CSV content
espKeyAuth <- paste('ESP-APIKEY ', apiKey, sep="")
requestHeaders <- c('Content-Type'='text/xmlmc',
                    'Authorization'=espKeyAuth)
reportContent <-  getURI(	url <- getDavUrl, httpheader=requestHeaders, async=FALSE)

#Now go delete the report run instance  
if(deleteReportInstance == TRUE) {
  Sys.sleep(1)
  arrXmlmcRequest <- c(	"<params>",
                        "<runId>", runID, "</runId>",
                        "</params>")
  xml.request <- paste(arrXmlmcRequest)
  reportDeleteHist <- invokeXmlmc("reporting", "reportRunDelete", xml.request)
}

## CSV vector in to data frame object
output <- read.csv(textConnection(reportContent), header = TRUE)