port <- as.integer(Sys.getenv("PORT", "8008"))
if (is.na(port) || port < 1) port <- 8008L

plumber::pr("plumber.R") |>
  plumber::pr_run(host = "0.0.0.0", port = port)
