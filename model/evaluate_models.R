# example usage of analyzeError
#   need input "xs" "col_sat" "target" "psat"
#   need also a list of predictors (as R functions); see example below   
#
# This script uses "analyzeError" to compare 5 methods of 
# predicting either undermatch or col_sat for dcps:
#
# -linear model with lots of features and linear model with gpa & honors
# -random forest with lots of features and random forest with gpa & honors
# -random forest with network

#usage:
# In R:
# source('dcps-augment-error.R')


library(glmnet)
library(randomForest)

# basic analytics table
ok.data = read.csv("/ebs/dssg-shared/data/dc_ok_data.csv")
n<-nrow(ok.data)

# national model response (RF)
load("/ebs/dssg-shared/RData/demo_score_rf_augment.RData")
demo.score = demo.score.rf.augment

# network 
source("/ebs/dssg-shared/github/dcps_process/dcps_network.r")
if (!exists("network")){
	network = dcps_network.load_data(large_flag = FALSE)
}
ok.data = ok.data[ok.data$id %in% colnames(network),]

source('/ebs/dssg-shared/github/dcps_model/error-analysis/analyze-error-boot.R')
#-----#
# Example Function Definition:
#  input: train.x, train.y, test.x 
#  output: test.y
#
#  -inputs NOT standardized, NON-zero mean
#  -train.x has column names


netRFFunBase <- function(train.x, train.y, test.x, options, tune=0.0001){ 
  print("Using network")
  flush.console()

  stopifnot(c('train.ids', 'test.ids', 'network', 'demo.score') %in% names(options))
  ntest = nrow(test.x)
  train.ids = options$train.ids
  test.ids = options$test.ids
  train.x$demo.score = demo.score[match(train.ids, demo.score$id),2]
  test.x$demo.score = demo.score[match(test.ids, demo.score$id),2] 
  network = options$network

  rf.obj = randomForest(x=train.x, y=train.y, ntree=500)
  yhat_rf = predict(rf.obj, test.x)  
 
  net_ixs = colnames(network) %in% test.ids
 
  sm_net = network[net_ixs, net_ixs] 
  diag(sm_net) = -apply(sm_net, 1, sum) 
  yhat = solve(diag(ntest) + 0.000005*sm_net)%*%yhat_rf
  return(as.vector(yhat))
}




# a TOTAL CLUDGE to get civis undermatch prediction
civisFun2<-function(train.x, train.y, test.x, options){
  print("Using civis undermatch prediction (target-col_demo_test).")
  flush.console()
  return(target.df$target[match(test.x$composite_psat, target.df$psat_rg)] - 
			test.x$col_demo_test)
}

linearAllFun <- function(train.x, train.y, test.x, options){
  print("Using linear with all features and Tikhon regularization.")
  flush.console()
  cvo<-cv.glmnet(as.matrix(train.x), train.y, nfolds=10, alpha=0)
  test.y<-predict(cvo, as.matrix(test.x), s="lambda.min")
}

linearLassoFun <- function(train.x, train.y, test.x, options){
  print("Using linear with all features and lasso selection.")
  flush.console()
  cvo<-cv.glmnet(as.matrix(train.x),train.y,nfolds=10)

  i_min<-match(cvo$lambda.min, cvo$lambda)
  beta_lin<-cvo$glmnet.fit$beta[,i_min]
  #refit
  relvars = which(abs(beta_lin) > 0.00001) #for fewer features only
  #print(names(train.x)[relvars])
  train = data.frame(train.y, train.x[,relvars]) 
  glmfit = glm(train.y~., data=train)
  test.y = predict(glmfit, data.frame(test.x[,relvars])) 
  return(test.y)
}

linearGPAHonFun<- function(train.x, train.y, test.x, options){
  print("Using linear with gpa+honors.")
  flush.console()
  relvars = c("gender", "sat", "honors", "total_gpa", "col_demo_test", "target")
  train<-data.frame(train.y, train.x[,relvars])
  glmfit = glm(train.y~., data=train)
  test.y = predict(glmfit, data.frame(test.x[,relvars]))
  return(test.y)
}

randForestFun <- function(train.x, train.y, test.x, options){
  print("Using RF with all features and lasso selection.")
  flush.console()
  cvo <- cv.glmnet(as.matrix(train.x), train.y, nfolds=10)
  i_min<-match(cvo$lambda.min, cvo$lambda)
  beta_lin<-cvo$glmnet.fit$beta[,i_min]
  #refit
  relvars = which(abs(beta_lin) > 0.00001) #for fewer features only
  rf.obj = randomForest(x=train.x[,relvars], y=train.y, ntree=500)
  test.y = predict(rf.obj, test.x[,relvars])   
}

randForestGPAHonFun <- function(train.x, train.y, test.x, options){
  print("Using RF with honors+total_gap.")
  flush.console()
  relvars = c("gender", "sat", "honors", "total_gpa", "col_demo_test", "target")
  rf.obj = randomForest(x=train.x[,relvars], y=train.y, ntree=500)
  test.y = predict(rf.obj, test.x[,relvars])   
}

rfrfFun <- function(train.x, train.y, test.x, options){
  print("Using RFRF")
  flush.console()
  
  stopifnot(c('train.ids', 'test.ids', 'demo.score') %in% names(options))
  train.ids = options$train.ids
  test.ids = options$test.ids
  train.x$demo.score = demo.score[match(train.ids, demo.score$id),2]
  test.x$demo.score = demo.score[match(test.ids, demo.score$id),2] 

  rf.obj = randomForest(x=train.x, y=train.y, ntree=500)
  test.y = predict(rf.obj, test.x)   
}


fun_ls = list( 
		linearAll=linearAllFun, 
		linearLasso=linearLassoFun, linearGPAHon=linearGPAHonFun, 
		rfLasso=randForestFun, rfGPAHon=randForestGPAHonFun, 
		netRF=netRFFun1, netRF2=netRFFun2, netRF3 = netRFFun3,
		rfrf=rfrfFun)

#- variables to keep in xs
remove_vars = c('id', 'weight_v1', 'weight_v2', 'att_flag', 
		'days', 'col_sat', 'resid', 
		'col_nodemo_test', colnames(ok.data)[grep('sat_', colnames(ok.data))], 
		colnames(ok.data)[grep('_grade', colnames(ok.data))])

var_ls = -which(colnames(ok.data) %in% remove_vars) 
xs <- ok.data[,var_ls]
xs[is.na(xs)] = 0


res <- analyzeError(xs, pred.undermatch=T, 
		col_sat=ok.data$col_sat, target=ok.data$target, 
		psat=ok.data$composite_psat, FUNS=fun_ls, 
		ids=ok.data$id, ntrial=30,
		options=list(demo.score=demo.score,
				network=network)) 

#write.table(res, file="/ebs/dssg-shared/github/dcps_model/error-analysis/augment-error.csv", col.names=T, row.names=T)

