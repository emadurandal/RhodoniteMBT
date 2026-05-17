///|
/// Stores the browser demo engine after asynchronous initialization.
let demo_engine : @ref.Ref[@app.Engine?] = @ref.new(None)

///|
/// Converts DOM pointer button indices to the shared mouse button enum.
fn mouse_button_from_dom(button : Int) -> @input.MouseButton {
  match button {
    0 => Left
    1 => Middle
    2 => Right
    3 => Back
    4 => Forward
    _ => Other(button)
  }
}

///|
/// Enqueues an input event when the demo engine is initialized.
fn enqueue_input(event : @input.InputEvent) -> Unit {
  match demo_engine.val {
    Some(engine) => engine.input().enqueue_event(event)
    None => ()
  }
}

///|
/// Creates the browser WebGPU demo state and registers engine handlers.
async fn create_webgpu_demo_state_async(
  canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let ctx = @html_ctx.gpu_context_from_html_canvas(canvas)
  let engine = @app.Engine::new(ctx)
  match @demo_state.create_demo_state_for_engine(engine) {
    Some(demo_state) => {
      @demo_state.register_engine_handlers(engine, demo_state)
      engine.initialize()
      demo_engine.val = Some(engine)
      println("ecs-scene-graph: DemoState ready")
    }
    None => println("ecs-scene-graph: failed to create DemoState")
  }
}

///|
/// Implements `create_webgpu_demo_state`.
pub fn create_webgpu_demo_state(
  canvas : @wgpu.HTMLCanvasElement,
) -> @js_async.Promise[Unit] {
  @js_async.Promise::from_async(() => create_webgpu_demo_state_async(canvas))
}

///|
/// Implements `ecs_scene_graph_render_tick`.
pub fn ecs_scene_graph_render_tick(delta_seconds : Double) -> Unit {
  match demo_engine.val {
    Some(engine) => ignore(engine.run_frame(Float::from_double(delta_seconds)))
    _ => ()
  }
}

///|
/// Implements `ecs_scene_graph_input_pointer_move`.
pub fn ecs_scene_graph_input_pointer_move(x : Double, y : Double) -> Unit {
  enqueue_input(PointerMove(Float::from_double(x), Float::from_double(y)))
}

///|
/// Implements `ecs_scene_graph_input_mouse_down`.
pub fn ecs_scene_graph_input_mouse_down(
  button : Int,
  x : Double,
  y : Double,
) -> Unit {
  enqueue_input(
    MouseDown(
      mouse_button_from_dom(button),
      Float::from_double(x),
      Float::from_double(y),
    ),
  )
}

///|
/// Implements `ecs_scene_graph_input_mouse_up`.
pub fn ecs_scene_graph_input_mouse_up(
  button : Int,
  x : Double,
  y : Double,
) -> Unit {
  enqueue_input(
    MouseUp(
      mouse_button_from_dom(button),
      Float::from_double(x),
      Float::from_double(y),
    ),
  )
}

///|
/// Implements `ecs_scene_graph_input_wheel`.
pub fn ecs_scene_graph_input_wheel(delta_x : Double, delta_y : Double) -> Unit {
  enqueue_input(Wheel(Float::from_double(delta_x), Float::from_double(delta_y)))
}

///|
/// Implements `ecs_scene_graph_input_focus_lost`.
pub fn ecs_scene_graph_input_focus_lost() -> Unit {
  enqueue_input(FocusLost)
}

///|
/// Provides the package entry point for MoonBit JS builds.
fn main {
  println("ecs-scene-graph js stub")
}
