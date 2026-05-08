///| TypeScript / Vitest 向けに `Vector3F` をそのまま JS に出せるようラップする。

///|
pub fn v3f_new(x : Float, y : Float, z : Float) -> @v3.Vector3F {
  @v3.Vector3::new(x, y, z)
}

///|
pub fn v3f_zero() -> @v3.Vector3F {
  @v3.Vector3::zero()
}

///|
pub fn v3f_x(v : @v3.Vector3F) -> Float {
  v.x()
}

///|
pub fn v3f_y(v : @v3.Vector3F) -> Float {
  v.y()
}

///|
pub fn v3f_z(v : @v3.Vector3F) -> Float {
  v.z()
}

///|
pub fn v3f_add(a : @v3.Vector3F, b : @v3.Vector3F) -> @v3.Vector3F {
  a + b
}

///|
pub fn v3f_sub(a : @v3.Vector3F, b : @v3.Vector3F) -> @v3.Vector3F {
  a - b
}

///|
pub fn v3f_neg(v : @v3.Vector3F) -> @v3.Vector3F {
  -v
}

///|
pub fn v3f_mul(a : @v3.Vector3F, b : @v3.Vector3F) -> @v3.Vector3F {
  a * b
}

///|
pub fn v3f_scale(v : @v3.Vector3F, s : Float) -> @v3.Vector3F {
  v.scale(s)
}

///|
pub fn v3f_div_scalar(v : @v3.Vector3F, s : Float) -> @v3.Vector3F {
  v.div_scalar(s)
}

///|
pub fn v3f_eq(a : @v3.Vector3F, b : @v3.Vector3F) -> Bool {
  a == b
}

///|
pub fn v3f_to_string(v : @v3.Vector3F) -> String {
  v.to_string()
}

///| TypeScript / Vitest 向けに `Vector4F` をそのまま JS に出せるようラップする。

///|
pub fn v4f_new(x : Float, y : Float, z : Float, w : Float) -> @v4.Vector4F {
  @v4.Vector4::new(x, y, z, w)
}

///|
pub fn v4f_zero() -> @v4.Vector4F {
  @v4.Vector4::zero()
}

///|
pub fn v4f_x(v : @v4.Vector4F) -> Float {
  v.x()
}

///|
pub fn v4f_y(v : @v4.Vector4F) -> Float {
  v.y()
}

///|
pub fn v4f_z(v : @v4.Vector4F) -> Float {
  v.z()
}

///|
pub fn v4f_w(v : @v4.Vector4F) -> Float {
  v.w()
}

///|
pub fn v4f_add(a : @v4.Vector4F, b : @v4.Vector4F) -> @v4.Vector4F {
  a + b
}

///|
pub fn v4f_sub(a : @v4.Vector4F, b : @v4.Vector4F) -> @v4.Vector4F {
  a - b
}

///|
pub fn v4f_neg(v : @v4.Vector4F) -> @v4.Vector4F {
  -v
}

///|
pub fn v4f_mul(a : @v4.Vector4F, b : @v4.Vector4F) -> @v4.Vector4F {
  a * b
}

///|
pub fn v4f_scale(v : @v4.Vector4F, s : Float) -> @v4.Vector4F {
  v.scale(s)
}

///|
pub fn v4f_div_scalar(v : @v4.Vector4F, s : Float) -> @v4.Vector4F {
  v.div_scalar(s)
}

///|
pub fn v4f_eq(a : @v4.Vector4F, b : @v4.Vector4F) -> Bool {
  a == b
}

///|
pub fn v4f_to_string(v : @v4.Vector4F) -> String {
  v.to_string()
}

///|
fn main {
  ()
}
