port <- as.integer(Sys.getenv("PORT", "8080"))
if (is.na(port) || port < 1) port <- 8080L

plumber::pr("plumber.R") |>
  plumber::pr_run(host = "0.0.0.0", port = port)

