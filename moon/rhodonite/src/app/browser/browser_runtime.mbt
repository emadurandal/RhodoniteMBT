///|
/// Handle returned by the browser requestAnimationFrame loop helper.
pub type BrowserFrameLoop

///|
/// Handle returned by the browser DOM input binding helper.
pub type BrowserInputBinding

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
/// Stops a browser frame loop returned by `start_browser_frame_loop`.
pub extern "js" fn BrowserFrameLoop::stop(self : BrowserFrameLoop) -> Unit =
  #| (self) => self.stop()

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
    },
    fn(code, shift, ctrl, alt, meta) {
      input.enqueue_event(
        KeyUp(
          @input.KeyCode::new(code),
          @input.Modifiers::new(shift, ctrl, alt, meta),
        ),
      )
    },
    fn(x, y) {
      input.enqueue_event(
        PointerMove(Float::from_double(x), Float::from_double(y)),
      )
    },
    fn(button, x, y) {
      input.enqueue_event(
        MouseDown(
          mouse_button_from_browser(button),
          Float::from_double(x),
          Float::from_double(y),
        ),
      )
    },
    fn(button, x, y) {
      input.enqueue_event(
        MouseUp(
          mouse_button_from_browser(button),
          Float::from_double(x),
          Float::from_double(y),
        ),
      )
    },
    fn(delta_x, delta_y) {
      input.enqueue_event(
        Wheel(Float::from_double(delta_x), Float::from_double(delta_y)),
      )
    },
    fn() { input.enqueue_event(FocusLost) },
  )
}
