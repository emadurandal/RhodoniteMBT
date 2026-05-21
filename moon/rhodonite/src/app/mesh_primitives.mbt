/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// CPU-side bytes and layout metadata for a static indexed mesh.
pub(all) struct StaticIndexedMeshDesc {
  priv vertices : FixedArray[Byte]
  priv indices_u16 : FixedArray[Byte]
  priv index_count : Int
  priv vertex_layout : @wgpu.GPUVertexBufferLayout
}

///|
/// Builds a static indexed mesh descriptor from raw vertex and u16 index bytes.
pub fn StaticIndexedMeshDesc::new(
  vertices : FixedArray[Byte],
  indices_u16 : FixedArray[Byte],
  index_count : Int,
  vertex_layout : @wgpu.GPUVertexBufferLayout,
) -> StaticIndexedMeshDesc {
  { vertices, indices_u16, index_count, vertex_layout }
}

///|
/// Returns the raw vertex bytes for this mesh descriptor.
pub fn StaticIndexedMeshDesc::vertices(
  self : StaticIndexedMeshDesc,
) -> FixedArray[Byte] {
  self.vertices
}

///|
/// Returns the little-endian u16 index bytes for this mesh descriptor.
pub fn StaticIndexedMeshDesc::indices_u16(
  self : StaticIndexedMeshDesc,
) -> FixedArray[Byte] {
  self.indices_u16
}

///|
/// Returns the number of u16 indices to draw.
pub fn StaticIndexedMeshDesc::index_count(self : StaticIndexedMeshDesc) -> Int {
  self.index_count
}

///|
/// Returns the vertex layout expected by the primitive mesh bytes.
pub fn StaticIndexedMeshDesc::vertex_layout(
  self : StaticIndexedMeshDesc,
) -> @wgpu.GPUVertexBufferLayout {
  self.vertex_layout
}

///|
/// Returns the standard position-only vertex stride used by primitive meshes.
pub fn primitive_position3_vertex_stride() -> Int {
  12
}

///|
/// Returns the standard position-only vertex layout used by primitive meshes.
pub fn primitive_position3_vertex_layout() -> @wgpu.GPUVertexBufferLayout {
  {
    array_stride: primitive_position3_vertex_stride().to_uint64(),
    step_mode: @wgpu.GPUVertexStepMode::Vertex,
    attributes: [
      {
        format: @wgpu.GPUVertexFormat::Float32x3,
        offset: 0UL,
        shader_location: 0U,
      },
    ],
  }
}

///|
/// CPU descriptor for a position-only cube primitive centered at the origin.
pub(all) struct CubeMeshDesc {
  priv half_extent : Double
}

///|
/// Builds a cube mesh descriptor with the given half extent.
pub fn CubeMeshDesc::new(half_extent? : Double = 1.0) -> CubeMeshDesc {
  { half_extent, }
}

///|
/// Returns half the cube edge length.
pub fn CubeMeshDesc::half_extent(self : CubeMeshDesc) -> Double {
  self.half_extent
}

///|
/// Returns the position-only vertex layout used by cube primitive meshes.
pub fn cube_position3_vertex_layout() -> @wgpu.GPUVertexBufferLayout {
  primitive_position3_vertex_layout()
}

///|
/// Returns the number of vertices in the shared-corner cube mesh.
pub fn cube_vertex_count() -> Int {
  8
}

///|
/// Returns the number of u16 indices in the cube mesh.
pub fn cube_index_count() -> Int {
  36
}

///|
/// Returns the local-space corners used by the shared-corner cube mesh.
fn cube_local_corners() -> Array[(Double, Double, Double)] {
  [
    (-1.0, -1.0, -1.0),
    (1.0, -1.0, -1.0),
    (1.0, 1.0, -1.0),
    (-1.0, 1.0, -1.0),
    (-1.0, -1.0, 1.0),
    (1.0, -1.0, 1.0),
    (1.0, 1.0, 1.0),
    (-1.0, 1.0, 1.0),
  ]
}

///|
/// Builds position-only vertex bytes for the cube primitive.
pub fn cube_vertex_position_bytes(
  desc? : CubeMeshDesc = CubeMeshDesc::new(),
) -> FixedArray[Byte] {
  let bytes = FixedArray::make(
    cube_vertex_count() * primitive_position3_vertex_stride(),
    (0 : Byte),
  )
  let corners = cube_local_corners()
  for vi = 0; vi < cube_vertex_count(); vi = vi + 1 {
    let (lx, ly, lz) = corners[vi]
    let base = vi * primitive_position3_vertex_stride()
    let half_extent = desc.half_extent
    @writes.put_f32_le(bytes, base + 0, lx * half_extent)
    @writes.put_f32_le(bytes, base + 4, ly * half_extent)
    @writes.put_f32_le(bytes, base + 8, lz * half_extent)
  }
  bytes
}

///|
/// Builds little-endian u16 index bytes for the cube primitive.
pub fn cube_index_u16_bytes() -> FixedArray[Byte] {
  let bytes = FixedArray::make(cube_index_count() * 2, (0 : Byte))
  let indices : Array[UInt] = [
    0U, 1U, 2U, 2U, 3U, 0U, 4U, 5U, 6U, 6U, 7U, 4U, 0U, 4U, 7U, 7U, 3U, 0U, 1U, 5U,
    6U, 6U, 2U, 1U, 0U, 1U, 5U, 5U, 4U, 0U, 3U, 2U, 6U, 6U, 7U, 3U,
  ]
  for i = 0; i < cube_index_count(); i = i + 1 {
    @writes.put_u16_le(bytes, i * 2, indices[i])
  }
  bytes
}

///|
/// Builds a static indexed mesh descriptor for a position-only cube primitive.
pub fn cube_mesh_desc(
  desc? : CubeMeshDesc = CubeMeshDesc::new(),
) -> StaticIndexedMeshDesc {
  StaticIndexedMeshDesc::new(
    cube_vertex_position_bytes(desc~),
    cube_index_u16_bytes(),
    cube_index_count(),
    cube_position3_vertex_layout(),
  )
}
