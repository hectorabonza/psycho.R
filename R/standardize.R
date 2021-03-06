#' Standardize (scale and reduce) numeric variables.
#'
#' Select numeric variables and standardize (Z-score, "normalize") them.
#'
#' @param df Dataframe.
#' @param subset Character or list of characters of column names to be standardized.
#' @param except Character or list of characters of column names to be excluded from standardized.
#'
#' @return Dataframe.
#'
#' @examples
#' df <- data.frame(
#'   Participant = as.factor(rep(1:50,each=2)),
#'   Condition = base::rep_len(c("A", "B"), 100),
#'   V1 = rnorm(100, 30, .2),
#'   V2 = runif(100, 3, 5),
#'   V3 = rnorm(100, 100, 10)
#'   )
#'
#' dfZ <- standardize(df)
#' dfZ <- standardize(df, except="V3")
#' dfZ <- standardize(df, except=c("V1", "V2"))
#' dfZ <- standardize(df, subset="V3")
#' dfZ <- standardize(df, subset=c("V1", "V2"))
#' dfZ <- standardize(df, subset=c("V1", "V2"), except="V3")
#'
#' summary(dfZ)
#'
#' @author \href{https://dominiquemakowski.github.io/}{Dominique Makowski}
#'
#'
#' @import purrr
#' @import dplyr
#' @export
standardize <- function(df, subset=NULL, except=NULL) {

  # If vector
  if (ncol(as.matrix(df)) == 1) {
    return(as.vector(scale(df)))
  }

  # Variable order
  var_order <- names(df)

  # Keep subset
  if (!is.null(subset) && subset %in% names(df)) {
    to_keep <- as.data.frame(df[!names(df) %in% c(subset)])
    df <- df[names(df) %in% c(subset)]
  } else {
    to_keep <- NULL
  }

  # Remove exceptions
  if (!is.null(except) && except %in% names(df)) {
    if (is.null(to_keep)) {
      to_keep <- as.data.frame(df[except])
    } else {
      to_keep <- cbind(to_keep, as.data.frame(df[except]))
    }

    df <- df[!names(df) %in% c(except)]
  }

  # Remove non-numerics
  dfother <- purrr::discard(df, is.numeric)
  dfnum <- purrr::keep(df, is.numeric)

  # Scale
  dfnum <- as.data.frame(scale(dfnum))

  # Add non-numerics
  if (is.null(ncol(dfother))) {
    df <- dfnum
  } else {
    df <- dplyr::bind_cols(dfother, dfnum)
  }

  # Add exceptions
  if (!is.null(subset) | !is.null(except) && exists("to_keep")) {
    df <- dplyr::bind_cols(df, to_keep)
  }

  # Reorder
  df <- df[var_order]

  return(df)
}
