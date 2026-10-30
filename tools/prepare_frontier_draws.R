# Recreate draw identities locally; no estimates are calculated in R.
args <- commandArgs(trailingOnly=TRUE)
root <- normalizePath(if(length(args)) args[1] else getwd())
out <- file.path(root,'run/KSOI_stata_frontier_20261030')
setwd(out)
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
p<-read.csv(file.path(root,'run/KSOI_stata_migration_20261030/data/processed/enterprise_activity_technology_strategy_panel_2017_2024.csv'),fileEncoding='UTF-8-BOM')
cols<-c('ln_capital','ln_employees','ln_value_added');p<-p[complete.cases(p[,cols]),]
ids<-unique(p$firm_id);stopifnot(length(ids)==8857)
set.seed(20261007)
w<-replicate(1000,tabulate(sample.int(length(ids),length(ids),replace=TRUE),nbins=length(ids)))
colnames(w)<-paste0('w',1:1000)
write.csv(data.frame(firm_id=ids,w,check.names=FALSE),'validation/joint_shared_weights.csv',row.names=FALSE)
d<-read.csv(file.path(root,'run/KSOI_stata_global_20261030/data/processed/enterprise_activity_bogetoft_t3_stack.csv'),fileEncoding='UTF-8-BOM')
d<-d[d$family=='ai',];d<-d[order(d$group,d$event_id,d$horizon),]
groups<-unique(d$group);events<-lapply(groups,function(g)d$event_id[d$group==g&d$horizon==0])
set.seed(20261008)
eq<-lapply(events,function(e)matrix(NA_integer_,94,1000))
for(k in 1:1000)for(g in 1:3)eq[[g]][,k]<-sample.int(length(events[[g]]),94,replace=TRUE)
for(g in 1:3){colnames(eq[[g]])<-paste0('r',1:1000);write.csv(eq[[g]],paste0('validation/equal_shared_indices_',g,'.csv'),row.names=FALSE);write.csv(data.frame(event_id=events[[g]]),paste0('validation/equal_events_',g,'.csv'),row.names=FALSE)}

cat("FRONTIER_DRAWS_READY\n")
