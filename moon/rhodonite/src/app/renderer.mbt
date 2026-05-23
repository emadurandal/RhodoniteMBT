/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Per-renderable instance row: builtin GlobalTransform ref plus unlit RGB color.
let renderer_instance_stride : Int = 24

///|
/// Shader visibility bit for vertex-stage renderer bindings.
let renderer_shader_stage_vertex : UInt64 = 1UL

///|
/// WebGPU buffer binding type used for read-only storage buffers.
let renderer_buffer_binding_read_only_storage : UInt = 4U

///|
/// Handle for a renderer-owned instance vertex buffer.
pub(all) struct InstanceBufferHandle {
  priv index : Int
} derive(Eq)

///|
/// Returns the renderer-local slot index for diagnostics and tests.
pub fn InstanceBufferHandle::index(self : InstanceBufferHandle) -> Int {
  self.index
}

///|
/// Static indexed mesh resource owned by `Renderer`.
priv struct RendererMesh {
  vertex_buffer : @wgpu.GPUBuffer
  index_buffer : @wgpu.GPUBuffer
  vertex_byte_length : UInt64
  index_byte_length : UInt64
  index_count : Int
}

///|
/// Description for an unlit material registered with `Renderer`.
pub(all) struct UnlitMaterialDesc {
  priv base_color_r : Double
  priv base_color_g : Double
  priv base_color_b : Double
  priv alpha : Double
  priv flags : UInt
}

///|
/// Builds an unlit material description.
pub fn UnlitMaterialDesc::new(
  base_color_r : Double,
  base_color_g : Double,
  base_color_b : Double,
  alpha? : Double = 1.0,
  flags? : UInt = 0U,
) -> UnlitMaterialDesc {
  { base_color_r, base_color_g, base_color_b, alpha, flags }
}

///|
/// Returns the red channel of the unlit base color.
pub fn UnlitMaterialDesc::base_color_r(self : UnlitMaterialDesc) -> Double {
  self.base_color_r
}

///|
/// Returns the green channel of the unlit base color.
pub fn UnlitMaterialDesc::base_color_g(self : UnlitMaterialDesc) -> Double {
  self.base_color_g
}

///|
/// Returns the blue channel of the unlit base color.
pub fn UnlitMaterialDesc::base_color_b(self : UnlitMaterialDesc) -> Double {
  self.base_color_b
}

///|
/// Returns the alpha channel reserved for future blending support.
pub fn UnlitMaterialDesc::alpha(self : UnlitMaterialDesc) -> Double {
  self.alpha
}

///|
/// Returns the raw material option flags.
pub fn UnlitMaterialDesc::flags(self : UnlitMaterialDesc) -> UInt {
  self.flags
}

///|
/// Unlit material resource owned by `Renderer`.
priv struct RendererMaterial {
  desc : UnlitMaterialDesc
}

///|
/// Renderer-owned instance vertex buffer with the Renderable v1 row layout.
priv struct RendererInstanceBuffer {
  buffer : @wgpu.GPUBuffer
  byte_capacity : Int
}

///|
/// One scene draw extracted from ECS Renderable rows.
priv struct RendererDrawItem {
  entity : @ecs.EntityId
  mesh_index : Int
  material_index : Int
}

///|
/// Surface-local render target resources used by the v1 renderer.
pub struct RenderTargetResources {
  priv device : @wgpu.GPUDevice
  priv mut format : String
  priv mut width : Int
  priv mut height : Int
  priv mut depth_texture : @wgpu.GPUTexture?
  priv mut depth_view : @wgpu.GPUTextureView?
}

///|
/// Creates render target resources for one color target format and extent.
pub fn RenderTargetResources::new(
  device : @wgpu.GPUDevice,
  width : Int,
  height : Int,
  format : String,
) -> RenderTargetResources {
  let target = {
    device,
    format,
    width: 0,
    height: 0,
    depth_texture: None,
    depth_view: None,
  }
  target.resize(width, height, format)
  target
}

///|
/// Returns whether this target has valid surface-sized resources.
pub fn RenderTargetResources::active(self : RenderTargetResources) -> Bool {
  self.width > 0 &&
  self.height > 0 &&
  (match self.depth_view {
    Some(_) => true
    None => false
  })
}

///|
/// Returns the color format used to select a compatible render pipeline.
pub fn RenderTargetResources::format(self : RenderTargetResources) -> String {
  self.format
}

///|
/// Returns the current depth view when the target is active.
pub fn RenderTargetResources::depth_view(
  self : RenderTargetResources,
) -> @wgpu.GPUTextureView? {
  self.depth_view
}

///|
/// Recreates surface-sized depth resources for the supplied extent and format.
pub fn RenderTargetResources::resize(
  self : RenderTargetResources,
  width : Int,
  height : Int,
  format : String,
) -> Unit {
  self.release_depth_resources()
  if format != "" {
    self.format = format
  }
  self.width = width
  self.height = height
  if width <= 0 || height <= 0 {
    self.width = 0
    self.height = 0
    return
  }
  let texture = self.device.create_texture(
    width.reinterpret_as_uint(),
    height.reinterpret_as_uint(),
    "depth24plus",
    @wgpu.GPU_TEXTURE_USAGE_RENDER_ATTACHMENT,
  )
  self.depth_texture = Some(texture)
  self.depth_view = Some(texture.create_view())
}

///|
/// Releases only the target-local depth resources.
fn RenderTargetResources::release_depth_resources(
  self : RenderTargetResources,
) -> Unit {
  match self.depth_view {
    Some(view) => @wgpu.textureView_release(view)
    None => ()
  }
  match self.depth_texture {
    Some(texture) => texture.release()
    None => ()
  }
  self.depth_view = None
  self.depth_texture = None
}

///|
/// Releases target-local GPU resources.
pub fn RenderTargetResources::release(self : RenderTargetResources) -> Unit {
  self.release_depth_resources()
}

///|
/// Render pipeline cached for one color target format.
priv struct RendererPipelineEntry {
  format : String
  pipeline : @wgpu.GPURenderPipeline
}

///|
/// Minimal engine-owned renderer for ECS Renderable entities.
pub struct Renderer {
  priv device : @wgpu.GPUDevice
  priv queue : @wgpu.GPUQueue
  priv transform_layout : @wgpu.GPUBindGroupLayout
  priv camera_layout : @wgpu.GPUBindGroupLayout
  priv pipeline_layout : @wgpu.GPUPipelineLayout
  priv vertex_layout : @wgpu.GPUVertexBufferLayout
  priv pipeline_entries : Array[RendererPipelineEntry]
  priv meshes : Array[RendererMesh]
  priv materials : Array[RendererMaterial]
  priv instance_buffers : Array[RendererInstanceBuffer]
  priv mut transform_storage : @wgpu.GPUBuffer?
  priv mut camera_storage : @wgpu.GPUBuffer?
  priv mut bind_transforms : @wgpu.GPUBindGroup?
  priv mut bind_camera : @wgpu.GPUBindGroup?
  priv mut renderable_instance_buffer : @wgpu.GPUBuffer?
  priv mut renderable_instance_byte_capacity : Int
  priv mut transform_word_capacity : Int
  priv mut camera_word_capacity : Int
}

///|
/// Implements `Renderer::device`.
pub fn Renderer::device(self : Renderer) -> @wgpu.GPUDevice {
  self.device
}

///|
/// Returns WGSL for the v1 unlit Renderable pipeline.
fn renderable_unlit_wgsl() -> String {
  let prefix = @ecs_wgsl.global_transform_words_binding_default() +
    @ecs_wgsl.camera_words_binding_default()
  let suffix =
    #|
    #|struct VertexOut {
    #|  @builtin(position) position: vec4<f32>,
    #|  @location(0) color: vec3<f32>,
    #|};
    #|
    #|@vertex
    #|fn vertexMain(
    #|  @location(0) local_pos: vec3<f32>,
    #|  @location(1) transform_ref: vec2<u32>,
    #|  @location(2) color: vec3<f32>,
    #|) -> VertexOut {
    #|  let world_pos = rn_transform_point(
    #|    rn_load_global_transform(transform_ref),
    #|    local_pos,
    #|  );
    #|  let camera = rn_load_camera(0u);
    #|  var o: VertexOut;
    #|  o.position = camera.view_proj * world_pos;
    #|  o.color = color;
    #|  return o;
    #|}
    #|
    #|@fragment
    #|fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
    #|  return vec4<f32>(color, 1.0);
    #|}
    #|
  prefix +
  @ecs_wgsl.global_transform_helpers_default() +
  @ecs_wgsl.camera_helpers_default() +
  suffix
}

///|
/// Builds the fixed instance vertex-buffer layout used by Renderable v1.
fn renderable_instance_vertex_buffer_layout() -> @wgpu.GPUVertexBufferLayout {
  @wgpu.global_transform_ref_instance_vertex_buffer_layout(
    renderer_instance_stride.to_uint64(),
    1U,
    0UL,
    [
      {
        format: @wgpu.GPUVertexFormat::Float32x3,
        offset: 8UL,
        shader_location: 2U,
      },
    ],
  )
}

///|
/// Creates the v1 unlit render pipeline.
fn create_renderable_unlit_pipeline(
  device : @wgpu.GPUDevice,
  pipeline_layout : @wgpu.GPUPipelineLayout,
  format : String,
  vertex_layout : @wgpu.GPUVertexBufferLayout,
) -> @wgpu.GPURenderPipeline {
  let shader = device.create_shader_module(renderable_unlit_wgsl())
  let pipeline = device.create_render_pipeline({
    layout: Some(pipeline_layout),
    vertex: shader,
    fragment: shader,
    topology: @wgpu.GPUPrimitiveTopology::TriangleList,
    formats: [format],
    vertex_buffers: [vertex_layout, renderable_instance_vertex_buffer_layout()],
    depth_stencil_format: Some("depth24plus"),
  })
  @wgpu.shaderModule_release(shader)
  pipeline
}

///|
/// Creates shared renderer resources for the supplied WebGPU device.
pub fn Renderer::new(
  device : @wgpu.GPUDevice,
  queue : @wgpu.GPUQueue,
  vertex_layout : @wgpu.GPUVertexBufferLayout,
) -> Renderer {
  let transform_layout = device.create_bind_group_layout({
    buffer_entries: [
      {
        binding: 0U,
        visibility: renderer_shader_stage_vertex,
        buffer_type: renderer_buffer_binding_read_only_storage,
        has_dynamic_offset: false,
        min_binding_size: 0UL,
      },
    ],
  })
  let camera_layout = device.create_bind_group_layout({
    buffer_entries: [
      {
        binding: 0U,
        visibility: renderer_shader_stage_vertex,
        buffer_type: renderer_buffer_binding_read_only_storage,
        has_dynamic_offset: false,
        min_binding_size: 0UL,
      },
    ],
  })
  let pipeline_layout = device.create_pipeline_layout({
    bind_group_layouts: [transform_layout, camera_layout],
  })
  {
    device,
    queue,
    transform_layout,
    camera_layout,
    pipeline_layout,
    vertex_layout,
    pipeline_entries: [],
    meshes: [],
    materials: [],
    instance_buffers: [],
    transform_storage: None,
    camera_storage: None,
    bind_transforms: None,
    bind_camera: None,
    renderable_instance_buffer: None,
    renderable_instance_byte_capacity: 0,
    transform_word_capacity: 0,
    camera_word_capacity: 0,
  }
}

///|
/// Returns a pipeline compatible with the supplied target format.
fn Renderer::pipeline_for_format(
  self : Renderer,
  format : String,
) -> @wgpu.GPURenderPipeline {
  for i = 0; i < self.pipeline_entries.length(); i = i + 1 {
    let entry = self.pipeline_entries[i]
    if entry.format == format {
      return entry.pipeline
    }
  }
  let pipeline = create_renderable_unlit_pipeline(
    self.device,
    self.pipeline_layout,
    format,
    self.vertex_layout,
  )
  self.pipeline_entries.push({ format, pipeline })
  pipeline
}

///|
/// Registers raw static indexed u16 mesh bytes.
fn Renderer::register_static_indexed_mesh_bytes(
  self : Renderer,
  vertices : FixedArray[Byte],
  indices_u16 : FixedArray[Byte],
  index_count : Int,
) -> MeshHandle {
  let vusage = @wgpu.GPU_BUFFER_USAGE_VERTEX | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let iusage = @wgpu.GPU_BUFFER_USAGE_INDEX | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let vertex_buffer = self.device.create_buffer(
    vertices.length().to_uint64(),
    vusage,
  )
  self.queue.write_buffer_from_fixed_array(vertex_buffer, 0UL, vertices)
  let index_buffer = self.device.create_buffer(
    indices_u16.length().to_uint64(),
    iusage,
  )
  self.queue.write_buffer_from_fixed_array(index_buffer, 0UL, indices_u16)
  let index = self.meshes.length()
  self.meshes.push({
    vertex_buffer,
    index_buffer,
    vertex_byte_length: vertices.length().to_uint64(),
    index_byte_length: indices_u16.length().to_uint64(),
    index_count,
  })
  { index, }
}

///|
/// Registers a static indexed u16 mesh.
pub fn Renderer::register_static_indexed_mesh(
  self : Renderer,
  vertices : FixedArray[Byte],
  indices_u16 : FixedArray[Byte],
  index_count : Int,
) -> MeshHandle {
  self.register_static_indexed_mesh_bytes(vertices, indices_u16, index_count)
}

///|
/// Registers a static indexed u16 mesh from a CPU mesh descriptor.
pub fn Renderer::register_static_indexed_mesh_desc(
  self : Renderer,
  desc : StaticIndexedMeshDesc,
) -> MeshHandle {
  self.register_static_indexed_mesh_bytes(
    desc.vertices,
    desc.indices_u16,
    desc.index_count,
  )
}

///|
/// Registers a position-only cube primitive mesh.
pub fn Renderer::register_cube_mesh(
  self : Renderer,
  desc? : CubeMeshDesc = CubeMeshDesc::new(),
) -> MeshHandle {
  self.register_static_indexed_mesh_desc(cube_mesh_desc(desc~))
}

///|
/// Registers an unlit material.
pub fn Renderer::register_unlit_material(
  self : Renderer,
  desc : UnlitMaterialDesc,
) -> MaterialHandle {
  let index = self.materials.length()
  self.materials.push({ desc, })
  { index, }
}

///|
/// Registers a renderer-owned instance buffer using the v1 instance row layout.
pub fn Renderer::register_static_instance_buffer(
  self : Renderer,
  instance_bytes : FixedArray[Byte],
) -> InstanceBufferHandle {
  let usage = @wgpu.GPU_BUFFER_USAGE_VERTEX | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let buffer = self.device.create_buffer(
    instance_bytes.length().to_uint64(),
    usage,
  )
  self.queue.write_buffer_from_fixed_array(buffer, 0UL, instance_bytes)
  let index = self.instance_buffers.length()
  self.instance_buffers.push({ buffer, byte_capacity: instance_bytes.length() })
  { index, }
}

///|
/// Updates a renderer-owned instance buffer if the new bytes fit its capacity.
pub fn Renderer::update_static_instance_buffer(
  self : Renderer,
  handle : InstanceBufferHandle,
  instance_bytes : FixedArray[Byte],
) -> Bool {
  if !self.has_instance_buffer(handle.index) {
    return false
  }
  let entry = self.instance_buffers[handle.index]
  if instance_bytes.length() > entry.byte_capacity {
    return false
  }
  self.queue.write_buffer_from_fixed_array(entry.buffer, 0UL, instance_bytes)
  true
}

///|
/// Reports whether `index` addresses a registered mesh.
fn Renderer::has_mesh(self : Renderer, index : Int) -> Bool {
  index >= 0 && index < self.meshes.length()
}

///|
/// Reports whether `index` addresses a registered material.
fn Renderer::has_material(self : Renderer, index : Int) -> Bool {
  index >= 0 && index < self.materials.length()
}

///|
/// Reports whether `index` addresses a registered instance buffer.
fn Renderer::has_instance_buffer(self : Renderer, index : Int) -> Bool {
  index >= 0 && index < self.instance_buffers.length()
}

///|
/// Releases an optional buffer.
fn release_buffer(buffer : @wgpu.GPUBuffer?) -> Unit {
  match buffer {
    Some(buffer) => buffer.release()
    None => ()
  }
}

///|
/// Releases an optional bind group.
fn release_bind_group(group : @wgpu.GPUBindGroup?) -> Unit {
  match group {
    Some(group) => @wgpu.bindGroup_release(group)
    None => ()
  }
}

///|
/// Ensures the transient Renderable instance buffer can hold `byte_length` bytes.
fn Renderer::ensure_instance_buffer(
  self : Renderer,
  byte_length : Int,
) -> @wgpu.GPUBuffer? {
  if byte_length <= 0 {
    return None
  }
  if self.renderable_instance_buffer is None ||
    byte_length > self.renderable_instance_byte_capacity {
    release_buffer(self.renderable_instance_buffer)
    let usage = @wgpu.GPU_BUFFER_USAGE_VERTEX | @wgpu.GPU_BUFFER_USAGE_COPY_DST
    self.renderable_instance_buffer = Some(
      self.device.create_buffer(byte_length.to_uint64(), usage),
    )
    self.renderable_instance_byte_capacity = byte_length
  }
  self.renderable_instance_buffer
}

///|
/// Ensures the renderer has storage buffers and bind groups for the scene world.
fn Renderer::ensure_scene_buffers(self : Renderer, world : @ecs.World) -> Unit {
  let transform_capacity = world.global_transform_blob_word_capacity()
  if self.transform_storage is None ||
    transform_capacity > self.transform_word_capacity {
    release_bind_group(self.bind_transforms)
    release_buffer(self.transform_storage)
    self.transform_storage = Some(
      self.device.create_global_transform_words_buffer(world),
    )
    self.transform_word_capacity = transform_capacity
    match self.transform_storage {
      Some(buffer) =>
        self.bind_transforms = Some(
          self.device.create_global_transform_words_bind_group(
            self.transform_layout,
            buffer,
            0U,
          ),
        )
      None => ()
    }
  }
  let camera_capacity = world.camera_blob_word_capacity()
  if self.camera_storage is None || camera_capacity > self.camera_word_capacity {
    release_bind_group(self.bind_camera)
    release_buffer(self.camera_storage)
    self.camera_storage = Some(self.device.create_camera_words_buffer(world))
    self.camera_word_capacity = camera_capacity
    match self.camera_storage {
      Some(buffer) =>
        self.bind_camera = Some(
          self.device.create_camera_words_bind_group(
            self.camera_layout,
            buffer,
            0U,
          ),
        )
      None => ()
    }
  }
}

///|
/// Uploads explicit GlobalTransform write views into the renderer-owned storage.
pub fn Renderer::upload_global_transform_writes(
  self : Renderer,
  world : @ecs.World,
  writes : Array[@ecs.GpuWriteView],
) -> Unit {
  self.ensure_scene_buffers(world)
  match self.transform_storage {
    Some(buffer) => self.queue.upload_global_transform_writes(buffer, writes)
    None => ()
  }
}

///|
/// Extracts valid Renderable rows from a scene world.
fn Renderer::extract_draw_items(
  self : Renderer,
  scene : Scene,
) -> Array[RendererDrawItem] {
  let world = scene.world()
  let renderable = scene.renderable_component_id
  let items : Array[RendererDrawItem] = []
  @ecs.Query::new([renderable, world.global_transform_component()]).for_each(
    world,
    row => {
      row.read(renderable, bytes => {
        let flags = renderable_flags_from_view(bytes)
        if flags.contains(renderable_flags_visible()) {
          let mesh_index = renderable_mesh_handle_from_view(bytes).index
          let material_index = renderable_material_handle_from_view(bytes).index
          if self.has_mesh(mesh_index) && self.has_material(material_index) {
            items.push({ entity: row.entity(), mesh_index, material_index })
          }
        }
      })
    },
  )
  items
}

///|
/// RGB tuple used while building v1 instance bytes.
priv struct RendererInstanceColor {
  r : Double
  g : Double
  b : Double
}

///|
/// Builds v1 instance bytes from entities and per-instance colors.
fn build_renderer_instance_bytes(
  world : @ecs.World,
  entities : Array[@ecs.EntityId],
  colors : Array[RendererInstanceColor],
) -> FixedArray[Byte] {
  let bytes = FixedArray::make(
    entities.length() * renderer_instance_stride,
    (0 : Byte),
  )
  world.write_global_transform_refs_into(
    entities, bytes, renderer_instance_stride, 0,
  )
  let color_count = if colors.length() < entities.length() {
    colors.length()
  } else {
    entities.length()
  }
  for i = 0; i < color_count; i = i + 1 {
    let base = i * renderer_instance_stride
    @writes.put_f32_le(bytes, base + 8, colors[i].r)
    @writes.put_f32_le(bytes, base + 12, colors[i].g)
    @writes.put_f32_le(bytes, base + 16, colors[i].b)
  }
  bytes
}

///|
/// Builds the transient per-frame instance buffer bytes for draw items.
fn Renderer::build_instance_bytes(
  self : Renderer,
  world : @ecs.World,
  items : Array[RendererDrawItem],
) -> FixedArray[Byte] {
  let entities : Array[@ecs.EntityId] = []
  for i = 0; i < items.length(); i = i + 1 {
    entities.push(items[i].entity)
  }
  let colors : Array[RendererInstanceColor] = []
  for i = 0; i < items.length(); i = i + 1 {
    let material = self.materials[items[i].material_index]
    colors.push({
      r: material.desc.base_color_r,
      g: material.desc.base_color_g,
      b: material.desc.base_color_b,
    })
  }
  build_renderer_instance_bytes(world, entities, colors)
}

///|
/// Renders all visible Renderable entities in `scene` to `color_view`.
pub fn Renderer::render_scene_renderables(
  self : Renderer,
  scene : Scene,
  target : RenderTargetResources,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  let depth_view = match target.depth_view() {
    Some(view) => view
    None => return
  }
  let pipeline = self.pipeline_for_format(target.format())
  let world = scene.world()
  self.ensure_scene_buffers(world)
  let items = self.extract_draw_items(scene)
  let instance_buffer = if items.length() > 0 {
    let instance_bytes = self.build_instance_bytes(world, items)
    let buffer = self.ensure_instance_buffer(instance_bytes.length())
    match buffer {
      Some(buffer) =>
        self.queue.write_buffer_from_fixed_array(buffer, 0UL, instance_bytes)
      None => ()
    }
    buffer
  } else {
    None
  }
  match self.transform_storage {
    Some(buffer) =>
      self.queue.drain_and_upload_global_transform_writes(buffer, world)
    None => ()
  }
  match self.camera_storage {
    Some(buffer) => self.queue.drain_and_upload_camera_writes(buffer, world)
    None => ()
  }
  let encoder = self.device.create_command_encoder()
  let render_pass = encoder.begin_render_pass({
    color_attachments: [
      Some({
        view: color_view,
        clear_value: Some({ r: 0.03, g: 0.04, b: 0.09, a: 1.0 }),
        load_op: @wgpu.GPULoadOp::Clear,
        store_op: @wgpu.GPUStoreOp::Store,
      }),
    ],
    depth_stencil_attachment: Some({
      view: depth_view,
      depth_clear_value: Some(1.0),
      depth_load_op: @wgpu.GPULoadOp::Clear,
      depth_store_op: @wgpu.GPUStoreOp::Store,
    }),
  })
  render_pass.set_pipeline(pipeline)
  match self.bind_transforms {
    Some(group) => render_pass.set_bind_group(0U, group, [])
    None => ()
  }
  match self.bind_camera {
    Some(group) => render_pass.set_bind_group(1U, group, [])
    None => ()
  }
  match instance_buffer {
    Some(buffer) => {
      render_pass.set_vertex_buffer(
        1,
        buffer,
        0UL,
        (items.length() * renderer_instance_stride).to_uint64(),
      )
      for i = 0; i < items.length(); i = i + 1 {
        let mesh = self.meshes[items[i].mesh_index]
        render_pass.set_index_buffer(
          mesh.index_buffer,
          @wgpu.GPUIndexFormat::Uint16,
          0UL,
          mesh.index_byte_length,
        )
        render_pass.set_vertex_buffer(
          0,
          mesh.vertex_buffer,
          0UL,
          mesh.vertex_byte_length,
        )
        render_pass.draw_indexed(
          mesh.index_count,
          instance_count=1,
          first_instance=i,
        )
      }
    }
    None => ()
  }
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  self.queue.submit(command_buffer)
  encoder.release()
}

///|
/// Renders one mesh using a renderer-owned instance buffer.
pub fn Renderer::render_instanced_mesh(
  self : Renderer,
  scene : Scene,
  mesh : MeshHandle,
  instances : InstanceBufferHandle,
  instance_count : Int,
  target : RenderTargetResources,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  if instance_count <= 0 ||
    !self.has_mesh(mesh.index) ||
    !self.has_instance_buffer(instances.index) {
    return
  }
  let depth_view = match target.depth_view() {
    Some(view) => view
    None => return
  }
  let pipeline = self.pipeline_for_format(target.format())
  let instance_entry = self.instance_buffers[instances.index]
  let instance_byte_length = instance_count * renderer_instance_stride
  if instance_byte_length > instance_entry.byte_capacity {
    return
  }
  let world = scene.world()
  self.ensure_scene_buffers(world)
  match self.transform_storage {
    Some(buffer) =>
      self.queue.drain_and_upload_global_transform_writes(buffer, world)
    None => ()
  }
  match self.camera_storage {
    Some(buffer) => self.queue.drain_and_upload_camera_writes(buffer, world)
    None => ()
  }
  let mesh_entry = self.meshes[mesh.index]
  let encoder = self.device.create_command_encoder()
  let render_pass = encoder.begin_render_pass({
    color_attachments: [
      Some({
        view: color_view,
        clear_value: Some({ r: 0.03, g: 0.04, b: 0.09, a: 1.0 }),
        load_op: @wgpu.GPULoadOp::Clear,
        store_op: @wgpu.GPUStoreOp::Store,
      }),
    ],
    depth_stencil_attachment: Some({
      view: depth_view,
      depth_clear_value: Some(1.0),
      depth_load_op: @wgpu.GPULoadOp::Clear,
      depth_store_op: @wgpu.GPUStoreOp::Store,
    }),
  })
  render_pass.set_pipeline(pipeline)
  match self.bind_transforms {
    Some(group) => render_pass.set_bind_group(0U, group, [])
    None => ()
  }
  match self.bind_camera {
    Some(group) => render_pass.set_bind_group(1U, group, [])
    None => ()
  }
  render_pass.set_index_buffer(
    mesh_entry.index_buffer,
    @wgpu.GPUIndexFormat::Uint16,
    0UL,
    mesh_entry.index_byte_length,
  )
  render_pass.set_vertex_buffer(
    0,
    mesh_entry.vertex_buffer,
    0UL,
    mesh_entry.vertex_byte_length,
  )
  render_pass.set_vertex_buffer(
    1,
    instance_entry.buffer,
    0UL,
    instance_byte_length.to_uint64(),
  )
  render_pass.draw_indexed(mesh_entry.index_count, instance_count~)
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  self.queue.submit(command_buffer)
  encoder.release()
}

///|
/// Releases renderer-owned GPU resources.
pub fn Renderer::release(self : Renderer) -> Unit {
  for i = 0; i < self.meshes.length(); i = i + 1 {
    self.meshes[i].vertex_buffer.release()
    self.meshes[i].index_buffer.release()
  }
  for i = 0; i < self.instance_buffers.length(); i = i + 1 {
    self.instance_buffers[i].buffer.release()
  }
  release_bind_group(self.bind_transforms)
  release_bind_group(self.bind_camera)
  release_buffer(self.transform_storage)
  release_buffer(self.camera_storage)
  release_buffer(self.renderable_instance_buffer)
  for i = 0; i < self.pipeline_entries.length(); i = i + 1 {
    self.pipeline_entries[i].pipeline.release()
  }
  self.pipeline_layout.release()
  @wgpu.bindGroupLayout_release(self.transform_layout)
  @wgpu.bindGroupLayout_release(self.camera_layout)
}
