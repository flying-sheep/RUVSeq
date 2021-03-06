setMethod(
          f = "RUVr",
          signature = signature(x="matrix", cIdx="ANY", k="numeric", residuals="matrix"),
          definition = function(x, cIdx, k, residuals, center=TRUE, round=TRUE, epsilon=1, tolerance=1e-8, isLog=FALSE) {

            if(!isLog && !all(.isWholeNumber(x))) {
              warning(paste0("The expression matrix does not contain counts.\n",
                             "Please, pass a matrix of counts (not logged) or set isLog to TRUE to skip the log transformation"))
            }
            
            if(isLog) {
              Y <- t(x)
            } else {
              Y <- t(log(x+epsilon))
            }
            
            
          if(center) {
              E <- apply(residuals, 1, function(x) scale(x, center=TRUE, scale=FALSE))
            } else {
              E <- t(residuals)
            }
            m <- nrow(Y)
            n <- ncol(Y)
            svdWa <- svd(E[, cIdx])
            k <- min(k, max(which(svdWa$d > tolerance)))
            W <- svdWa$u[, (1:k), drop = FALSE]
            alpha <- solve(t(W) %*% W) %*% t(W) %*% Y
            correctedY <- Y - W %*% alpha
            if(!isLog && all(.isWholeNumber(x))) {
                if(round) {
                    correctedY <- round(exp(correctedY) - epsilon)
                    correctedY[correctedY<0] <- 0
                } else {
                    correctedY <- exp(correctedY) - epsilon
                }
            }
            colnames(W) <- paste("W", seq(1, ncol(W)), sep="_")
            return(list(W = W, normalizedCounts = t(correctedY)))
          }
          )

setMethod(
          f = "RUVr",
          signature = signature(x="SeqExpressionSet", cIdx="character", k="numeric", residuals="matrix"),
          definition = function(x, cIdx, k, residuals, center=TRUE, round=TRUE, epsilon=1, tolerance=1e-8, isLog=FALSE) {
            if(!all(cIdx %in% rownames(x))) {
              stop("'cIdx' must contain gene names present in 'x'")
            }
            if(k >= ncol(x)) {
              stop("'k' must be less than the number of samples in 'x'")
            }
            if(any(dim(residuals) != dim(x))) {
              stop("'residuals' must be a matrix with the same dimension of 'x.'")
            }
            if(!all(rownames(residuals)==rownames(x))) {
              stop("The gene names of 'residuals' do not match those of 'x.'")
            }
            if(!all(colnames(residuals)==colnames(x))) {
              stop("The sample names of 'residuals' do not match those of 'x.'")
            }
            if(all(is.na(normCounts(x)))) {
              counts <- counts(x)
            } else {
              counts <- normCounts(x)
            }

            retval <- RUVr(counts, cIdx, k, residuals, center, round, epsilon, tolerance, isLog=isLog)
            newSeqExpressionSet(counts = counts(x),
                                normalizedCounts = retval$normalizedCounts,
                                phenoData = cbind(pData(x), retval$W)
                                )
          }
          )

