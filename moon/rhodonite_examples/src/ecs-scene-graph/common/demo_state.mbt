/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
let camera_elevation_rad : Double = 0.38

///|
/// Defines `DemoState`.
pub(all) struct DemoState {
  context : @wgpu.GPUCanvasContext?
  renderer : @app.Renderer
  target : @app.RenderTargetResources
  scene : @app.Scene
  bodies : Array[@ecs.EntityId]
  gt : @ecs.ComponentTypeId
  frame : @ref.Ref[Int]
}

///|
/// Defines interactive Undo/Redo sample state layered over the scene graph demo.
pub(all) struct UndoRedoDemoState {
  demo : DemoState
  history : @ecs.WorldHistory
  mut edit_index : Int
}

///|
/// Internal action selected by one Undo/Redo sample keyboard shortcut.
enum UndoRedoShortcut {
  NoShortcut
  ApplyMove
  UndoShortcut
  RedoShortcut
} derive(Eq)

///|
/// Implements `quat_y`.
fn quat_y(angle : Double) -> (Double, Double, Double, Double) {
  let half = angle * 0.5
  let s = @math.sin(half)
  let c = @math.cos(half)
  (0.0, s, 0.0, c)
}

///|
/// Updates sample animation inputs before the owning engine runs the scene system_runner.
pub fn DemoState::update_scene(
  self : DemoState,
  frame : @app.FrameState,
) -> Unit {
  let world = self.scene.world()
  let bodies = self.bodies
  let t = frame.elapsed_seconds()
  let sun_angle = t * 0.35
  let earth_orbit = t * 0.9
  let earth_spin = t * 2.2
  let moon_orbit = t * 2.8
  let (sqx, sqy, sqz, sqw) = quat_y(sun_angle)
  ignore(
    world.set_transform_trs(
      bodies[0],
      (0.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      sqx,
      sqy,
      sqz,
      sqw,
      (0.55 : Float),
      (0.55 : Float),
      (0.55 : Float),
    ),
  )
  let ex = @math.cos(earth_orbit) * 2.35
  let ez = @math.sin(earth_orbit) * 2.35
  let (eqx, eqy, eqz, eqw) = quat_y(earth_spin)
  ignore(
    world.set_transform_trs(
      bodies[1],
      Float::from_double(ex),
      (0.0 : Float),
      Float::from_double(ez),
      eqx,
      eqy,
      eqz,
      eqw,
      (0.22 : Float),
      (0.22 : Float),
      (0.22 : Float),
    ),
  )
  let moon_orbit_radius = 1.05
  let mx = @math.cos(moon_orbit) * moon_orbit_radius
  let mz = @math.sin(moon_orbit) * moon_orbit_radius
  ignore(
    world.set_transform_trs(
      bodies[2],
      Float::from_double(mx),
      (0.0 : Float),
      Float::from_double(mz),
      0.0,
      0.0,
      0.0,
      1.0,
      (0.5 : Float),
      (0.5 : Float),
      (0.5 : Float),
    ),
  )
}

///|
/// Renders a scene by uploading scene-owned ECS data and issuing draw commands.
pub fn DemoState::render_scene(
  self : DemoState,
  scene : @app.Scene,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  self.renderer.render_scene_renderables(scene, self.target, color_view)
}

///|
/// Renders the current scene state without advancing app time or running systems.
pub fn render_current_frame(demo_state : DemoState) -> Unit {
  let canvas_context = match demo_state.context {
    Some(c) => c
    None => abort("render_current_frame requires a canvas context")
  }
  let texture = canvas_context.get_current_texture()
  let color_view = texture.create_view()
  demo_state.render_scene(demo_state.scene, color_view)
  @wgpu.textureView_release(color_view)
  canvas_context.present()
}

///|
/// Registers engine phase handlers that drive this DemoState.
pub fn register_engine_handlers(
  engine : @app.Engine,
  demo_state : DemoState,
) -> Unit {
  engine.on_scene_update(demo_state.scene, fn(frame) {
    demo_state.update_scene(frame)
  })
  engine.on_scene_render(demo_state.scene, fn(_frame) {
    render_current_frame(demo_state)
  })
}

///|
/// Creates demo state backed by caller-owned renderer and target resources.
pub fn create_demo_state(
  scene : @app.Scene,
  renderer : @app.Renderer,
  target : @app.RenderTargetResources,
  context? : @wgpu.GPUCanvasContext? = None,
) -> DemoState {
  let world = scene.world()
  let camera = world.create_entity()
  let sun = world.create_entity()
  let earth = world.create_entity()
  let moon = world.create_entity()
  let bodies : Array[@ecs.EntityId] = [sun, earth, moon]
  let gt = world.global_transform_component()
  let id_m = @m44.Matrix44F::identity()
  ignore(world.set_global_transform(sun, id_m))
  ignore(world.set_global_transform(earth, id_m))
  ignore(world.set_global_transform(moon, id_m))
  ignore(world.set_child_of(earth, sun))
  ignore(world.set_child_of(moon, earth))
  scene.set_main_camera(Some(camera))
  ignore(
    @ecs.setup_orbit_orthographic_camera(
      world,
      camera,
      @ecs.OrbitOrthographicCameraDesc::new_yz_pitched(
        camera_elevation_rad,
        (2.0 : Float),
        (5.6 : Float),
        (0.1 : Float),
        (50.0 : Float),
        (1.0 : Float),
        (3.8 : Float),
      ),
    ),
  )
  let cube_mesh = renderer.register_cube_mesh(
    desc=@app.CubeMeshDesc::new(half_extent=0.42),
  )
  let sun_material = renderer.register_unlit_material(
    @app.UnlitMaterialDesc::new(1.0, 0.65, 0.15),
  )
  let earth_material = renderer.register_unlit_material(
    @app.UnlitMaterialDesc::new(0.2, 0.55, 1.0),
  )
  let moon_material = renderer.register_unlit_material(
    @app.UnlitMaterialDesc::new(1.0, 0.0, 1.0),
  )
  ignore(
    @app.add_renderable(
      scene,
      sun,
      @app.RenderableDesc::new(cube_mesh, sun_material),
    ),
  )
  ignore(
    @app.add_renderable(
      scene,
      earth,
      @app.RenderableDesc::new(cube_mesh, earth_material),
    ),
  )
  ignore(
    @app.add_renderable(
      scene,
      moon,
      @app.RenderableDesc::new(cube_mesh, moon_material),
    ),
  )
  let demo_state = {
    context,
    renderer,
    target,
    scene,
    bodies,
    gt,
    frame: @ref.new(0),
  }
  demo_state.update_scene(@app.FrameState::new((0.0 : Float), 0, 0.0))
  demo_state
}

///|
/// Applies the deterministic Undo/Redo visual edit to one visible scene body.
pub fn DemoState::apply_undo_redo_visual_edit(self : DemoState) -> Bool {
  let world = self.scene.world()
  let history = @ecs.WorldHistory::new()
  let body = self.bodies[1]
  let ok = history.with_transaction(world, "Scene Graph Visual Move", fn() {
    history.set_transform_trs(
      world,
      body,
      (1.15 : Float),
      (0.0 : Float),
      (1.65 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (0.36 : Float),
      (0.36 : Float),
      (0.36 : Float),
    )
  })
  if !ok {
    return false
  }
  if !history.undo(world) {
    return false
  }
  if !history.redo(world) {
    return false
  }
  self.scene.prepare_render_state()
}

///|
/// Creates interactive Undo/Redo state for the current engine scene.
pub fn create_undo_redo_demo_state(
  scene : @app.Scene,
  renderer : @app.Renderer,
  target : @app.RenderTargetResources,
  context? : @wgpu.GPUCanvasContext? = None,
) -> UndoRedoDemoState {
  {
    demo: create_demo_state(scene, renderer, target, context~),
    history: @ecs.WorldHistory::new(),
    edit_index: 0,
  }
}

///|
/// Applies one tracked scene edit for the interactive Undo/Redo sample.
pub fn UndoRedoDemoState::apply_move(self : UndoRedoDemoState) -> Bool {
  let world = self.demo.scene.world()
  let body = self.demo.bodies[1]
  let next_index = self.edit_index + 1
  let offset = Float::from_double((next_index % 4).to_double() * 0.35)
  let ok = self.history.with_transaction(world, "Move Earth \{next_index}", fn() {
    self.history.set_transform_trs(
      world,
      body,
      (1.15 : Float) + offset,
      (0.0 : Float),
      (1.65 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (0.36 : Float),
      (0.36 : Float),
      (0.36 : Float),
    )
  })
  if ok {
    self.edit_index = next_index
    ignore(self.demo.scene.prepare_render_state())
  }
  ok
}

///|
/// Undoes one interactive sample edit and refreshes renderable state.
pub fn UndoRedoDemoState::undo(self : UndoRedoDemoState) -> Bool {
  let ok = self.history.undo(self.demo.scene.world())
  if ok {
    ignore(self.demo.scene.prepare_render_state())
  }
  ok
}

///|
/// Redoes one interactive sample edit and refreshes renderable state.
pub fn UndoRedoDemoState::redo(self : UndoRedoDemoState) -> Bool {
  let ok = self.history.redo(self.demo.scene.world())
  if ok {
    ignore(self.demo.scene.prepare_render_state())
  }
  ok
}

///|
/// Reports whether a platform command modifier is active.
fn command_modifier_pressed(modifiers : @input.Modifiers) -> Bool {
  modifiers.ctrl() || modifiers.meta()
}

///|
/// Classifies the first Undo/Redo sample shortcut in the current input frame.
fn undo_redo_shortcut_from_input(input : @input.InputState) -> UndoRedoShortcut {
  let events = input.events()
  for i = 0; i < events.length(); i = i + 1 {
    match events[i] {
      KeyDown(key, modifiers, repeat) =>
        if !repeat {
          let command = command_modifier_pressed(modifiers)
          if !command &&
            (
              key == @input.KeyCode::key_m() ||
              key == @input.KeyCode::space() ||
              key == @input.KeyCode::enter()
            ) {
            return ApplyMove
          }
          if command && key == @input.KeyCode::key_z() {
            if modifiers.shift() {
              return RedoShortcut
            }
            return UndoShortcut
          }
          if command && key == @input.KeyCode::key_y() {
            return RedoShortcut
          }
        }
      _ => ()
    }
  }
  NoShortcut
}

///|
/// Handles keyboard input for the interactive Undo/Redo sample.
pub fn UndoRedoDemoState::update_from_input(
  self : UndoRedoDemoState,
  input : @input.InputState,
) -> Bool {
  match undo_redo_shortcut_from_input(input) {
    ApplyMove => self.apply_move()
    UndoShortcut => self.undo()
    RedoShortcut => self.redo()
    NoShortcut => false
  }
}

///|
/// Registers input and render handlers for the interactive Undo/Redo sample.
pub fn register_undo_redo_engine_handlers(
  engine : @app.Engine,
  demo_state : UndoRedoDemoState,
) -> Unit {
  engine.add_phase_handler(
    @app.phase_input(),
    fn(engine, _frame) {
      if demo_state.update_from_input(engine.input()) {
        engine.request_render("undo-redo")
      }
    },
    slot=@app.PhaseSlot::AfterSystems,
  )
  engine.on_scene_render(demo_state.demo.scene, fn(_frame) {
    render_current_frame(demo_state.demo)
  })
}

///|
/// Creates DemoState, applies the Undo/Redo visual edit, and registers rendering only.
pub fn setup_undo_redo_visual_engine(engine : @app.Engine) -> Bool {
  let (_device, canvas_context, _format, _queue) = engine.gpu_context().get()
  let demo_state = create_demo_state(
    engine.main_scene(),
    engine.renderer(),
    engine.render_target_resources(),
    context=Some(canvas_context),
  )
  if !demo_state.apply_undo_redo_visual_edit() {
    return false
  }
  engine.on_scene_render(demo_state.scene, fn(_frame) {
    render_current_frame(demo_state)
  })
  true
}

///|
/// Creates interactive Undo/Redo state and registers input/render handlers.
pub fn setup_undo_redo_interactive_engine(engine : @app.Engine) -> Bool {
  let (_device, canvas_context, _format, _queue) = engine.gpu_context().get()
  let demo_state = create_undo_redo_demo_state(
    engine.main_scene(),
    engine.renderer(),
    engine.render_target_resources(),
    context=Some(canvas_context),
  )
  register_undo_redo_engine_handlers(engine, demo_state)
  true
}

///|
/// Creates DemoState and registers the sample engine handlers.
pub fn setup_engine(engine : @app.Engine) -> Bool {
  let (_device, canvas_context, _format, _queue) = engine.gpu_context().get()
  let demo_state = create_demo_state(
    engine.main_scene(),
    engine.renderer(),
    engine.render_target_resources(),
    context=Some(canvas_context),
  )
  register_engine_handlers(engine, demo_state)
  true
}
