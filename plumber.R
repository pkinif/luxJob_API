library(plumber)
library(luxJob)


# TO DO
# - improve the documentation
# EG. Could be NULL or not
# EG. Arguments are optional or not
# - Test the API
# - Add Bearer Authentication that query

#* @apiTitle luxJob API
#* @apiDescription API to explore skills, jobs, companies, learning tracks and book recommendations from the ADEM dataset.

# ---- SKILLS ----

#* Get all skills
#* @param limit Max number of skills to return
#* @get /skills
function(limit = 100) {
    luxJob::get_skills(as.numeric(limit))
}

#* Get skill by ID
#* @param skill_id The ESCO skill ID
#* @get /skills/<skill_id>
function(skill_id) {
    luxJob::get_skill_by_id(as.character(skill_id))
}

# ---- COMPANIES ----

#* Get all companies
#* @param limit Max number of companies to return
#* @get /companies
function(limit = 100) {
    luxJob::get_companies(as.numeric(limit))
}

#* Get company details by ID
#* @param company_id The company ID
#* @get /companies/<company_id>
function(company_id) {
    luxJob::get_company_details(as.numeric(company_id))
}

# ---- JOB VACANCIES ----

#* Get job vacancies
#* @param skill Filter by skill_id
#* @param company Filter by company_id
#* @param canton Filter by canton name
#* @param limit Max number of results
#* @get /vacancies
function(skill = NULL, company = NULL, canton = NULL, limit = 100) {
    luxJob::get_vacancies(
        skill = skill,
        company = if (!is.null(company)) as.numeric(company) else NULL,
        canton = canton,
        limit = as.numeric(limit)
    )
}

#* Get vacancy by ID
#* @param vacancy_id The ID of the vacancy
#* @get /vacancies/<vacancy_id>
function(vacancy_id) {
    luxJob::get_vacancy_by_id(as.numeric(vacancy_id))
}

# ---- LEARNING TRACKS ----

#* Get all learning tracks
#* @param skill_id Filter by skill_id
#* @get /learning_tracks
function(skill_id = NULL) {
    luxJob::get_learning_tracks(skill_id = skill_id)
}

#* Get learning track by ID
#* @param track_id The ID of the learning track
#* @get /learning_tracks/<track_id>
function(track_id) {
    luxJob::get_learning_track_by_id(as.numeric(track_id))
}

# ---- BOOKS ----

#* Get all books
#* @param skill Filter by skill_id
#* @get /books
function(skill = NULL) {
    luxJob::get_books(skill = skill)
}

#* Get book by ID
#* @param book_id The book ID
#* @get /books/<book_id>
function(book_id) {
    luxJob::get_book_by_id(as.numeric(book_id))
}

# ---- SEARCH LOGGING ----

#* Log a user search
#* @param user_id Integer user ID
#* @param query Search query
#* @post /log_search
function(user_id, query) {
    success <- luxJob::log_search(
        user_id = as.numeric(user_id),
        query = query
    )
    list(status = if (success) "ok" else "error")
}

# ---- CONFIGURATION ----

#* @plumber
function(pr) {
    pr |> 
        pr_set_serializer(serializer_unboxed_json()) 
}

