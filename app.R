library(shiny)
library(bslib)
library(httr2)
library(rhino)
library(DT)
library(shinybusy)
library(plotly)

# Custom theme with green accents
custom_theme <- bs_theme(
  version = 5,
  bootswatch = "flatly",
  primary = "#28a745",
  secondary = "#007bff",
  success = "#28a745",
  base_font = font_google("Roboto"),
  heading_font = font_google("Roboto"),
  bg = "#f8f9fa",
  fg = "#212529",
  "table-border-color" = "#dee2e6",
  "card-cap-bg" = "#ffffff",
  "card-border-color" = "#dee2e6"
) |>
  bs_add_rules(
    "
    .sidebar { background: linear-gradient(180deg, #ffffff, #e9ecef); }
    .nav-tabs .nav-link.active { background-color: #28a745 !important; color: white !important; }
    .btn-refresh { transition: all 0.3s; }
    .btn-refresh:hover { transform: scale(1.05); }
    .dt-green { background-color: #e6f4ea !important; }
    "
  )

# API call function
call_api <- function(endpoint, token, ...) {
  if (is.null(token) || token == "") {
    return(list(error = "Please provide a valid API token"))
  }
  tryCatch({
    response <- request(endpoint) |>
      req_auth_bearer_token(token) |>
      req_url_query(...) |>
      req_perform()
    list(
      status = resp_status(response),
      data = resp_body_json(response)
    )
  }, error = function(e) {
    list(
      status = if (grepl("404", e$message)) 404 else NULL,
      error = paste("API request failed:", e$message)
    )
  })
}

# UI
ui <- page_sidebar(
  title = tags$div(
    class = "d-flex align-items-center",
    icon("database", class = "me-2", style = "color: #28a745;"),
    "API Data Explorer"
  ),
  sidebar = sidebar(
    title = "Control Panel",
    class = "sidebar p-3",
    passwordInput("token", "API Token", value = "TokenExample1234567890"),
    numericInput("limit", "Result Limit", value = 5, min = 1, max = 100),
    actionButton(
      "refresh",
      "Refresh Data",
      icon = icon("sync"),
      class = "btn-success btn-refresh w-100"
    )
  ),
  navset_card_tab(
    nav_panel(
      "Skills",
      card(
        card_header(class = "bg-success text-white", "Skills Visualization"),
        card_body(
          add_busy_spinner(spin = "fading-circle", color = "#28a745"),
          plotlyOutput("skills_chart", height = "300px")
        ),
        full_screen = TRUE
      ),
      card(
        card_header(class = "bg-success text-white", "Skills Data"),
        card_body(DTOutput("skills_table")),
        full_screen = TRUE
      )
    ),
    nav_panel(
      "Companies",
      card(
        card_header(class = "bg-success text-white", "Companies Visualization"),
        card_body(
          add_busy_spinner(spin = "fading-circle", color = "#28a745"),
          plotlyOutput("companies_chart", height = "300px")
        ),
        full_screen = TRUE
      ),
      card(
        card_header(class = "bg-success text-white", "Companies Data"),
        card_body(DTOutput("companies_table")),
        full_screen = TRUE
      )
    ),
    nav_panel(
      "Vacancies",
      card(
        card_header(class = "bg-success text-white", "Vacancies Visualization"),
        card_body(
          add_busy_spinner(spin = "fading-circle", color = "#28a745"),
          plotlyOutput("vacancies_chart", height = "300px")
        ),
        full_screen = TRUE
      ),
      card(
        card_header(class = "bg-success text-white", "Vacancies Data"),
        card_body(DTOutput("vacancies_table")),
        full_screen = TRUE
      )
    ),
    nav_panel(
      "Learning Tracks",
      card(
        card_header(class = "bg-success text-white", "Learning Tracks Visualization"),
        card_body(
          add_busy_spinner(spin = "fading-circle", color = "#28a745"),
          plotlyOutput("learning_tracks_chart", height = "300px")
        ),
        full_screen = TRUE
      ),
      card(
        card_header(class = "bg-success text-white", "Learning Tracks Data"),
        card_body(DTOutput("learning_tracks_table")),
        full_screen = TRUE
      )
    ),
    nav_panel(
      "Books",
      card(
        card_header(class = "bg-success text-white", "Books Visualization"),
        card_body(
          add_busy_spinner(spin = "fading-circle", color = "#28a745"),
          plotlyOutput("books_chart", height = "300px")
        ),
        full_screen = TRUE
      ),
      card(
        card_header(class = "bg-success text-white", "Books Data"),
        card_body(DTOutput("books_table")),
        full_screen = TRUE
      )
    ),
    card_footer("Data fetched from API with authentication")
  ),
  theme = custom_theme
)

# Server
server <- function(input, output, session) {
  # Hardcoded endpoint URLs
  endpoints <- list(
    skills = "http://localhost:8080/skills",
    companies = "http://localhost:8080/companies",
    vacancies = "http://localhost:8080/vacancies",
    learning_tracks = "http://localhost:8080/learning_tracks",
    books = "http://localhost:8080/books"
  )

  # Reactive trigger for refresh
  refresh_trigger <- reactiveVal(0)
  observeEvent(input$refresh, {
    refresh_trigger(refresh_trigger() + 1)
    showNotification("Fetching data from API...", type = "message", duration = 3)
  })

  # Reactive API calls
  skills_data <- reactive({
    refresh_trigger()
    call_api(endpoint = endpoints$skills, token = input$token, limit = input$limit)
  })

  companies_data <- reactive({
    refresh_trigger()
    call_api(endpoint = endpoints$companies, token = input$token, limit = 25) # Fixed limit of 25
  })

  vacancies_data <- reactive({
    refresh_trigger()
    call_api(endpoint = endpoints$vacancies, token = input$token, limit = input$limit)
  })

  learning_tracks_data <- reactive({
    refresh_trigger()
    call_api(endpoint = endpoints$learning_tracks, token = input$token, limit = input$limit)
  })

  books_data <- reactive({
    refresh_trigger()
    call_api(endpoint = endpoints$books, token = input$token, limit = input$limit)
  })

  # Debug API responses
  observe({
    print("Skills API Response:")
    print(skills_data())
    print("Companies API Response:")
    print(companies_data())
    print("Vacancies API Response:")
    print(vacancies_data())
    print("Learning Tracks API Response:")
    print(learning_tracks_data())
    print("Books API Response:")
    print(books_data())
  })

  # Render Skills Chart (Blue)
  output$skills_chart <- renderPlotly({
    result <- skills_data()
    if (!is.null(result$error)) {
      plot_ly() |> add_text(x = 0.5, y = 0.5, text = paste("Error:", result$error), textposition = "middle center")
    } else if (result$status != 200) {
      plot_ly() |> add_text(x = 0.5, y = 0.5, text = paste("HTTP Error:", result$status, "- Check endpoint or token"), textposition = "middle center")
    } else {
      data <- result$data
      if (length(data) == 0 || !all(c("skill", "frequency") %in% names(data[[1]]))) {
        plot_ly() |> add_text(x = 0.5, y = 0.5, text = "Invalid data: Expected 'skill' and 'frequency' fields", textposition = "middle center")
      } else {
        df <- do.call(rbind, lapply(data, as.data.frame))
        plot_ly(
          data = df,
          x = ~skill,
          y = ~frequency,
          type = "bar",
          marker = list(color = "#1f77b4"),
          text = ~frequency,
          textposition = "auto"
        ) |>
          layout(
            title = "Skill Frequencies",
            xaxis = list(title = "Skill", tickangle = 45),
            yaxis = list(title = "Frequency"),
            margin = list(b = 100),
            showlegend = FALSE
          )
      }
    }
  })

  # Render Skills Table
  output$skills_table <- renderDT({
    result <- skills_data()
    if (!is.null(result$error)) {
      showNotification(result$error, type = "error", duration = 5)
      datatable(data.frame(Error = result$error))
    } else if (result$status != 200) {
      showNotification(paste("HTTP Error:", result$status), type = "error", duration = 5)
      datatable(data.frame(Error = paste("HTTP Error:", result$status)))
    } else {
      data <- result$data
      datatable(
        do.call(rbind, lapply(data, as.data.frame)),
        options = list(
          pageLength = 10,
          dom = "tip",
          columnDefs = list(list(className = "dt-green", targets = "_all"))
        ),
        style = "bootstrap5",
        class = "table table-hover table-bordered"
      )
    }
  })

  # Render Companies Chart (Orange)
  output$companies_chart <- renderPlotly({
    result <- companies_data()
    if (!is.null(result$error)) {
      plot_ly() |> add_text(x = 0.5, y = 0.5, text = paste("Error:", result$error), textposition = "middle center")
    } else if (result$status != 200) {
      plot_ly() |> add_text(x = 0.5, y = 0.5, text = paste("HTTP Error:", result$status, "- Check endpoint or token"), textposition = "middle center")
    } else {
      data <- result$data
      if (length(data) == 0 || !all(c("company", "employees") %in% names(data[[1]]))) {
        plot_ly() |> add_text(x = 0.5, y = 0.5, text = "Invalid data: Expected 'company' and 'employees' fields", textposition = "middle center")
      } else {
        df <- do.call(rbind, lapply(data, as.data.frame))
        plot_ly(
          data = df,
          x = ~company,
          y = ~employees,
          type = "bar",
          marker = list(color = "#ff7f0e"),
          text = ~employees,
          textposition = "auto"
        ) |>
          layout(
            title = "Company Employees",
            xaxis = list(title = "Company", tickangle = 45),
            yaxis = list(title = "Employees"),
            margin = list(b = 100),
            showlegend = FALSE
          )
      }
    }
  })

  # Render Companies Table
  output$companies_table <- renderDT({
    result <- companies_data()
    if (!is.null(result$error)) {
      showNotification(result$error, type = "error", duration = 5)
      datatable(data.frame(Error = result$error))
    } else if (result$status != 200) {
      showNotification(paste("HTTP Error:", result$status), type = "error", duration = 5)
      datatable(data.frame(Error = paste("HTTP Error:", result$status)))
    } else {
      data <- result$data
      datatable(
        do.call(rbind, lapply(data, as.data.frame)),
        options = list(
          pageLength = 10,
          dom = "tip",
          columnDefs = list(list(className = "dt-green", targets = "_all"))
        ),
        style = "bootstrap5",
        class = "table table-hover table-bordered"
      )
    }
  })

  # Render Vacancies Chart (Red)
  output$vacancies_chart <- renderPlotly({
    result <- vacancies_data()
    if (!is.null(result$error)) {
      plot_ly() |> add_text(x = 0.5, y = 0.5, text = paste("Error:", result$error), textposition = "middle center")
    } else if (result$status != 200) {
      plot_ly() |> add_text(x = 0.5, y = 0.5, text = paste("HTTP Error:", result$status, "- Check endpoint or token"), textposition = "middle center")
    } else {
      data <- result$data
      if (length(data) == 0 || !all(c("title", "applications") %in% names(data[[1]]))) {
        plot_ly() |> add_text(x = 0.5, y = 0.5, text = "Invalid data: Expected 'title' and 'applications' fields", textposition = "middle center")
      } else {
        df <- do.call(rbind, lapply(data, as.data.frame))
        plot_ly(
          data = df,
          x = ~title,
          y = ~applications,
          type = "bar",
          marker = list(color = "#d62728"),
          text = ~applications,
          textposition = "auto"
        ) |>
          layout(
            title = "Job Applications",
            xaxis = list(title = "Job Title", tickangle = 45),
            yaxis = list(title = "Applications"),
            margin = list(b = 100),
            showlegend = FALSE
          )
      }
    }
  })

  # Render Vacancies Table
  output$vacancies_table <- renderDT({
    result <- vacancies_data()
    if (!is.null(result$error)) {
      showNotification(result$error, type = "error", duration = 5)
      datatable(data.frame(Error = result$error))
    } else if (result$status != 200) {
      showNotification(paste("HTTP Error:", result$status), type = "error", duration = 5)
      datatable(data.frame(Error = paste("HTTP Error:", result$status)))
    } else {
      data <- result$data
      datatable(
        do.call(rbind, lapply(data, as.data.frame)),
        options = list(
          pageLength = 10,
          dom = "tip",
          columnDefs = list(list(className = "dt-green", targets = "_all"))
        ),
        style = "bootstrap5",
        class = "table table-hover table-bordered"
      )
    }
  })

  # Render Learning Tracks Chart (Purple)
  output$learning_tracks_chart <- renderPlotly({
    result <- learning_tracks_data()
    if (!is.null(result$error)) {
      plot_ly() |> add_text(x = 0.5, y = 0.5, text = paste("Error:", result$error), textposition = "middle center")
    } else if (result$status != 200) {
      plot_ly() |> add_text(x = 0.5, y = 0.5, text = paste("HTTP Error:", result$status, "- Check endpoint or token"), textposition = "middle center")
    } else {
      data <- result$data
      if (length(data) == 0 || !all(c("title") %in% names(data[[1]]))) {
        plot_ly() |> add_text(x = 0.5, y = 0.5, text = "Invalid data: Expected 'title' field", textposition = "middle center")
      } else {
        df <- do.call(rbind, lapply(data, as.data.frame))
        df$count <- 1 # Dummy count for visualization
        plot_ly(
          data = df,
          x = ~title,
          y = ~count,
          type = "bar",
          marker = list(color = "#9467bd"),
          text = ~count,
          textposition = "auto"
        ) |>
          layout(
            title = "Learning Tracks",
            xaxis = list(title = "Track Title", tickangle = 45),
            yaxis = list(title = "Count"),
            margin = list(b = 100),
            showlegend = FALSE
          )
      }
    }
  })

  # Render Learning Tracks Table
  output$learning_tracks_table <- renderDT({
    result <- learning_tracks_data()
    if (!is.null(result$error)) {
      showNotification(result$error, type = "error", duration = 5)
      datatable(data.frame(Error = result$error))
    } else if (result$status != 200) {
      showNotification(paste("HTTP Error:", result$status), type = "error", duration = 5)
      datatable(data.frame(Error = paste("HTTP Error:", result$status)))
    } else {
      data <- result$data
      df <- do.call(rbind, lapply(data, as.data.frame))
      datatable(
        df,
        options = list(
          pageLength = 10,
          dom = "tip",
          columnDefs = list(
            list(className = "dt-green", targets = "_all"),
            list(
              targets = which(names(df) == "url") - 1, # Adjust for zero-based indexing
              render = JS(
                "function(data, type, row) {",
                "  return type === 'display' && data ? '<a href=\"' + data + '\" target=\"_blank\">' + data + '</a>' : data;",
                "}"
              )
            )
          )
        ),
        style = "bootstrap5",
        class = "table table-hover table-bordered",
        escape = FALSE
      )
    }
  })

  # Render Books Chart (Teal)
  output$books_chart <- renderPlotly({
    result <- books_data()
    if (!is.null(result$error)) {
      plot_ly() |> add_text(x = 0.5, y = 0.5, text = paste("Error:", result$error), textposition = "middle center")
    } else if (result$status != 200) {
      plot_ly() |> add_text(x = 0.5, y = 0.5, text = paste("HTTP Error:", result$status, "- Check endpoint or token"), textposition = "middle center")
    } else {
      data <- result$data
      if (length(data) == 0 || !all(c("title") %in% names(data[[1]]))) {
        plot_ly() |> add_text(x = 0.5, y = 0.5, text = "Invalid data: Expected 'title' field", textposition = "middle center")
      } else {
        df <- do.call(rbind, lapply(data, as.data.frame))
        df$count <- 1 # Dummy count for visualization
        plot_ly(
          data = df,
          x = ~title,
          y = ~count,
          type = "bar",
          marker = list(color = "#2ca02c"),
          text = ~count,
          textposition = "auto"
        ) |>
          layout(
            title = "Books",
            xaxis = list(title = "Book Title", tickangle = 45),
            yaxis = list(title = "Count"),
            margin = list(b = 100),
            showlegend = FALSE
          )
      }
    }
  })

  # Render Books Table
  output$books_table <- renderDT({
    result <- books_data()
    if (!is.null(result$error)) {
      showNotification(result$error, type = "error", duration = 5)
      datatable(data.frame(Error = result$error))
    } else if (result$status != 200) {
      showNotification(paste("HTTP Error:", result$status), type = "error", duration = 5)
      datatable(data.frame(Error = paste("HTTP Error:", result$status)))
    } else {
      data <- result$data
      df <- do.call(rbind, lapply(data, as.data.frame))
      datatable(
        df,
        options = list(
          pageLength = 10,
          dom = "tip",
          columnDefs = list(
            list(className = "dt-green", targets = "_all"),
            list(
              targets = which(names(df) == "skill_id") - 1, # Adjust for zero-based indexing
              render = JS(
                "function(data, type, row) {",
                "  return type === 'display' && data ? '<a href=\"' + data + '\" target=\"_blank\">' + data + '</a>' : data;",
                "}"
              )
            )
          )
        ),
        style = "bootstrap5",
        class = "table table-hover table-bordered",
        escape = FALSE
      )
    }
  })
}

# Run the app
shinyApp(ui = ui, server = server)
