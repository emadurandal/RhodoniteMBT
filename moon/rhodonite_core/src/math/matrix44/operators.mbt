///|
pub impl[T : Add] Add for Matrix44[T] with add(self, other) {
  Matrix44::{
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
        self.data[9] + other.data[9],
        self.data[10] + other.data[10],
        self.data[11] + other.data[11],
        self.data[12] + other.data[12],
        self.data[13] + other.data[13],
        self.data[14] + other.data[14],
        self.data[15] + other.data[15],
      ] : FixedArray[T]),
  }
}

///|
pub impl[T : Sub] Sub for Matrix44[T] with sub(self, other) {
  Matrix44::{
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
        self.data[9] - other.data[9],
        self.data[10] - other.data[10],
        self.data[11] - other.data[11],
        self.data[12] - other.data[12],
        self.data[13] - other.data[13],
        self.data[14] - other.data[14],
        self.data[15] - other.data[15],
      ] : FixedArray[T]),
  }
}

///|
pub impl[T : Neg] Neg for Matrix44[T] with neg(self) {
  Matrix44::{
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
        -self.data[9],
        -self.data[10],
        -self.data[11],
        -self.data[12],
        -self.data[13],
        -self.data[14],
        -self.data[15],
      ] : FixedArray[T]),
  }
}

///|
/// Hadamard (component-wise) product; use [`Matrix44::mat_mul`] for matrix multiplication.
pub impl[T : Mul] Mul for Matrix44[T] with mul(self, other) {
  Matrix44::{
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
        self.data[9] * other.data[9],
        self.data[10] * other.data[10],
        self.data[11] * other.data[11],
        self.data[12] * other.data[12],
        self.data[13] * other.data[13],
        self.data[14] * other.data[14],
        self.data[15] * other.data[15],
      ] : FixedArray[T]),
  }
}

///|
pub impl[T : Eq] Eq for Matrix44[T] with equal(self, other) {
  self.data[0] == other.data[0] &&
  self.data[1] == other.data[1] &&
  self.data[2] == other.data[2] &&
  self.data[3] == other.data[3] &&
  self.data[4] == other.data[4] &&
  self.data[5] == other.data[5] &&
  self.data[6] == other.data[6] &&
  self.data[7] == other.data[7] &&
  self.data[8] == other.data[8] &&
  self.data[9] == other.data[9] &&
  self.data[10] == other.data[10] &&
  self.data[11] == other.data[11] &&
  self.data[12] == other.data[12] &&
  self.data[13] == other.data[13] &&
  self.data[14] == other.data[14] &&
  self.data[15] == other.data[15]
}
