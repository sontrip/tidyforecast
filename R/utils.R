#' Retry with backup function
#' 
#' Attempts functions sequentially until one evaluates without error.
#' 
#' @param ... A list of functions, formulas, or atomic vectors.
#'
#'   If a __function__, it is used as is.
#'
#'   If a __formula__, e.g. `~ .x + 2`, it is converted to a function. There
#'   are three ways to refer to the arguments:
#'
#'   * For a single argument function, use `.`
#'   * For a two argument function, use `.x` and `.y`
#'   * For more arguments, use `..1`, `..2`, `..3` etc
#'
#'   This syntax allows you to create very compact anonymous functions.
#'
#'   If __character vector__, __numeric vector__, or __list__, it
#'   is converted to an extractor function. Character vectors index by name
#'   and numeric vectors index by position; use a list to index by position
#'   and name at different levels. Within a list, wrap strings in [get-attr()]
#'   to extract named attributes. If a component is not present, the value of
#'   `.default` will be returned.
#'   
#' @inheritParams purrr::possibly
#' 
#' @importFrom purrr as_mapper
#' @export
retry <- function(..., otherwise, quiet = TRUE) {
  .f <- list(...)
  
  missing_otherwise <- missing(otherwise)
  
  fn <- function(..., .list_fn_pos = 1) {
    tryCatch(as_mapper(.f[[.list_fn_pos]])(...),
             error = function(e) {
               if (!quiet)
                 message("Error: ", e$message)
               if(.list_fn_pos >= length(.f)){
                 if(missing_otherwise){
                   stop(e)
                 }
                 force(otherwise)
                 otherwise
               }
               else{
                 fn(..., .list_fn_pos = .list_fn_pos + 1)
               }
             },
             interrupt = function(e) {
               stop("Terminated by user", call. = FALSE)
             }
    )
  }
  fn
}

expr_sym <- function(expr){
  sym(expr_name(expr))
}

quo_sym <- function(quo){
  sym(quo_name(quo))
}

# Small function to combine two named lists
merge_named_list <- function(x,y){
  all_names <- union(names(x), names(y))
  all_names %>%
    map(~ c(x[[.x]], y[[.x]])) %>%
    set_names(all_names)
}

flatten_first_args <- function(args){
  args %>% 
    map(~ if(length(.x) > 1){stop("Only one special of each type is allowed for this model")} else {.x[[1]]}) %>%
    set_names(NULL) %>%
    unlist(recursive = FALSE) %>%
    as.list # If no args are provided, unlist removes list structure
}

#' @importFrom purrr imap reduce
enclass <- function(x, subclass, ...){
  dots_list(...) %>%
    imap(function(value, name) set_names(list(value), name)) %>%
    reduce(.init = x, # Add attributes (from ...)
           function(x, attr) {
             if (!is.null(attr[[1]])) {
               attr(x, names(attr)) <- attr[[1]]
             }
             x
           }) %>%
    `class<-`(c(subclass, class(.))) # Add classes
}

rm_class <- function(x, class){
  `class<-`(x, class(x)[!(class(x) %in% class)])
}