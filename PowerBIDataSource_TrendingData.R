#Define Instance Details
instanceName = "yourinstanceid"
apiKey = "yourapikey"

# Define Measure details
measureID = "71"

# Import dependencies
library('httr')
library('jsonlite')

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

# Fire off API call to get measure data
measureResponse = invokeXmlmc("reporting", "measureGetInfo", paste("<measureId>", measureID, "</measureId>",
                                                                   "<returnMeasureValue>true</returnMeasureValue>",
                                                                   "<returnMeasureTrendData>true</returnMeasureTrendData>"))
runOutput <- fromJSON(content(measureResponse, encoding="UTF-8"))
runStatus <- runOutput$"@status"

if (runStatus == FALSE || runStatus == "fail") {
  stop(runOutput$state$error)
} else {
  # Return trendValue table object, with flattened values within, to ensure dateRange.from and dateRange.to are properly represented in the table output
  dataframe <- flatten(runOutput$params$trendValue)
}
