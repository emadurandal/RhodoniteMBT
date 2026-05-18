# Engine / Scene Architecture Plan

この資料は、RhodoniteMBT に `Engine` / `Scene` の概念を導入するための初期設計案です。目的は、既存の ECS と WebGPU sample code を保ちながら、ゲームエンジンとしての実行単位、更新順序、描画責務を明確にすることです。

## 目標

- `World` を ECS storage として保ち、engine runtime の概念と混ぜない。
- `SystemRunner` は 1 つの `World` に対応させ、cross-world 処理を通常 system に混ぜない。
- `Scene` を runtime scene instance として導入し、`World`、`SystemRunner`、main camera、scene-level state をまとめる。
- `Engine` は platform、time、renderer、scene lifecycle を扱う。
- WebGPU resource の実体は `World` / `Scene` ではなく renderer 側で所有する。
- 既存の browser / native sample を段階的に `Engine` API へ移行できるようにする。

## 用語と責務

| 型 | 責務 |
|----|------|
| `Engine` | platform context、time/frame state、renderer、scene collection、phase handler registry を所有する実行基盤。 |
| `Scene` | runtime scene instance。1 つの `World` と 1 つの `SystemRunner` を所有し、main camera や enabled/visible state を持つ。 |
| `World` | ECS の entity/component/archetype storage。simulation data を持つ。 |
| `SystemRunner` | 1 つの `World` に対する system set。access guard と command buffer の適用境界を持つ。 |
| `Renderer` | WebGPU device/queue を使い、GPU buffer、texture、pipeline、material、mesh などを所有して描画する。 |

## 基本構造

```text
Engine
  owns Platform / WebGPU context
  owns TimeState / FrameState
  owns Renderer
  owns Scene[]

Scene
  owns World
  owns SystemRunner
  stores main_camera: EntityId?
  stores enabled / visible flags

World
  owns ECS entities and components
  owns builtin CPU refs and packed blob stores

Renderer
  owns GPU resources
  uploads builtin World blob changes
  draws visible renderables from Scene
```

`World` は「何が存在するか」を表し、`Renderer` は「GPU へどう流して描くか」を扱います。`Scene` は runtime 上の実行単位であり、`World + SystemRunner` を直接ばらばらに扱わせないための境界です。

## World と SystemRunner

`World` と `SystemRunner` は 1:1 の対応にします。

```text
Scene
  world: World
  system_runner: SystemRunner
```

1 つの `SystemRunner` が複数の `World` を扱う設計にはしません。理由は、既存 ECS の system access declaration が `World` の mutation guard と結びついているためです。

- `reads` / `writes` / `structural_write` の対象が曖昧になる。
- `ComponentTypeId` が world 間で同じ意味を持つ保証が必要になる。
- `CommandBuffer` の flush 先が曖昧になる。
- query 中 mutation guard を world ごとに分離する必要が出る。
- render extraction や synchronization の責務が scene-local system と engine-level task のどちらに属するか曖昧になる。

複数 scene / 複数 world 間の処理が必要になった場合は、scene-local `SystemRunner` ではなく、`PhaseKey` / `PhaseSlot` 上の engine-level task として扱います。

## Scene

`Scene` は `World` と `SystemRunner` をまとめる runtime scene instance です。

初期版の想定 state:

```text
Scene
  name: String
  world: World
  system_runner: SystemRunner
  main_camera: EntityId?
  enabled: Bool
  visible: Bool
```

初期 API の方向性:

```moonbit
let scene = Scene::new("main")
let entity = scene.world().create_entity()
scene.add_transform_propagation_system(phase_update())
scene.set_main_camera(camera)
```

`SystemRunner` は `Scene` 内部に隠し、system 登録や system runner 実行は `Scene` method 経由に寄せます。ECS component 登録や sample 固有の setup ではまだ `world()` への直接 access が必要なため、`World` は公開したままにします。

## Engine

`Engine` は application loop の実行基盤です。runtime は単一の `Engine` を中心にし、複数の実行対象が必要な場合は `Engine` が複数 `Scene` を持つ形で対応します。

初期版の想定 state:

```text
Engine
  renderer: Renderer
  scenes: Array[Scene]
  main_scene_index: Int
  frame_state: FrameState
  time_state: TimeState
  phase_handlers: Array[PhaseHandler]
```

初期 API の方向性:

```moonbit
let engine = Engine::new(context)
let scene = engine.main_scene()
engine.add_phase_handler(phase_update(), fn(engine, frame) { ... })
engine.initialize()
ignore(engine.run_frame(delta_seconds))
```

標準 frame tick の順序:

```text
Engine::run_frame
  input.begin_frame()
  update render time/frame state and capture the current surface snapshot
  run phase_group_frame_begin()
    run phase_surface()
    engine handlers in PhaseSlot::BeforeSystems
    enabled scene systems for Surface
    engine handlers in PhaseSlot::AfterSystems
    run phase_input()
    engine handlers in PhaseSlot::BeforeSystems
    enabled scene systems for Input
    engine handlers in PhaseSlot::AfterSystems
  accumulate fixed-step elapsed time
  run phase_group_fixed_step() 0..max_fixed_steps_per_frame times
    run phase_fixed_update()
    engine handlers / enabled scene systems / after handlers
    run phase_fixed_post_update()
    engine handlers / enabled scene systems / after handlers
  run phase_group_render_frame()
    run phase_update()
    engine handlers in PhaseSlot::BeforeSystems
    enabled scene systems for Update
    engine handlers in PhaseSlot::AfterSystems
    run phase_post_update()
    same slot/system-runner structure
    if surface is active: run phase_render_extract()
    same slot/system-runner structure
    if surface is active: run phase_render_prepare()
    same slot/system-runner structure
    if surface is active: run phase_render()
    engine handlers in PhaseSlot::BeforeSystems
    visible scene systems for Render
    engine handlers in PhaseSlot::AfterSystems
    if surface is active: run phase_present()
    same slot/system-runner structure
```

`Engine::run_frame(elapsed_seconds)` は frame-begin、fixed-step、render-frame group に total order を与える標準 runner です。platform loop は SDL tick 差分や browser `requestAnimationFrame(timestamp)` 差分を秒に変換して `run_frame` に渡します。engine は内部 accumulator に経過時間を積み、固定 delta ごとに `phase_group_fixed_step()` を 0 回以上実行してから、その tick の render-frame group を 1 回実行します。ただし browser tab の background 復帰や OS suspend 復帰で大きな delta が入っても一度に固定更新を走らせすぎないよう、1 tick あたりの固定ステップは既定で 5 回に打ち切り、まだ残る backlog は破棄します。`Engine::request_render(reason)` は on-demand platform に次の1フレーム描画を要求し、`Engine::request_continuous_render(reason)` / `Engine::stop_continuous_render(reason)` はアニメーションなどの継続描画を制御します。`Engine::set_surface_active(width, height, format)` / `Engine::set_surface_suspended()` は platform runtime から surface 状態を通知する入口で、実際に状態が変わった場合は描画を request します。`FrameState` はその frame の surface snapshot と `surface_changed` を持ち、`phase_surface()` handler は depth texture や renderer-owned resource を再作成できます。surface が suspended の間、engine は update/post-update までは進めますが `render_extract` / `render_prepare` / `render` / `present` を skip します。On-demand mode では dirty でない間 `run_frame` 自体が呼ばれないため、time progression、update、fixed update も停止します。Scene/ECS の任意変更を自動 dirty 化する仕組みは持たず、利用側は見た目が変わる state mutation の後に `request_render` を呼びます。`run_phase_group` / `run_phase` は特殊用途や test 用の低レベル API として残します。

`Engine` の内部 field や命名は `scenes` / `main_scene_index` にし、複数 scene へ拡張できるようにします。

## Engine Lifecycle

`Engine` は phase lifecycle に登録する handler registry も持ちます。`Engine::update` / `Engine::render` のような固定 per-frame callback は持たず、処理は `PhaseKey` と `PhaseSlot` に明示的に載せます。

目標 API:

```moonbit
let engine = Engine::new(context)
engine.add_phase_handler(phase_update(), fn(engine, frame) { ... })
engine.add_phase_handler(
  phase_render(),
  fn(engine, frame) { ... },
  slot=PhaseSlot::AfterSystems,
)
engine.initialize()
```

sample migration では、既存 sample の `DemoState` が持っていた update/render/shutdown 処理を、それぞれ `phase_update()` / `phase_render()` / `phase_shutdown()` handler として追加登録します。`Engine::add_phase_handler` は同じ phase/slot に複数 handler を登録でき、登録順に実行します。ここでの `DemoState` は sample 固有の pipeline、buffer、animation state をまとめるための枠組みであり、engine-owned な汎用 `Renderer` ではありません。renderer abstraction や material system を同時に入れすぎないようにします。

## WebGPU Renderer との関係

WebGPU context、device、queue、surface、GPU resources は最終的には `Engine` が所有する汎用 `Renderer` 側に置きます。`Scene` / `World` は GPU resource の所有者にしません。

## Multi-surface Platform

`Platform` は WebGPU device / queue と event loop を共有所有し、`Surface` は canvas/window/swapchain と surface-local input を所有する。`Engine` は `SurfaceId` で登録された複数 surface view を持ち、1 tick で update/fixed update を共有してから active surface ごとに render path を実行する。

`FrameState` は render path では `surface_id`、`surface`、`input` を持つ。depth texture や drawable size に依存する renderer resource は engine/global 単位ではなく `SurfaceId` keyed に保持する。入力は標準で surface-local とし、canvas/window A の pointer event は canvas/window B の camera controller に影響させない。

単一 surface 利用は引き続き主要ユースケースなので、browser は `run_single_canvas_platform(...)`、SDL3 は `run_single_window_platform(...)` を簡易 entry point として提供する。これらは互換 API ではなく、multi-surface 設計上の thin wrapper として扱う。

MassCubes のように大きな `GlobalTransform` storage buffer を丸ごと bind する sample があるため、browser / native の device creation では adapter が公開する最大の `maxStorageBufferBindingSize` を required limit として要求します。browser / TypeScript host では同時に `maxBufferSize` も最大値へ引き上げます。それでも必要 buffer size が adapter limit を超える場合は、単一 storage buffer ではなく buffer / binding を分割する設計が必要です。

```text
World
  Transform3D
  GlobalTransform
  Camera
  Renderable component with handles

Renderer
  MeshHandle -> GPU vertex/index buffers
  MaterialHandle -> shader/pipeline/bind groups
  TextureHandle -> GPU texture/sampler
  GlobalTransform upload buffer
  Camera upload buffer
```

既存 ECS の `GlobalTransform` / `Camera` packed blob store は当面そのまま使います。Camera 行列は `OrbitCameraController -> Transform3D -> GlobalTransform -> Camera blob` の流れに寄せ、標準 camera では `CameraLens` と `camera_blob_sync_system` が `GlobalTransform` から view/projection を生成します。orbit camera では `orbit_camera_blob_sync_system` が `OrbitCameraController` の dolly を orthographic projection に反映します。Phase 4 時点では sample-local な `DemoState` が scene の world から blob resize/write events を drain し、対応する GPU buffer へ upload します。Phase 5 で engine-owned な汎用 `Renderer` を導入し、この責務を resource table と `Renderable` component と一緒に移します。

重要な境界:

- `World` は `GPUDevice`、`GPUQueue`、`GPURenderPipeline` を持たない。
- `Scene` は render source であり、GPU resource owner ではない。
- Phase 4 の `DemoState` は scene の ECS data を query/extract して描画する暫定実装である。
- `OrbitCameraController` は Camera blob を直接更新せず、camera entity の `Transform3D` を更新する。reset は `CameraHomeTransform` の local TRS snapshot に戻す one-shot request として扱う。
- `Camera` blob 更新は `GlobalTransform + CameraLens` から行う。MassCubes のように sample 固有の framing が必要な場合も、render path ではなく render-extract 相当の custom camera solver に閉じ込める。MassCubes の custom solver は高 Entity 数で格子間隔がサブピクセルに潰れて orbit rotation が視認しづらくなることを避けるため、auto-fit 時の画面上 XZ grid pitch に下限を置く。
- Phase 5 の汎用 `Renderer` は `MeshHandle` / `MaterialHandle` / `TextureHandle` / `Renderable` を通じて scene を描画する。
- 将来の `Mesh` / `Material` / `Renderable` は ECS component 側に handle を置き、GPU 実体は renderer resource table に置く。

## 実装計画

### 現在の Phase 3 runtime package

Phase 3 で `Engine` / `Scene` は public facade の [`moon/rhodonite/src/app/`](../moon/rhodonite/src/app/) に昇格しました。import path は `emadurandal/rhodonite/app` です。Phase 1/2 の `moon/rhodonite_examples/src/common/app/` prototype は削除済みで、examples は facade package を直接 import します。

現在の runtime package は次の型を持ちます。

| 型 | 現在の内容 |
|----|------------|
| `SurfaceState` | drawable surface の `width`、`height`、`format`、`active`、`generation`。 |
| `FrameState` | `delta_seconds`、`frame_index`、`elapsed_seconds`、surface snapshot、`surface_changed`。`SystemContext` へ変換できる。 |
| `PhaseKey` | 文字列名を持つ open phase id。`phase("user/foo")` で追加でき、標準 phase は `phase_surface()`、`phase_update()`、`phase_render_extract()`、`phase_render()` などで取得する。 |
| `PhaseGroupKey` | 文字列名を持つ open phase group id。`phase_group("user/simulation")` で追加でき、標準 group は `phase_group_frame_begin()`、`phase_group_fixed_step()`、`phase_group_render_frame()` で取得する。 |
| `PhaseSlot` | phase 内の `BeforeSystems` / `AfterSystems` 実行帯。system runner 外処理や将来の renderer task を phase lifecycle 内に置く。 |
| `TimeState` | render-frame clock と fixed-step clock を持つ。render は caller-supplied delta、fixed は accumulator と固定 delta で進む。固定ステップは 1 tick あたりの上限を持ち、超過 backlog を破棄できる。 |
| `Scene` | 1 つの `World` と 1 つの `SystemRunner`、`main_camera`、enabled/visible state を持つ。 |
| `Engine` | `GPUContext`、scene collection、main scene index、time state、phase groups、phase handler registry、on-demand rendering state を持つ。`add_phase_handler` で handler を追加登録し、`request_render` / `request_continuous_render` で platform に描画要求を伝え、`run_frame(elapsed_seconds)` は frame-begin、fixed-step、render-frame group を標準順序で実行する。 |

`Engine::initialize()` は `phase_startup()` handler を実行し、その実行中だけ phase group の編集を許可します。標準 group として `phase_group_frame_begin()`、`phase_group_fixed_step()`、`phase_group_render_frame()` があり、必要なら `Engine::add_phase_group(group)` で custom group を追加できます。phase の追加は `append_phase_to_group(group, phase)`、`insert_phase_before_in_group(group, anchor, phase)`、`insert_phase_after_in_group(group, anchor, phase)` で行います。`phase_startup()` / `phase_shutdown()` は OneShot Phase なので、どの phase group にも追加できず、anchor にも使えません。render-frame group の先頭に独自 phase を置きたい場合は、startup handler 内で `insert_phase_before_in_group(phase_group_render_frame(), phase_update(), custom_phase)` を使います。その後、登録 handler が `phase_startup()`、`phase_shutdown()`、またはいずれかの phase group に含まれる phase だけを使っているか検証します。未登録 phase を `Engine::add_phase_handler` に渡した場合は `Engine::initialize()` で error になります。`Engine::run_frame(delta_seconds)`、`Engine::run_phase_group(group, frame)`、`Engine::run_phase(phase, frame)`、`Engine::shutdown()` は `Engine::initialize()` 済みであることを要求します。

WebGPU sample の browser/native entry point は library platform へ移行済みです。[`basic-triangle`](../moon/rhodonite_examples/src/basic-triangle/)、[`ondemand-triangle`](../moon/rhodonite_examples/src/ondemand-triangle/)、[`triangle-with-buffer`](../moon/rhodonite_examples/src/triangle-with-buffer/)、[`ecs-scene-graph`](../moon/rhodonite_examples/src/ecs-scene-graph/)、[`ecs-mass-cubes`](../moon/rhodonite_examples/src/ecs-mass-cubes/) は `Engine::run_frame(delta_seconds)` から標準 frame tick を駆動します。native は `emadurandal/rhodonite_app_sdl3/sdl3` の `run_platform(config, app, options)` が SDL tick 差分を秒に変換して渡し、browser は `emadurandal/rhodonite/app/browser` の `run_platform(config, app, options)` が canvas から engine 作成、surface sync、single-frame/loop/on-demand 実行、input binding、同一 canvas 差し替え時の dispose/shutdown までをまとめます。`ondemand-triangle` は browser/native ともに `interactive_on_demand()` を使い、入力・surface 変更による `Engine::request_render` で必要なフレームだけ起床します。OnDemand loop は idle に戻ると前回 timestamp を破棄するため、長時間 idle 後に再開した最初のフレームの `delta_seconds` は idle 時間を含まず 0 になります。`PlatformApp` は `create_engine` と `setup_engine` を束ね、sample entry は browser/native ともに `PlatformConfig`、`PlatformApp`、`PlatformOptions` を渡す同じ作法に寄せます。native platform は SDL window resize を受けて WebGPU surface を再 configure し、0x0/minimize は fatal error ではなく `Engine::set_surface_suspended()` として伝播します。native session は opaque で、利用側は GPU context と現在の surface 情報を accessor 経由で読むだけです。sample-local state は `DemoState` という名前に統一し、`create_demo_state_for_engine(engine)` と `register_engine_handlers(engine, demo_state)` を公開します。`ecs-scene-graph`、`ecs-mass-cubes` は `phase_surface()` で depth attachment を drawable size に合わせて再作成します。`TransformPropagation`、標準 orbit camera 入力、標準 `OrbitCameraController -> Transform3D -> Camera blob` 経路のような共有処理は `Engine::add_common_handlers` で登録し、engine handler を使わない直接 scene setup や test は `Scene::add_common_systems` を使います。MassCubes の framing のように sample 固有でも ECS component を読む/書く camera solver は sample 側の render-extract system として登録します。

Browser JS export も sample-local state の名前に合わせ、`create_webgpu_demo_state(canvas)` を入口にします。MoonBit JS sample はこの入口で `app/browser` の WebGPU context 作成、DOM input binding、RAF loop helper を起動し、sample 固有の tick/input export は持ちません。WASM host-driven sample も `create_wasm_demo_state`、`initialize_demo_state`、`render_demo_frame` を ABI 名として使い、sample-local state と将来の engine-owned `Renderer` を名前で混同しないようにします。

ECS sample の `DemoState` は `World` と `SystemRunner` を直接所有せず、`Scene` を render source として持ちます。`basic-triangle` と `triangle-with-buffer` のような低レベル WebGPU sample は ECS scene data を使わないため、`Engine` の main scene は実行境界としてのみ使います。`ecs-scene-graph` の `DemoState` は `phase_update()` handler で animated scene entity を更新し、`phase_render()` handler でその frame の描画だけを行います。

TypeScript-only sample の [`src/main-ts-ecs-mass-cubes.ts`](../src/main-ts-ecs-mass-cubes.ts) も同じ作法に寄せています。[`src/app-runtime.ts`](../src/app-runtime.ts) が TypeScript 用の lightweight wrapper として `SurfaceState`、`FrameState`、`TimeState`、`PhaseKey`、`PhaseGroupKey`、`PhaseSlot`、`Scene`、`Engine`、browser platform helper を提供し、sample は `runPlatform(config, app, options)` に browser lifecycle を委譲します。`runPlatform` は canvas 単位で active platform を管理するため、複数 canvas は相互に独立して差し替えられます。`Scene` は `world()`、`setMainCamera()`、`mainCamera()`、enabled/visible state を持ち、camera entity は `Transform3D` / `GlobalTransform` / `OrbitCameraController` / `CameraHomeTransform` / `CameraLens` / builtin `Camera` を所有します。`DemoState` は `renderScene(demo_state, scene, colorView)` で scene を render source として扱います。この wrapper は browser WebGPU の async device creation を扱うため、MoonBit の `Engine::new(context)` と完全な API 互換ではありませんが、phase group、surface snapshot、phase lifecycle は同じです。handler 登録 API は `addPhaseHandler` です。TypeScript 側も `Engine.addCommonHandlers` で orbit camera 入力 handler と post-update scene systems をまとめ、MassCubes 固有 camera solver は render-extract scene systems に置きます。

[`ecs-mass-cubes` の WASM/TypeScript host-driven variants](../moon/rhodonite_examples/src/ecs-mass-cubes/wasm/) は、MoonBit 側が WebGPU `GPUContext` を持たず TypeScript host が描画ループを所有するため、この `Engine(GPUContext)` runtime にはまだ直接載せていません。WASM ABI は update / render-extract / render に分け、MoonBit JS/native 版と同じく MassCubes camera solver を render-extract 相当に閉じ込めます。将来 `Engine` から platform/GPU context を分離した runner を用意するまでは例外として扱います。

### 現在の Phase 2 state

Phase 2 では `Scene` API を少し整理し、[`ecs-mass-cubes`](../moon/rhodonite_examples/src/ecs-mass-cubes/) も runtime に寄せました。

- `Scene::new_with_world(name, world)` を追加し、sample ごとの特殊な `World` 初期化を `Scene` に束ねられるようにする。
- `Scene::add_system(phase, ...)` を追加し、system 登録を scene 経由に寄せる。
- `Engine::new_with_main_scene(context, scene)` を追加し、main scene を明示的に指定できるようにする。
- `ecs-scene-graph` は `Scene::add_system` と `Scene::visible` を使う形に寄せる。
- `ecs-mass-cubes` は fp16 global transform 用の `World` を `Scene::new_with_world` で包み、browser/native entry point を `Engine::run_frame(delta_seconds)` 経由へ移行する。

この段階でも `Scene::world()` は残します。ECS component の登録や sample 固有の setup ではまだ直接 access が必要なためです。ただし `SystemRunner` は公開せず、system 登録や system runner 実行のように scene の境界を強く出せる操作は `Scene` method へ寄せます。

### Phase 1: examples 内 prototype（完了済み）

目的は public API を固定する前に、既存 sample の重複を減らしながら `Engine` / `Scene` の形を検証することでした。この phase の prototype package は Phase 3 で削除され、現在の実体は `moon/rhodonite/src/app/` です。

- `moon/rhodonite_examples/src/common/app/` を追加する（Phase 3 で削除済み）。
- `Scene` prototype を追加し、`World` と `SystemRunner` を 1:1 で所有させる。
- `FrameState` / `TimeState` を追加する。
- browser/native の sample runner が共通の `Engine` lifecycle を呼べるようにする。
- まず `basic-triangle` か `ecs-scene-graph` のどちらか 1 つだけを移行する。

検証:

```bash
moon check --target all
pnpm run dev:js:ecs-scene-graph
pnpm run dev:native:ecs-scene-graph
pnpm run test:examples:visual
```

### Phase 2: Scene API の整理（完了済み）

目的は `Scene` を ECS access の自然な入口にすることです。

- `Scene::world()` の公開範囲を見直し、`SystemRunner` は scene 内部に隠す。
- `Scene::run_systems_for_phase()` を追加する。
- `Scene::set_main_camera()` / `Scene::main_camera()` を追加する。
- `Scene` の enabled/visible state を renderer loop に反映する。
- `ecs-scene-graph` と `ecs-mass-cubes` を `Scene` runtime に寄せる。

検証:

```bash
moon check --target all
pnpm run test:core:mbt
pnpm run test:examples:visual
```

### Phase 3: facade への昇格

runtime concept は public facade へ移行済みです。

- `moon/rhodonite/src/app/` を追加する。
- `Engine`、`Scene`、`FrameState` を facade 側で公開する。
- `rhodonite_core` は ECS と math に集中させる。
- `rhodonite_webgpu` は WebGPU abstraction と renderer support に集中させる。
- [`docs/module_boundaries.md`](module_boundaries.md) に runtime layer の公開位置と examples から facade への依存を追記する。

検証:

```bash
moon info
moon fmt
moon check --target all
pnpm run test:core:mbt
pnpm run test:core:js
pnpm run test:examples:visual
```

### Phase 4: Renderer integration（完了済み）

目的は `Scene` を render source として扱う API を作ることです。

- `DemoState::render_scene(scene, color_view)` の形を導入する。
- `DemoState` が `GlobalTransform` / `Camera` blob events を upload する暫定責務を持つ。
- `Scene` の main camera を `DemoState` が参照する。
- TypeScript wrapper でも `Scene.mainCamera()` と `renderScene(demoState, scene, colorView)` の流れに揃える。
- 将来の `Renderable` component のために handle-based resource ownership 方針を固める。

この phase ではまだ full material system は入れていません。既存 sample の `DemoState` を共通入口へ寄せることを優先し、[`ecs-scene-graph`](../moon/rhodonite_examples/src/ecs-scene-graph/) と [`ecs-mass-cubes`](../moon/rhodonite_examples/src/ecs-mass-cubes/) は `scene.main_camera()` を primary camera source として `render_scene` から描画します。TypeScript-only sample も同じく `Scene` を render source として渡します。

### Phase 5: Mesh / Material / Renderable

`Engine` / `Scene` の境界が固まってから、engine-owned な汎用 `Renderer` と描画対象の高レベル abstraction を追加します。Phase 4 の `DemoState` は汎用 renderer ではないため、Phase 5 では resource table と `Renderable` component を導入するタイミングで `Engine` が抱える `Renderer` を設計します。

- `MeshHandle`
- `MaterialHandle`
- `TextureHandle`
- `Renderable` ECS component
- renderer resource table
- pipeline cache

この phase で初めて、sample code から直接 WebGPU buffer / pipeline を組む量を大きく減らします。

## Open Questions

- `Scene::world()` をどの程度公開するか。
- browser/native の platform runner を facade に公開するか、examples/common に置くか。
- `Renderer::render_scene` が直接 ECS query するか、`phase_render_extract()` / `PhaseSlot` 上の renderer task として extraction layer を用意するか。

Resolved in Phase 3:

- `Engine` は `PhaseKey` / `PhaseSlot` handler registry を所有する。
- `Engine` は `Scene` values の array と `main_scene_index` を所有する。
- `FrameState` は render-frame clock と fixed-step clock のどちらからでも作られる単一型とし、`TimeState` が clock ごとの `frame_index` / `elapsed_seconds` を別々に管理する。

## 最初の推奨 PR

Phase 1 の最初の PR は完了済みです。現在は `emadurandal/rhodonite/app` が public runtime package になっており、`ecs-scene-graph` と `ecs-mass-cubes` がこの runtime package を使います。この段階では mesh/material/resource manager はまだ入れていません。まず `Engine`、`Scene`、`World`、`SystemRunner`、`Renderer` の境界を実コードで検証する状態です。
