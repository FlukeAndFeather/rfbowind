fit_hmm <- function(tracks) {
  # Process data
  rfbo_move <- prepData(
    dplyr::select(tracks, ID = burst, x, y),
    type = "LL",
    coordNames = c("x", "y")
  )

  # Initial parameters
  rfbo_move_complete <- drop_na(rfbo_move)
  # mixfit() doesn't work with targets! because of how it uses environments?
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
  step_par0 <- c(0.04772447, 0.36786316, 1.25252533,
                 0.02725201, 0.17958237, 0.36818209)
  angle_par0 <- c(-0.01529728, -0.04277677, -0.01149509,
                  2.68410888, 1.66646372, 7.17154479)

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
