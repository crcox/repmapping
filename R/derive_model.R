#!/usr/bin/env Rscript
library("argparser")

## local functions
cosineDist <- function(x){
  as.dist((1 - (x%*%t(x)))/(sqrt(rowSums(x^2) %*% t(rowSums(x^2)))))
}
## (end) local functions

varargin <- commandArgs(TRUE)
p <- arg_parser("Generate n-dimension model from feature norms.")
p <- add_argument(p, 'd', help="The number of components to include in the model.", type="numeric")
p <- add_argument(p, 'feature_file', help="File containing a word x feature matrix.", type="character")
args <- parse_args(p, varargin)

dimension <- args[['d']]
feature_file <- args[['feature_file']]
#model_file <- args[['output']]

stopifnot(file.exists(feature_file))

x <- read.csv(feature_file, header=FALSE)
if (is.factor(x[,1])) {
  row.names(x) <- x[,1]
  x[,1] <- NULL
}
for (j in 1:ncol(x)) {
  if (is.factor(x[,j])) {
    x[,j] <- as.numeric(as.character(x[,j]))
  }
}
m <- as.matrix(x)
m <- m[,colSums(m!=0)>0] # drop factors that are always zero
d <- cosineDist(m)
#pca <- princomp(d)
#model <- pca$scores[,1:dimension]
model <- cmdscale(d, k=dimension)
write.csv(model, file=stdout(), quote=FALSE)
