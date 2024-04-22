data {
  int<lower=0> N; // number of data points (train)
  vector[N] x; // longitude of train
  vector[N] y; // latitude of train
  vector[N] crimes; // count of train
  
  int<lower=0> N_new; // number of data points (test)
  vector[N_new] x_new; // longitude of test
  vector[N_new] y_new; // latitude of test

  // Precomputed distances
  matrix[N, N] dist; // distances between training locations
  matrix[N, N_new] dist_new; // distances from training to testing locations
}

parameters {
  real alpha; // intercept
  real beta_x; // coefficient for longitude
  real beta_y; // coefficient for latitude
  real<lower=0> rho; // range
  real<lower=0> sigma; // spatial variance
  real<lower=0> sigma_err; // measurement error
}

transformed parameters {
  matrix[N, N] covar_matrix = sigma * exp(-dist / rho) + diag_matrix(rep_vector(sigma_err, N));
}

model {
  vector[N] mu = alpha + beta_x * x + beta_y * y; // vectorized mean computation

  // Priors
  alpha ~ normal(0, 10);
  beta_x ~ normal(0, 1);
  beta_y ~ normal(0, 1);
  rho ~ inv_gamma(5, 5);
  sigma ~ normal(0, 1);
  sigma_err ~ normal(0, 1);

  // Spatial model
  crimes ~ multi_normal(mu, covar_matrix);
}

generated quantities {
  vector[N_new] pred_crimes; // predicted crimes
  vector[N_new] mu_new = alpha + beta_x * x_new + beta_y * y_new; // vectorized mean computation for new data

  for (i in 1:N_new) {
    vector[N] spatial_weights = exp(-dist_new[, i] / rho);
    vector[N] adjusted_crimes = crimes - (alpha + beta_x * x + beta_y * y); // Adjusted crimes recalculated in this block
    pred_crimes[i] = normal_rng(mu_new[i] + dot_product(spatial_weights, adjusted_crimes), sigma_err);
  }
}
