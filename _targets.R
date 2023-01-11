# Load packages required to define the pipeline:
library(here)
library(targets)
# library(tarchetypes) # Load other packages as needed. # nolint

# Set target options:
tar_option_set(
  packages = c("adehabitatLT", "lubridate", "tidyverse"), # packages that your targets need to run
  format = "rds" # default storage format
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()

# Replace the target list below with your own:
list(
  tar_target(
    name = rfbo_path,
    command = here("analysis", "data", "raw_data", "RFBO_eObs_clean.csv"),
    format = "file"
  ),
  tar_target(
    name = rfbo_tracks,
    command = get_tracks(rfbo_path)
  )
)
