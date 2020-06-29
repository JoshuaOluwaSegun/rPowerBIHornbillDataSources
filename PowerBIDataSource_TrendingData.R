#Define Instance Details
instanceName = "yourinstanceid"
apiKey = "yourapikey"

# Define Measure details
measureID = "71"

# Define Proxy Details
proxyAddress <- NULL # "127.0.0.1" - location of proxy
proxyPort <- NULL # 8080 - proxy port
proxyUsername = NULL # login details for proxy, if needed
proxyPassword = NULL # login details for proxy, if needed
proxyAuth = NULL # "any" - type of HTTP authentication to use. Should be one of the following: basic, digest, digest_ie, gssnegotiate, ntlm, any.

# Import dependencies
library('httr')
library('jsonlite')

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
