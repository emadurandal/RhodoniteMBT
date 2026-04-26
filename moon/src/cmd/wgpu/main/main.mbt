///| Native wgpu: 全画面三角（`vertex_index` から生成する 3 頂点）をオフスクリーン 1x1 に描画。
///|
fn main {
  @wgpu.with_default_device_queue_sync((instance, device, queue) => {
    let _ = instance
    let tex = device.create_texture_rgba8_2d(1U, 1U)
    let view = tex.create_view()
    let wgsl : String =
      #|struct VSOut { @builtin(position) pos: vec4<f32> };
      #|
      #|@vertex
      #|fn vs_main(@builtin(vertex_index) vid: u32) -> VSOut {
      #|  var positions = array<vec2<f32>, 3>(
      #|    vec2<f32>(-1.0, -1.0),
      #|    vec2<f32>( 3.0, -1.0),
      #|    vec2<f32>(-1.0,  3.0),
      #|  );
      #|  var out: VSOut;
      #|  out.pos = vec4<f32>(positions[vid], 0.0, 1.0);
      #|  return out;
      #|}
      #|
      #|@fragment
      #|fn fs_main() -> @location(0) vec4<f32> {
      #|  return vec4<f32>(0.0, 0.7, 1.0, 1.0);
      #|}
      #|
    let sm = device.create_shader_module_wgsl(wgsl)
    let pipeline = device.create_render_pipeline_rgba8(sm)
    let encoder = device.create_command_encoder()
    let pass = encoder.begin_render_pass_color(view)
    pass.set_pipeline(pipeline)
    pass.draw(3U, 1U, 0U, 0U)
    pass.end()
    pass.release()
    let cmd = encoder.finish()
    queue.submit_one(cmd)
    let _ = device.poll(wait=true)
    cmd.release()
    encoder.release()
    pipeline.release()
    sm.release()
    view.release()
    tex.release()
  }) catch {
    _ => println("wgpu: error")
  }
}
