######
# script for processing swmp data - all reserves, stations, data
# data retrieved from CDMO Nov. 21, 2014

######
# process stations, 15 minute step and daily aggs

# stations to process
path <- 'M:/wq_models/swmp2/raw'
stats <- unique(gsub('[0-9].*\\.csv$', '', dir(path)))

# setup parallel backend
cl<-makeCluster(8)
registerDoParallel(cl)
strt<-Sys.time()

stats <- stats[1:20]
# process all stations
foreach(stat = stats) %dopar% {
  
  sink('C:/Users/mbeck/Desktop/log.txt')
  cat(stat, which(stat == stats), 'of', length(stats), '\n')
  print(Sys.time()-strt)
  sink()
  
  # import raw
  tmp <- import_local(path, stat)
  
  # qaqc
  tmp <- qaqc(tmp, qaqc_keep = c(5, 4, 0))
  
  # treat nuts differently
  if(grepl('nut$', stat)){
    
    tmp <- rem_reps(tmp)
    
    # assign tmp to object, save, clear memory
    assign(stat, tmp)
    save(list = stat, file = paste0('M:/wq_models/SWMP2/proc1/', stat, '.RData'))
    save(list = stat, file = paste0('M:/wq_models/SWMP2/proc2/', stat, '.RData'))
    rm(list = stat)
    rm(list = tmp)
  
  # wq, met processing
  } else {
  
    # setstep to 15
    tmp <- setstep(tmp)
    
    # aggregate by days
    tmp_agg <- aggregate(tmp, by = 'days')
    
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
  
}
stopCluster(cl)
