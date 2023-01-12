fit_hmm <- function(tracks) {
  # mixfit() doesn't work with targets! because of how it uses environments?
  # tracks <- tar_read("rfbo_tracks_clean")

  # Process data
  rfbo_move <- prepData(
    dplyr::select(tracks, ID = burst, x, y),
    type = "LL",
    coordNames = c("x", "y")
  )

  # Initial parameters
  rfbo_move_complete <- drop_na(rfbo_move)
  # step_mix <- mixfit(
  #   rfbo_move_complete$step,
  #   ncomp = 3,
  #   family = "gamma"
  # )
  # step_par0 <- c(step_mix$mu,
  #                step_mix$sd)
  # angle_summary <- rfbo_move_complete %>%
  #   mutate(state0 = apply(step_mix$comp.prob, 1, which.max)) %>%
  #   group_by(state0) %>%
  #   summarize(kappa = est.kappa(angle),
  #             angle_mean = circ.mean(angle))
  # angle_par0 <- c(angle_summary$angle_mean,
  #                 angle_summary$kappa)
  step_par0 <- c(0.04862000, 0.38454036, 1.26205033,
                 0.02178526, 0.18278770, 0.29642142)
  angle_par0 <- c(0.008038844, -0.010528904, -0.010428729,
                  2.547351225, 1.322956452, 6.498919447)

  # Fit model
  fitHMM(
    data = rfbo_move,
    nbStates = 3,
    stepPar0 = step_par0,
    anglePar0 = angle_par0,
    stepDist = "gamma",
    angleDist = "vm"
  )
}
