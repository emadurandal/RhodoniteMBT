///|
/// Handle returned by the browser requestAnimationFrame loop helper.
pub type BrowserFrameLoop

///|
/// Handle returned by the browser DOM input binding helper.
pub type BrowserInputBinding

///|
/// Configuration for the browser platform lifecycle owner.
pub struct PlatformConfig {
  priv canvas : @wgpu.HTMLCanvasElement
}

///|
/// Application hooks used by the browser platform to create and set up an engine.
pub struct PlatformApp {
  priv create_engine : (@wgpu.GPUContext) -> @app.Engine
  priv setup_engine : (@app.Engine) -> Bool
}

///|
/// Browser platform frame driving mode.
pub enum FrameMode {
  Loop
  SingleFrame
  OnDemand
}

///|
/// Options for starting the standard browser platform.
pub struct PlatformOptions {
  frame_mode : FrameMode
  priv install_input : Bool
}

///|
/// Owns browser platform resources for one engine.
pub struct Platform {
  priv engine : @app.Engine
  priv mut frame_loop : BrowserFrameLoop?
  priv mut input_binding : BrowserInputBinding?
  priv mut disposed : Bool
}

///|
/// Builds browser platform configuration from a canvas.
pub fn PlatformConfig::new(canvas : @wgpu.HTMLCanvasElement) -> PlatformConfig {
  { canvas, }
}

///|
/// Builds browser platform application hooks.
pub fn PlatformApp::new(
  create_engine : (@wgpu.GPUContext) -> @app.Engine,
  setup_engine : (@app.Engine) -> Bool,
) -> PlatformApp {
  { create_engine, setup_engine }
}

///|
/// Builds browser platform application hooks using the default engine constructor.
pub fn PlatformApp::default_engine(
  setup_engine : (@app.Engine) -> Bool,
) -> PlatformApp {
  PlatformApp::new(fn(context) { @app.Engine::new(context) }, setup_engine)
}

///|
/// Creates browser platform options for an interactive canvas sample.
pub fn PlatformOptions::interactive() -> PlatformOptions {
  { frame_mode: Loop, install_input: true }
}

///|
/// Creates browser platform options for a render-only loop.
pub fn PlatformOptions::render_loop() -> PlatformOptions {
  { frame_mode: Loop, install_input: false }
}

///|
/// Creates browser platform options for interactive on-demand rendering.
pub fn PlatformOptions::interactive_on_demand() -> PlatformOptions {
  { frame_mode: OnDemand, install_input: true }
}

///|
/// Creates browser platform options for render-only on-demand rendering.
pub fn PlatformOptions::render_on_demand() -> PlatformOptions {
  { frame_mode: OnDemand, install_input: false }
}

///|
/// Creates browser platform options for a single-frame canvas sample.
pub fn PlatformOptions::single_frame() -> PlatformOptions {
  { frame_mode: SingleFrame, install_input: false }
}

///|
/// Replaces the active browser platform for a canvas in the JS-side registry.
extern "js" fn replace_platform_for_canvas(
  canvas : @wgpu.HTMLCanvasElement,
  platform : Platform,
  dispose_platform : (Platform) -> Unit,
) -> Unit =
  #| (canvas, platform, disposePlatform) => {
  #|   const key = "__rhodonite_browser_platforms";
  #|   const platforms =
  #|     globalThis[key] ?? (globalThis[key] = new WeakMap());
  #|   const existing = platforms.get(canvas);
  #|   if (existing !== undefined && existing !== platform) {
  #|     disposePlatform(existing);
  #|   }
  #|   platforms.set(canvas, platform);
  #| }

///|
/// Stops and removes the active browser platform for a canvas.
extern "js" fn stop_platform_for_canvas(
  canvas : @wgpu.HTMLCanvasElement,
  dispose_platform : (Platform) -> Unit,
) -> Unit =
  #| (canvas, disposePlatform) => {
  #|   const key = "__rhodonite_browser_platforms";
  #|   const platforms = globalThis[key];
  #|   if (platforms === undefined) {
  #|     return;
  #|   }
  #|   const existing = platforms.get(canvas);
  #|   if (existing === undefined) {
  #|     return;
  #|   }
  #|   disposePlatform(existing);
  #|   platforms.delete(canvas);
  #| }

///|
/// Disposes browser platform handles and shuts down the owned engine once.
pub fn Platform::dispose(self : Platform) -> Unit {
  if self.disposed {
    return
  }
  self.disposed = true
  self.engine.set_render_wakeup(None)
  match self.frame_loop {
    Some(frame_loop) => frame_loop.stop()
    None => ()
  }
  match self.input_binding {
    Some(input_binding) => input_binding.dispose()
    None => ()
  }
  self.frame_loop = None
  self.input_binding = None
  self.engine.shutdown()
}

///|
/// Builds a WebGPU context from a browser canvas element.
pub async fn gpu_context_from_html_canvas(
  canvas : @wgpu.HTMLCanvasElement,
) -> @wgpu.GPUContext raise Error {
  let instance = @wgpu.create_webgpu_instance(@wgpu.navigatorGPU())
  let adapter = instance.request_adapter()
  let device = adapter.request_device()
  let webgpu_canvas_context = @wgpu.create_canvas_context(
    @wgpu.canvas_getContext(canvas),
  )
  let format = instance.get_preferred_canvas_format_for_surface(
    adapter, webgpu_canvas_context,
  )
  webgpu_canvas_context.configure(device, format)
  let queue = device.get_queue()
  @wgpu.create_webgpu_context(device, webgpu_canvas_context, format, queue)
}

///|
/// Starts a browser `requestAnimationFrame` loop and passes elapsed seconds.
pub extern "js" fn start_browser_frame_loop(
  tick : (Double) -> Unit,
) -> BrowserFrameLoop =
  #| (tick) => {
  #|   let stopped = false;
  #|   let previousTimestamp = null;
  #|   let requestId = 0;
  #|   const loop = (timestamp) => {
  #|     if (stopped) {
  #|       return;
  #|     }
  #|     const deltaSeconds =
  #|       previousTimestamp === null ? 0 : (timestamp - previousTimestamp) / 1000;
  #|     previousTimestamp = timestamp;
  #|     tick(deltaSeconds);
  #|     if (!stopped) {
  #|       requestId = requestAnimationFrame(loop);
  #|     }
  #|   };
  #|   requestId = requestAnimationFrame(loop);
  #|   return {
  #|     stop() {
  #|       stopped = true;
  #|       if (requestId !== 0) {
  #|         cancelAnimationFrame(requestId);
  #|         requestId = 0;
  #|       }
  #|     },
  #|   };
  #| }

///|
/// Starts an on-demand browser frame loop that only schedules frames when requested.
pub extern "js" fn start_browser_on_demand_frame_loop(
  tick : (Double) -> Unit,
  should_continue : () -> Bool,
) -> BrowserFrameLoop =
  #| (tick, shouldContinue) => {
  #|   let stopped = false;
  #|   let scheduled = false;
  #|   let previousTimestamp = null;
  #|   let requestId = 0;
  #|   const request = () => {
  #|     if (stopped || scheduled) {
  #|       return;
  #|     }
  #|     scheduled = true;
  #|     requestId = requestAnimationFrame(loop);
  #|   };
  #|   const loop = (timestamp) => {
  #|     if (stopped) {
  #|       return;
  #|     }
  #|     scheduled = false;
  #|     const deltaSeconds =
  #|       previousTimestamp === null ? 0 : (timestamp - previousTimestamp) / 1000;
  #|     previousTimestamp = timestamp;
  #|     tick(deltaSeconds);
  #|     if (!stopped && shouldContinue()) {
  #|       request();
  #|     } else {
  #|       previousTimestamp = null;
  #|     }
  #|   };
  #|   return {
  #|     request,
  #|     stop() {
  #|       stopped = true;
  #|       if (scheduled && requestId !== 0) {
  #|         cancelAnimationFrame(requestId);
  #|       }
  #|       scheduled = false;
  #|       requestId = 0;
  #|     },
  #|   };
  #| }

///|
/// Stops a browser frame loop returned by `start_browser_frame_loop`.
pub extern "js" fn BrowserFrameLoop::stop(self : BrowserFrameLoop) -> Unit =
  #| (self) => self.stop()

///|
/// Requests one frame from an on-demand browser frame loop.
pub extern "js" fn BrowserFrameLoop::request(self : BrowserFrameLoop) -> Unit =
  #| (self) => {
  #|   if (typeof self.request === "function") {
  #|     self.request();
  #|   }
  #| }

///|
/// Returns the canvas backing width in pixels.
pub extern "js" fn browser_canvas_width(
  canvas : @wgpu.HTMLCanvasElement,
) -> Int =
  #| (canvas) => canvas.width | 0

///|
/// Returns the canvas backing height in pixels.
pub extern "js" fn browser_canvas_height(
  canvas : @wgpu.HTMLCanvasElement,
) -> Int =
  #| (canvas) => canvas.height | 0

///|
/// Synchronizes the engine surface state with a browser canvas backing size.
pub fn sync_browser_engine_surface(
  engine : @app.Engine,
  canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let width = browser_canvas_width(canvas)
  let height = browser_canvas_height(canvas)
  if width <= 0 || height <= 0 {
    engine.set_surface_suspended()
  } else {
    let (_device, _context, format, _queue) = engine.gpu_context().get()
    engine.set_surface_active(width, height, format)
  }
}

///|
/// Starts the standard browser frame loop for an initialized engine.
pub fn start_browser_engine_loop(engine : @app.Engine) -> BrowserFrameLoop {
  start_browser_frame_loop(fn(delta_seconds) {
    ignore(engine.run_frame(Float::from_double(delta_seconds)))
  })
}

///|
/// Starts the browser frame loop and propagates canvas backing-size changes to the engine.
pub fn start_browser_engine_canvas_loop(
  engine : @app.Engine,
  canvas : @wgpu.HTMLCanvasElement,
) -> BrowserFrameLoop {
  sync_browser_engine_surface(engine, canvas)
  start_browser_frame_loop(fn(delta_seconds) {
    sync_browser_engine_surface(engine, canvas)
    ignore(engine.run_frame(Float::from_double(delta_seconds)))
  })
}

///|
/// Starts an on-demand browser loop and wires engine render requests to RAF.
pub fn start_browser_engine_on_demand_canvas_loop(
  engine : @app.Engine,
  canvas : @wgpu.HTMLCanvasElement,
) -> BrowserFrameLoop {
  sync_browser_engine_surface(engine, canvas)
  let frame_loop = start_browser_on_demand_frame_loop(
    fn(delta_seconds) {
      sync_browser_engine_surface(engine, canvas)
      ignore(engine.run_frame(Float::from_double(delta_seconds)))
    },
    fn() { engine.render_requested() || engine.continuous_render_requested() },
  )
  engine.set_render_wakeup(Some(fn() { frame_loop.request() }))
  frame_loop.request()
  frame_loop
}

///|
/// Installs raw browser input callbacks on a canvas.
extern "js" fn install_browser_input_callbacks(
  canvas : @wgpu.HTMLCanvasElement,
  key_down : (String, Bool, Bool, Bool, Bool, Bool) -> Unit,
  key_up : (String, Bool, Bool, Bool, Bool) -> Unit,
  pointer_move : (Double, Double) -> Unit,
  mouse_down : (Int, Double, Double) -> Unit,
  mouse_up : (Int, Double, Double) -> Unit,
  wheel : (Double, Double) -> Unit,
  focus_lost : () -> Unit,
) -> BrowserInputBinding =
  #| (
  #|   canvas,
  #|   keyDown,
  #|   keyUp,
  #|   pointerMove,
  #|   mouseDown,
  #|   mouseUp,
  #|   wheel,
  #|   focusLost,
  #| ) => {
  #|   const canvasPoint = (event) => {
  #|     const rect = canvas.getBoundingClientRect();
  #|     const scaleX = canvas.width / rect.width;
  #|     const scaleY = canvas.height / rect.height;
  #|     return {
  #|       x: (event.clientX - rect.left) * scaleX,
  #|       y: (event.clientY - rect.top) * scaleY,
  #|     };
  #|   };
  #|   const onKeyDown = (event) => {
  #|     keyDown(
  #|       event.code,
  #|       event.shiftKey,
  #|       event.ctrlKey,
  #|       event.altKey,
  #|       event.metaKey,
  #|       event.repeat,
  #|     );
  #|   };
  #|   const onKeyUp = (event) => {
  #|     keyUp(event.code, event.shiftKey, event.ctrlKey, event.altKey, event.metaKey);
  #|   };
  #|   const onPointerMove = (event) => {
  #|     const point = canvasPoint(event);
  #|     pointerMove(point.x, point.y);
  #|   };
  #|   const onPointerDown = (event) => {
  #|     event.preventDefault();
  #|     if (typeof canvas.setPointerCapture === "function") {
  #|       canvas.setPointerCapture(event.pointerId);
  #|     }
  #|     const point = canvasPoint(event);
  #|     mouseDown(event.button, point.x, point.y);
  #|   };
  #|   const onPointerUp = (event) => {
  #|     const point = canvasPoint(event);
  #|     mouseUp(event.button, point.x, point.y);
  #|   };
  #|   const onWheel = (event) => {
  #|     event.preventDefault();
  #|     wheel(event.deltaX, event.deltaY);
  #|   };
  #|   window.addEventListener("keydown", onKeyDown);
  #|   window.addEventListener("keyup", onKeyUp);
  #|   canvas.addEventListener("pointermove", onPointerMove);
  #|   canvas.addEventListener("pointerdown", onPointerDown);
  #|   canvas.addEventListener("pointerup", onPointerUp);
  #|   canvas.addEventListener("wheel", onWheel, { passive: false });
  #|   window.addEventListener("blur", focusLost);
  #|   return {
  #|     dispose() {
  #|       window.removeEventListener("keydown", onKeyDown);
  #|       window.removeEventListener("keyup", onKeyUp);
  #|       canvas.removeEventListener("pointermove", onPointerMove);
  #|       canvas.removeEventListener("pointerdown", onPointerDown);
  #|       canvas.removeEventListener("pointerup", onPointerUp);
  #|       canvas.removeEventListener("wheel", onWheel);
  #|       window.removeEventListener("blur", focusLost);
  #|     },
  #|   };
  #| }

///|
/// Disposes a browser input binding returned by `install_browser_input`.
pub extern "js" fn BrowserInputBinding::dispose(
  self : BrowserInputBinding,
) -> Unit =
  #| (self) => self.dispose()

///|
/// Converts a browser pointer button index to the shared mouse button enum.
fn mouse_button_from_browser(button : Int) -> @input.MouseButton {
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
/// Installs browser keyboard, pointer, wheel, and blur events for an engine.
pub fn install_browser_input(
  engine : @app.Engine,
  canvas : @wgpu.HTMLCanvasElement,
) -> BrowserInputBinding {
  let input = engine.input()
  install_browser_input_callbacks(
    canvas,
    fn(code, shift, ctrl, alt, meta, repeat) {
      input.enqueue_event(
        KeyDown(
          @input.KeyCode::new(code),
          @input.Modifiers::new(shift, ctrl, alt, meta),
          repeat,
        ),
      )
      engine.request_render("input")
    },
    fn(code, shift, ctrl, alt, meta) {
      input.enqueue_event(
        KeyUp(
          @input.KeyCode::new(code),
          @input.Modifiers::new(shift, ctrl, alt, meta),
        ),
      )
      engine.request_render("input")
    },
    fn(x, y) {
      input.enqueue_event(
        PointerMove(Float::from_double(x), Float::from_double(y)),
      )
      engine.request_render("input")
    },
    fn(button, x, y) {
      input.enqueue_event(
        MouseDown(
          mouse_button_from_browser(button),
          Float::from_double(x),
          Float::from_double(y),
        ),
      )
      engine.request_render("input")
    },
    fn(button, x, y) {
      input.enqueue_event(
        MouseUp(
          mouse_button_from_browser(button),
          Float::from_double(x),
          Float::from_double(y),
        ),
      )
      engine.request_render("input")
    },
    fn(delta_x, delta_y) {
      input.enqueue_event(
        Wheel(Float::from_double(delta_x), Float::from_double(delta_y)),
      )
      engine.request_render("input")
    },
    fn() {
      input.enqueue_event(FocusLost)
      engine.request_render("input")
    },
  )
}

///|
/// Starts the standard browser platform resources for an initialized engine.
pub fn start_platform(
  engine : @app.Engine,
  canvas : @wgpu.HTMLCanvasElement,
  options : PlatformOptions,
) -> Platform {
  sync_browser_engine_surface(engine, canvas)
  let frame_loop = match options.frame_mode {
    Loop => Some(start_browser_engine_canvas_loop(engine, canvas))
    OnDemand => Some(start_browser_engine_on_demand_canvas_loop(engine, canvas))
    SingleFrame => {
      ignore(engine.run_frame((0.0 : Float)))
      None
    }
  }
  let input_binding = if options.install_input {
    Some(install_browser_input(engine, canvas))
  } else {
    None
  }
  { engine, frame_loop, input_binding, disposed: false }
}

///|
/// Runs the browser platform lifecycle from configuration and application hooks.
pub async fn run_platform(
  config : PlatformConfig,
  app : PlatformApp,
  options : PlatformOptions,
) -> Platform? {
  let ctx = gpu_context_from_html_canvas(config.canvas)
  let engine = (app.create_engine)(ctx)
  if !(app.setup_engine)(engine) {
    return None
  }
  engine.initialize()
  let platform = start_platform(engine, config.canvas, options)
  replace_platform_for_canvas(config.canvas, platform, fn(platform) {
    platform.dispose()
  })
  Some(platform)
}

///|
/// Stops the active browser platform associated with a canvas.
pub fn stop_platform(canvas : @wgpu.HTMLCanvasElement) -> Unit {
  stop_platform_for_canvas(canvas, fn(platform) { platform.dispose() })
}
