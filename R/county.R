if (base::getRversion() >= "2.15.1") {
  utils::globalVariables(c("df_county_unemployment", "county.regions"))
}

#' Get county level unemployment data
#' 
#' Data is scraped from the US Bureau of Labor Statistics (BSL) webpage. This function is 
#' intended for internal use only - please use ?df_county_unemployment instead.
#' @param year The year of the data you want. Must bet between 1990 and 2013
#' @importFrom stringr str_trim
get_county_unemployment_df = function(year)
{
  stopifnot(is.numeric(year))
  stopifnot(year >= 1990 && year <= 2013) # at the time of this writing, the only dates available
  
  # BLS uses final 2 years for string - URL is formulaic
  year_string = as.character(year)
  year_string = substr(year_string, 3, 4)
  url = paste0(
    "http://www.bls.gov/lau/laucnty",
    year_string,
    ".txt")
  
  # these magic numbers come from
  # http://stackoverflow.com/questions/27758176/creating-a-data-frame-with-all-usa-county-unemployment-data/27758599#27758599
  df = read.fwf(url, 
                widths=diff(c(0,16,21,29,80,86,100,115,125,132)+1), 
                skip=6,
                colClasses="character")
  df = df[1:(nrow(df)-2),] # last two lines are whitespace plus date
  
  #choroplethr needs column named "region", which is numeric county FIPS
  df$V2 = str_trim(df$V2) # state fips
  df$V3 = str_trim(df$V3) # county fips
  df$region=paste0(df$V2,df$V3)
  df$region=as.numeric(df$region)
  
  #choroplethr needs one column named "value"
  df$value=str_trim(df$V9)
  df$value=as.numeric(df$value)
  
  df=df[,c("region", "value")]
  
  # now remove unmappable regions
  data(county.regions, package="choroplethrMaps", envir=environment())
  df = df[df$region %in% county.regions$region,]  
}

#' Build the data object df_county_unemployment
#' 
#' This function is intended for internal use only - please use ?df_county_unemployment 
#' instead.
build_county_df = function()
{
  data(county.regions, package="choroplethrMaps", envir=environment())
  df_county_unemployment = data.frame(region=county.regions$region)
  for (year in 1990:2013)
  {
    df = get_county_unemployment_df(year)
    colnames(df) = c("region", eval(year))
    df_county_unemployment = merge(df_county_unemployment, df, all=TRUE)
  }
  df_county_unemployment
}
