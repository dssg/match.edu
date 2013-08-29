studs <- read.csv("../students.csv")
col_sats <- aggregate(studs$psat, by=list(studs$college), FUN=mean)

col_sats$col_sat <- col_sats$x
col_sats$x <- NULL
col_sats$college <- col_sats$Group.1
col_sats$Group.1 <- NULL

studs$X <- NULL
studs <- merge(studs, col_sats, by="college", all=F)
write.table(studs,file="../students.csv", sep=",")
