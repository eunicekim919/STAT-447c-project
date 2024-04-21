//data {
//  int<lower=0> N; // number of data points (train)
//  vector[N] x; // longitude of train data
//  vector[N] y; // latitude of train data
//  vector[N] crimes; // crime count of train data

//  int<lower=0> N_new; // number of data points (test)
//  vector[N_new] x_new; // longitude of test data
//  vector[N_new] y_new; // latitude of test data
//}

//parameters {
//  real<lower=0> rho;
//  real<lower=0> sigma; // scale of the output
//  real<lower=0> sigma_err; // noise level
//  vector[N] mu; //spatially varying mean
//}

//transformed parameters {
//  matrix[N, N] covar_matrix;
//  for (i in 1:N) {
//    for (j in i:N) {
//      real dist = sqrt(square(x[i] - x[j]) + square(y[i] - y[j]));
//      covar_matrix[i, j] = sigma * exp(-dist / rho);
//      if (i != j) {
//        covar_matrix[j, i] = covar_matrix[i, j]; // Symmetric matrix
//      }
//    }
//    covar_matrix[i, i] += sigma_err^2; // adding noise variance to the diagonal
//  }
//}

//model {
  // Priors
//  rho ~ inv_gamma(5, 5);
//  sigma ~ normal(0, 1);
//  sigma_err ~ normal(0, 0.1);
//  
  //prior for spatial mean
//  mu ~ multi_normal(rep_vector(0, N), covar_matrix);

  // Likelihood
//  crimes ~ multi_normal_cholesky(rep_vector(0, N), cholesky_decompose(covar_matrix));
//}

//generated quantities {
//  vector[N_new] pred_crimes; // predicted crimes
//  
//  for (i in 1:N_new) {
//    vector[N] weights; // Weights for spatial interpolation
//    
//    for (j in 1:N) {
//      real dist = sqrt(square(x_new[i] - x[j]) + square(y_new[i] - y[j]));
//      weights[j] = exp(-dist / rho);
//    }
//    // Draw from the posterior predictive distribution
//    pred_crimes[i] = normal_rng(dot_product(weights, crimes - mu) + mu' * weights, sigma_err);
//  }
//}

data {
  int<lower=0> N; // number of training data points
  vector[N] x; // longitude of training data
  vector[N] y; // latitude of training data
  vector[N] crimes; // crime count of training data
  
  int<lower=0> N_new; // number of test data points
  vector[N_new] x_new; // longitude of test data
  vector[N_new] y_new; // latitude of test data
}

parameters {
  real<lower=0> alpha; // inverse range parameter of the GP
  real<lower=0> rho; // length-scale parameter of the GP
  real<lower=0> sigma; // noise standard deviation of GP

  vector[N] eta; // latent GP values at training locations
}

transformed parameters {
  vector[N] mu = exp(eta); // log transformation for count data
}

model {
  // Priors
  alpha ~ normal(0, 1);
  rho ~ inv_gamma(2, 2);
  sigma ~ normal(0, 1);
  
  // Spatial correlation kernel (Exponential or Matern)
  matrix[N, N] L_K;
  {
    matrix[N, N] K = cov_exp_quad(x, y, alpha, rho);
    for (i in 1:N) {
      K[i, i] = K[i, i] + square(sigma); // adding noise variance
    }
    L_K = cholesky_decompose(K);
  }
  
  eta ~ multi_normal_cholesky(rep_vector(0, N), L_K); // Latent GP values

  // Likelihood of observed data
  crimes ~ lognormal(mu, sigma);
}

generated quantities {
  vector[N_new] crimes_new;
  {
    matrix[N_new, N] K_new = cov_exp_quad(x_new, y_new, x, y, alpha, rho);
    vector[N] k_vec = diag_pre_multiply(sigma, L_K) \ (eta - rep_vector(0, N));
    vector[N_new] mu_new = K_new * k_vec;
    for (i in 1:N_new) {
      crimes_new[i] = lognormal_rng(mu_new[i], sigma);
    }
  }
}
