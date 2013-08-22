#======#
# Example
# Constructing a "target college quality" as a function
# of student academic ability
#
# In this example, we measure "college quality" with
# average SAT score in the college
# and we measure student "academic quality" with
# the PSAT score.
#
# 
# 
#
#
#====#

DIR = "~/projects/dssg/match-edu/" # set to github repo distory

# We ASSUME the following variables exist:
# "students"
#	a data frame, one row per student
#	has fields "psat", "col_sat", "race"


sub.stud = subset(students, !is.na(col_sat) & !is.na(psat) & !is.na(race))

# Choice of comparison group
# we choose to compare against white and asian students
compare_ixs = (sub.stud$race == 'white' | sub.stud$race == 'asian')
compare.stud = sub.stud[compare_ixs,]

# Use monotone regression to 
# map PSAT to col_sat
# need to first bin and compute mean for bin
# because "monoreg" package assumes each point
# has a unique "x"-value
psat_range = 60:240;
bin_n = rep(0,length(psat_range))
bin_mean = rep(0, length(psat_range))
for (i in 1:length(psat_range)) {
  cur_psat = psat_range[i]
  bin_n[i] = sum(compare.stud$psat == cur_psat)
  bin_mean[i] = mean(compare.stud$col_sat[compare.stud$psat==cur_psat])
}

bin_mean[bin_n < 5] = 0
monofit = monoreg(x=psat_range, y=bin_mean, w=bin_n)
target = monofit$yf
target[target == 0] = min(target[target > 0])

target.df = data.frame(cbind(psat_range, target))

# Assign a target score to every student in "students" table
students = merge(students, target.df, by.x="psat", 
		by.y="psat_range", all.x=TRUE, all.y=FALSE)


####
# Visualization, sanity check
#
#
# Visualizing the target group fit
# compare also with quantile means
bins = c(0,0.025,seq(0.05,0.95,length=20),0.975,1);
xtiles = quantile(sub.stud$psat, probs=bins, na.rm=TRUE)

aves=rep(1,length(xtiles)-1)

mids = rep(1,length(xtiles)-1)
for (i in 2:length(xtiles)){
      tmp = subset(sub.stud, psat < xtiles[i] & psat > xtiles[i-1], 
			select=c(col_sat,race)) 
      compare_ixs = (tmp$race == 'white' | tmp$race == 'asian');
      tmp.compare = tmp[compare_ixs,];

      aves[i-1] = mean(tmp.compare$col_sat, na.rm=TRUE)
}


filename='/viz/target_plot.jpg'
jpeg(file=paste0(DIR, filename), height=700, width=700)
plot(compare.stud$psat, compare.stud$col_sat, 
	main="target score", xlab="composite psat", 
	ylab="college sat", col=rgb(0.1,0.8,1,0.05), pch=20)
lines(psat_range, target, lwd=3, col='red');
legend(190,900, c("target"), col=c('red'), lty=c(1))
dev.off()

