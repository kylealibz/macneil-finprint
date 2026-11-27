simulate_effort <- function(replicates = 1000L, seed = 20200722L) {
  set.seed(seed)
  n <- 60L
  probabilities <- c(.20, .35)
  truth <- diff(probabilities)
  k <- 8
  scenarios <- c("Balanced", "Uneven within groups", "Uneven between groups",
                 "Effort linked to encounter rate")
  comparison <- rep(c(FALSE, TRUE), each = n)
  mean_p <- rep(probabilities, each = n)
  run <- function(rep_id) {
    p <- rbeta(2 * n, k * mean_p, k * (1 - mean_p))
    # Generate paired potential BRUV observations, reusing videos across scenarios.
    videos <- matrix(runif(2 * n * 75L), nrow = 2 * n) < p
    uneven <- c(rep(5L, n / 2), rep(75L, n / 2))
    target <- rep(5L, 2L * n)
    reference_high_effort <- order(p[!comparison])[seq_len(n / 2)]
    comparison_high_effort <- n + order(p[comparison], decreasing = TRUE)[seq_len(n / 2)]
    target[c(reference_high_effort, comparison_high_effort)] <- 75L
    efforts <- list(rep(40L, 2L * n), c(sample(uneven), sample(uneven)),
                    rep(c(15L, 65L), each = n), target)
    do.call(rbind, lapply(seq_along(efforts), function(i) {
      m <- efforts[[i]]
      stopifnot(sum(m) == 4800)
      encounters <- rowSums(videos & rep(seq_len(ncol(videos)), each = nrow(videos)) <= m)
      rates <- encounters / m
      estimate <- function(weighted) {
        group <- function(index) {
          r <- rates[index]
          w <- if (weighted) m[index] / sum(m[index]) else rep(1/n, n)
          avg <- sum(w * r)
          # Reef-cluster variance for the weighted mean. For equal weights
          # this reduces to the usual sample variance divided by n.
          var_mean <- n/(n - 1) * sum(w^2 * (r - avg)^2)
          c(mean = avg, variance = var_mean)
        }
        a <- group(!comparison)
        b <- group(comparison)
        difference <- b[1] - a[1]
        margin <- qt(.975, df = n - 1L) * sqrt(a[2] + b[2])
        c(estimate = unname(difference), lower = unname(difference - margin),
          upper = unname(difference + margin))
      }
      values <- rbind(estimate(FALSE), estimate(TRUE))
      data.frame(replicate = rep_id, scenario = scenarios[i],
                 estimator = c("Equal reef weights", "Pooled cameras"),
                 truth, values, total_cameras = sum(m),
                 no_detection_reference = mean(encounters[!comparison] == 0),
                 no_detection_comparison = mean(encounters[comparison] == 0))
    }))
  }
  draws <- do.call(rbind, lapply(seq_len(replicates), run))
  groups <- split(draws, list(draws$scenario, draws$estimator), drop = TRUE)
  summary <- do.call(rbind, lapply(groups, function(d) {
    error <- d$estimate - d$truth
    data.frame(scenario = d$scenario[1], estimator = d$estimator[1],
      replicates = nrow(d), mean_estimate = mean(d$estimate), bias = mean(error),
      rmse = sqrt(mean(error^2)), coverage = mean(d$lower <= d$truth & d$upper >= d$truth),
      positive_interval = mean(d$lower > 0),
      median_interval_width = median(d$upper - d$lower),
      no_detection_reference = mean(d$no_detection_reference),
      no_detection_comparison = mean(d$no_detection_comparison))
  }))
  rownames(summary) <- NULL
  list(draws = draws, summary = summary, scenarios = scenarios)
}
