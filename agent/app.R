library(shiny)
library(bslib)
library(ellmer)
library(shinychat)
library(httr2)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
API_BASE <- Sys.getenv("LUXJOB_API_URL", "http://localhost:8080")

SYSTEM_PROMPT <- paste(
  "You are a helpful Luxembourg job-market assistant.",
  "You help users explore job vacancies, companies, skills,",
  "learning tracks and book recommendations available in Luxembourg.",
  "Use the tools provided to look up real data — never invent job listings.",
  "When presenting results, format them clearly with bullet points or tables.",
  "If a query returns no results, say so and suggest broadening the search.",
  "Always reply in the same language the user writes in."
)

# ---------------------------------------------------------------------------
# Helper: call the Plumber API
# ---------------------------------------------------------------------------
api_get <- function(path, query = list()) {
  query <- Filter(Negate(is.null), query)
  resp <- request(API_BASE) |>
    req_url_path_append(path) |>
    req_url_query(!!!query) |>
    req_perform()
  resp_body_json(resp)
}

# ---------------------------------------------------------------------------
# Tool definitions
# ---------------------------------------------------------------------------
tool_search_vacancies <- tool(
  function(skill = NULL, company = NULL, canton = NULL, limit = 20) {
    api_get("/vacancies", list(
      skill   = skill,
      company = company,
      canton  = canton,
      limit   = limit
    ))
  },
  name = "search_vacancies",
  description = paste(
    "Search for job vacancies in Luxembourg.",
    "Can filter by skill ID, company ID, and/or canton name.",
    "Returns a list of matching vacancies with job title, company, location, etc."
  ),
  arguments = list(
    skill   = type_string("ESCO skill URI to filter by (e.g. 'http://data.europa.eu/esco/skill/...')", required = FALSE),
    company = type_integer("Company ID to filter by", required = FALSE),
    canton  = type_string("Canton name to filter by (e.g. 'Luxembourg', 'Esch-sur-Alzette')", required = FALSE),
    limit   = type_integer("Max results to return (default 20)", required = FALSE)
  )
)

tool_get_skills <- tool(
  function(limit = 50) {
    api_get("/skills", list(limit = limit))
  },
  name = "get_skills",
  description = "List available skills. Useful for discovering skill IDs to use in vacancy searches.",
  arguments = list(
    limit = type_integer("Max number of skills to return (default 50)", required = FALSE)
  )
)

tool_get_skill_by_id <- tool(
  function(skill_id) {
    api_get(paste0("/skills/", URLencode(skill_id, reserved = TRUE)))
  },
  name = "get_skill_by_id",
  description = "Get details for a specific skill by its ESCO URI.",
  arguments = list(
    skill_id = type_string("The ESCO skill URI")
  )
)

tool_get_companies <- tool(
  function(limit = 50) {
    api_get("/companies", list(limit = limit))
  },
  name = "get_companies",
  description = "List companies that have job vacancies in Luxembourg.",
  arguments = list(
    limit = type_integer("Max number of companies to return (default 50)", required = FALSE)
  )
)

tool_get_company_details <- tool(
  function(company_id) {
    api_get(paste0("/companies/", company_id))
  },
  name = "get_company_details",
  description = "Get detailed information about a specific company.",
  arguments = list(
    company_id = type_integer("The company ID")
  )
)

tool_get_vacancy_details <- tool(
  function(vacancy_id) {
    api_get(paste0("/vacancies/", vacancy_id))
  },
  name = "get_vacancy_details",
  description = "Get full details of a specific job vacancy.",
  arguments = list(
    vacancy_id = type_integer("The vacancy ID")
  )
)

tool_get_learning_tracks <- tool(
  function(skill_id = NULL) {
    api_get("/learning_tracks", list(skill_id = skill_id))
  },
  name = "get_learning_tracks",
  description = "Get learning tracks (training / upskilling paths). Optionally filter by skill.",
  arguments = list(
    skill_id = type_string("ESCO skill URI to filter by", required = FALSE)
  )
)

tool_get_learning_track_by_id <- tool(
  function(track_id) {
    api_get(paste0("/learning_tracks/", track_id))
  },
  name = "get_learning_track_by_id",
  description = "Get details of a specific learning track.",
  arguments = list(
    track_id = type_integer("The learning track ID")
  )
)

tool_get_books <- tool(
  function(skill = NULL) {
    api_get("/books", list(skill = skill))
  },
  name = "get_books",
  description = "Get book recommendations, optionally filtered by skill.",
  arguments = list(
    skill = type_string("ESCO skill URI to filter by", required = FALSE)
  )
)

tool_get_book_by_id <- tool(
  function(book_id) {
    api_get(paste0("/books/", book_id))
  },
  name = "get_book_by_id",
  description = "Get details of a specific book.",
  arguments = list(
    book_id = type_integer("The book ID")
  )
)

ALL_TOOLS <- list(
  tool_search_vacancies,
  tool_get_skills,
  tool_get_skill_by_id,
  tool_get_companies,
  tool_get_company_details,
  tool_get_vacancy_details,
  tool_get_learning_tracks,
  tool_get_learning_track_by_id,
  tool_get_books,
  tool_get_book_by_id
)

# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------
ui <- page_fillable(
  title = "luxJob Agent",
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#2c3e50"
  ),
  layout_sidebar(
    sidebar = sidebar(
      title = "luxJob Agent",
      width = 280,
      p("Ask me anything about the Luxembourg job market:"),
      tags$ul(
        tags$li("Search vacancies by skill or location"),
        tags$li("Explore companies"),
        tags$li("Find learning tracks"),
        tags$li("Get book recommendations")
      ),
      hr(),
      p(class = "text-muted small", "Powered by Claude + ellmer")
    ),
    chat_ui("chat", placeholder = "e.g. Show me IT jobs in Luxembourg city")
  )
)

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------
server <- function(input, output, session) {
  chat_client <- chat_anthropic(
    system_prompt = SYSTEM_PROMPT,
    model = "claude-sonnet-4-20250514"
  )

  for (t in ALL_TOOLS) {
    chat_client$register_tool(t)
  }

  observeEvent(input$chat_user_input, {
    stream <- chat_client$stream_async(
      input$chat_user_input,
      stream = "content"
    )
    chat_append("chat", stream)
  })
}

shinyApp(ui, server)
