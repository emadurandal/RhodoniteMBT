# Input architecture

RhodoniteMBT のユーザー入力は、描画 API から独立した共通状態と、プラットフォーム別 adapter に分ける。

## Goals

- gameplay / app code は browser DOM や SDL3 の型を直接見ない。
- keyboard と mouse を browser / native の両方で同じ `InputState` API から読む。
- WebGPU surface や canvas context の抽象と入力抽象を混ぜない。
- adapter は platform event を薄く正規化するだけにし、状態管理は共通コードに寄せる。

## Packages

`emadurandal/rhodonite_core/input` は依存なしの入力モデルを持つ。

- `KeyCode`: 物理キー名を表す open identifier。browser では `KeyboardEvent.code`、native では SDL scancode 由来の名前をここへ正規化する。`KeyCode::key_w()`, `KeyCode::space()`, `KeyCode::arrow_left()` などの canonical constructor は browser-style physical key name を返す。
- `MouseButton`: `Left`, `Middle`, `Right`, `Back`, `Forward`, `Other(Int)`。
- `Modifiers`: shift / ctrl / alt / meta の snapshot。
- `InputEvent`: platform adapter が enqueue する正規化済みイベント。
- `InputState`: 現在押されているキー・ボタン、フレーム内 pressed/released、pointer delta、wheel delta、フレーム内イベント列を管理する。

`emadurandal/rhodonite/app` の `Engine` は `InputState` を所有し、`Engine::input()` で公開する。`Engine::run_frame(delta_seconds)` はフレーム冒頭で `input.begin_frame()` を呼び、前フレームから enqueue されたイベントを現在フレームの状態へ確定する。

## Phase order

標準 frame tick は入力 phase を fixed step と update より前に走らせる。

```text
rhodonite/frame_begin:
  rhodonite/input
rhodonite/fixed_step 0..N:
  rhodonite/fixed_update
  rhodonite/fixed_post_update
rhodonite/render_frame:
  rhodonite/update
  rhodonite/post_update
  rhodonite/render_extract
  rhodonite/render_prepare
  rhodonite/render
  rhodonite/present
```

入力を読む gameplay system は通常 `rhodonite/update` に置く。`rhodonite/input` は、入力確定直後に adapter 由来の補正や user-level action mapping を挟みたい場合のために予約する。

ECS component に入力状態を反映して、その component を後続の update / render が読む controller 型の処理は `rhodonite/input` に置いてよい。これにより、同一フレーム内で「入力確定 -> controller 更新 -> scene 更新 -> 描画」の順序を保てる。

## Event flow

Browser:

```text
emadurandal/rhodonite/app/browser install_browser_input
または src/app-runtime.ts installBrowserInputCallbacks
  -> engine.input().enqueue_event(...)
app/browser start_browser_engine_loop
または startBrowserEngineRuntime
  -> engine.run_frame(delta_seconds)
     -> input.begin_frame()
     -> rhodonite/input
     -> rhodonite/fixed_update / rhodonite/fixed_post_update 0..N
     -> rhodonite/update
```

Native SDL3:

```text
SDL event polling / SDL_GetMouseState
  -> engine.input().enqueue_event(...)
render loop
  -> engine.run_frame(delta_seconds)
     -> input.begin_frame()
     -> rhodonite/input
     -> rhodonite/fixed_update / rhodonite/fixed_post_update 0..N
     -> rhodonite/update
```

この順序により、DOM の非同期イベントと SDL の polling はどちらも同じ queue に合流し、app 側は `key_down`, `key_pressed`, `mouse_down`, `pointer_delta_x` などの状態 API だけを読む。

Native SDL3 の render loop は WebGPU surface の vsync 設定に frame pacing を任せ、追加の固定 sleep は入れない。CPU 計測は submit までの処理時間であり、FPS は前フレーム開始から次フレーム開始までの wall-clock 間隔で見る。`get_current_texture()` が surface / vblank を待つ時間は frame pacing 由来なので、MassCubes の CPU 計測からは除外する。

SDL window resize は app runtime の責務として扱う。`emadurandal/rhodonite_app_sdl3/sdl3` は `SDL_EVENT_WINDOW_RESIZED`、`SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED`、`SDL_EVENT_WINDOW_METAL_VIEW_RESIZED` を受け、drawable pixel size が変わった場合に WebGPU canvas context を再 configure して `Engine` へ surface state を通知する。0x0/minimize は fatal error ではなく suspended surface として扱い、engine は update までは進めるが render path を skip する。sample 側は resize event を直接 poll せず、`phase_surface()` と `FrameState::surface_changed()` を読む。

## Adapter placement

Browser adapter はライブラリ側へ昇格済みで、MoonBit JS target と TypeScript runtime の両方から使える。

- MoonBit browser runtime: `emadurandal/rhodonite/app/browser` の `gpu_context_from_html_canvas(canvas)`、`start_browser_engine_canvas_loop(engine, canvas)`、`sync_browser_engine_surface(engine, canvas)`、`install_browser_input(engine, canvas)`。
- Browser TypeScript runtime: [`src/app-runtime.ts`](../src/app-runtime.ts) の `runBrowserWebGpuCanvasDemo(...)`、`startBrowserEngineRuntime(engine)`、`installBrowserInputCallbacks(...)`、`installBrowserInput(engine)`。
- Native SDL3 runtime: `emadurandal/rhodonite_app_sdl3/sdl3` の `run_sdl_metal_webgpu_app(...)`、`init_sdl_metal_webgpu_native(...)`、`run_sdl_metal_webgpu_input_render_loop(...)`。

SDL3 adapter は `emadurandal/rhodonite_app_sdl3` に分離する。browser / SDL3 adapter は `rhodonite_webgpu` へ入れない。入力と platform event loop は WebGPU ではなく window/event source の責務だからである。SDL3 runtime の session は opaque で、sample や利用側は `gpu_context()`、`surface_active()`、`surface_width()`、`surface_height()`、`surface_format()` の accessor だけを読む。初期化や loop 中の platform failure は `Sdl3AppError` として構造化して返す。

## Key naming

共通モデルの `KeyCode` は open string identifier とする。これは enum の網羅性より、platform adapter の段階的な改善と未知キーの保持を優先するためである。よく使う物理キーは `KeyCode::key_a()` から `KeyCode::key_z()`、`KeyCode::digit_0()` から `KeyCode::digit_9()`、`KeyCode::enter()`、`KeyCode::space()`、`KeyCode::arrow_left()` などの canonical constructor から生成できる。

Browser adapter は `KeyboardEvent.code` をそのまま使う。これは `KeyW`, `ArrowLeft`, `Space` などの物理キー名で、keyboard layout による文字差を受けにくい。

Native SDL3 adapter は SDL scancode 値から browser-style physical key name へ明示 mapping する。英数字、主要記号、矢印、F1-F12、左右 modifier、numpad などの通常キーは `KeyW`, `ArrowLeft`, `Space` のような browser と同じ名前になる。mapping にない scancode は未知キーを保持するため、従来どおり SDL scancode name / key name 由来の `KeyCode::new(...)` へ fallback する。

Text input / IME は `InputEvent::TextInput` としてイベント列には載せられるが、composition の lifecycle はまだ扱わない。UI text editing を本格的に扱うときに `TextEditingStart`, `TextEditingUpdate`, `TextEditingEnd` などを追加する。

## Mouse model

Pointer coordinates は canvas/window surface 座標で扱う。browser adapter は CSS pixel から canvas backing size へ変換する。native SDL3 adapter は `SDL_GetMouseState` の window-relative 座標を使う。

`pointer_delta_x/y` と `wheel_delta_x/y` はフレームごとに 0 に戻り、そのフレームで適用されたイベントの合計になる。button state はフレームをまたいで保持される。

wheel delta は controller 側で同じ sensitivity を使えるよう、adapter 側で browser の `WheelEvent.deltaX/Y` に近い符号と大きさへ寄せる。native SDL3 adapter は wheel step を DOM wheel の pixel delta 相当に近づけるため 100 倍して enqueue し、通常スクロールの上方向が dolly-in になるよう `deltaY` を負方向へ正規化する。

## ECS camera controller

MoonBit 実装の `ecs-mass-cubes` と `ecs-scene-graph` は `rhodonite_core/ecs` の `OrbitCameraController` component を使う。これは yaw / pitch / pan / dolly / distance、sensitivity、clamp、reset request を保持する CPU component で、通常は `Engine::add_common_handlers` が標準 scene systems と合わせて入力 handler を追加する。入力 handler は `rhodonite/input` phase で `Engine::input()` から mouse drag delta を読んで component を更新する。

camera matrix の生成側は DOM や SDL3 を見ず、camera entity の `Transform3D` / `GlobalTransform` / `CameraLens` を読む。標準経路では `Engine::add_common_handlers` が `Scene::add_common_systems` を通じて `TransformPropagation`、`orbit_camera_transform_system`、`orbit_camera_blob_sync_system` を必要に応じて登録し、`OrbitCameraController + CameraHomeTransform` から `Transform3D` を更新してから `GlobalTransform + CameraLens + OrbitCameraController.dolly` から builtin `Camera` packed blob を更新する。engine handler を使わない直接 scene setup や test は `Scene::add_common_systems` を呼ぶ。reset は入力 binding には固定せず、ユーザーまたは sample が `request_orbit_camera_reset` を呼ぶ one-shot request として扱う。

TypeScript 実装の `ts-ecs-mass-cubes` は [`src/orbit-camera-controller.ts`](../src/orbit-camera-controller.ts) で MoonBit 側と同じ byte layout の `OrbitCameraController` / `CameraHomeTransform` / `CameraLens` component を登録し、camera entity に保持する。`Engine.addCommonHandlers` が `Phase.Input` handler で `Engine.input` から `OrbitCameraController` component を更新し、`Phase.PostUpdate` scene systems で `OrbitCameraController + CameraHomeTransform` から `Transform3D` / `GlobalTransform` を更新する。MassCubes 固有の camera solver は `Phase.RenderExtract` scene systems で builtin `Camera` blob を更新し、render 側は `drainAndUploadCameraWrites` と draw に集中する。WASM host は host 側で所有する `InputState` の集約済み mouse frame 値だけを WASM import として渡し、WASM 側の `World` が camera entity と `OrbitCameraController` component を所有する。TypeScript runtime は [`installBrowserInputCallbacks`](../src/app-runtime.ts) を共通入口にして browser pointer event を同じ入力モデルへ正規化する。MoonBit native / JS 版の MassCubes は render path ではなく `phase_render_extract()` の sample-local ECS system で MassCubes 固有の framing を `GlobalTransform` と `Camera` blob に反映し、render では camera writes の upload と draw だけを行う。WASM / WASM-GC 版は host-driven のままだが、WASM export を update / render-extract / render に分け、render-extract で view/proj 生成、`World::set_camera_matrices`、packed camera blob row upload まで行う。host の render phase は WebGPU の render pass を発行する。

controller の操作は、左 button drag が yaw / pitch の orbit、中 button drag が view-space の左右上下 pan、wheel が dolly scale である。中 button drag は右へ動かすと camera view を右へ、下へ動かすと camera view を下へ移動する。既定の dolly scale は `0.01` から `4.0` に clamp され、初期値 `1.0` から 100 倍相当まで寄れる。mass-cubes と scene-graph はどちらも orthographic projection を使うため、wheel の dolly は view-space camera state に加えて ortho 表示範囲にも反映し、前後移動として見た目に分かるようにする。
