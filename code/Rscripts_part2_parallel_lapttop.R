
setwd("C:/Users/janez/OneDrive - Rudolfovo – znanstveno in tehnološko središče Novo Mesto/Documents/UL FS/Projekti/2022/EuroCC II/Izobrazecanja UL/Parallel R")
dir()


needed.packages <- c("foreach", "doParallel","parallel","tictoc","pracma")
new.packages <- needed.packages[!(needed.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(foreach)
library(doParallel)
library(parallel)
library(tictoc)
library(pracma)


detectCores()


N=5000
K=100
set.seed(2021)

#************************************************
# for loop
#************************************************

sum_rand=rep(0,K-1);

tic()
for(i in c(1:K)){
  A=rand(N,N)
  sum_rand[i]=sum(A)
}


#************************************************
#  foreach do
#************************************************
set.seed(2021)
sum_rand=rep(0,K-1);
tic()
foreach (i = c(1:K)) %do% {
A=rand(N,N)
sum_rand[i]=sum(A)
  }
time_foreach_w=toc()

#************************************************
#  foreach dopar - no cluster
#************************************************
set.seed(2021)
sum_rand=rep(0,K-1);
tic()
print("for each-dopar (no cluster)")
foreach (i = c(1:K)) %dopar% {
  library(pracma)
  A= rand(N,N)
  sum_rand[i]=sum(A)
}
time_foreach_dopar=toc()



#************************************************
#  foreach dopar - with cluster
#************************************************
set.seed(2021)
clust <- makeCluster(12, type="PSOCK")  
registerDoParallel(clust,cores=12)  # use multicore, set to the number of our cores - needed for foerach dopar

sum_rand=rep(0,K-1);
tic()
print("for each-dopar (cluster allocated)")
foreach (i = c(1:K)) %dopar% {
  library(pracma)
  A=rand(N)
  sum_rand[i]=sum(A)
}
time_foreach_dopar_1=toc()
registerDoSEQ()

#************************************************
#  apply and parallel apply
#************************************************
mat_sum<-function(x){
  library(pracma)
  A=rand(x)
  return(sum(A))
}

tic()
time_lapply<-system.time({
  set.seed(2021)
  sum_rand_lapply=lapply(rep(N,K),FUN=mat_sum)
})
time_lapply_wall=toc()

tic()
time_sapply<-system.time({
  set.seed(2021)
  sum_rand_sapply=sapply(rep(N,K),FUN=mat_sum)
})
time_sapply_wall=toc()

# forking
tic()
time_mcLapply<-system.time({
  set.seed(2021)
#  sum_rand_mcLapply=mclapply(X=rep(N,K),FUN=mat_sum,mc.cores = 12)
  sum_rand_mcLapply=mclapply(X=rep(N,K),FUN=mat_sum,mc.cores = 1)
})
time_mcLapply_w=toc()


#forking with foreach dopar
#library(doMC) # should be included in doParallel, but is not
#time_foreach_dopar_fork<-system.time({registerDoMC(cores = 12) # make a fork cluster
#sum_rand=c()
#foreach (i=1:20, .combine = 'c') %dopar% {
#            A=rand(N,N)
#            sum_rand[i]=sum(A)}
#registerDoSEQ()
#}
#) # time the fork cluster



# socketing
tic()
time_parLapply<-system.time({
  clust <- makeCluster(12, type="PSOCK")  
  set.seed(2021)
  sum_rand_parLapply=parLapply(clust,rep(N,K),fun=mat_sum)
  stopCluster(clust)
})
time_parLapply_w=toc()

clust <- makeCluster(12, type="PSOCK")  
tic()
time_parSapply<-system.time({
  set.seed(2021)
  sum_rand_parSapply=parSapply(clust,rep(N,K),FUN=mat_sum)
})
time_parSapply_w=toc
stopCluster(clust)

times_apply<-rbind(time_lapply,time_sapply,time_parLapply,time_parSapply,time_mcLapply)
final_times=cbind(times_apply[,1:3],c(time_lapply_wall,time_sapply_wall,time_parLapply_w,time_parSapply_w(),time_mcLapply_w))
#times_apply<-rbind(time_lapply,time_sapply,time_parLapply,time_parSapply,time_mcLapply,time_foreach_dopar_fork) 
print(final_times)
