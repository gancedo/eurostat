#' Read data from Eurostat database.
#' 
#' Download dataset from the Eurostat database (\url{ec.europa.eu/eurostat}). 
#' 
#' @param id A code name for the dataset of interest. 
#' See \code{\link{search_eurostat}} or details for how to get code.
#' @param time_format a string giving a type of the conversion of the time 
#' 	  column from the eurostat format. A "date" (default) convers to 
#'	  a \code{\link{Date}} with a first date of the period. 
#'	  A "date_last" convers to a \code{\link{Date}} with 
#'         a last date of the period. A "num" convers to a numeric and "raw" 
#'         does not do conversion. See \code{\link{eurotime2date}} and 
#'         \code{\link{eurotime2num}}.
#' @param select_time a character symbol for a time frequence or NULL (default).
#'    Most of the datasets have just one time frequency, in which case 
#'    the \code{NULL} is of. However, some of the datasets 
#'    includes multible time frequences. Use symbols to 
#'    select one of them with: Y = annual, S = semi-annual, Q = quarterly, M = monthly. 
#'    For all frequencies in same data.frame \code{time_format = "raw"} 
#'    should be used. 
#' @param cache a logical wheather to do caching. Default is \code{TRUE}.
#' @param update_cache a locigal wheater to update cache. Can be set also with
#' 	  options(eurostat_update = TRUE)
#' @param cache_dir a path to a cache directory. The directory have to exist.
#'    The \code{NULL} (default) uses and creates 
#'    'eurostat' directory in the temporary directory from 
#'    \code{\link{tempdir}}. Directory can also be set with 
#'    \code{option} eurostat_cache_dir.
#'  @param stringsAsFactors if \code{TRUE} (the default) variables are
#'         converted to factors in original Eurostat order. If \code{FALSE}
#'         they are returned as a character.
#' 
#' @export
#' @details Datasets are downloaded from the Eurostat bulk download facility 
#' \url{http://ec.europa.eu/eurostat/estat-navtree-portlet-prod/BulkDownloadListing}. 
#' The data is transformed into the molten row-column-value format (RCV).
#' 
#' By default datasets are cached. In a temporary directory by default or in 
#' a named directory if cache_dir or option eurostat_cache_dir is defined.
#' The cache can be emptied with \code{\link{clean_eurostat_cache}}.
#'
#' The \code{id}, a code, for the dataset can be searched with 
#' the \code{\link{search_eurostat}} or from the Eurostat database 
#' \url{http://ec.europa.eu/eurostat/data/database}. The Eurostat
#' database gives codes in the Data Navigation Tree after every dataset 
#' in parenthesis.
#'
#' @return a data.frame. One column for each dimension in the data and 
#'    the values column for numerical values. 
#'    The time column for a time dimension. 
#' @seealso \code{\link{search_eurostat}}, \code{\link{label_eurostat}}
#' @examples \dontrun{
#' k <- get_eurostat("nama_10_lp_ulc")
#' k <- get_eurostat("nama_10_lp_ulc", time_format = "num")
#' k <- get_eurostat("nama_10_lp_ulc", update_cache = TRUE)
#' dir.create("r_cache")
#' k <- get_eurostat("nama_10_lp_ulc", cache_dir = "r_cache")
#' options(eurostat_update = TRUE)
#' k <- get_eurostat("nama_10_lp_ulc")
#' options(eurostat_update = FALSE)
#' options(eurostat_cache_dir = "r_cache")
#' k <- get_eurostat("nama_10_lp_ulc")
#' k <- get_eurostat("nama_10_lp_ulc", cache = FALSE)
#' k <- get_eurostat("avia_gonc", select_time = "Y", cache = FALSE)
#' }
get_eurostat <- function(id, time_format = "date", select_time = NULL, 
                         cache = TRUE, update_cache = FALSE, cache_dir = NULL,
                         stringsAsFactors = default.stringsAsFactors()){

  if (cache){  
    # check option for update
    update_cache <- update_cache | getOption("eurostat_update", FALSE)
    
    # get cache directory
    if (is.null(cache_dir)){
      cache_dir <- getOption("eurostat_cache_dir", NULL)
      if (is.null(cache_dir)){
        cache_dir <- file.path(tempdir(), "eurostat")
        if (!file.exists(cache_dir)) dir.create(cache_dir)
      } 
    } else {
      if (!file.exists(cache_dir)) {
        stop("The folder ", cache_dir, " does not exist")
      }
    }
    
    # cache filename
    cache_file <- file.path(cache_dir, 
                            paste0(id, "_", time_format, 
                                   "_", select_time, "_", stringsAsFactors,
                                   ".rds"))
  }
  
  # if cache = FALSE or update or new: dowload else read from cache
  if (!cache || update_cache || !file.exists(cache_file)){
    y_raw <- get_eurostat_raw(id)
    y <- tidy_eurostat(y_raw, time_format, select_time, 
                       stringsAsFactors = stringsAsFactors)
  } else {
    y <- readRDS(cache_file)
    message("Table ", id, " read from cache file: ", path.expand(cache_file))   
  }
  
  # if update or new: save
  if (cache && (update_cache || !file.exists(cache_file))){
    saveRDS(y, file = cache_file, compress = FALSE)
    message("Table ", id, " cached at ", path.expand(cache_file))    
  }

  y    
}