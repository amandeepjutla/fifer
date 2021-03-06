% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/meta.data.R
\name{write.fife}
\alias{write.fife}
\alias{write.meta}
\alias{write.meta.data}
\alias{write.metadata}
\alias{write.fifer}
\title{Write a dataset and load the meta-data}
\usage{
write.fife(object, newfile, originalfile = NULL, file.type = ".csv",
  row.names = F, fullpath = T, ...)
}
\arguments{
\item{object}{An R object to be written as a .csv (or whatever) file.}

\item{newfile}{The location of the subsetted dataset to be written.}

\item{originalfile}{The location of the original file that was subsetted.}

\item{file.type}{The file type to be read. Defaults to .csv.}

\item{row.names}{Should row names be written? Defaults to FALSE.}

\item{fullpath}{Should the full path be written to the meta-data? (e.g., "documents/research/datasets/medical_data_ap9_2014.csv"). Defaults to T.}

\item{...}{Other arguments passed to \code{\link{write.csv}}.}
}
\description{
Oftentimes the original data matrix is too large to practically read in everytime you want to do analysis.
This often means creating a separate file for analysis. Unfortunately, if the original file is changed, the separate
file doesn't reflect those changes. \code{read.fife} and \code{\link{write.fife}} both read and write meta-data,
then display the original file name for the meta data.
}
\details{
Technically, \code{read.fife} and \code{\link{write.fife}} don't actually read and write meta-data. Instead, they create
(or read) a separate file that has the same name (though different extension) than the subsetted dataset. The extension of 
the meta data file is .file.
}
\seealso{
\code{\link{read.fife}}
}
\author{
Dustin Fife
}
