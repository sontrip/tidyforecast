#' @inherit forecast::Arima
#' @param data A data frame
#' @param formula Model specification.
#' @param period Time series frequency for seasonal component.
#' 
#' @export
#' 
#' @examples 
#' 
#' USAccDeaths %>%
#'   ARIMA(log(value) ~ pdq(0,1,1) + PDQ(0,1,1))
#' 
#' @importFrom forecast Arima
ARIMA <- function(data, formula, period = "smallest", ...){
  # Capture call
  cl <- new_quosure(match.call())
  formula <- enquo(formula)
  
  # Coerce data
  data <- as_tsibble(data)
  
  # Handle multivariate inputs
  if(n_keys(data) > 1){
    return(multi_univariate(data, cl))
  }
  
  # Define specials
  specials <- new_specials_env(
    pdq = function(p = 0, d = 0, q = 0){
      list(order = c(p=p, d=d, q=q))
    },
    PDQ = function(P = 0, D = 0, Q = 0){
      list(seasonal = c(P=P, D=D, Q=Q))
    },
    trend = function(trend = TRUE){
      list(include.drift = trend)
    },
    xreg = specials_xreg,
    
    parent_env = get_env(cl)
  )
  
  # Parse model
  model <- data %>% 
    parse_model(formula, specials = specials)

  # Output model
  wrap_ts_model(data, "Arima", model, !!!flatten_first_args(model$args), period = period, ...)
}

model_sum.ARIMA <- function(x){
  order <- x$arma[c(1, 6, 2, 3, 7, 4, 5)]
  m <- order[7]
  result <- paste("ARIMA(", order[1], ",", order[2], ",", order[3], ")", sep = "")
  if (m > 1 && sum(order[4:6]) > 0) {
    result <- paste(result, "(", order[4], ",", order[5], ",", order[6], ")[", m, "]", sep = "")
  }
  result
}