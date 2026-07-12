// Matrix Algebra and Linear Equations Solver
// This module provides basic matrix structures, arithmetic operations, 
// and solvers like Gauss-Jordan elimination and LU decomposition.

///|
pub struct Matrix {
  pub rows : Int
  pub cols : Int
  pub data : Array[Double]
}

///|
pub fn make_matrix(rows : Int, cols : Int) -> Matrix {
  { rows, cols, data: Array::make(rows * cols, 0.0) }
}

///|
pub fn make_identity(n : Int) -> Matrix {
  let m = make_matrix(n, n)
  for i = 0; i < n; i = i + 1 {
    m.data[i * n + i] = 1.0
  }
  m
}

///|
pub fn Matrix::matrix_get(self : Matrix, r : Int, c : Int) -> Double {
  self.data[r * self.cols + c]
}

///|
pub fn Matrix::matrix_set(
  self : Matrix,
  r : Int,
  c : Int,
  val : Double,
) -> Unit {
  self.data[r * self.cols + c] = val
}

///|
pub fn matrix_add(m1 : Matrix, m2 : Matrix) -> Matrix? {
  if m1.rows != m2.rows || m1.cols != m2.cols {
    return None
  }
  let res = make_matrix(m1.rows, m1.cols)
  for i = 0; i < m1.data.length(); i = i + 1 {
    res.data[i] = m1.data[i] + m2.data[i]
  }
  Some(res)
}

///|
pub fn matrix_sub(m1 : Matrix, m2 : Matrix) -> Matrix? {
  if m1.rows != m2.rows || m1.cols != m2.cols {
    return None
  }
  let res = make_matrix(m1.rows, m1.cols)
  for i = 0; i < m1.data.length(); i = i + 1 {
    res.data[i] = m1.data[i] - m2.data[i]
  }
  Some(res)
}

///|
pub fn matrix_scale(m : Matrix, factor : Double) -> Matrix {
  let res = make_matrix(m.rows, m.cols)
  for i = 0; i < m.data.length(); i = i + 1 {
    res.data[i] = m.data[i] * factor
  }
  res
}

///|
pub fn matrix_mul(m1 : Matrix, m2 : Matrix) -> Matrix? {
  if m1.cols != m2.rows {
    return None
  }
  let res = make_matrix(m1.rows, m2.cols)
  for r = 0; r < m1.rows; r = r + 1 {
    for c = 0; c < m2.cols; c = c + 1 {
      let mut sum = 0.0
      for i = 0; i < m1.cols; i = i + 1 {
        sum = sum + m1.matrix_get(r, i) * m2.matrix_get(i, c)
      }
      res.matrix_set(r, c, sum)
    }
  }
  Some(res)
}

///|
pub fn matrix_transpose(m : Matrix) -> Matrix {
  let res = make_matrix(m.cols, m.rows)
  for r = 0; r < m.rows; r = r + 1 {
    for c = 0; c < m.cols; c = c + 1 {
      res.matrix_set(c, r, m.matrix_get(r, c))
    }
  }
  res
}

///|
fn abs_val(v : Double) -> Double {
  if v < 0.0 {
    -v
  } else {
    v
  }
}

///|
pub fn matrix_inverse_gauss_jordan(m : Matrix) -> Matrix? {
  if m.rows != m.cols {
    return None
  }
  let n = m.rows
  // Augmented matrix: [M | I]
  let aug = make_matrix(n, 2 * n)
  for r = 0; r < n; r = r + 1 {
    for c = 0; c < n; c = c + 1 {
      aug.matrix_set(r, c, m.matrix_get(r, c))
    }
    aug.matrix_set(r, n + r, 1.0)
  }

  // Forward and backward elimination
  for i = 0; i < n; i = i + 1 {
    // Find pivot
    let mut max_row = i
    let mut max_val = abs_val(aug.matrix_get(i, i))
    for r = i + 1; r < n; r = r + 1 {
      let val = abs_val(aug.matrix_get(r, i))
      if val > max_val {
        max_val = val
        max_row = r
      }
    }

    // Singular matrix check
    if max_val < 0.000000001 {
      return None
    }

    // Swap rows if necessary
    if max_row != i {
      for c = 0; c < 2 * n; c = c + 1 {
        let temp = aug.matrix_get(i, c)
        aug.matrix_set(i, c, aug.matrix_get(max_row, c))
        aug.matrix_set(max_row, c, temp)
      }
    }

    // Scale row so pivot is 1.0
    let pivot = aug.matrix_get(i, i)
    for c = 0; c < 2 * n; c = c + 1 {
      aug.matrix_set(i, c, aug.matrix_get(i, c) / pivot)
    }

    // Eliminate other rows
    for r = 0; r < n; r = r + 1 {
      if r != i {
        let factor = aug.matrix_get(r, i)
        for c = 0; c < 2 * n; c = c + 1 {
          let new_val = aug.matrix_get(r, c) - factor * aug.matrix_get(i, c)
          aug.matrix_set(r, c, new_val)
        }
      }
    }
  }

  // Extract inverse
  let inv = make_matrix(n, n)
  for r = 0; r < n; r = r + 1 {
    for c = 0; c < n; c = c + 1 {
      inv.matrix_set(r, c, aug.matrix_get(r, n + c))
    }
  }
  Some(inv)
}

///|
pub struct LuResult {
  pub l : Matrix
  pub u : Matrix
  pub p : Array[Int]
}

///|
pub fn matrix_lu_decomposition(m : Matrix) -> LuResult? {
  if m.rows != m.cols {
    return None
  }
  let n = m.rows
  let l = make_matrix(n, n)
  let u = make_matrix(n, n)
  let p = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    p[i] = i
  }

  // Copy m to u
  for i = 0; i < n * n; i = i + 1 {
    u.data[i] = m.data[i]
  }

  for i = 0; i < n; i = i + 1 {
    l.data[i * n + i] = 1.0
  }

  for i = 0; i < n; i = i + 1 {
    // Pivot selection
    let mut pivot_row = i
    let mut pivot_val = abs_val(u.matrix_get(i, i))
    for r = i + 1; r < n; r = r + 1 {
      let val = abs_val(u.matrix_get(r, i))
      if val > pivot_val {
        pivot_val = val
        pivot_row = r
      }
    }

    if pivot_val < 0.000000001 {
      return None
    }

    if pivot_row != i {
      // Swap rows in U
      for c = 0; c < n; c = c + 1 {
        let temp = u.matrix_get(i, c)
        u.matrix_set(i, c, u.matrix_get(pivot_row, c))
        u.matrix_set(pivot_row, c, temp)
      }

      // Swap elements in permutation vector
      let temp_p = p[i]
      p[i] = p[pivot_row]
      p[pivot_row] = temp_p

      // Swap rows in L (up to column i)
      for c = 0; c < i; c = c + 1 {
        let temp = l.matrix_get(i, c)
        l.matrix_set(i, c, l.matrix_get(pivot_row, c))
        l.matrix_set(pivot_row, c, temp)
      }
    }

    for r = i + 1; r < n; r = r + 1 {
      let factor = u.matrix_get(r, i) / u.matrix_get(i, i)
      l.matrix_set(r, i, factor)
      for c = i; c < n; c = c + 1 {
        let new_u = u.matrix_get(r, c) - factor * u.matrix_get(i, c)
        u.matrix_set(r, c, new_u)
      }
    }
  }

  Some({ l, u, p })
}
