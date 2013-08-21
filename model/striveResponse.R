#======#
# Build "strive" as (college_sat vs. psat_score)
#
# Build "opgap"
#  as an explicit response variable
#
# OTUPUT:
#  file "cbstud_opgap.RData" with "cb.stud $strive $opgap"
#
# REQ:
#  "cb.stud, $hs_income_lo"
#
#
#
# "hs_income_lo" should come from "hs_demo.csv"
# "hs_demo.csv" outputted by "hs_income.R" (database call and smoothing)
#
#====#

# load('/ebs/dssg-shared/RData/monotone_strive.RData')
# load('/ebs/dssg-shared/RData/newan_ssm.RData')

hs_demo = read.csv(file="/ebs/dssg-shared/data/hs/hs_demo_old.csv")
cb.stud = merge(cb.stud, hs_demo, by.x="hs_id", by.y="hs_id", all.x=T, all.y=F)

#--- CONDITIONAL MEAN strive
if ( !sum(c('composite_psat','hs_income_lo') %in% names(cb.stud))) {
  stop("composite_psat or hs_income_lo not in cb.stud")
}


sub.stud = subset(cb.stud, !is.na(col_sat_final) & !is.na(composite_psat) & !is.na(hs_income_lo))
rich_ixs = (sub.stud$st_race == 'white' | sub.stud$st_race == 'asian') & (sub.stud$hs_income_lo > 100000); # RICH CONDITION must change
rich.stud = sub.stud[rich_ixs,]

# build monotonic regressor
psat_rg = 60:240;
bin_n = rep(0,length(psat_rg))
bin_mean = rep(0, length(psat_rg))
for (i in 1:length(psat_rg)) {
  cur_psat = psat_rg[i]
  bin_n[i] = sum(rich.stud$composite_psat == cur_psat)
  bin_mean[i] = mean(rich.stud$col_sat_final[rich.stud$composite_psat==cur_psat])
}

bin_mean[bin_n < 5] = 0
monofit = monoreg(x=psat_rg, y=bin_mean, w=bin_n)
strive = monofit$yf
strive[strive == 0] = min(strive[strive > 0])

# combine into  
strive.df = data.frame(cbind(psat_rg, strive))
cb.stud = merge(cb.stud, strive.df, by.x="composite_psat", by.y="psat_rg", all.x=TRUE, all.y=FALSE)

# SAVE FILE!
save(cb.stud, strive.df, file='/ebs/dssg-shared/RData/cbstud_opgap.RData')



# Visualizing the strive group fit
# compare also with quantile means and linear fit
bins = c(0,0.025,seq(0.05,0.95,length=20),0.975,1);
xtiles = quantile(sub.stud$composite_psat, probs=bins, na.rm=TRUE)

aves=rep(1,length(xtiles)-1)

mids = rep(1,length(xtiles)-1)
for (i in 2:length(xtiles)){
      tmp = subset(sub.stud, composite_psat < xtiles[i] & composite_psat > xtiles[i-1], select=c(col_sat_final,st_race,rich,poor,sat,hs_income_lo)) # CONDITON must change
      rich_ixs = (tmp$st_race == 'white' | tmp$st_race == 'asian') & (tmp$hs_income_lo > 100000);     # RICH CONDITION must change
      tmp.rich = tmp[rich_ixs,];

      aves[i-1] = mean(tmp.rich$col_sat_final, na.rm=TRUE)
}


#gen col_nodemo = 603.04
#replace col_nodemo = col_nodemo + 3.27 * composite_psat
linear_strive <- 603.04 + 3.27*psat_rg



filename='/ebs/dssg-shared/github/viz/strive_plot'
jpeg(file=paste0(filename, '_iso.jpg'), height=700, width=700)
plot(rich.stud$composite_psat, rich.stud$col_sat_final, main="strive score", xlab="composite psat", ylab="college sat", col=rgb(0.1,0.8,1,0.05), pch=20)
lines(psat_rg, strive, lwd=3, col='red');
lines(psat_rg, linear_strive, lwd=2, col='blue')
#points(mids, aves,lwd=4, col='black')
legend(190,900, c("monotone strive", "linear strive"), col=c('red', 'blue'), lty=c(1,1))
dev.off()


#kerfit = ksmooth(x=rich.stud$composite_psat, y=rich.stud$col_sat_final, kernel='normal', bandwidth=0.5, x.points=50:240);
#jpeg(file=paste0(filename, '_ksmooth.jpg'),height=700,width=700)
#plot(rich.stud$composite_psat, rich.stud$col_sat_final, xlab="composite psat", ylab="college sat", col=rgb(0.1,0.8,1,0.05), pch=20)
#lines(kerfit$x, kerfit$y, lwd=3, col='red');
#dev.off()

