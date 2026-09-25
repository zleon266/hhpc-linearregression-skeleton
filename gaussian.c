#include "gaussian.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

/* -------------------------------------------------------------------------
 * TODO (STUDENT): gaussian_elimination_solve
 *
 * Solve the p x p system:
 *
 *   XtX * beta = Xty
 *
 * using Gaussian elimination with partial pivoting, followed by back
 * substitution:
 *
 *   1. Build an augmented p x (p+1) matrix [XtX | Xty] (work on a local
 *      copy — do not modify XtX/Xty in place, you may want to keep them
 *      for the report).
 *   2. Forward elimination: for each pivot column k = 0..p-1,
 *        a. partial pivoting: find the row r >= k with the largest
 *           absolute value in column k, and swap rows k and r if r != k
 *           (this avoids dividing by a very small/zero pivot).
 *        b. eliminate column k from all rows below k by subtracting an
 *           appropriate multiple of row k.
 *   3. Back substitution: once the augmented matrix is in upper
 *      triangular form, solve for beta[p-1], beta[p-2], ..., beta[0]
 *      from the bottom row upward.
 *
 * XtX  : p x p, row-major (read-only)
 * Xty  : p (right-hand side, read-only)
 * beta : p (output, caller-allocated)
 * ---------------------------------------------------------------------- */
void gaussian_elimination_solve(const double *XtX, const double *Xty,
                                double *beta, int p) {


  const int width = p + 1;
  double *aug = malloc((size_t)p * width * sizeof(double));

  if (aug == NULL) {
    fprintf(stderr, "Failed to allocate augmented matrix.\n");
    exit(EXIT_FAILURE);
  }

  /* Build the augmented matrix [XtX | Xty]. */
  for (int i = 0; i < p; i++) {
    for (int j = 0; j < p; j++) {
      aug[i * width + j] = XtX[i * p + j];
    }
    aug[i * width + p] = Xty[i];
  }

  /* Forward elimination with partial pivoting. */
  for (int k = 0; k < p; k++) {
    int pivot_row = k;
    double pivot_abs = fabs(aug[k * width + k]);

    for (int r = k + 1; r < p; r++) {
      double candidate = fabs(aug[r * width + k]);
      if (candidate > pivot_abs) {
        pivot_abs = candidate;
        pivot_row = r;
      }
    }

    if (pivot_abs < 1e-12) {
      fprintf(stderr, "Singular or ill-conditioned system at column %d.\n", k);
      free(aug);
      exit(EXIT_FAILURE);
    }

    if (pivot_row != k) {
      for (int j = 0; j < width; j++) {
        double tmp = aug[k * width + j];
        aug[k * width + j] = aug[pivot_row * width + j];
        aug[pivot_row * width + j] = tmp;
      }
    }

    for (int i = k + 1; i < p; i++) {
      double factor = aug[i * width + k] / aug[k * width + k];
      aug[i * width + k] = 0.0;

      for (int j = k + 1; j < width; j++) {
        aug[i * width + j] -= factor * aug[k * width + j];
      }
    }
  }

  /* Back substitution. */
  for (int i = p - 1; i >= 0; i--) {
    double rhs = aug[i * width + p];

    for (int j = i + 1; j < p; j++) {
      rhs -= aug[i * width + j] * beta[j];
    }

    beta[i] = rhs / aug[i * width + i];
  }

  free(aug);

}



void gauss_jordan_solve(const double *XtX, const double *Xty,
                        double *beta, int p) {
  const int width = p + 1;
  double *aug = malloc((size_t)p * width * sizeof(double));

  if (aug == NULL) {
    fprintf(stderr, "Failed to allocate augmented matrix.\n");
    exit(EXIT_FAILURE);
  }

  for (int i = 0; i < p; i++) {
    for (int j = 0; j < p; j++) {
      aug[i * width + j] = XtX[i * p + j];
    }
    aug[i * width + p] = Xty[i];
  }

  for (int k = 0; k < p; k++) {
    int pivot_row = k;
    double pivot_abs = fabs(aug[k * width + k]);

    for (int r = k + 1; r < p; r++) {
      double candidate = fabs(aug[r * width + k]);
      if (candidate > pivot_abs) {
        pivot_abs = candidate;
        pivot_row = r;
      }
    }

    if (pivot_abs < 1e-12) {
      fprintf(stderr, "Singular or ill-conditioned system at column %d.\n", k);
      free(aug);
      exit(EXIT_FAILURE);
    }

    if (pivot_row != k) {
      for (int j = 0; j < width; j++) {
        double tmp = aug[k * width + j];
        aug[k * width + j] = aug[pivot_row * width + j];
        aug[pivot_row * width + j] = tmp;
      }
    }

    double pivot = aug[k * width + k];
    for (int j = k; j < width; j++) {
      aug[k * width + j] /= pivot;
    }

    for (int r = 0; r < p; r++) {
      if (r == k) {
        continue;
      }

      double factor = aug[r * width + k];
      aug[r * width + k] = 0.0;

      for (int j = k + 1; j < width; j++) {
        aug[r * width + j] -= factor * aug[k * width + j];
      }
    }
  }

  for (int i = 0; i < p; i++) {
    beta[i] = aug[i * width + p];
  }

  free(aug);
}
