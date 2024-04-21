data {
  int<lower=0> N; // number of data points (train)
  vector[N] x; // longitude of train data
  vector[N] y; // latitude of train data
  vector[N] crimes; // crime count of train data

  int<lower=0> N_new; // number of data points (test)
  vector[N_new] x_new; // longitude of test data
  vector[N_new] y_new; // latitude of test data
}

parameters {
  real<lower=0> rho;
  real<lower=0> sigma; // scale of the output
  real<lower=0> sigma_err; // noise level
  vector[N] mu; //spatially varying mean
}

transformed parameters {
  matrix[N, N] covar_matrix;
  for (i in 1:N) {
    for (j in i:N) {
      real dist = sqrt(square(x[i] - x[j]) + square(y[i] - y[j]));
      covar_matrix[i, j] = sigma * exp(-dist / rho);
      if (i != j) {
        covar_matrix[j, i] = covar_matrix[i, j]; // Symmetric matrix
      }
    }
    covar_matrix[i, i] += sigma_err^2; // adding noise variance to the diagonal
  }
}

model {
  // Priors
  rho ~ inv_gamma(5, 5);
  sigma ~ normal(0, 1);
  sigma_err ~ normal(0, 0.1);
  
  //prior for spatial mean
  mu ~ multi_normal(rep_vector(0, N), covar_matrix);

  // Likelihood
  crimes ~ multi_normal_cholesky(rep_vector(0, N), cholesky_decompose(covar_matrix));
}

generated quantities {
  vector[N_new] pred_crimes; // predicted crimes
  
  for (i in 1:N_new) {
    vector[N] weights; // Weights for spatial interpolation
    
    for (j in 1:N) {
      real dist = sqrt(square(x_new[i] - x[j]) + square(y_new[i] - y[j]));
      weights[j] = exp(-dist / rho);
    }
    // Draw from the posterior predictive distribution
    pred_crimes[i] = normal_rng(dot_product(weights, crimes - mu) + mu' * weights, sigma_err);
  }
}
