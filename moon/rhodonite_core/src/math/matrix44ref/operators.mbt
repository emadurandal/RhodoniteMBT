///|
pub impl[T : Eq + Matrix44RefElem] Eq for Matrix44Ref[T] with equal(self, other) {
  self.at(0, 0) == other.at(0, 0) &&
  self.at(1, 0) == other.at(1, 0) &&
  self.at(2, 0) == other.at(2, 0) &&
  self.at(3, 0) == other.at(3, 0) &&
  self.at(0, 1) == other.at(0, 1) &&
  self.at(1, 1) == other.at(1, 1) &&
  self.at(2, 1) == other.at(2, 1) &&
  self.at(3, 1) == other.at(3, 1) &&
  self.at(0, 2) == other.at(0, 2) &&
  self.at(1, 2) == other.at(1, 2) &&
  self.at(2, 2) == other.at(2, 2) &&
  self.at(3, 2) == other.at(3, 2) &&
  self.at(0, 3) == other.at(0, 3) &&
  self.at(1, 3) == other.at(1, 3) &&
  self.at(2, 3) == other.at(2, 3) &&
  self.at(3, 3) == other.at(3, 3)
}
