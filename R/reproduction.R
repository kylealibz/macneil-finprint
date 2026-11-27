reproduce_footprint <- function() {
  monthly <- read.csv("data/Sampling_summaries.csv", check.names = FALSE)
  reefs <- read.csv("data/ReefCheck.csv")
  encounter <- read.csv("data/Mean_ReefAbsence.csv", check.names = FALSE)
  month_names <- as.character(seq_len(12))
  stopifnot(all(month_names %in% names(monthly)), !anyDuplicated(reefs$Reef_ID),
            !anyDuplicated(monthly$location_name), !anyDuplicated(encounter$Location))
  deployments <- rowSums(monthly[month_names])
  # The notebook computes the fraction with p_set > 0, despite the CSV header.
  positive <- encounter$Nreefs * encounter[["Mean_P(no_sharks)"]]
  stopifnot(all(abs(positive - round(positive)) < 1e-5),
            sum(encounter$Nreefs) == nrow(reefs))
  observed <- c(sum(deployments), nrow(reefs), length(unique(reefs$Location)),
                sum(encounter$Nreefs - round(positive)))
  totals <- data.frame(
    metric = c("BRUV deployments", "Surveyed reefs", "Reporting locations",
               "Reefs with no shark encounter"),
    archive = observed, paper = c(15165, 371, 58, 69))
  totals$archive_minus_paper <- totals$archive - totals$paper
  stopifnot(all(totals$archive_minus_paper[1:3] == 0))
  list(totals = totals,
       locations = data.frame(location = monthly$location_name, deployments),
       encounters = data.frame(location = encounter$Location, reefs = encounter$Nreefs,
                               positive_reefs = round(positive),
                               zero_reefs = encounter$Nreefs - round(positive)))
}

reproduce_model_weights <- function() {
  archive <- read.csv("data/ModelCompLoo.csv", row.names = 1)
  stopifnot(abs(sum(archive$weight) - 1) < 1e-8,
            all(archive$loo_scale == "deviance"))
  weight <- round(100 * archive$weight)
  stopifnot(weight[rownames(archive) == "ZINB_full"] == 77,
            weight[rownames(archive) == "ZINB_full_count"] == 16)
  data.frame(model = rownames(archive), rank = archive$rank + 1L,
             loo_deviance = archive$loo, delta_loo = archive$d_loo,
             weight_percent = 100 * archive$weight, paper_scale_percent = weight)
}
