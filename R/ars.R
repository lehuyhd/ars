#' @title Adaptive Rejection Sampling
#' @description Adaptive Rejection Sampling from log-concave density functions h(x)
#' @param h input a valid probability density function we want to sample from, the function h(x) should only take one argument x. i.e. correct: h = function(x) \{dnorm(x,0,1)\}; wrong: h = function(x,mean = 0,sd = 1) \{dnorm(x,mean,sd)\}
#' @param start lower bound of the domain of h(x)
#' @param end upper bound of the domain of h(x)
#' @param N sample size
#' @param k number of starting points, the default is 3
#' @param x1 the right starting point, if NULL, the function will find one
#' @param xk the left starting point, if NULL, the function will find one
#' @export
#' @import rlang numDeriv
#' @return a vector of N sampled value from the density h(x)
#' @examples
#' library(ars)
#' h = function(x){dnorm(x)}
#' sample = ars(h = h,start = -Inf , end = Inf,N = 100)
#' hist(sample)
ars = function(h,start,end,N,k = 3,x1 = NULL,xk = NULL){
  ## function input check
  if(!is.function(h)){
    stop("Please input a valid function h")
  }
  if(!is.numeric(start)|length(start)!=1){
    stop("Please input valid lower bound")
  }
  if(!is.numeric(end)|length(end)!=1){
    stop("Please input valid upper bound")
  }

  if(!is.numeric(end)|length(end)!=1){
    stop("Please input one numeric value as sample size N")
  }
  if(!is.numeric(k)|length(k)!=1){
    stop("Please input one numeric value as number of starting points k or use default")
  }

  if(!is.null(x1) & (!is.numeric(x1)|length(x1)!=1)){
    stop("Please input one numeric value as starting point x1 or use default")
  }
  if(!is.null(xk) & (!is.numeric(xk)|length(xk)!=1)){
    stop("Please input one numeric value as starting point xk or use default")
  }

  # choosing the starting point
  if(is.null(x1)|is.null(xk)){
    if (!is.infinite(start) && !is.infinite(end)) {
      x1_choose = start + 0.01
      xk_choose = end - 0.01
    } else {
      result = suppressWarnings(initial_point_sample(h, start, end))
      x1_choose = result[1]
      xk_choose = result[3]
    }

    # if the user don't specify, we will choose the starting point for them
    if (is.null(x1)) {
      x1 = x1_choose
    }
    if (is.null(xk)) {
      xk = xk_choose
    }
  }


  #### convert function to log
  f = convert_log(h)
  ## domain check
  domain_check(f,start, end, x1, xk)
  ## concave
  case = log_concave_check(f,x1,xk)

  if (case == 1) {
    # uniform case
    u2 = runif(N,start,end)
    return(u2)
  } else if (case == 2){
    # exponential case
    left = start
    right = end
    m = numDeriv::grad(func = f, x = start, method = "simple")
    u2 = runif(N,0,1)
    x_star = log(u2*(exp(m*right) - exp(m*left)) + exp(m*left))/m
    return(x_star)
  } else if (case == 3) {

    ### Initialize Tk,l,u,s,z
    Tk = initial_Tk(f,x1,xk, k = k); zlist = initial_zlist(f,Tk,start,end)

    z = zlist[[1]]; u = update_u(f,Tk,z); l = update_l(f,Tk)

    ### Start sampling loop
    sample = numeric(N); count = 0
    while(count<N){
      ## need sample_from_u()
      x = samp_ars(f,Tk,start = start,end = end,zlist = zlist)
      uni = runif(1)

      if(length(exp(l(x)-u(x)))!= 1){
        stop("Generated numbers that exceed machine maximum, try to run again or modify the input h(x)")
      }else if(is.na(exp(l(x)-u(x)))| is.null(exp(l(x)-u(x)))){
        stop("Generated numbers that exceed machine maximum, try to run again or modify the input h(x)")
      }
      ## Squeezing Test
      if(uni <= exp(l(x)-u(x))){
        count = count + 1
        sample[count] = x
      }
      else if(uni <= exp(f(x)-u(x))){
        ## Rejection Test
        count = count + 1
        sample[count] = x
        ### updating step
        zlist = update_zlist(f,zlist,Tk,x)
        Tk = update_Tk(Tk,x)
        z = zlist[[1]]
        u = update_u(f,Tk,z)
        l = update_l(f,Tk)
      } else{
        ### updating step
        zlist = update_zlist(f,zlist,Tk,x)
        Tk = update_Tk(Tk,x)
        z = zlist[[1]]
        u = update_u(f,Tk,z)
        l = update_l(f,Tk)
      }

    }
    return(sample)
  } else {
    stop("The function is not log-concave, please input the log-concave function")
  }
}
