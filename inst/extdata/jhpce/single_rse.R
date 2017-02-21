## Required libraries
stopifnot(packageVersion('recount.bwtool') >= '0.99.2')
library('recount.bwtool')
library('BiocParallel')
library('devtools')
library('getopt')

## Specify parameters
spec <- matrix(c(
    'projectid', 'p', 1, 'integer', 'A number between 1 and 2036. 2035 is GTEx and 2036 is TCGA',
    'regions', 'r', 1, 'character', 'Path to a file that has a GRanges object',
    'sumsdir', 's', 1, 'character', 'Path to the output directory for the bwtool sum files',
    'cores', 'c', 1, 'integer', 'Number of cores to use. That is, how many bigWig files to process simultaneously',
    'bed', 'b', 2, 'character', 'Path to a bed file (optional)',
	'help' , 'h', 0, 'logical', 'Display help'
), byrow=TRUE, ncol=5)
opt <- getopt(spec)

## if help was asked for print a friendly message
## and exit with a non-zero error code
if (!is.null(opt$help)) {
	cat(getopt(spec, usage=TRUE))
	q(status=1)
}

## Load the custom url table and project names
load('/dcl01/leek/data/recount-website/fileinfo/local_url.RData')
projects <- unique(local_url$project[grep('.bw$', local_url$file_name)])
stopifnot(opt$projectid >=1 & opt$projectid <= length(projects))
project <- projects[opt$projectid]

## Load the regions
reg_load <- function(regpath) {
    regname <- load(regpath)
    get(regname)
}
regions <- reg_load(opt$regions)
stopifnot(is(regions, 'GRanges'))

## Create the sums directory
dir.create(opt$sumsdir, recursive = TRUE, showWarnings = FALSE)

if(opt$cores == 1) {
    bp <- SerialParam()
} else {
    bp <- MulticoreParam(cores = opt$cores, outfile = Sys.getenv('SGE_STDERR_PATH'))
}

## Obtain rse file for the given project
rse <- coverage_matrix_bwtool(project = project,
    regions = regions, sumsdir = opt$sumsdir, bed = opt$bed,
    url_table = local_url, bpparam = bp)

save(rse, file = paste0('rse_', project, '.Rdata'))

## Reproducibility information
print('Reproducibility information:')
Sys.time()
proc.time()
options(width = 120)
session_info()