#' Analyze stanreg objects.
#'
#' Analyze stanreg objects.
#'
#' @param x A stanreg model.
#' @param CI Credible interval bounds.
#' @param effsize Compute Effect Sizes according to Cohen (1988)? Your outcome variable must be standardized.
#' @param ... Arguments passed to or from other methods.
#'
#' @return output
#'
#' @examples
#' \dontrun{
#' library(psycho)
#' library(rstanarm)
#'
#' data <- standardize(attitude)
#' fit <- rstanarm::stan_glm(rating ~ advance + privileges, data=data)
#'
#' results <- analyze(fit, effsize=TRUE)
#' summary(results)
#' plot(results)
#' print(results)
#'
#' fit <- rstanarm::stan_glmer(Sepal.Length ~ Sepal.Width + (1|Species), data=iris)
#' results <- analyze(fit)
#' summary(results)
#' }
#'
#' @author \href{https://dominiquemakowski.github.io/}{Dominique Makowski}
#'
#' @import rstanarm
#' @import tidyr
#' @import dplyr
#' @import ggplot2
#' @importFrom stats quantile as.formula
#' @importFrom utils head tail
#' @importFrom broom tidy
#' @export
analyze.stanreg <- function(x, CI=90, effsize=FALSE, ...) {


  # Processing
  # -------------
  fit <- x

  predictors <- all.vars(as.formula(fit$formula))
  outcome <- predictors[[1]]
  predictors <- tail(predictors, -1)

  # Extract posterior distributions
  posteriors <- as.data.frame(fit)

  # Varnames
  varnames <- names(fit$coefficients)
  varnames <- varnames[grepl("b\\[", varnames) == FALSE]

  # Priors
  info_priors <- rstanarm::prior_summary(fit)


  # R2 ----------------------------------------------------------------------
  if ("R2" %in% names(posteriors)) {
    varnames <- c(varnames, "R2")
    R2 <- TRUE
  } else {
    posteriors$R2 <- tryCatch({
      rstanarm::bayes_R2(fit)
    }, error = function(e) {
      0
    })

    if (all(posteriors$R2 == 0)) {
      R2 <- FALSE
    } else {
      R2 <- TRUE
    }

    varnames <- c(varnames, "R2")
  }




  # Random effect info --------------------------------------------
  mixed <- tryCatch({
    broom::tidy(fit, parameters = "varying")
    TRUE
  }, error = function(e) {
    FALSE
  })

  if (mixed == TRUE) {
    random_info <- broom::tidy(fit, parameters = "varying") %>%
      dplyr::rename_(
        "Median" = "estimate",
        "MAD" = "std.error"
      )
  }



  # Get indices of each variable --------------------------------------------

  # Initialize empty values
  values <- list()
  # Loop over all variables
  for (varname in varnames) {




    # Prior
    # TBD: this doesn't work with categorical predictors :(
    info_prior <- list()
    if (varname %in% predictors) {
      predictor_index <- which(predictors == varname)
      if (length(info_priors$prior$dist) == 1) {
        info_priors$prior$dist <- rep(
          info_priors$prior$dist,
          length(info_priors$prior$location)
        )
      }
      info_prior["distribution"] <- info_priors$prior$dist[predictor_index]
      info_prior["location"] <- info_priors$prior$location[predictor_index]
      info_prior["scale"] <- info_priors$prior$scale[predictor_index]
      info_prior["adjusted_scale"] <- info_priors$prior$adjusted_scale[predictor_index]
    }

    if (varname == "(Intercept)") {
      info_prior["distribution"] <- info_priors$prior_intercept$dist
      info_prior["location"] <- info_priors$prior_intercept$location
      info_prior["scale"] <- info_priors$prior_intercept$scale
      info_prior["adjusted_scale"] <- info_priors$prior_intercept$adjusted_scale
    }




    # Extract posterior
    posterior <- posteriors[, varname]

    if (varname == "R2" & R2 == FALSE) {
      text <- ""
      median <- "unavailable"
      mad <- "unavailable"
      mean <- "unavailable"
      sd <- "unavailable"
      CI_values <- "unavailable"
      CI_values <- "unavailable"
      MPE <- "unavailable"
      MPE_values <- "unavailable"
    } else {
      # Find basic posterior indices
      median <- median(posterior)
      mad <- mad(posterior)
      mean <- mean(posterior)
      sd <- sd(posterior)
      CI_values <- hdi(posterior, prob = CI / 100)
      CI_values <- c(CI_values$values$HDImin, CI_values$values$HDImax)

      # Compute MPE
      MPE <- mpe(posterior)$MPE
      MPE_values <- mpe(posterior)$values




      # Create text
      if (grepl(":", varname)) {
        splitted <- strsplit(varname, ":")[[1]]
        if (length(splitted) == 2) {
          name <- paste0(
            "interaction effect between ",
            splitted[1], " and ", splitted[2]
          )
        } else {
          name <- varname
        }
      } else {
        name <- paste0("effect of ", varname)
      }

      text <- paste0(
        "   - The ", name, " has a probability of ",
        format_digit(MPE), "% that its coefficient is between ",
        format_digit(MPE_values[1], null_treshold = 0.0001), " and ",
        format_digit(MPE_values[2], null_treshold = 0.0001),
        " (Median = ", format_digit(median, null_treshold = 0.0001),
        ", MAD = ", format_digit(mad, null_treshold = 0.0001),
        # ", Mean = ", format_digit(mean),
        # ", SD = ", format_digit(sd),
        ", ", CI, "% CI [",
        format_digit(CI_values[1], null_treshold = 0.0001), ", ",
        format_digit(CI_values[2], null_treshold = 0.0001), "], ",
        "MPE = ", format_digit(MPE), "%)."
      )

      if (varname == "(Intercept)") {
        text <- paste0(
          "The model's intercept is at ",
          format_digit(median(posterior)),
          " (MAD = ",
          format_digit(mad(posterior)),
          ", ",
          CI,
          "% CI [",
          format_digit(CI_values[1], null_treshold = 0.0001),
          ", ",
          format_digit(CI_values[2], null_treshold = 0.0001),
          "]). Within this model:"
        )
      }

      if (varname == "R2") {
        text <- paste0(
          "The model explains between ",
          format_digit(min(posterior) * 100),
          "% and ",
          format_digit(max(posterior) * 100),
          "% of the outcome's variance (R2's median = ",
          format_digit(median(posterior)),
          ", MAD = ",
          format_digit(mad(posterior)),
          ", ",
          CI,
          "% CI [",
          format_digit(CI_values[1], null_treshold = 0.0001),
          ", ",
          format_digit(CI_values[2], null_treshold = 0.0001),
          "]). "
        )
      }
    }


    # Store all indices
    values[[varname]] <- list(
      name = varname,
      median = median,
      mad = mad,
      mean = mean,
      sd = sd,
      CI_values = CI_values,
      MPE = MPE,
      MPE_values = MPE_values,
      posterior = posterior,
      text = text,
      prior = info_prior
    )
  }






  # Effect Sizes ------------------------------------------------------------
  if (effsize == T) {

    # Check if standardized
    model_data <- fit$data
    model_data <- model_data[all.vars(as.formula(fit$formula))]
    standardized <- is.standardized(model_data)
    if (standardized == FALSE) {
      warning("It seems that your data was not standardized... Interpret effect sizes with caution!")
    }


    EffSizes <- data.frame()
    for (varname in varnames) {
      if (varname == "R2") {
        values[[varname]]$EffSize <- NA
        values[[varname]]$EffSize_text <- NA
        values[[varname]]$EffSize_VL <- NA
        values[[varname]]$EffSize_L <- NA
        values[[varname]]$EffSize_M <- NA
        values[[varname]]$EffSize_S <- NA
        values[[varname]]$EffSize_VS <- NA
        values[[varname]]$EffSize_O <- NA
      } else {
        EffSize <- interpret_d_posterior(posteriors[, varname])

        EffSize_table <- EffSize$table
        EffSize_table$Variable <- varname
        EffSizes <- rbind(EffSizes, EffSize_table)

        values[[varname]]$EffSize <- EffSize_table
        values[[varname]]$EffSize_text <- EffSize$text

        values[[varname]]$EffSize_VL <- EffSize$probs$VeryLarge
        values[[varname]]$EffSize_L <- EffSize$probs$Large
        values[[varname]]$EffSize_M <- EffSize$probs$Medium
        values[[varname]]$EffSize_S <- EffSize$probs$Small
        values[[varname]]$EffSize_VS <- EffSize$probs$VerySmall
        values[[varname]]$EffSize_O <- EffSize$probs$Opposite
      }
    }
  }


  # Summary --------------------------------------------------------------------
  if (R2 == TRUE) {
    varnames_for_summary <- varnames
  } else {
    varnames_for_summary <- varnames[varnames != "R2"]
  }

  summary <- data.frame()
  for (varname in varnames_for_summary) {
    summary <- rbind(
      summary,
      data.frame(
        Variable = varname,
        MPE = values[[varname]]$MPE,
        Median = values[[varname]]$median,
        MAD = values[[varname]]$mad,
        Mean = values[[varname]]$mean,
        SD = values[[varname]]$sd,
        CI_lower = values[[varname]]$CI_values[1],
        CI_higher = values[[varname]]$CI_values[2]
      )
    )
  }

  if (effsize == T) {
    EffSizes <- data.frame()
    for (varname in varnames_for_summary) {
      Current <- data.frame(
        Very_Large = values[[varname]]$EffSize_VL,
        Large = values[[varname]]$EffSize_L,
        Medium = values[[varname]]$EffSize_M,
        Small = values[[varname]]$EffSize_S,
        Very_Small = values[[varname]]$EffSize_VS,
        Opposite = values[[varname]]$EffSize_O
      )
      EffSizes <- rbind(EffSizes, Current)
    }
    summary <- cbind(summary, EffSizes)
  }



  # Text --------------------------------------------------------------------

  # Model
  if (effsize) {
    info_effsize <- " Effect sizes are based on Cohen (1988) recommandations."
  } else {
    info_effsize <- ""
  }

  info <- paste0(
    "We fitted a Markov Chain Monte Carlo ",
    fit$family$family,
    " (link = ",
    fit$family$link,
    ") model to predict ",
    outcome,
    " (formula = ", format(fit$formula),
    ").",
    info_effsize,
    " Priors were set as follows: "
  )

  # Priors
  if ("adjusted_scale" %in% names(info_priors$prior) & !is.null(info_priors$prior$adjusted_scale)) {
    scale <- paste0(
      "), scale = (",
      paste(sapply(info_priors$prior$adjusted_scale, format_digit), collapse = ", ")
    )
  } else {
    scale <- paste0(
      "), scale = (",
      paste(sapply(info_priors$prior$scale, format_digit), collapse = ", ")
    )
  }

  info_priors_text <- paste0(
    "  ~ ",
    info_priors$prior$dist,
    " (location = (",
    paste(info_priors$prior$location, collapse = ", "),
    scale,
    "))"
  )

  # Coefs
  coefs_text <- c()
  for (varname in names(values)) {
    coefs_text <- c(coefs_text, values[[varname]]$text)
    if (effsize == TRUE) {
      if (!varname %in% c("(Intercept)", "R2")) {
        coefs_text <- c(coefs_text, values[[varname]]$EffSize_text, "")
      }
    }
  }
  text <- c(info, "", info_priors_text, "", "", paste0(tail(coefs_text, 1), head(coefs_text, 1)), "", head(tail(coefs_text, -1), -1))



  # Plot --------------------------------------------------------------------

  plot <- posteriors[varnames] %>%
    # select(-`(Intercept)`) %>%
    gather() %>%
    rename_(Variable = "key", Coefficient = "value") %>%
    ggplot(aes_string(x = "Variable", y = "Coefficient", fill = "Variable")) +
    geom_violin() +
    geom_boxplot(fill = "grey", alpha = 0.3, outlier.shape = NA) +
    stat_summary(
      fun.y = "mean", geom = "errorbar",
      aes_string(ymax = "..y..", ymin = "..y.."),
      width = .75, linetype = "dashed", colour = "red"
    ) +
    geom_hline(aes(yintercept = 0)) +
    theme_classic() +
    coord_flip() +
    scale_fill_brewer(palette = "Set1") +
    scale_colour_brewer(palette = "Set1")




  if (mixed == TRUE) {
    output <- list(text = text, plot = plot, summary = summary, values = values, random = random_info)
  } else {
    output <- list(text = text, plot = plot, summary = summary, values = values)
  }

  class(output) <- c("psychobject", "list")
  return(output)
}
