#============================================#
# DCPS: The Augmented Model
#============================================#
# This does feature selection to augment the existing Civis analysis: predict student undermatch at the end of 11th grade fall (when students take the PSAT)
# Written by Nihar Shah
# Acknowledgements: Min Xu's error analysis code (original source: dcps-error-analysis.R)
# This is standalone code and runs without any dependencies (other than R libraries)

setwd("/ebs/dssg-shared/RData")
source("dcps_build_table.R")
library(glmnet)
data = dcps_build_table.load_data(10, FALSE)

# This code does step-down regression based on p-values
# "alpha" refers to the p-value cutoff (0.05)
stepwise_p = function(v, i = 1, w = 1, suppress = FALSE, alpha = 0.05) {
	if(length(w) == 1) { w = rep(1, dim(data)[1]) }
	if(length(i) == 1) { i = seq(1:dim(data)[1]) }
	flag = TRUE
	while(flag) {
		f = as.formula(paste(
			paste("col_sat_final[i] ~ col_demo_test[i] + ", 
			paste(v, collapse = "[i] + "), collapse = " "), 
			"[i]", sep = ""))

		model = summary(lm(f, data = data, weights = w[i]))
		pvalues = model$coef[3:(length(v) + 2),4]
		index = which(pvalues == max(pvalues))
		if(pvalues[index] < alpha) { flag = FALSE }
		if(pvalues[index] >= alpha) {
			if(!suppress) { 
				print(paste("This variable is being eliminated: ", 
					v[index], " (p-value: ", 
					round(pvalues[index], 4), ")", sep = ""), 
				    quote = FALSE) }
			v = v[-index]
		}
	}
	if(!suppress) { print(model) }
		return(model)
	}
	
# This code does step-down regression based on adjusted R^2
# The cutoff indicates whether we should eliminate a variable as long as the R^2 drop is lower than this cutoff
stepwise_r = function(v, i = 1, w = 1, suppress = FALSE, cutoff = 0) {
	if(length(w) == 1) { w = rep(1, dim(data)[1]) }
	if(length(i) == 1) { i = seq(1:dim(data)[1]) }
	flag = TRUE
	while(flag) {
		f = as.formula(paste(paste("col_sat_final[i] ~ col_demo_test[i] + ", paste(v, collapse = "[i] + "), collapse = " "), "[i]", sep = ""))
		model = summary(lm(f, data = data, weights = w[i]))
		adjr = model$adj.r.squared
		counter = rep(NA, length(v))
		for(j in 1:length(v)) {
			f = as.formula(paste(paste("col_sat_final[i] ~ col_demo_test[i] + ", paste(v[-j], collapse = "[i] + "), collapse = " "), "[i]", sep = ""))
			counter[j] = adjr - cutoff - summary(lm(f, data = data, weights = w[i]))$adj.r.squared
			}
		flag = ifelse(as.logical(prod(counter > 0)), FALSE, TRUE)
		if(flag) {
			index = which(counter == min(counter))
			if(!suppress) { print(paste("This variable is being eliminated: ", v[index], " (Adj R^2: ", round(adjr, 4), ")", sep = ""), quote = FALSE) }
			v = v[-index]
		}
	}
	if(!suppress) { print(model) }
	return(model)
}

# This code does step-down regression based on the Kendall-Tau coefficient
# The cutoff indicates whether we should eliminate a variable as long as the KTC drop is lower than this cutoff
stepwise_kendall = function(v, i = 1, w = 1, suppress = FALSE, cutoff = 0.005) {
	if(length(w) == 1) { w = rep(1, dim(data)[1]) }
	if(length(i) == 1) { i = seq(1:dim(data)[1]) }
	flag = TRUE
	while(flag) {
		data2 = cbind(data, w)
		temp_df = na.omit(data2[i, names(data2) %in% 
			c(v, "col_nodemo_test", "col_sat_final", 
			  "col_demo_test", "w")])
		f = as.formula(paste(paste("col_sat_final ~ col_demo_test + ", 
			paste(v, collapse = " + "), collapse = " "), 
			sep = ""))
		model = lm(f, data = temp_df, weights = w)
		ktc = cor(temp_df$col_nodemo_test - temp_df$col_sat_final, temp_df$col_nodemo_test - model$fitted.values, method = "kendall")
		counter = rep(NA, length(v))
		for(j in 1:length(v)) {
			f = as.formula(paste(paste("col_sat_final ~ col_demo_test + ", paste(v[-j], collapse = " + "), collapse = " "), sep = ""))
			data2 = cbind(data, w)
			temp_df = na.omit(data2[i, names(data2) %in% c(v[-j], "col_nodemo_test", "col_sat_final", "col_demo_test", "w")])
			temp = lm(f, data = temp_df, weights = w)
			counter[j] = ktc - cutoff - cor(temp_df$col_nodemo_test - temp_df$col_sat_final, temp_df$col_nodemo_test - temp$fitted.values, method = "kendall")
			}
		flag = ifelse(as.logical(prod(counter > 0)), FALSE, TRUE)
		if(flag) {
			index = which(counter == min(counter))
			if(!suppress) { print(paste("This variable is being eliminated: ", v[index], " (Kendall Tau: ", round(ktc, 4), ")", sep = ""), quote = FALSE) }
			v = v[-index]
			}
		}
	if(!suppress) { print(summary(model)) }
	return(model)
	}

# This code does Lasso regularization
lasso = function(v, i = 1, w = 1, suppress = FALSE, coef_flag = FALSE) {
	if(length(w) == 1) { w = rep(1, dim(data)[1]) }
	if(length(i) == 1) { i = seq(1:dim(data)[1]) }
	temp = data[i, colnames(data) %in% c(v, "col_demo_test", "col_sat_final")]
	temp = scale(na.omit(temp))
	model = cv.glmnet(temp[,colnames(temp) %in% c(v, "col_demo_test")], temp[,colnames(temp) %in% "col_sat_final"])
	results = rownames(coef(model))[which(coef(model) != 0)]
	results = (coef(model))[which(coef(model) != 0),]
	results = as.data.frame(sort(results[2:length(results)], decreasing = TRUE))
	colnames(results) = c("Coefficient")
	if(!suppress) { print(results) }
	if(coef_flag) { return(results) }
	return(model)
	}

# This code tests bootstrapped samples and amalgamates results
wrapper = function(iterations, seed = 1000) {
	set.seed(seed)
	v = c('cas_math', 'cas_reading', 'en_gpa', 'en_count', 'fl_gpa', 'fl_count', 'ma_gpa', 'ma_count', 'sc_gpa', 'sc_count', 'ss_gpa', 'ss_count', 'total_gpa', 'total_count', 'honors', 'en_math_psat', 'en_read_psat', 'en_write_psat', 'en_degree', 'fl_math_psat', 'fl_read_psat', 'fl_write_psat', 'fl_degree', 'ma_math_psat', 'ma_read_psat', 'ma_write_psat', 'ma_degree', 'sc_math_psat', 'sc_read_psat', 'sc_write_psat', 'sc_degree', 'ss_math_psat', 'ss_read_psat', 'ss_write_psat', 'att_ratio', 'unapp_ratio', 'days')
	results_p = c()
	results_r = c()
	results_k = c()
	results_l = c()
	for(j in 1:iterations) {
		i = sample(dim(data)[1], dim(data)[1], replace = TRUE)
		dummy = tryCatch({
			model = stepwise_p(v, i = i, alpha = 0.01, suppress = TRUE)
			results_p = c(results_p, as.vector(unlist(sapply(unlist(strsplit(rownames(coef(model)), "\\[i\\]")), function(x) x[!(x %in% c("(Intercept)", "col_demo_test"))]))))
			}, warning = function(w) {}, error = function(e) {})
		dummy = tryCatch({
			model = stepwise_r(v, i = i, cutoff = 0.01, suppress = TRUE)
			results_r = c(results_r, as.vector(unlist(sapply(unlist(strsplit(rownames(coef(model)), "\\[i\\]")), function(x) x[!(x %in% c("(Intercept)", "col_demo_test"))]))))
			}, warning = function(w) {}, error = function(e) {})
		dummy = tryCatch({
			model = stepwise_kendall(v, i = i, cutoff = 0.01, suppress = TRUE)
			results_k = c(results_k, as.vector(unlist(sapply(unlist(strsplit(names(coef(model)), "\\[i\\]")), function(x) x[!(x %in% c("(Intercept)", "col_demo_test"))]))))
			}, warning = function(w) {}, error = function(e) {})
		dummy = tryCatch({
			model = lasso(v, i = i, suppress = TRUE, coef_flag = TRUE)
			results_l = c(results_l, rownames(model)[rownames(model) != "col_demo_test"])
			}, warning = function(w) {}, error = function(e) {})
		if(j %% 1 == 0) { print(j) }
		}
	output = matrix(0, 0, 5)
	for(i in 1:length(v)) {
		row = cbind(v[i], length(which(results_p == v[i])), length(which(results_r == v[i])), length(which(results_k == v[i])), length(which(results_l == v[i])))
		output = rbind(output, row)
		}
	output = as.data.frame(output, stringsAsFactors = FALSE)
	names(output) = c("features", "step.pvalue", "step.r2", "step.ktc", "lasso")
	output = transform(output, step.pvalue = as.numeric(step.pvalue), step.r2 = as.numeric(step.r2), step.ktc = as.numeric(step.ktc), lasso = as.numeric(lasso))
	output = output[with(output, order(-step.r2, -step.ktc, -lasso, -step.pvalue)),]
	setwd("/ebs/dssg-shared/github/dcps_model/feature_selection/augmented")
	write.csv(output, file = paste("augmented_", iterations, ".csv", sep = ""), quote = FALSE, row.names = FALSE)
	}

#wrapper(10)
