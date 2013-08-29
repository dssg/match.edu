#=================#
#
#
#
#===========#

library(ggplot2)

errs <- read.table(file="../errors.csv")
errs$method = rownames(errs)


plotErrors <- function(tmp, filename) {
  theme_set(theme_grey(base_size=18))

  pdf(paste0("../viz/errors/", filename, "-all-recov.pdf"))
  plot.obj<-  ggplot(tmp, aes(x=method, y=all_recov.mean, color=method)) + 
      geom_bar(position=position_dodge(), stat="identity") +
      geom_errorbar(aes(ymin=all_recov.mean-all_recov.sd,
                        ymax=all_recov.mean+all_recov.sd),
                    width=.6,                    # Width of the error bars
                    position=position_dodge(.9),
		    size=1) +
      guides(color=FALSE) +
      geom_hline(yintercept=0.2, size=2, alpha=0.5, color="red") +
      scale_y_continuous(name="Disadvantaged Recovery")
  print(plot.obj)
  dev.off()

  pdf(paste0("../viz/errors/", filename, "-good-recov.pdf"))
  plot.obj<- ggplot(tmp, aes(x=method, y=good_recov.mean, color=method)) + 
      geom_bar(position=position_dodge(), stat="identity") +
      geom_errorbar(aes(ymin=good_recov.mean-good_recov.sd,
                        ymax=good_recov.mean+good_recov.sd),
                    width=.6,                    # Width of the error bars
                    position=position_dodge(.9),
		    size=1) +
      guides(color=FALSE) +
      geom_hline(yintercept=0.5, size=2, alpha=0.5, color="red") +
      scale_y_continuous(name="High Potential Recovery")
  print(plot.obj)
  dev.off()

  pdf(paste0("../viz/errors/", filename, "-ok-recov.pdf"))
  plot.obj<- ggplot(tmp, aes(x=method, y=ok_recov.mean, color=method)) + 
      geom_bar(position=position_dodge(), stat="identity") +
      geom_errorbar(aes(ymin=ok_recov.mean-ok_recov.sd,
                        ymax=ok_recov.mean+ok_recov.sd),
                    width=.6,                    # Width of the error bars
                    position=position_dodge(.9),
		    size=1) +
      guides(color=FALSE) +
      geom_hline(yintercept=0.5, size=2, alpha=0.5, color="red") +
      scale_y_continuous(name="Moderate Potential Recovery")
  print(plot.obj)
  dev.off()

  pdf(paste0("../viz/errors/", filename, "-err.pdf"))
  plot.obj<- ggplot(tmp, aes(x=method, y=total_err.mean, color=method)) + 
      geom_bar(position=position_dodge(), stat="identity") +
      geom_errorbar(aes(ymin=total_err.mean-total_err.sd,
                        ymax=total_err.mean+total_err.sd),
                    width=.6,                    # Width of the error bars
                    position=position_dodge(.9),
		    size=1) +
      guides(color=FALSE) +
      scale_y_continuous(name="Mean Squared Error (predicting Op-gap)")
  print(plot.obj)
  dev.off()

  pdf(paste0("../viz/errors/", filename, "-kendall.pdf"))
  plot.obj<-ggplot(tmp, aes(x=method, y=kendall.mean, color=method)) + 
      geom_bar(position=position_dodge(), stat="identity") +
      geom_errorbar(aes(ymin=kendall.mean-kendall.sd,
                        ymax=kendall.mean+kendall.sd),
                    width=.6,                    # Width of the error bars
                    position=position_dodge(.9),
		    size=1) +
      guides(color=FALSE) +
      scale_y_continuous(name="Kendall Tau Distance")
  print(plot.obj)
  dev.off()

  xtile_df = NULL  
  #xtile_df = data.frame(tmp$method)
  #names(xtile_df) = c("method") 
  for (jj in 1:4){
    means = array(tmp[, grep('xtile_err.mean', colnames(tmp))[jj]])
    sds = array(tmp[, grep('xtile_err.sd', colnames(tmp))[jj]])
    tmp2 <- data.frame(as.character(rep(jj,length(tmp$method))),
                       means, sds)
    tmp2$method = tmp$method
    colnames(tmp2) <- c("quarts", "means", "sds", "method") 
    xtile_df = rbind(xtile_df, tmp2) 
  } 
 
   
  pdf(paste0("../viz/errors/", filename, "-quartile-err.pdf")) 
  plot.obj<-ggplot(xtile_df, aes(x=quarts, y=means, fill=method)) + 
      geom_bar(position=position_dodge(), stat="identity") +
      geom_errorbar(aes(ymin=means-sds, ymax=means+sds),
                    width=0.6,                    # Width of the error bars
  		  size=1, 
		  position=position_dodge(.9))+
      scale_x_discrete(name="Quartiles",
                       labels=c("1st", "2nd", "3rd", "4th")) +
      scale_y_continuous(name="Mean Square Errs (Predicting Op-gap)") +
      labs(title="MSE per PSAT Quartile") 
  print(plot.obj)
  dev.off()

#                    position=position_dodge(.9)) +
}  



tmp = errs[c("linearAll", "rfLasso"),]
plotErrors(tmp, "linear-RF-all")


tmp = errs[c("linearGPAHon", "rfGPAHon"),]
plotErrors(tmp, "linear-RF-GPAHon")

