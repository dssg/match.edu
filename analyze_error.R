#=========#
#
# use random sampling to evaluate model errors on 6 metrics:
# * overall mse
# * mse per quartile of psat scorer
# * kendall tau between true and estimated ranking
# * recovery of high under-matcher
# * recovery of high-achieving under-matcher 
# * ROC curve for high under-match recovery
#
# how to use:
#  -FUNS is list of functions, each function takes 4 input
#	train.x, train.y, test.x, options and output test.y
#  -fun can predict either undermatch (pred.undermatch = T): target-col_sat
#	or predict col_sat
#  -NOTE. all features of "xs" will be used in the prediction
#       garbage features must be filtered a priori
#
#
# simple example: see "evaluate_example.R"
# example: see "evaluate_models.R"

analyzeError<-function(xs, col_sat, target, pred.undermatch=F, 
		       psat, FUNS, ntrial=120, ntest=120, ids=NULL, options=NULL) {

print(paste0("Analyze error: predict under-match --", pred.undermatch))
print(sprintf("total: %f   num test: %f",nrow(xs), ntest))

n=nrow(xs); p=ncol(xs);
nfun<-length(FUNS);

#build response
if (pred.undermatch){
  ys <- target-col_sat_final
} else {
  ys <- col_sat_final
}

#sanity check
stopifnot(length(psat) == n)
stopifnot(nfun > 0)

#build psat quantile and set up error beakers
ntiles= 4;
psat_xtiles = quantile(psat, probs=c(0,0.25,0.5,0.75,1))

xtile_err=list()
for (jj in 1:ntrial){
  xtile_err[[jj]] = matrix(0, nrow=nfun, ncol=ntiles)
}
total_err = matrix(0, nrow=ntrial, ncol=nfun)
kendall = matrix(0, nrow=ntrial, ncol=nfun)
#among top 20% most undermatch, recov accuracy
all_recov = matrix(0, nrow=ntrial, ncol=nfun) 
#top 50% recovery among good studs (top 25% psat scorer)
good_recov = matrix(0, nrow=ntrial, ncol=nfun)
#top 50% recovery among moderate studs (top 50% psat scorer) 
ok_recov = matrix(0, nrow=ntrial, ncol=nfun)


#initialize values for roc curves
rocs = list()
for (ii in 1:nfun){
  rocs[[ii]] = matrix(0, nrow=2, ncol=ntest)
}


#permute indices for random folds
ixt = 1
while (TRUE) {
  if (ixt > ntrial){
    break
  } 
  print(sprintf("--Trial %f/%f--", ixt,ntrial))
  perm_ixs <- sample(n,n)
 
  test_ixs = perm_ixs[1:ntest];
  train_ixs = !(1:n %in% test_ixs)

  test.y = ys[test_ixs]
  train.y = ys[train_ixs] 
  test.x = xs[test_ixs,] 
  train.x = xs[train_ixs,]

  #to map training sample to a student
  #only used if we have extra demographic info
  if (!is.null(ids)){
    options$train.ids=ids[train_ixs]
    options$test.ids=ids[test_ixs]
  } 

 
  for (ii in 1:nfun) {
    fun<-FUNS[[ii]]
    
    hat_ys = fun(train.x, train.y, test.x, options=options)
    
    total_err[ixt, ii] = ((1/ntest)*sum((hat_ys-test.y)^2))/var(test.y)
    # error per student quantile 
    for (j in 1:ntiles) { 
      tile_ixs = which(psat[test_ixs] < psat_xtiles[j+1] & 
			psat[test_ixs] > psat_xtiles[j])

      xtile_err[[ixt]][ii,j] = xtile_err[[ixt]][ii,j] + 
 	((1/length(tile_ixs))*sum((hat_ys[tile_ixs]-
	test.y[tile_ixs])^2))/var(test.y) 
    }

    gold.undermatch = (target-col_sat)[test_ixs]
    if (pred.undermatch){
      new.undermatch = hat_ys 
    } else {
      new.undermatch = target[test_ixs] - hat_ys
    }
    true_order = order(gold.undermatch, decreasing=TRUE)
    new_order = order( new.undermatch, decreasing=TRUE )

    #kendall tau
    # num(concordant pairs) - #(discordant pairs) 
    # normalized to be in [-1,1]
    kendall[ixt,ii] = cor(gold.undermatch, new.undermatch, method="kendall") 

    nrecov = floor(0.2*ntest)  
    all_recov[ixt,ii] = length(which(new_order[1:nrecov] %in% true_order[1:nrecov]))

    #computing the ROC curves
    true_pos_indicator = new_order %in% true_order[1:nrecov]
    false_pos_indicator = !true_pos_indicator
    tp_rate = cumsum(true_pos_indicator)
    fp_rate = cumsum(false_pos_indicator)         
    rocs[[ii]][1,] = rocs[[ii]][1,]+tp_rate/(0.2*ntest)
    rocs[[ii]][2,] = rocs[[ii]][2,]+fp_rate/(0.8*ntest) 

    #nrecov.large = sum(gold.undermatch > 50)
    nrecov.large = floor(0.5*ntest)
    #nrecov.large2 = sum(new.undermatch > 50)
    nrecov.large2 = floor(0.5*ntest)
    top_tile_ixs = which(psat[test_ixs] > psat_xtiles[ntiles-1] & 
			psat[test_ixs] < psat_xtiles[ntiles])
    good_poor_kids = intersect(true_order[1:nrecov.large], top_tile_ixs)

    #make sure smart undermatchers exist
    stopifnot(length(good_poor_kids) > 0)

    good_recov[ixt,ii] = length(intersect(good_poor_kids, 
		new_order[1:nrecov.large2]))/length(good_poor_kids)

    top2_tile_ixs = which(psat[test_ixs] > psat_xtiles[ntiles-2] & 
			  psat[test_ixs] < psat_xtiles[ntiles])
    ok_poor_kids = intersect(true_order[1:nrecov.large], top2_tile_ixs)
    ok_recov[ixt,ii] = length(intersect(ok_poor_kids, 
			new_order[1:nrecov.large2]))/length(ok_poor_kids)

  }
  print(sprintf('Good kid num:%f   Mid undermatch:%f', 
		length(good_poor_kids), gold.undermatch[true_order[nrecov.large]]))
 
  
  ixt = ixt+1
}

# Average out number of trials
all_recov = all_recov/nrecov;
 
for (meas in c("kendall", "all_recov", "total_err", "good_recov", "ok_recov")){
  eval(parse(text=paste0(meas, ".mean <- apply(", meas, ", 2, mean)")))
  eval(parse(text=paste0(meas, ".sd <- apply(", meas, ", 2, sd)")))
  eval(parse(text=meas))
}

xtile_err.mean = matrix(0, nrow=ntiles, ncol=nfun)
xtile_err.sd = matrix(0, nrow=ntiles, ncol=nfun)
for (ii in 1:ntiles){
  for (jj in 1:nfun){
    vals<-sapply(xtile_err, function(x) {x[jj,ii]})
    xtile_err.mean[ii,jj]<-mean(vals)
    xtile_err.sd[ii,jj]<-sd(vals)
  }
} 

for (ii in 1:nfun){
  rocs[[ii]] = rocs[[ii]]/ntrial
}

#xtile_err is matrix (ntiles--by--nfun)
return(list(df=data.frame(total_err.mean=total_err.mean, total_err.sd=total_err.sd,
 		xtile_err.mean=t(xtile_err.mean), xtile_err.sd=t(xtile_err.sd),
		kendall.mean=kendall.mean, kendall.sd=kendall.sd,
		all_recov.mean=all_recov.mean, all_recov.sd=all_recov.sd,
		good_recov.mean=good_recov.mean, good_recov.sd=good_recov.sd,
 		ok_recov.mean=ok_recov.mean, ok_recov.sd=ok_recov.sd,
		row.names=names(FUNS)),
       rocs=rocs))

}



