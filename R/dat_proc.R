######
# script for processing swmp data - all reserves, stations, data
# data retrieved from CDMO Nov. 21, 2014

######
# process stations, 15 minute step and daily aggs

# stations to process
path <- 'M:/wq_models/swmp2/raw'
stats <- unique(gsub('[0-9][0-9][0-9][0-9]\\.csv$', '', dir(path)))

# setup parallel backend
cl<-makeCluster(8)
registerDoParallel(cl)
strt<-Sys.time()

# process all stations
foreach(stat = stats) %dopar% {
  
  sink('C:/Users/mbeck/Desktop/log.txt')
  cat(stat, which(stat == stats), 'of', length(stats), '\n')
  print(Sys.time()-strt)
  sink()
  
  # import raw
  tmp <- import_local(path, stat)
  
  # nut processing
  if(grepl('nut$', stat)){
    
    tmp <- rem_reps(tmp)
    
    tmp <- qaqc(tmp, qaqc_keep = c(0, 4, 5))
    
    tmp_agg <- tmp
    
  }
  
  # met processing
  if(grepl('met$', stat)){
  
    # setstep to 15
    tmp <- setstep(tmp)
    
    # keep passed, historical, corrected for all except totprcp
    # keep only passed for totprcp\
    totprcp <- subset(tmp, select = 'totprcp')
    totprcp <- qaqc(totprcp, qaqc_keep = 0)
    tmp <- qaqc(tmp, qaqc_keep = c(0))
    tmp$totprcp <- totprcp$totprcp
    
    # aggregate by days
    tmp_agg <- aggregate(tmp, by = 'days')
    
    # use daily max for cumprcp
    cumprcp <- aggregate(tmp, by = 'days', 
      FUN = function(x) max(x, na.rm = T), 
      params = 'cumprcp')
    cumprcp$cumprcp[cumprcp$cumprcp == -Inf] <- NA_real_
    tmp_agg$cumprcp <- cumprcp$cumprcp
  
  }
  
  # wq processing
  if(grepl('wq$', stat)){
    
    # setstep to 15
    tmp <- setstep(tmp)
    
    # keep passed, historical, corrected for all except totprcp
    tmp <- qaqc(tmp, qaqc_keep = c(0, 4, 5))
    
    # aggregate by days
    tmp_agg <- aggregate(tmp, by = 'days')
    
  }
    
  # assign tmp to object, save, clear memory
  assign(stat, tmp)
  save(list = stat, file = paste0('M:/wq_models/SWMP2/proc1/', stat, '.RData'))
  rm(list = stat)
  rm('tmp')
  
  # assign tmp_agg to object, save, clear memory
  assign(stat, tmp_agg)
  save(list = stat, file = paste0('M:/wq_models/SWMP2/proc2/', stat, '.RData'))
  rm(list = stat)
  rm('tmp_agg')

}
stopCluster(cl)
