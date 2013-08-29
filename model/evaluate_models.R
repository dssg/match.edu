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
ok.data <- read.csv("../students.csv")
n <- nrow(ok.data)
ok.data$race <- factor(ok.data$race)


# national demographics model score
demo.score <- NULL

# network code  
#source("../network/network.r")
#if (!exists("network")){
#	network = network.load_data(large_flag = FALSE)
#}
#ok.data <- ok.data[ok.data$id %in% colnames(network),]
network <- NULL

source("analyze_error.R")


# We use "analyze-error-boot.R" to perform tests

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

  stopifnot(c('train.ids', 'test.ids', 'network') %in% names(options))
  ntest <- nrow(test.x)
  train.ids <- options$train.ids
  test.ids <- options$test.ids

  network <- options$network

  rf.obj <- randomForest(x=train.x, y=train.y, ntree=500)
  yhat_rf <- predict(rf.obj, test.x)  
 
  net_ixs <- colnames(network) %in% test.ids
 
  sm_net <- network[net_ixs, net_ixs] 
  diag(sm_net) <- -apply(sm_net, 1, sum) 
  yhat <- solve(diag(ntest) + 0.000005*sm_net)%*%yhat_rf
  return(as.vector(yhat))
}


linearAllFun <- function(train.x, train.y, test.x, options){
  print("Using linear with all features and Tikhon regularization.")
  flush.console()
  cvo <- cv.glmnet(as.matrix(train.x), train.y, nfolds=10, alpha=0)
  test.y <- predict(cvo, as.matrix(test.x), s="lambda.min")
}

linearLassoFun <- function(train.x, train.y, test.x, options){
  print("Using linear with all features and lasso selection.")
  flush.console()
  cvo <- cv.glmnet(as.matrix(train.x),train.y,nfolds=10)

  i_min <- match(cvo$lambda.min, cvo$lambda)
  beta_lin <- cvo$glmnet.fit$beta[,i_min]
  
  #refit
  relvars <- which(abs(beta_lin) > 0.00001) #for fewer features only
  #print(names(train.x)[relvars])
  train <- data.frame(train.y, train.x[,relvars]) 
  glmfit <- glm(train.y~., data=train)
  test.y <- predict(glmfit, data.frame(test.x[,relvars])) 
  return(test.y)
}

linearGPAHonFun<- function(train.x, train.y, test.x, options){
  print("Using linear with gpa+honors.")
  flush.console()
  relvars <- c("psat", "gpa", "target")
  train <- data.frame(train.y, train.x[,relvars])
  glmfit <- glm(train.y~., data=train)
  test.y <- predict(glmfit, data.frame(test.x[,relvars]))
  return(test.y)
}

randForestFun <- function(train.x, train.y, test.x, options){
  print("Using RF with all features and lasso selection.")
  flush.console()
  cvo <- cv.glmnet(as.matrix(train.x), train.y, nfolds=10)
  i_min <- match(cvo$lambda.min, cvo$lambda)
  beta_lin <- cvo$glmnet.fit$beta[,i_min]
  #refit
  relvars <- which(abs(beta_lin) > 0.00001) #for fewer features only
  rf.obj <- randomForest(x=train.x[,relvars], y=train.y, ntree=500)
  test.y <- predict(rf.obj, test.x[,relvars])   
}

randForestGPAHonFun <- function(train.x, train.y, test.x, options){
  print("Using RF with gpa, psat.")
  flush.console()
  relvars <- c("gpa", "psat", "target")
  rf.obj <- randomForest(x=train.x[,relvars], y=train.y, ntree=500)
  test.y <- predict(rf.obj, test.x[,relvars])   
}


fun_ls <- list( 
		linearAll=linearAllFun, 
		linearLasso=linearLassoFun, linearGPAHon=linearGPAHonFun, 
		rfLasso=randForestFun, rfGPAHon=randForestGPAHonFun)

#- variables to keep remove in xs
remove_vars <- c('sid', 'weight_v1', 'weight_v2', 'att_flag', 
		'days', 'col_sat', 'resid', 'name', 'college', 'race',
		colnames(ok.data)[grep('sat_', colnames(ok.data))], 
		colnames(ok.data)[grep('_grade', colnames(ok.data))])

var_ls <- -which(colnames(ok.data) %in% remove_vars) 
xs <- ok.data[,var_ls]
xs[is.na(xs)] <- 0


res <- analyzeError(xs, pred.undermatch=T, 
		col_sat=ok.data$col_sat, target=ok.data$target, 
		psat=ok.data$psat, FUNS=fun_ls, 
		ids=ok.data$id, ntrial=30,
		options=list(demo.score=demo.score,
				network=network)) 

write.table(res$df, file="../errors.csv",
            col.names=T, row.names=T)


# produce ROC plots

nfun <- length(fun_ls)
aucs <- rep(0, nfun)

for (ii in 1:nfun){
  cur_x = 2
  cur_y = 1
  ixs = 2:ncol(res$rocs[[ii]])
  aucs[ii] <- (res$rocs[[ii]][cur_x,ixs] - res$rocs[[ii]][cur_x,ixs-1]) %*%
                (res$rocs[[ii]][cur_y,ixs] + res$rocs[[ii]][cur_y,ixs-1])/2
}


theme_set(theme_grey(base_size=22))
p_obj <- ggplot() +
        geom_line(aes(x=res$rocs[[1]][cur_x,], y=res$rocs[[1]][cur_y,],
                        colour="red"), width=3) +
        geom_line(aes(x=res$rocs[[4]][cur_x,], y=res$rocs[[4]][cur_y,],
                        colour="blue"), width=3) +
        geom_abline(intercept=0, slope=1) +
        scale_x_continuous("False Positive Rate") +
        scale_y_continuous("True Positive Rate") +
        scale_colour_manual(name="AUC", values=c("red", "blue"),
                        labels=c(paste0("RF: ", aucs[1]),
                          paste0("lin: ", aucs[4]) )) +
        coord_fixed(ratio=1)

pdf("../viz/roc_test.pdf")
dev.off()
