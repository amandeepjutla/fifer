unique(c(11, 12, 14, NA), incomparables=NA)

##' Perform a two-independent sample t-test
##'
##' This function performs a t-test, but does so in a way that adheres to the 7 steps of data analysis (it reports residuals/effect sizes/parameter estimates before showing significance). 
##'	
##' The validity of a t-test relies on basic statistical assumptions (normality, homoskedasiticity, and independence). Furthermore, statistical significance can easily be
##' conflated with practical significance. This function is simply a wrapper for r's native \code{\link{t.test}} function, but outputs the results in such a way that encourages
##' the user to focus on estimation as model appropriateness. 
##' @param y Either a vector containing the Dependent variable scores, or a vector containing the scores of group 1
##' @param x Either a vector containing the group categories, or a vector containing the scores of group 2
##' @param related Are the two groups related (paired)? Specify true if the people are matched or if there's repeated measures. 
##' @seealso \code{\link{t.test}}
##' @return Two objects: cohen's d and a table of estimates (means and difference between groups)
##' @author Dustin Fife
##' @export
##' @examples
##' # where y and x are scores for group 1 and group 2 (respectively)
##' y = rnorm(30, 10, 5)
##' x = rnorm(30, 12, 5)
##' ttest(y,x)
##' 
##' # where y is all scores and x is the group labels
##' y = rnorm(300, 10, 5)
##' x = sample(c(1:2), size=length(y), replace=T)
##' ttest(y,x)
ttest = function(y, x, related=F){


	if(length(x) != length(y)){
		stop(paste0(deparse(substitute(x)), " and ", deparse(substitute(y))), " need to be the same length!")	
	}
	#### if they specify y and x as continuous (i.e., y is group 1, x is group 2)
	if(length(unique(x))!=2 & !(NA %in% unique(y))){
		print(paste0("Note: there are ", length(unique(x)), " unique values for ", deparse(substitute(x)), ". I am assuming ", deparse(substitute(x)), " is the scores for one group, while ", deparse(substitute(y)), " is the scores of the other. If not, you need to make sure ", deparse(substitute(x)), " has only two levels."))
		m = data.frame(y=c(x,y), x=c(rep(1, times=length(x)), rep(2, times=length(x))))
		miss = which(is.na(m$y))
		if (length(miss)>0){
			m = m[-miss,]
		}
		n = length(x)*2
	} else {
		m = data.frame(y=y, x=x)		
		miss = which(is.na(m$y) | is.na(m$x))
		if (length(miss)>0){
			m = m[-miss,]
		}		
		n = length(y)
	}
	
	x.name = deparse(substitute(x))
	y.name = deparse(substitute(y))	
	
	##### do a t test	
	test = t.test(y~x, data=m, paired=related)

	
	#### figure out reference group

	if (related){
		diff = 	test$estimate
		means = diff
	} else {		
		means = test$estimate		
		diff.1 = means[1]-means[2]
		diff.2 = means[2]-means[1]
		if (diff.1-test$conf.int[1] == test$conf.int[2] - diff.1){
			### reference group is first group
			diff = diff.1
		} else {
			diff = diff.2
		}	
	}
	
	##### compute cohen's d
	if (related){
		group1 = which(m$x==unique(m$x)[1])
		group2 = which(m$x!=unique(m$x)[1])		
		sd = sd(m$y[group1] - m$y[group2])
		hist(m$y[group1] - m$y[group2])
		d = diff/sd
		
		difference.scores = m$y[group1] - m$y[group2]
		
		#### CI for Cohen's d (see https://stats.stackexchange.com/questions/87068/conflict-in-confidence-intervals-for-mean-difference-and-confidence-interval-for)
		tval = test$statistic
		ns = nrow(m)/2
		ns.=ns
		f = function(ci, ns.=ns){
			lower = pt(tval, df=ns-1, ncp=ci[1] * sqrt(ns.), lower.tail=F)
			upper = pt(tval, df=ns-1, ncp=ci[2] * sqrt(ns.), lower.tail=T)			
			return((lower-.025)^2 + (upper-.025)^2)
		}
		vals = as.numeric(test$conf.int)/sd
		op = optim(vals, f)
		d = c(d, d.lower=op$par[1], d.upper=op$par[2])
		names(d) = c("d", "lower", "upper")		

	} else {
		ns = aggregate(y~x, data=m, FUN=length)$y
		vars = aggregate(y~x, data=m, FUN=var)$y
		pooled.var = sqrt(((ns[1]- 1) * vars[1] + (ns[2] - 1) * vars[2])/(ns[1] + ns[2] - 
	        2))
	    d = diff/pooled.var 
	    
		#### CI for Cohen's d		
		var.d = (ns[1] + ns[2])/(ns[1]*ns[2]) + d^2/(2*(ns[1]+ns[2]))
		tcrit = qt(.025, sum(ns)-2, lower.tail=F)
		d.lower = d-tcrit*sqrt(var.d)
		d.upper = d+tcrit*sqrt(var.d)
		d = c(d, d.lower, d.upper, sqrt(var.d))
		names(d) = c("d", "lower", "upper", "se")	    
		difference.scores = NULL
    }
    

	
	#### save estimates
	estimates = ci.mean(m$y, m$x)
	diff = data.frame(x="Difference", y=diff, lower=test$conf.int[1], upper = test$conf.int[2])
	names(diff)[2] = "y mean"
	estimates = rbind(estimates, diff)
	names(estimates) = c("Group", "Mean", "Lower 95% CI", "Upper 95% CI")
	rownames(estimates) = c()
	
	#### output information for plotting:
	fitted = rep(estimates$Mean[1], times=nrow(m))
	fitted[m$x==levels(m$x)[2]] = estimates$Mean[2]
	m$residuals = m$y - fitted
	m$abs.resids = abs(m$residuals)

	p.report = ifelse(test$p.value<.001, "p < 0.001", paste0("p = ", round(test$p.value, digits=3)))

	report = paste0("t(", round(test$parameter, digits=2), ") = ", round(test$statistic, digits=2), ", ", p.report)
	output = list('cohens.d' = d, 'estimates'=estimates, 'report' = report, t.test.object = test, 'data' = m, 'x' = x.name, 'y' = y.name, difference.scores=difference.scores)
	attr(output, "class") = "ttest"
	return(output)
}




#' Report ttest object Estimates (effect sizes and parameters)
#'
#' Report ttest object Estimates
#' @aliases estimates.ttest estimates
#' @param object a ttest object
#' @export
estimates.ttest = function(object){
	file.name = deparse(substitute(object))
	cat(paste("Cohen's d:\n", round(object$cohens.d[1], digits=3), " (", round(object$cohens.d[2], digits=2),", ", round(object$cohens.d[3], digits=2),")\n\nParameter Estimates:\n",sep=""))
	print(object$estimates)
}


#' Output APA style statistical significance from a ttest object
#'
#' Output APA style statistical significance from a ttest object
#' @aliases report.ttest report report.default
#' @param object a ttest object
#' @export
report.ttest = function(object){
	print(object$report)
}

#' Print ttest Summary
#'
#' Print ttest Summary
#' @aliases print.ttest
#' @param x a ttest object
#' @param ... ignored
#' @export
print.ttest = function(x,...){

	file.name = deparse(substitute(x))
	cat(paste("Cohen's d:\n", round(x$cohens.d[1], digits=2), " (", round(x$cohens.d[2], digits=2),", ", round(x$cohens.d[3], digits=2),")\n\nParameter Estimates:\n",sep=""))
	print(x$estimates, row.names=F)
	cat(paste("\n\n Objects within this object:\n"))
	print(names(x))	
}


#' Plot ttest Summary
#'
#' Plot ttest Summary
#' @aliases plot plot.ttest
#' @param x a ttest object
#' @param y igorned
#' @param residuals should the residuals be plotted?
#' @param ... other parameters passed to plot
#' @importFrom cowplot plot_grid
#' @export
plot.ttest = function(x, residuals=T,...){
	m = x$data
	
	x.name = x$x.name
	y.name = x$y.name
	
	##### do a plot
	
	if (is.null(x$difference.scores)){
		t.test = ggplot(data=m, aes(x=x, y=y)) + geom_jitter(alpha = .15, width=.05, size=.75) + stat_summary(fun.y='median', geom='point', size=2, color='red') + 
			stat_summary(aes(x=x, y=y), geom='errorbar', fun.ymin=function(z) {quantile(z, .25)}, fun.ymax = function(z) {quantile(z, .75)}, fun.y=median, color='red', width=.2) +
			theme_bw() + labs(x=x.name, y=y.name, title="Median (+ IQR) Plot")
	} else {
		k = data.frame(differences=x$difference.scores, x=1)
		t.test = ggplot(data=k, aes(x=x, y=differences)) + geom_jitter(alpha=.15, width=.05, size=.75) + stat_summary(fun.y='median', geom='point', size=2, color='red') + 
			stat_summary(aes(x=x, y=differences), geom='errorbar', fun.ymin=function(z) {quantile(z, .25)}, fun.ymax = function(z) {quantile(z, .75)}, fun.y=median, color='red', width=.2) +
			theme_bw() + labs(x="", y="Difference Between Group (Jittered)", title="Median (+ IQR) Plot") +
			theme(axis.title.x=element_blank(),
			        axis.text.x=element_blank(),
			        axis.ticks.x=element_blank()) +
			coord_cartesian(xlim=c(.5,1.5)) + 
			geom_hline(yintercept=0)					
			
			
	}
	histo = ggplot(data=m, aes(x=residuals)) + geom_histogram(fill='lightgray', col='black') + theme_bw() + labs(x=x.name, title="Histogram of Residuals")


	##### and a residual dependence plot
	res.dep = ggplot(data=m, aes(y=residuals, x=x)) + geom_jitter(alpha=.15, width=.05, size=.75) + stat_summary(fun.y=median, color="red", geom="line", aes(group=1)) + theme_bw() + labs(x=x.name, y="Absolute Value of Residuals", title="S-L Plot")
	
	##### put into a single plot
	if (residuals){
		plot_grid(t.test, histo, res.dep)
	} else {
		t.test
	}

}