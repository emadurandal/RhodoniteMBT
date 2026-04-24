// Triangle vertex data

// Triangle vertices with positions and colors
// Format: x, y, r, g, b
pub let triangle_vertices : Array[Double] = [
  // Top vertex - Red
  0.0, 0.5, 1.0, 0.0, 0.0,
  // Bottom left - Green
  -0.5, -0.5, 0.0, 1.0, 0.0,
  // Bottom right - Blue
  0.5, -0.5, 0.0, 0.0, 1.0
]

pub fn get_vertex_count() -> Int {
  3
}

pub fn get_vertex_data_size() -> Int {
  triangle_vertices.length() * 8 // 8 bytes per double
}