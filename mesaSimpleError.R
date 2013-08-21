

load("/shared/RData/mesa11.RData")
dataframe$idno = dataframe$SIS_NUMBER
dataframe$SIS_NUMBER = NULL

nsc=read.csv("/shared/data/NSC_CBcol_hs_MPSethn.bsv", sep="|")
strive = read.csv("/shared/dssg-college/tiny_data/strive.csv")
strive$ix=NULL


stud = merge(nsc, dataframe, by="idno", all.x=T, all.y=F)

# some basic summary statistics
#> sum(!is.na(stud$ACT_Composite) & is.na(stud$PSAT_Total))
#[1] 2533

# FILL IN STRIVE
stud = merge(stud, strive, by.x="PSAT_Total", by.y="psat_rg", all.x=T)

vars_keep = c("strive","col_sat_final","total_gpa","total_honors",
              "hs_income_lo","minority","ethnicity_code","gender",
 	      "PSAT_Total","AIMS_8","NOT_EXCUSED")

ok.stud = stud[,vars_keep]


ok.stud2 = ok.stud[!is.na(ok.stud$col_sat_final),]
ok.stud2 = ok.stud2[!is.na(ok.stud2$strive),]
ok.stud2[ok.stud2$gender=="", "gender"] = "M"

#ok.stud2$gender[ok.stud2$gender=="M"]=1
#ok.stud2$gender[ok.stud2$gender=="F"]=0
ok.stud2$ethnicity_code = factor(ok.stud2$ethnicity_code)


source("/shared/dssg-college/dcps_model/error-analysis/analyze-error-boot.R")

library(randomForest)

remove_vars=c("col_sat_final")
var_ls = -which(names(ok.stud2) %in% remove_vars)
xs = ok.stud2[,var_ls]

xs[is.na(xs)]=0


rfFun<-function(train.x,train.y,test.x,options){
	print("Using RF")
	flush.console()
	rf.obj = randomForest(x=train.x,y=train.y,ntree=500)
	test.y=predict(rf.obj,test.x)
	return(test.y)
}

linFun <- function(train.x,train.y,test.x,options){
	print("Using Linear")
	flush.console()
	train.x$ethnicity_code = NULL
	test.x$ethnicity_code=NULL
	tmpdf = train.x
	tmpdf$y = train.y
	lin.obj = glm(y~., data=tmpdf)
	test.y=predict(lin.obj, test.x)
	return(test.y)
}

fun_ls = list(rf=rfFun, linear=linFun)

res <- analyzeError(xs, pred.opgap=T, ntest=600, ntrial=20,
           col_sat_final=ok.stud2$col_sat_final, 
	   strive=ok.stud2$strive, psat=ok.stud2$PSAT_Total, 
 	   FUNS=fun_ls)

nfun = length(fun_ls)
aucs = rep(0, nfun)

for (ii in 1:nfun){
  cur_x = 2
  cur_y = 1
  ixs = 2:ncol(res$rocs[[ii]])
  aucs[ii] = (res$rocs[[ii]][cur_x,ixs] - res$rocs[[ii]][cur_x,ixs-1]) %*% 
		(res$rocs[[ii]][cur_y,ixs] + res$rocs[[ii]][cur_y,ixs-1])/2
}

theme_set(theme_grey(base_size=22))
p_obj = ggplot() +
	geom_line(aes(x=res$rocs[[1]][cur_x,], y=res$rocs[[1]][cur_y,], 
			colour="red"), width=3) +
        geom_line(aes(x=res$rocs[[2]][cur_x,], y=res$rocs[[2]][cur_y,], 
			colour="blue"), width=3) +
        geom_abline(intercept=0, slope=1) +
        scale_x_continuous("False Positive Rate") +
	scale_y_continuous("True Positive Rate") +
	scale_colour_manual(name="AUC", values=c("red", "blue"),
			labels=c("RF: 0.835", 
			  "lin: 0.8352")) +
	coord_fixed(ratio=1)

pdf("/shared/dssg-college/viz/roc_test.pdf")
print(p_obj)
dev.off()			
