save_plot <- function(path, draw) {
  png(path, width = 1440, height = 850, res = 145)
  on.exit(dev.off())
  draw()
}

plot_footprint <- function(locations) {
  old <- par(mar = c(5, 12, 4, 2))
  on.exit(par(old))
  top <- head(locations[order(-locations$deployments), ], 12)
  top <- top[12:1, ]
  barplot(top$deployments, names.arg = top$location, horiz = TRUE, las = 1,
    border = NA, col = "#14818A", cex.names = .8, xlab = "BRUV deployments",
    main = "Global FinPrint sampling footprint")
  mtext("12 reporting locations with the most deployments", line = .4, cex = .8)
}

plot_recovery <- function(draws, scenarios) {
  old <- par(mar = c(6, 5, 4, 2))
  on.exit(par(old))
  methods <- c("Equal reef weights", "Pooled cameras")
  colors <- c("#14818A", "#BE6237")
  groups <- unlist(lapply(scenarios, function(s) {
    lapply(methods, function(m) 100 * draws$estimate[draws$scenario == s & draws$estimator == m])
  }), recursive = FALSE)
  at <- c(1, 2, 4, 5, 7, 8, 10, 11)
  boxplot(groups, at = at, xaxt = "n", col = colors, outline = FALSE,
          xlab = "", ylab = "Estimated encounter difference (percentage points)",
          main = "Can unequal camera effort distort the reef contrast?", bty = "l")
  axis(1, at = c(1.5, 4.5, 7.5, 10.5), labels = c("Balanced", "Uneven within\ngroups",
    "Uneven between\ngroups", "Effort linked to\nencounter rate"), tick = FALSE)
  abline(h = 100 * draws$truth[1], lty = 2)
  legend("topleft", c(methods, "Known difference"), col = c(colors, "black"),
         lwd = c(5, 5, 1), lty = c(1, 1, 2), bty = "n", cex = .8)
}

plot_zeros <- function(summary, scenarios) {
  old <- par(mar = c(6, 5, 4, 2))
  on.exit(par(old))
  s <- summary[summary$estimator == "Equal reef weights", ]
  s <- s[match(scenarios, s$scenario), ]
  p <- 100 * rbind(s$no_detection_reference, s$no_detection_comparison)
  colors <- c("#244B77", "#CA853C")
  barplot(p, beside = TRUE, border = NA, col = colors, ylim = c(0, max(p)*1.25),
          names.arg = c("Balanced", "Uneven within\ngroups", "Uneven between\ngroups",
                        "Effort linked to\nencounter rate"),
          ylab = "Reefs with no camera encounter (%)", main = "Zero detections depend on camera effort")
  legend("topleft", c("Reference reefs", "Comparison reefs"), fill = colors, bty = "n")
}
