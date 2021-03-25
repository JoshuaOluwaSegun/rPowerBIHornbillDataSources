# [Power BI](https://powerbi.microsoft.com/) [R Script](https://cran.r-project.org/) Data Sources for Hornbill Reporting And Trend Engine

## Overview

These example scripts have been provided to enable Power BI administrators to build reports and dashboards using Hornbill Reporting and Advanced Analytics Trend Engine data as their data source(s).

## Dependencies

The scripts have been written in [R](https://cran.r-project.org/), and were developed using the following:

- [Power BI Desktop build 2.75.5649.861 64-bit (November 2019)](https://powerbi.microsoft.com/)
- [Microsoft R Open 3.5.3](https://mran.microsoft.com/open/)

The following packages are required dependencies, and can be installed via the CRAN repositories:

- [httr](https://cran.r-project.org/web/packages/httr/)
- [data.table](https://cran.r-project.org/web/packages/data.table/) - Just for the TrendingData script
- [readxl](https://cran.r-project.org/web/packages/readxl/) - Just for the Report and HistoricReport scripts, when useXLSX is set to TRUE

## Configuration used in all scripts

Each script requires the following variables to be set (all case-sensitive):

- instanceName - This is the name of the instance to connect to. So for instance, if you use https://live.hornbill.com/**yourinstancename** to connect to Hornbill, then **yourinstancename** is the part of the URL that should be used in this variable. Note, this is case sensitive.
- apiKey - This is an API key generated against a user account on the Hornbill Administration Console, where the user account has sufficient access to run reports and access trending data.

Each script an be configured to use a proxy for access to your Hornbill instance. Set all of the below to NULL to not use a proxy. If using a proxy, the proxyAddress and proxyPort are the minimum required to be provided.

- proxyAddress - The hostname or IP address of the proxy
- proxyPort - The proxy port
- proxyUsername - The username to access the proxy, if required
- proxyPassword - The password for the above account
- proxyAuth - The type of HTTP authentication to use. Should be one of the following: basic, digest, digest_ie, gssnegotiate, ntlm, any.

## Scripts

### PowerBIDataSource_Report.R

This script will:

- Run a pre-defined report on the Hornbill instance;
- Wait for the report to complete;
- Retrieve the report CSV data and present back as an R data frame called output, which can then be retrieved and reported on by PowerBI.

Script Variables:

- reportID: The ID (Primary Key, INT) of the  report to be run;
- reportComment: A comment to write against the report run job.
- deleteReportInstance: a boolean value to determine if, once the report is run on Hornbill and the data has been pulled in to PowerBI, whether the historic report run instance should be removed from your Hornbill report.
- useXLSX: FALSE = the script will use the CSV output from your report; TRUE = the script will use the XLSX output from your report. NOTE: XLSX output will need to be enabled within the Output Formats > Additional Data Formats section of your report in Hornbill;
- deleteLocalXLSX: FALSE = the downloaded XLSX file will remain on disk once the extract is complete; TRUE = the local XLSX file is deleted upon completion
- xlsxLocalFolder: The folder where to store the downloaded XLSX file. Can be left blank, or specify a local folder to store the downloaded XLSX file into. Requires the postfixed / or \ on the path, depending on your OS
- csvEncoding: The character set to be used when decoding the CSV report data, or when converting the XLSX data into a Power BI friendly codepage. This will usually be "UTF-8", but if you have issues returning data with certain characters (the Windows E2 80* characters are the usual culprits) then choose a different character set to use, ie: "ISO-8859-1". Look out for an error that looks like this for character set issues: "Details: "Unable to translate bytes [E2][80] at index 1077 from specified code page to Unicode"".
- suspendSeconds: The number of seconds the script should wait between checks to see if the report is complete. NOTE : there is a defect/incompatibility between Power BI and the RCurl library that we are using to make the HTTP requests to Hornbill, where if more than 4 or 5 calls with getURL are made within the same script then getURL hangs until Power BI releases it. Increasing the number of seconds between checks reduces the required number of calls to your Hornbill instance, and will fix data source hanging issues.

### PowerBIDataSource_HistoricReport.R

This script will:

- Retrieve a historic report CSV from your Hornbill instance;
- Present the report data back as an R data frame called dataframe, which can then be retrieved and reported on by PowerBI.

Script Variables:

- reportID: The ID (Primary Key, INT) of the  report to be run;
- runId: The Run ID (INT) of a historic run of the above report ID.
- useXLSX: FALSE = the script will use the CSV output from your report; TRUE = the script will use the XLSX output from your report. NOTE: XLSX output will need to be enabled within the Output Formats > Additional Data Formats section of your report in Hornbill;
- deleteLocalXLSX: FALSE = the downloaded XLSX file will remain on disk once the extract is complete; TRUE = the local XLSX file is deleted upon completion
- xlsxLocalFolder: The folder where to store the downloaded XLSX file. Can be left blank, or specify a local folder to store the downloaded XLSX file into. Requires the postfixed / or \ on the path, depending on your OS
- csvEncoding: The character set to be used when decoding the CSV report data, or when converting the XLSX data into a Power BI friendly codepage. This will usually be "UTF-8", but if you have issues returning data with certain characters (the Windows E2 80* characters are the usual culprits) then choose a different character set to use, ie: "ISO-8859-1". Look out for an error that looks like this for character set issues: "Details: "Unable to translate bytes [E2][80] at index 1077 from specified code page to Unicode"".

### PowerBIDataSource_TrendingData.R

This script will:

- Run the reporting::measureGetInfo API  against your Hornbill instance, with a given measure ID (Primary Key, INT);
- Build a table containing all Trend Value entries for the selected measure;
- Present the trend data back as an R data frame called dataframe, which can then be retrieved and reported on by PowerBI.

Script Variable:

- measureID: The ID (Primary Key, INT) of the measure to return trend data from.

Outputs:
As the response parameters from the Trending Engine is fixed (unlike the Reporting engine, which has user-specified column outputs), the output for this report will always consist  of the following columns:

- value - the value of the trend sample;
- sampleId - the ID of the sample;
- sampleTime - the time & date that the sample was taken;
- dateRange.from - the start date of the sample snapshot;
- dateRange.to - the end date of the sample snapshot;

## Power BI Notes

These scripts have been designed to be used as data sources only, and not as the source of R script visuals within Power BI. Which is not to say they couldn't be used in your R script visuals, with a little extra code :)
