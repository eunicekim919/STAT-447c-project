data {
  int<lower=0> N; // number of data points (train)
  vector[N] x; // long of train
  vector[N] y; // lat of train
  vector[N] crimes; // count of train
}

parameters {
  real alpha;
  real<lower=0> rho;
  real<lower=0> sigma;
  real<lower=0> sigma_err;
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
