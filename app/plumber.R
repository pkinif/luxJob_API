# plumber.R

# Load packages
library(plumber)
library(DBI)
library(RPostgres)
library(glue)
library(luxJob)

auth_helper <- function(res, req, FUN, ...) {
    # Get token from header
    auth_header <- if (!is.null(req$HTTP_AUTHORIZATION)) req$HTTP_AUTHORIZATION else ""
    token <- sub("^Bearer ", "", auth_header)
    valid_token <- luxJob::verify_token(token, schema = Sys.getenv("sql_schema")) 
    
    if (!valid_token) {
        res$status <- 401
        return(list(error = "Unauthorized: Invalid or missing token"))
    }
    
    FUN(...)
}


# ------------------------------------------------------------------------------
# Skills
# ------------------------------------------------------------------------------

#* Get all skills
#* @get /skills
#* @param limit:int Maximum number of skills to return
function(res, req, limit = 100) {
    auth_helper(res, req, function(limit) {
        luxJob::get_skills(as.integer(limit))
    }, limit = limit)
}

#* Get a skill by ID
#* @get /skills/<skill_id>
#* @param skill_id:string ID of the skill to retrieve
function(res, req, skill_id = 'http://data.europa.eu/esco/skill/97965983-0da4-4902-9daf-d5cd2693ef73') {
    auth_helper(res, req, function(skill_id) {
        skill_id <- utils::URLdecode(skill_id)
        luxJob::get_skill_by_id(as.character(skill_id))
    }, skill_id = skill_id)
}

# ------------------------------------------------------------------------------
# Companies
# ------------------------------------------------------------------------------

#* Get all companies
#* @get /companies
#* @param limit:int Maximum number of companies to return
function(res, req, limit = 100) {
    auth_helper(res, req, function(limit) {
        luxJob::get_companies(as.integer(limit))
    }, limit = limit)
}

#* Get a company by ID
#* @get /companies/<company_id>
#* @param company_id:int ID of the company to retrieve
function(res, req, company_id) {
    auth_helper(res, req, function(company_id) {
        luxJob::get_company_details(as.integer(company_id))
    }, company_id = company_id)
}

# ------------------------------------------------------------------------------
# Vacancies
# ------------------------------------------------------------------------------

#* Get job vacancies
#* @get /vacancies
#* @param skill:string Skill ID to filter by
#* @param company:int Company ID to filter by
#* @param canton:string Canton name to filter by
#* @param limit:int Maximum number of results to return
function(res, req, skill = NULL, company = NULL, canton = NULL, limit = 100) {
    auth_helper(res, req, function(skill, company, canton, limit) {
        luxJob::get_vacancies(
            skill = skill,
            company = if (!is.null(company)) as.integer(company) else NULL,
            canton = canton,
            limit = as.integer(limit)
        )
    }, skill = skill, company = company, canton = canton, limit = limit)
}

#* Get a vacancy by ID
#* @get /vacancies/<vacancy_id>
#* @param vacancy_id:int ID of the vacancy to retrieve
function(res, req, vacancy_id) {
    auth_helper(res, req, function(vacancy_id) {
        luxJob::get_vacancy_by_id(as.numeric(vacancy_id))
    }, vacancy_id = vacancy_id)
}

# ------------------------------------------------------------------------------
# Learning Tracks
# ------------------------------------------------------------------------------

#* Get learning tracks
#* @get /learning_tracks
#* @param skill_id:string Optional skill ID to filter learning tracks
function(res, req, skill_id = NULL) {
    auth_helper(res, req, function(skill_id) {
        luxJob::get_learning_tracks(skill_id)
    }, skill_id = skill_id)
}

#* Get a learning track by ID
#* @get /learning_tracks/<track_id>
#* @param track_id:int ID of the learning track to retrieve
function(res, req, track_id) {
    auth_helper(res, req, function(track_id) {
        luxJob::get_learning_track_by_id(as.integer(track_id))
    }, track_id = track_id)
}

# ------------------------------------------------------------------------------
# Books
# ------------------------------------------------------------------------------

#* Get book recommendations
#* @get /books
#* @param skill:string Optional skill ID to filter books
function(res, req, skill = 'http://data.europa.eu/esco/skill/70198e4e-86ad-4acc-a9eb-e24e2c107d18') {
    auth_helper(res, req, function(skill) {
        luxJob::get_books(skill)
    }, skill = skill)
}

#* Get a book by ID
#* @get /books/<book_id>
#* @param book_id:int ID of the book to retrieve
function(res, req, book_id) {
    auth_helper(res, req, function(book_id) {
        luxJob::get_book_by_id(as.integer(book_id))
    }, book_id = book_id)
}

# ------------------------------------------------------------------------------
# Logs
# ------------------------------------------------------------------------------

#* Log a search query
#* @post /log_search
#* @param user_id:int ID of the user making the search
#* @param query:string Text of the search query
function(res, req, user_id, query) {
    auth_helper(res, req, function(user_id, query) {
        luxJob::log_search(as.integer(user_id), query)
    }, user_id = user_id, query = query)
}
