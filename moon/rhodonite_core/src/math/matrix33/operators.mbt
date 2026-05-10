///|
pub impl[T : Add] Add for Matrix33[T] with add(self, other) {
  Matrix33::{
    data: (
      [
        self.data[0] + other.data[0],
        self.data[1] + other.data[1],
        self.data[2] + other.data[2],
        self.data[3] + other.data[3],
        self.data[4] + other.data[4],
        self.data[5] + other.data[5],
        self.data[6] + other.data[6],
        self.data[7] + other.data[7],
        self.data[8] + other.data[8],
      ] : FixedArray[T]),
  }
}

///|
pub impl[T : Sub] Sub for Matrix33[T] with sub(self, other) {
  Matrix33::{
    data: (
      [
        self.data[0] - other.data[0],
        self.data[1] - other.data[1],
        self.data[2] - other.data[2],
        self.data[3] - other.data[3],
        self.data[4] - other.data[4],
        self.data[5] - other.data[5],
        self.data[6] - other.data[6],
        self.data[7] - other.data[7],
        self.data[8] - other.data[8],
      ] : FixedArray[T]),
  }
}

///|
pub impl[T : Neg] Neg for Matrix33[T] with neg(self) {
  Matrix33::{
    data: (
      [
        -self.data[0],
        -self.data[1],
        -self.data[2],
        -self.data[3],
        -self.data[4],
        -self.data[5],
        -self.data[6],
        -self.data[7],
        -self.data[8],
      ] : FixedArray[T]),
  }
}

///|
/// Hadamard (component-wise) product; use [`Matrix33::mat_mul`] for matrix multiplication.
pub impl[T : Mul] Mul for Matrix33[T] with mul(self, other) {
  Matrix33::{
    data: (
      [
        self.data[0] * other.data[0],
        self.data[1] * other.data[1],
        self.data[2] * other.data[2],
        self.data[3] * other.data[3],
        self.data[4] * other.data[4],
        self.data[5] * other.data[5],
        self.data[6] * other.data[6],
        self.data[7] * other.data[7],
        self.data[8] * other.data[8],
      ] : FixedArray[T]),
  }
}

///|
pub impl[T : Eq] Eq for Matrix33[T] with equal(self, other) {
  self.data[0] == other.data[0] &&
  self.data[1] == other.data[1] &&
  self.data[2] == other.data[2] &&
  self.data[3] == other.data[3] &&
  self.data[4] == other.data[4] &&
  self.data[5] == other.data[5] &&
  self.data[6] == other.data[6] &&
  self.data[7] == other.data[7] &&
  self.data[8] == other.data[8]
}
