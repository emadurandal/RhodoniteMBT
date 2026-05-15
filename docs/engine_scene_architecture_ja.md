# Engine / Scene Architecture Plan

この資料は、RhodoniteMBT に `App` / `Engine` / `Scene` の概念を導入するための初期設計案です。目的は、既存の ECS と WebGPU sample code を保ちながら、ゲームエンジンとしての実行単位、更新順序、描画責務を明確にすることです。

## 目標

- `World` を ECS storage として保ち、engine runtime の概念と混ぜない。
- `Schedule` は 1 つの `World` に対応させ、cross-world 処理を通常 system に混ぜない。
- `Scene` を runtime scene instance として導入し、`World`、`Schedule`、main camera、scene-level state をまとめる。
- `Engine` は platform、time、renderer、scene lifecycle を扱う。
- WebGPU resource の実体は `World` / `Scene` ではなく renderer 側で所有する。
- 既存の browser / native sample を段階的に `App` / `Engine` API へ移行できるようにする。

## 用語と責務

| 型 | 責務 |
|----|------|
| `App` | ユーザー実装の game/application lifecycle。`init`、`update`、`render`、`shutdown` などを持つ。 |
| `Engine` | platform context、time/frame state、renderer、scene collection を所有する実行基盤。 |
| `Scene` | runtime scene instance。1 つの `World` と 1 つの `Schedule` を所有し、main camera や enabled/visible state を持つ。 |
| `World` | ECS の entity/component/archetype storage。simulation data を持つ。 |
| `Schedule` | 1 つの `World` に対する system set。access guard と command buffer の適用境界を持つ。 |
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
  owns Schedule
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

`World` は「何が存在するか」を表し、`Renderer` は「GPU へどう流して描くか」を扱います。`Scene` は runtime 上の実行単位であり、`World + Schedule` を直接ばらばらに扱わせないための境界です。

## World と Schedule

`World` と `Schedule` は 1:1 の対応にします。

```text
Scene
  world: World
  schedule: Schedule
```

1 つの `Schedule` が複数の `World` を扱う設計にはしません。理由は、既存 ECS の system access declaration が `World` の mutation guard と結びついているためです。

- `reads` / `writes` / `structural_write` の対象が曖昧になる。
- `ComponentTypeId` が world 間で同じ意味を持つ保証が必要になる。
- `CommandBuffer` の flush 先が曖昧になる。
- query 中 mutation guard を world ごとに分離する必要が出る。
- render extraction や synchronization の責務が通常 system に混ざる。

複数 scene / 複数 world 間の処理が必要になった場合は、通常の `Schedule` ではなく、`EngineTask`、`SceneTransfer`、`RenderExtract` のような engine-level 処理として扱います。

## Scene

`Scene` は `World` と `Schedule` をまとめる runtime scene instance です。

初期版の想定 state:

```text
Scene
  name: String
  world: World
  schedule: Schedule
  main_camera: EntityId?
  enabled: Bool
  visible: Bool
```

初期 API の方向性:

```moonbit
let scene = Scene::new("main")
let entity = scene.world().create_entity()
scene.schedule().add_system(@ecs.transform_propagation_system(scene.world()))
scene.set_main_camera(camera)
```

ただし `world()` と `schedule()` を無制限に分離して公開すると 1:1 の意図が薄れるため、最終 API では `Scene::run_schedule()` や `Scene::world_mut()` のように scene 経由の操作を優先します。

## Engine

`Engine` は application loop の実行基盤です。初期版では複数 scene を内部構造として想定しつつ、公開 API は main scene 中心にします。

初期版の想定 state:

```text
Engine
  renderer: Renderer
  scenes: Array[Scene]
  main_scene_index: Int
  frame_state: FrameState
  time_state: TimeState
```

初期 API の方向性:

```moonbit
let engine = Engine::new(context)
let scene = engine.main_scene()
engine.run_app(app)
```

frame の標準順序:

```text
Engine::tick
  update time/frame state
  app.update(engine, frame)
  for each enabled scene:
    scene.schedule.run(scene.world)
  app.render(engine, frame)
  renderer.begin_frame()
  for each visible scene:
    renderer.render_scene(scene)
  renderer.end_frame()
```

初期実装では scene は 1 つだけでもよいです。`Engine` の内部 field や命名だけを `scenes` / `main_scene_index` にしておくと、後で複数 scene を追加しやすくなります。

## App

`App` はユーザーが実装する application lifecycle です。MoonBit の trait / interface 表現が扱いづらい場合は、初期段階では callbacks を保持する runner でも構いません。

目標 API:

```moonbit
trait App {
  init(Self, engine : Engine) -> Unit
  update(Self, engine : Engine, frame : FrameState) -> Unit
  render(Self, engine : Engine, frame : FrameState) -> Unit
  shutdown(Self, engine : Engine) -> Unit
}
```

最初の sample migration では、既存の `WebGPURenderer` sample を `App` 実装へ包むだけでよいです。renderer abstraction や material system を同時に入れすぎないようにします。

## WebGPU Renderer との関係

WebGPU context、device、queue、surface、GPU resources は `Engine` / `Renderer` 側に置きます。`Scene` / `World` は GPU resource の所有者にしません。

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

既存 ECS の `GlobalTransform` / `Camera` packed blob store は当面そのまま使います。`Renderer` は scene の world から blob resize/write events を drain し、対応する GPU buffer へ upload します。

重要な境界:

- `World` は `GPUDevice`、`GPUQueue`、`GPURenderPipeline` を持たない。
- `Scene` は render source であり、GPU resource owner ではない。
- `Renderer` は scene の ECS data を query/extract して描画する。
- 将来の `Mesh` / `Material` / `Renderable` は ECS component 側に handle を置き、GPU 実体は renderer resource table に置く。

## 実装計画

### 現在の Phase 3 runtime package

Phase 3 で `App` / `Engine` / `Scene` は public facade の [`moon/rhodonite/src/app/`](../moon/rhodonite/src/app/) に昇格しました。import path は `emadurandal/rhodonite/app` です。Phase 1/2 の `moon/rhodonite_examples/src/common/app/` prototype は削除済みで、examples は facade package を直接 import します。

現在の runtime package は次の型を持ちます。

| 型 | 現在の内容 |
|----|------------|
| `FrameState` | `delta_seconds`、`frame_index`、`elapsed_seconds`。`SystemContext` へ変換できる。 |
| `TimeState` | 固定 delta の frame counter。初期値は既存 ECS samples に合わせて 0.022 秒。 |
| `Scene` | 1 つの `World` と 1 つの `Schedule`、`main_camera`、enabled/visible state を持つ。 |
| `App` | callback-backed lifecycle。`init`、`update`、`render`、`shutdown` を呼び出す。 |
| `Engine` | `GPUContext`、scene collection、main scene index、time state を持ち、`tick(app)` で update、scene schedule、render を実行する。 |

[`ecs-scene-graph`](../moon/rhodonite_examples/src/ecs-scene-graph/) と [`ecs-mass-cubes`](../moon/rhodonite_examples/src/ecs-mass-cubes/) は `emadurandal/rhodonite/app` へ移行済みです。sample renderer は `World` と `Schedule` を直接所有せず、`Scene` を render source として持ちます。browser/native entry point は `Engine::tick(app)` を呼び、renderer 側の `App` callback が animation input update と render を担当します。

### 現在の Phase 2 state

Phase 2 では `Scene` API を少し整理し、[`ecs-mass-cubes`](../moon/rhodonite_examples/src/ecs-mass-cubes/) も runtime に寄せました。

- `Scene::new_with_world(name, world)` を追加し、sample ごとの特殊な `World` 初期化を `Scene` に束ねられるようにする。
- `Scene::add_system(system)` を追加し、`scene.schedule().add_system(...)` より scene 経由の操作を優先する。
- `Engine::new_with_main_scene(context, scene)` を追加し、main scene を明示的に指定できるようにする。
- `ecs-scene-graph` は `Scene::add_system` と `Scene::visible` を使う形に寄せる。
- `ecs-mass-cubes` は fp16 global transform 用の `World` を `Scene::new_with_world` で包み、browser/native entry point を `Engine::tick(app)` 経由へ移行する。

この段階でも `Scene::world()` と `Scene::schedule()` は残します。ECS component の登録や sample 固有の setup ではまだ直接 access が必要なためです。ただし system 登録や schedule 実行のように scene の境界を強く出せる操作は `Scene` method へ寄せます。

### Phase 1: examples 内 prototype（完了済み）

目的は public API を固定する前に、既存 sample の重複を減らしながら `App` / `Engine` / `Scene` の形を検証することでした。この phase の prototype package は Phase 3 で削除され、現在の実体は `moon/rhodonite/src/app/` です。

- `moon/rhodonite_examples/src/common/app/` を追加する（Phase 3 で削除済み）。
- `Scene` prototype を追加し、`World` と `Schedule` を 1:1 で所有させる。
- `FrameState` / `TimeState` を追加する。
- browser/native の sample runner が共通の `App` lifecycle を呼べるようにする。
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

- `Scene::world()` / `Scene::schedule()` の公開範囲を見直す。
- `Scene::run_schedule()` を追加する。
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
- `App`、`Engine`、`Scene`、`FrameState` を facade 側で公開する。
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

### Phase 4: Renderer integration

目的は `Scene` を render source として扱う API を作ることです。

- `Renderer::render_scene(scene)` の形を導入する。
- `Renderer` が `GlobalTransform` / `Camera` blob events を upload する責務を持つ。
- `Scene` の main camera を renderer が参照する。
- 将来の `Renderable` component のために handle-based resource ownership 方針を固める。

この phase ではまだ full material system は必須ではありません。既存 sample renderer を共通入口へ寄せることを優先します。

### Phase 5: Mesh / Material / Renderable

`Engine` / `Scene` の境界が固まってから、描画対象の高レベル abstraction を追加します。

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
- `FrameState` に wall-clock time と fixed-step time の両方を初期から入れるか。
- `Renderer::render_scene` が直接 ECS query するか、将来の `RenderExtract` layer を最初から薄く用意するか。

Resolved in Phase 3:

- `App` は callback-backed struct として実装する。
- `Engine` は `Scene` values の array と `main_scene_index` を所有する。

## 最初の推奨 PR

Phase 1 の最初の PR は完了済みです。現在は `emadurandal/rhodonite/app` が public runtime package になっており、`ecs-scene-graph` と `ecs-mass-cubes` がこの runtime package を使います。この段階では mesh/material/resource manager はまだ入れていません。まず `Engine`、`Scene`、`World`、`Schedule`、`Renderer` の境界を実コードで検証する状態です。
