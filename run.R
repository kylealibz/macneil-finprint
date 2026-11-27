source("R/reproduction.R")
source("R/simulation.R")
source("R/plots.R")
footprint <- reproduce_footprint()
simulation <- simulate_effort()
dir.create("results", showWarnings = FALSE)
out <- list("reproduction" = footprint$totals,
            "model-weights" = reproduce_model_weights(), "sampling-by-location" = footprint$locations,
            "archived-encounters-by-location" = footprint$encounters,
            "simulation-summary" = simulation$summary, "simulation-replicates" = simulation$draws)
for (name in names(out)) write.csv(out[[name]], file.path("results", paste0(name, ".csv")), row.names = FALSE)
writeLines(capture.output(sessionInfo()), "results/session-info.txt")
save_plot("results/finprint-footprint.png", function() plot_footprint(footprint$locations))
save_plot("results/contrast-recovery.png", function() plot_recovery(simulation$draws, simulation$scenarios))
save_plot("results/zero-encounters.png", function() plot_zeros(simulation$summary, simulation$scenarios))
print(footprint$totals, row.names = FALSE)
print(simulation$summary, row.names = FALSE)

