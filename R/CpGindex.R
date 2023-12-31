#' Measure methylation status for PRCs or PMDs
#'
#' WARNING: This function will be deprecated in the next Bioconductor release
#'
#' Measures hypermethylation at PRCs in CGIs or hypomethylation at WCGWs in PMDs
#'
#' At some point in some conference call somewhere, a collaborator suggested
#' that a simple index of Polycomb repressor complex (PRC) binding site hyper-
#' methylation and CpG-poor "partially methylated domain" (PMD) hypomethylation
#' would be a handy yardstick for both deterministic and stochastic changes
#' associated with proliferation, aging, and cancer. This function provides
#' such an index by compiling measures of aberrant hyper- and hypo-methylation
#' along with the ratio of hyper- to hypo-methylation. (The logic for this is
#' that while the phenomena tend to occur together, there are many exceptions)
#' The resulting measures can provide a high-level summary of proliferation-,
#' aging-, and/or disease-associated changes in DNA methylation across samples.
#'
#' The choice of defaults is fairly straightforward: in 2006, three independent
#' groups reported recurrent hypermethylation in cancer at sites marked by both
#' H3K4me3 (activating) and H3K27me3 (repressive) histone marks in embryonic
#' stem cells; these became known as "bivalent" sites. The Roadmap Epigenome
#' project performed ChIP-seq on hundreds of normal primary tissues and cell
#' line results from the ENCODE project to generate a systematic catalog of
#' "chromatin states" alongside dozens of whole-genome bisulfite sequencing
#' experiments in the same tissues. We used both to generate a default atlas
#' of bivalent (Polycomb-associated and transcriptionally-poised) sites from
#' H9 human embryonic stem cells which retain low DNA methylation across normal
#' (non-placental) REMC tissues. In 2018, Zhou and Dinh (Nature Genetics) found
#' isolated (AT)CG(AT) sites, or "solo-WCGW" motifs, in common PMDs as the most
#' universal barometer of proliferation- and aging-associated methylation loss
#' in mammalian cells, so we use their solo-WCGW sites in common PMDs as the
#' default measure for hypomethylation. The resulting CpGindex is a vector of
#' length 3 for each sample: hypermethylation, hypomethylation, and their ratio.
#'
#' We suggest fitting a model for the composition of bulk samples (tumor/normal,
#' tissue1/tissue2, or whatever is most appropriate) prior to drawing any firm
#' conclusions from the results of this function. For example, a mixture of
#' two-thirds normal tissue and one-third tumor tissue may produce the same or
#' lower degree of hyper/hypomethylation than high-tumor-content cell-free DNA
#' samples from the blood plasma of the same patient. Intuition is simply not
#' a reliable guide in such situations, which occur with some regularity. If
#' orthogonal estimates of purity/composition are available (flow cytometry,
#' ploidy, yield of filtered cfDNA), it is a Very Good Idea to include them.
#'
#' The default for this function is to use the HMM-defined CpG islands from
#' Hao Wu's paper (Wu, Caffo, Jaffee, Irizarry & Feinberg, Biostatistics 2010)
#' as generic "hypermethylation" targets inside of "bivalent" (H3K27me3+H3K4me3)
#' sites (identified in H9 embryonic stem cells & unmethylated across normals),
#' and the solo-WCGW sites within common partially methylated domains from
#' Wanding Zhou and Huy Dinh's paper (Zhou, Dinh, et al, Nat Genetics 2018)
#' as genetic "hypomethylation" targets (as above, obvious caveats about tissue
#' specificity and user-supplied possibilities exist, but the defaults are sane
#' for many purposes, and can be exchanged for whatever targets a user wishes).
#'
#' The function returns all three components of the "CpG index", comprised of
#' hyperCGI and hypoPMD (i.e. hyper, hypo, and their ratio). The PMD "score" is
#' a base-coverage-weighted average of losses to solo-WCGW bases within PMDs;
#' the PRC score is similarly base-coverage-weighted but across HMM CGI CpGs,
#' within polycomb repressor complex sites (by default, the subset of state 23
#' segments in the 25-state, 12-mark ChromImpute model for H9 which have less
#' than 10 percent CpG methylation across the CpG-island-overlapping segment in
#' all normal primary tissues and cells from the Reference Epigenome project).
#' By providing different targets and/or regions, users can customize as needed.
#'
#' The return value is a CpGindex object, which is really just a DataFrame that
#' knows about the regions at which it was summarized, and reminds the user of
#' this when they implicitly call the `show` method on it.
#'
#' @param bsseq  A BSseq object
#' @param CGIs   A GRanges of CpG island regions - HMM CGIs if NULL
#'                 (DEFAULT: NULL)
#' @param PRCs   A GRanges of Polycomb targets - H9 state 23 low-meth if NULL
#'                 (DEFAULT: NULL)
#' @param WCGW   A GRanges of solo-WCGW sites - PMD WCGWs if NULL
#'                 (DEFAULT: NULL)
#' @param PMDs   A GRanges of hypomethylating regions - PMDs if NULL
#'                 (DEFAULT: NULL)
#'
#' @return       A CpGindex (DataFrame w/cols `hyper`, `hypo`, `ratio` + 2 GRs)
#'
#' @importFrom methods callNextMethod slot as new
#' @importFrom utils data
#' @import biscuiteerData
#' @import GenomeInfoDb
#' @import GenomicRanges
#' @import S4Vectors
#'
CpGindex <- function(bsseq,
                     CGIs = NULL,
                     PRCs = NULL,
                     WCGW = NULL,
                     PMDs = NULL) {

    warning("CpGindex() will be deprecated in the next Bioconductor release!")

    # necessary evil
    if (is.null(unique(genome(bsseq)))) {
        stop("You must assign a genome to your BSseq object before proceeding.")
    } else {
        genome <- unique(genome(bsseq))
        if (genome %in% c("hg19","GRCh37")) suffix <- "hg19"
        else if (genome %in% c("hg38","GRCh38")) suffix <- "hg38"
        else stop("Only human genomes (hg19/GRCh37, hg38/GRCh38) are supported ATM")
    }

    # summarize hypermethylation by region
    message("Computing hypermethylation indices...")
    if (is.null(CGIs)) CGIs <- .fetch(bsseq, "HMM_CpG_islands", suffix)
    if (is.null(PRCs)) PRCs <- .fetch(bsseq, "H9state23unmeth", suffix)
    hyperMeth <- .subsettedWithin(bsseq, y=CGIs, z=PRCs)

    # summarize hypomethylation (at WCGWs) by region
    message("Computing hypomethylation indices...")
    if (is.null(PMDs)) PMDs <- .fetchBiscuiteerData(bsseq, "PMDs", suffix)
    if (is.null(WCGW)) WCGW <- .fetchBiscuiteerData(bsseq,
                                                    "Zhou_solo_WCGW_inCommonPMDs",
                                                    suffix)
    hypoMeth <- .subsettedWithin(bsseq, y=WCGW, z=PMDs)

    # summarize both via ratios
    message("Computing indices...")
    res <- new("CpGindex",
               DataFrame(hyper=hyperMeth,
                         hypo=hypoMeth,
                         ratio=hyperMeth/hypoMeth),
               hyperMethRegions=PRCs,
               hypoMethRegions=PMDs)
    return(res)

}

# Class definition
setClass("CpGindex", contains="DFrame",
         slots=c(hyperMethRegions="GenomicRanges",
                 hypoMethRegions="GenomicRanges"))

# Default show method
setMethod("show", "CpGindex", function(object) {
              callNextMethod()
              nm <- deparse(substitute(object))
              if (length(slot(object, "hyperMethRegions")) > 0 |
                  length(slot(object, "hypoMethRegions")) > 0) {
                  cat("  -------\n")
                  cat("This object is just a DataFrame that has an idea of where",
                      "it came from:\n")
              }
              if (length(slot(object, "hyperMethRegions")) > 0) {
                  cat("Hypermethylation was tallied across",
                      length(slot(object, "hyperMethRegions")), "region (see",
                      "'object@hyperMethRegions').", "\n")
                  #show(object@hyperMethRegions)
              }
              if (length(slot(object, "hypoMethRegions")) > 0) {
                  cat("Hypomethylation was tallied across",
                      length(slot(object, "hypoMethRegions")), "region (see",
                      "'object@hypoMethRegions').", "\n")
                  #show(object@hypoMethRegions)
              }
         })

# Helper function
.fetch <- function(x, prefix, suffix) {
    dat <- paste(prefix, suffix, sep=".")
    message("Loading ", dat, "...")
    data(list=dat, package="biscuiteer")
    xx <- get(dat)
    seqlevelsStyle(xx) <- seqlevelsStyle(x)
    return(xx)
}

# Helper function
.fetchBiscuiteerData <- function(x, prefix, suffix) {
    dat <- paste(prefix, suffix, "rda", sep=".")
    message("Loading ", dat, " from biscuiteerData...")
    xx <- biscuiteerDataGet(dat)
    seqlevelsStyle(xx) <- seqlevelsStyle(x)
    return(xx)
}

# Helper function
.subsettedWithin <- function(x, y, z) {
    y <- sort(subsetByOverlaps(y, x))
    z <- sort(subsetByOverlaps(z, y))
    res <- getMeth(subsetByOverlaps(x,y), regions=z, type="raw", what="perRegion")
    if (any(is.na(res)) | any(is.nan(res))) {
        return(.delayedNoNaN(res, z)) # slower but exact
    } else {
        return((width(z)/sum(width(z))) %*% res) # much faster
    }
}

# Helper function
.delayedNoNaN <- function(x, z) {
    res <- c()
    for (i in colnames(x)) {
        use <- !is.na(x[,i]) & !is.nan(x[,i])
        zz <- z[which(as(use, "logical"))]
        res[i] <- as.matrix(((width(zz)/sum(width(zz))) %*% x[use, i]))
    }
    return(res)
}
