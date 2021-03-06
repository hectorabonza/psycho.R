context("analyze.stanreg")

test_that("If it works.", {
  # Fit
  require(rstanarm)


  fit <- rstanarm::stan_glm(
    vs ~ mpg * cyl,
    data = mtcars,
    family = binomial(link = "logit"),
    prior = NULL,
    seed = 666
  )

  model <- psycho::analyze(fit)
  values <- psycho::values(model)
  testthat::expect_equal(round(values$mpg$median, 2), -0.64, tolerance = 0.10)


  fit <- rstanarm::stan_glmer(
    Sepal.Length ~ Sepal.Width + (1 | Species),
    data = iris,
    seed = 666
  )

  model <- psycho::analyze(fit, effsize = T)
  values <- psycho::values(model)
  testthat::expect_equal(
    round(values$Sepal.Width$median, 2), 0.79,
    tolerance = 0.05
  )


  data <- standardize(attitude)
  fit <- rstanarm::stan_glm(rating ~ advance + privileges,
    data = data,
    prior = rstanarm::normal(0, 1, autoscale = F),
    seed = 666
  )
  results <- analyze(fit)
  testthat::expect_equal(
    round(results$values$advance$median), 0.01,
    tolerance = 0.025
  )

  data <- standardize(attitude)
  fit <- rstanarm::stan_glm(rating ~ advance + privileges,
    data = data,
    prior = rstanarm::normal(0, 1, autoscale = T),
    seed = 666
  )
  results <- analyze(fit)
  testthat::expect_equal(
    round(results$values$advance$median), 0,
    tolerance = 0.025
  )

  fit <- rstanarm::stan_glm(
    Sepal.Length ~ Sepal.Width,
    data = iris,
    seed = 666,
    algorithm = "meanfield"
  )

  model <- psycho::analyze(fit, effsize = T)
  values <- psycho::values(model)
  testthat::expect_equal(
    round(values$Sepal.Width$median, 2), -0.46,
    tolerance = 0.05
  )
})
