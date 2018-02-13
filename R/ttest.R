##' Perform a two-independent sample t-test
##'
##' This function performs a t-test, but does so in a way that adheres to the 7 steps of data analysis (it reports residuals/effect sizes/parameter estimates before showing significance). 
##'	
##' The validity of a t-test relies on basic statistical assumptions (normality, homoskedasiticity, and independence). Furthermore, statistical significance can easily be
##' conflated with practical significance. This function is simply a wrapper for r's native \code{\link{t.test}} function, but outputs the results in such a way that encourages
##' the user to focus on estimation as model appropriateness. 
##' @param y Either a vector containing the Dependent variable scores, or a vector containing the scores of group 1
##' @param x Either a vector containing the group categories, or a vector containing the scores of group 2
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
ttest = function(y, x){
	

	if(length(x) != length(y)){
		stop(paste0(deparse(substitute(x)), " and ", deparse(substitute(y))), " need to be the same length!")	
	}
	#### if they specify y and x as continuous (i.e., y is group 1, x is group 2)
	if(length(unique(x))!=2){
		print(paste0("Note: there are ", length(unique(x)), " unique values for ", deparse(substitute(x)), ". I am assuming ", deparse(substitute(x)), " is the scores for one group, while ", deparse(substitute(y)), " is the scores of the other. If not, you need to make sure ", deparse(substitute(x)), " has only two levels."))
		m = data.frame(y=c(x,y), x=c(rep(1, times=length(x)), rep(2, times=length(x))))
		n = length(x)*2
	} else {
		m = data.frame(y=y, x=x)
		n = length(y)
	}
	

	##### do a t test	
	test = t.test(y~x, data=m)
	
	#### compute cohen's d
	d = test$statistic/sqrt(n)
	names(d) = "Cohen's d"
	
	#### save estimates
	estimates = ci.mean(m$y, m$x)
	diff = data.frame(x="Difference", y=abs(diff(estimates[,2])), lower=test$conf.int[1], upper = test$conf.int[2])
	names(diff)[2] = "y mean"
	estimates = rbind(estimates, diff)
	names(estimates) = c("Group", "Mean", "Lower 95% CI", "Upper 95% CI")
	rownames(estimates) = c()
	
	#### output information for plotting:
	fitted = rep(estimates$Mean[1], times=nrow(m))
	fitted[m$x==levels(m$x)[2]] = estimates$Mean[2]
	m$residuals = m$y - fitted
	m$abs.resids = abs(m$residuals)
	
	
	output = list('cohens.d' = d, 'estimates'=estimates, 'data' = m, 'x' = x.name, 'y' = y.name)
	attr(output, "class") = "ttest"
	return(output)
}



#' Print ttest Summary
#'
#' Print ttest Summary
#' @aliases print.ttest
#' @param x a ttest object
#' @param ... ignored
#' @export
print.ttest = function(x,...){
	cat(paste("Cohen's d:\n", round(x$cohens.d, digits=2), "\n\nParameter Estimates:\n",sep=""))
	print(x$estimates, row.names=F)
}


#' Plot ttest Summary
#'
#' Plot ttest Summary
#' @aliases plot plot.ttest
#' @param x a ttest object
#' @param y igorned
#' @param ... other parameters passed to plot
#' @import cowplot
#' @export
plot.ttest = function(x, ...){
	m = x$data
	
	x.name = x$x.name
	y.name = x$y.name
	
	##### do a plot
	t.test = ggplot(data=m, aes(x=x, y=y)) + geom_jitter(alpha = .15, width=.05, size=.75) + stat_summary(fun.y='median', geom='point', size=2, color='red') + 
		stat_summary(aes(x=x, y=y), geom='errorbar', fun.ymin=function(z) {quantile(z, .25)}, fun.ymax = function(z) {quantile(z, .75)}, fun.y=median, color='red', width=.2) +
		theme_bw() + labs(x=x.name, y=y.name, title="Median (+ IQR) Plot")

	##### and a residual dependence plot
	res.dep = ggplot(data=p, aes(y=residuals, x=x)) + geom_jitter(alpha=.15, width=.05, size=.75) + stat_summary(fun.y=median, color="red", geom="line", aes(group=1)) + theme_bw() + labs(x=x.name, y="Absolute Value of Residuals", title="S-L Plot")
	
	##### put into a single plot
	require(cowplot)
	plot_grid(t.test, histo, res.dep)

}
?plot.lm
