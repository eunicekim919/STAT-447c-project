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
  real<lower=0> length_scale;
  real<lower=0> sigma; // scale of the output
  real<lower=0> sigma_noise; // noise level
}

transformed parameters {
  matrix[N, N] covar_matrix;
  for (i in 1:N) {
    for (j in i:N) {
      real dist = sqrt(square(x[i] - x[j]) + square(y[i] - y[j]));
      covar_matrix[i, j] = sigma * exp(-dist / length_scale);
      if (i != j) {
        covar_matrix[j, i] = covar_matrix[i, j]; // Symmetric matrix
      }
    }
    covar_matrix[i, i] += sigma_noise^2; // adding noise variance to the diagonal
  }
}

model {
  // Priors
  length_scale ~ inv_gamma(5, 5);
  sigma ~ normal(0, 1);
  sigma_noise ~ normal(0, 0.1);

  // Likelihood
  crimes ~ multi_normal_cholesky(rep_vector(0, N), cholesky_decompose(covar_matrix));
}

generated quantities {
  vector[N_new] pred_crimes; // predicted crimes
  matrix[N, N_new] new_dist; // distance from old to new

  // Compute distances for the new matrix
  for (i in 1:N) {
    for (j in 1:N_new) {
      new_dist[i, j] = sqrt(square(x[i] - x_new[j]) + square(y[i] - y_new[j]));
    }
  }

  // Covariance matrix between train and test data
  matrix[N, N_new] k_x_xnew;
  for (i in 1:N) {
    for (j in 1:N_new) {
      k_x_xnew[i, j] = sigma * exp(-new_dist[i, j] / length_scale);
    }
  }

  // Prediction mean
  matrix[N_new, N] k_xnew_x = k_x_xnew'; // Transpose
  vector[N] alpha = cholesky_decompose(covar_matrix) \ crimes; // Cholesky factorization and solve
  pred_crimes = k_xnew_x * alpha;
}
