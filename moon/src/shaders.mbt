// WGSL shader code for triangle rendering

///|
pub let vertex_shader_code : String =
  #| struct VertexOutput {
  #|   @builtin(position) position: vec4<f32>,
  #|   @location(0) color: vec3<f32>,
  #| };
  #| 
  #| @vertex
  #| fn vertexMain(@builtin(vertex_index) vertexIndex: u32) -> VertexOutput {
  #|   var pos = array<vec2<f32>, 3>(
  #|     vec2<f32>(0.0, 0.5),    // top - red
  #|     vec2<f32>(-0.5, -0.5),  // bottom left - green
  #|     vec2<f32>(0.5, -0.5)    // bottom right - blue
  #|   );
  #|   
  #|   var colors = array<vec3<f32>, 3>(
  #|     vec3<f32>(1.0, 0.0, 0.0),  // red
  #|     vec3<f32>(0.0, 1.0, 0.0),  // green
  #|     vec3<f32>(0.0, 0.0, 1.0)   // blue
  #|   );
  #| 
  #|   var output: VertexOutput;
  #|   output.position = vec4<f32>(pos[vertexIndex], 0.0, 1.0);
  #|   output.color = colors[vertexIndex];
  #|   return output;
  #| }

///|
pub let fragment_shader_code : String =
  #| @fragment
  #| fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
  #|   return vec4<f32>(color, 1.0);
  #| }
