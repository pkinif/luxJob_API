add_bearer_auth <- function(api, paths = NULL) {
  api$components <- list(
    securitySchemes = list(
      BearerAuth = list(
        type = "http",
        scheme = "bearer",
        bearerFormat = "JWT",
        description = "Enter a Bearer token like: Bearer abc123"
      )
    )
  )
  
  if (is.null(paths)) paths <- names(api$paths)
  
  for (path in paths) {
    methods <- names(api$paths[[path]])
    for (method in intersect(methods, c("get", "post", "put", "delete", "head"))) {
      api$paths[[path]][[method]] <- c(
        api$paths[[path]][[method]],
        list(security = list(list(BearerAuth = list())))
      )
    }
  }
  
  api
}


plumber::pr("plumber.R") |> 
  plumber::pr_set_api_spec(add_bearer_auth) |>
  plumber::pr_hook("preroute", function(req, res) {
    res$setHeader("Access-Control-Allow-Origin", "http://localhost:1234")
    res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    res$setHeader("Access-Control-Allow-Headers", "API_KEY, Accept")
    res$setHeader("Access-Control-Allow-Credentials", "true")
    if (req$REQUEST_METHOD == "OPTIONS") {
      res$status <- 200
      return(list())
    }
    plumber::forward()
  }) |>
  plumber::pr_run(
    port = 8080,
    host = "0.0.0.0"
  )