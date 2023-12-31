% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/filterLoci.R
\name{filterLoci}
\alias{filterLoci}
\title{Filter loci with zero coverage}
\usage{
filterLoci(bsseq, testCovariate)
}
\arguments{
\item{bsseq}{A bsseq object for filtering}

\item{testCovariate}{The name of the pData column dmrseq will test on}
}
\value{
\if{html}{\out{<div class="sourceCode">}}\preformatted{          A bsseq object ready for dmrseq to use
}\if{html}{\out{</div>}}
}
\description{
Function potentially used to be a part of dmrseq. Included here to avoid
dmrseq failing due to any number of reasons related to lack of coverage.
}
\details{
The code is adapted from the precheck loop of dmrseq::dmrseq
}
\examples{

  shuf_bed <- system.file("extdata", "MCF7_Cunha_chr11p15_shuffled.bed.gz",
                          package="biscuiteer")
  orig_bed <- system.file("extdata", "MCF7_Cunha_chr11p15.bed.gz",
                          package="biscuiteer")
  shuf_vcf <- system.file("extdata",
                          "MCF7_Cunha_shuffled_header_only.vcf.gz",
                          package="biscuiteer")
  orig_vcf <- system.file("extdata",
                          "MCF7_Cunha_header_only.vcf.gz",
                          package="biscuiteer")
  bisc1 <- readBiscuit(BEDfile = shuf_bed, VCFfile = shuf_vcf,
                       merged = FALSE)
  bisc2 <- readBiscuit(BEDfile = orig_bed, VCFfile = orig_vcf,
                       merged = FALSE)

  comb <- unionize(bisc1, bisc2)

  filt <- filterLoci(comb, "sampleNames")

}
\seealso{
dmrseq

WGBSeq

RRBSeq
}
