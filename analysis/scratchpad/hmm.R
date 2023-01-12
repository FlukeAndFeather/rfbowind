library(mixR)
library(moveHMM)
library(tidyverse)

rfbo_tracks <- tar_read("rfbo_tracks")

# Process data
rfbo_move <- prepData(
  dplyr::select(rfbo_tracks, ID = burst, x, y),
  type = "LL",
  coordNames = c("x", "y")
)

# Initial parameters
rfbo_move_complete <- drop_na(rfbo_move)
step_mix <- mixfit(
  rfbo_move_complete$step,
  ncomp = 3,
  family = "gamma"
)
step_par0 <- c(step_mix$mu,
               step_mix$sd)
angle_summary <- rfbo_move_complete %>%
  mutate(state0 = apply(step_mix$comp.prob, 1, which.max)) %>%
  group_by(state0) %>%
  summarize(kappa = est.kappa(angle),
            angle_mean = circ.mean(angle))
angle_par0 <- c(angle_summary$angle_mean,
                angle_summary$kappa)

# Fit model
rfbo_hmm <- fitHMM(
  data = rfbo_move,
  nbStates = 3,
  stepPar0 = step_par0,
  anglePar0 = angle_par0,
  stepDist = "gamma",
  angleDist = "vm"
)

# Decode
rfbo_tracks2 <- mutate(rfbo_tracks, state = viterbi(rfbo_hmm))
