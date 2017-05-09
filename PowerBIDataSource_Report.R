#Define Instance Details
instanceName = "Instance Name Goes Here"
instanceZone = "eur"

# Define API Key
apiKey = "API key goes here"

# Define Report details
reportID = "report primary key (INT) goes here"
reportComment = "A comment to add to the report run"

# Import dependencies
library('RCurl')
library('XML')

# Build XMLMC URL
arrUrl = c("https://", 
           instanceZone, 
           "api.hornbill.com/", 
           instanceName)

xmlmcURL = paste(arrUrl, collapse="")

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
  
  data =  getURL(	url = invokeURL,
                  postfields=request,
                  httpheader=requestHeaders,
                  verbose=TRUE)
  
  return(data)
}

# suspendExec - wait for a given number of seconds
suspendExec = function(susSec)
{
  p1 = proc.time()
  Sys.sleep(susSec)
  proc.time() - p1 # The cpu usage should be negligible
}

### Kick off report run, get job ID

# Build XMLMC Request
arrXmlmcParams = c(	"<params>",
                    "<reportId>", reportID, "</reportId>",
                    "<comment>", reportComment, "</comment>",
                    "</params>")

reportRunResponse = invokeXmlmc(xmlmcURL, apiKey, "reporting", "reportRun", arrXmlmcParams)
xmltext  = xmlTreeParse(reportRunResponse, asText = TRUE,useInternalNodes=T)
runID = unlist(xpathApply(xmltext,'//methodCallResult/params/runId',xmlValue))

reportSuccess = FALSE
if(runID > 0){
  reportComplete = FALSE
  while(reportComplete == FALSE){
    # Wait a second...
    suspendExec(1)
    
    # Check status of report
    arrXmlmcRequest = c(	"<params>",
                         "<runId>", runID, "</runId>",
                         "</params>")
    xml.request = paste(arrXmlmcRequest , collapse="")
    
    reportRunStatus = invokeXmlmc(xmlmcURL, apiKey, "reporting", "reportRunGetStatus", xml.request)
    xmlRunStatus  = xmlTreeParse(reportRunStatus, asText = TRUE,useInternalNodes=T)
    runStatus = unlist(xpathApply(xmlRunStatus,'//methodCallResult/params/reportRun/status',xmlValue))
    if ( runStatus == "completed" ){
      reportCSVLink = unlist(xpathApply(xmlRunStatus,'//methodCallResult/params/reportRun/csvLink',xmlValue))
      reportSuccess = TRUE
      reportComplete = TRUE
    } else if ( runStatus == "failed" ){	
      reportSuccess = FALSE
      reportComplete = TRUE
    }
  }
}

if(reportSuccess == TRUE) {	
  # Now go get CSV 
  # Build Invoke URL
  invokeURL = paste(xmlmcURL, "/dav/reports/", reportID, "/", reportCSVLink, sep="")
  
  # Build Headers
  espKeyAuth = paste('ESP-APIKEY ', apiKey, sep="")
  requestHeaders = c('Content-Type'='text/xmlmc',
                     'Authorization'=espKeyAuth)

  # GET request for report CSV content
  reportContent =  getURL(	url = invokeURL, httpheader=requestHeaders)
  ## CSV vector in to data frame object
  dataframe <- read.csv(textConnection(reportContent))
}

