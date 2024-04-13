data {
  int<lower=0> N; // number of data points (train)
  vector[N] x; // long of train
  vector[N] y; // lat of train
  vector[N] crimes; // count of train
  
  int<lower=0> N_new; // number of data points (test)
  vector[N_new] x_new; // long of test
  vector[N_new] y_new; //lat of test
}

parameters {
  real alpha; //intercept
  real<lower=0> rho; //range
  real<lower=0> sigma; //spatial variance
  real<lower=0> sigma_err; // measurement error
}

model {
  vector[N] mu;
  
  for (i in 1:N) {
    mu[i] = alpha;
  }
  
  // Priors
  alpha ~ normal(0, 10);
  rho ~ inv_gamma(2, 1);
  sigma ~ normal(0, 1);
  sigma_err ~ normal(0, 1);

  // Spatial structure
  {
    matrix[N, N] dist;
    for (i in 1:N) {
      for (j in 1:N) {
        dist[i, j] = sqrt(square(x[i] - x[j]) + square(y[i] - y[j]));
      }
    }
    crimes ~ multi_normal(mu, sigma * exp(-dist/rho) + diag_matrix(rep_vector(sigma_err, N)));
  }
}

generated quantities{
  vector[N_new] pred_crimes; //predicted crimes
  matrix[N, N_new] new_dist; //distance from old to new
  for (i in 1:N){
    for (j in 1:N_new){
      new_dist[i, j] = exp(-sqrt(square(x[i] - x_new[j]) + square(y[i] - y_new[j])) / rho);
    }
  }
  
  for (i in 1:N_new){
    pred_crimes[i] = normal_rng(alpha + dot_product(new_dist[, i], crimes - rep_vector(alpha, N)), sigma_err);
  }
}


