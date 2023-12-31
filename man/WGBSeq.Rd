% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/WGBSeq.R
\name{WGBSeq}
\alias{WGBSeq}
\title{Wrapper for WGBS settings for dmrseq}
\usage{
WGBSeq(bsseq, testCovariate, bpSpan = 1000, ...)
}
\arguments{
\item{bsseq}{A bsseq object}

\item{testCovariate}{The pData column to test on}

\item{bpSpan}{Span of smoother AND 2x max gap in DMR CpGs
(DEFAULT: 1000)}

\item{...}{Other arguments to pass along to dmrseq}
}
\value{
\if{html}{\out{<div class="sourceCode">}}\preformatted{          A GRanges object (same as from dmrseq)
}\if{html}{\out{</div>}}
}
\description{
Wrapper for WGBS settings for dmrseq
}
\examples{

  data(BS.chr21, package="dmrseq")
  dat <- BS.chr21

  wgbs <- WGBSeq(dat[1:500, ], "CellType", cutoff = 0.05,
                 BPPARAM=BiocParallel::SerialParam())

}
