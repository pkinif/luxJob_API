library(httr2)


# Example -----------------------------------------------------------------

resp <- request("http://localhost:8080/skills") |> 
  req_auth_bearer_token("TokenExample1234567890") |> 
  req_url_query(limit = 5) |>    # <- add your query parameter here
  req_perform()

result <- resp |> resp_body_json()
class(result)
class(resp)
print(result)



# Query Parameter ---------------------------------------------------------

call_api <- function(endpoint, token = 'TokenExample1234567890', ...) {
  request(endpoint) |> 
    req_auth_bearer_token(token) |> 
    req_url_query(...) |> 
    req_perform() |> 
    resp_body_json()
}

result <- call_api(
  endpoint = "http://localhost:8080/skills", 
  token = "TokenExample1234567890"
)

result <- call_api(
  endpoint = "http://localhost:8080/skills", 
  token = "TokenExample1234567890",
  limit = 10
)

print(result)


# POST --------------------------------------------------------------------

call_api_post <- function(endpoint, token, ...) {
  # browser()
  request(endpoint) |> 
    req_auth_bearer_token(token) |> 
    req_method("POST") |> 
    req_body_json(list(...)) |> 
    req_perform() |> 
    resp_body_json()
}

result_log_search <- call_api_post(
  endpoint = "http://localhost:8080/log_search",
  token = "TokenExample1234567890",
  query  = "data scientist",
  user_id = 10
)
result_log_search

# URL path parameter -----------------------------------------------------------
call_api_path <- function(base_endpoint, 
                          token = 'TokenExample1234567890', 
                          url_append, 
                          url_encode = T) {
  req <- request(base_endpoint) |> 
    req_auth_bearer_token(token)
  
  if (url_encode) {
    req <- req |> 
      req_url_path_append(utils::URLencode(url_append, reserved = TRUE)) |> 
      req_perform() |> 
      resp_body_json()
  } else {
    req <- req |> 
      req_url_path_append(url_append) |> 
      req_perform() |> 
      resp_body_json()
  }
  return(req)
}


test <- call_api_path(
  base_endpoint = 'http://localhost:8080/skills',
  url_append = 'http://data.europa.eu/esco/skill/97965983-0da4-4902-9daf-d5cd2693ef73'
)

test
