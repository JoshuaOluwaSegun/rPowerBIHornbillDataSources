#Define Instance Details
instanceName = "Instance Name Goes Here"
instanceZone = "eur"

# Define API Key
apiKey = "API key goes here"

# Define Measure details
measureID = "the primary key (INT) of the measure you wish to return trending data from"

# Import dependencies
library('RCurl')
library('jsonlite')

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
  # Implode request array in to string
  request = paste(arrRequest, collapse="")
  
  # Build Invoke URL
  invokeURL = paste(url, "/xmlmc/", service, "/?method=", xmethod, sep="")
  
  # Build Headers
  espKeyAuth = paste('ESP-APIKEY ', key, sep="")
  requestHeaders = c('Content-Type'='text/xmlmc',
                     'Cache-control'='no-cache',
                     'Accept'='text/json',
                     'Authorization'=espKeyAuth)
  # Run GET request
  data =  getURL(	url = invokeURL,
                  postfields=request,
                  httpheader=requestHeaders,
                  verbose=TRUE)
  return(data)
}

### Fire off API call to get measure data
# Build XMLMC Request
arrXmlmcParams = c(	"<params>",
                    "<measureId>", measureID, "</measureId>",
                    "<returnMeasureValue>true</returnMeasureValue>",
                    "<returnMeasureTrendData>true</returnMeasureTrendData>",
                    "</params>")
# Invoke XMLMC Request
measureResponse = invokeXmlmc(xmlmcURL, apiKey, "reporting", "measureGetInfo", arrXmlmcParams)

# Build table pointers from JSON string returned
table = fromJSON(measureResponse)

# Return trendValue table object, with flattened values within, 
# to ensure dateRange.from and dateRange.to are properly represented in the table output
dataframe <- flatten(table$params$trendValue)