######
# script for processing swmp data - all reserves, stations, data
# data retrieved from CDMO Jan. 29, 2015
# includes all data from 1995 through 2015

######
# process stations, 15 minute step and daily aggs

library(SWMPr)
library(doParallel)
library(foreach)

# stations to process
path <- 'ignore/raw'
stats <- unique(gsub('[0-9][0-9][0-9][0-9]\\.csv$', '', dir(path)))

# setup parallel backend
cl<-makeCluster(6)
registerDoParallel(cl)
strt<-Sys.time()

# process all stations
foreach(stat = stats, .packages = 'SWMPr') %dopar% {
  
  sink('log.txt')
  cat(stat, which(stat == stats), 'of', length(stats), '\n')
  print(Sys.time()-strt)
  sink()
  
  # import raw
  tmp <- import_local(path, stat)
  
  # nut processing
  if(grepl('nut$', stat)){
    
    # qaqc
    tmp <- qaqc(tmp, qaqc_keep = c(0, 4, 5))
    tmp <- rem_reps(tmp)
    
    tmp_agg <- tmp
    
  }
  
  # met processing
  if(grepl('met$', stat)){
  
    # setstep to 15
    tmp <- setstep(tmp)
    
    # qaqc, keep only passed totprcp
    totprcp <- subset(tmp, select = 'totprcp')
    totprcp <- qaqc(totprcp, qaqc_keep = 0)
    tmp <- qaqc(tmp, qaqc_keep = c(0, 4, 5))
    tmp$totprcp <- totprcp$totprcp
    
    # aggregate by days
    tmp_agg <- aggreswmp(tmp, by = 'days')
    
    # use daily max for cumprcp
    if('cumprcp' %in% names(tmp)){
      cumprcp <- aggreswmp(tmp, by = 'days', 
        FUN = function(x) max(x, na.rm = T), 
        params = 'cumprcp'
        )
      tmp_agg$cumprcp <- cumprcp$cumprcp
    }
  
  }
  
  # wq processing
  if(grepl('wq$', stat)){
    
    # setstep to 15
    tmp <- setstep(tmp)
    
    # keep passed
    tmp <- qaqc(tmp, qaqc_keep = c(0, 4, 5))
    
    # aggregate by days
    tmp_agg <- aggreswmp(tmp, by = 'days')
    
  }
    
  # assign tmp to object, save, clear memory
  assign(stat, tmp)
  save(list = stat, file = paste0('ignore/proc1/', stat, '.RData'))
  rm(list = stat)
  rm('tmp')
  
  # assign tmp_agg to object, save, clear memory
  assign(stat, tmp_agg)
  save(list = stat, file = paste0('ignore/proc2/', stat, '.RData'))
  rm(list = stat)
  rm('tmp_agg')

}
stopCluster(cl)
