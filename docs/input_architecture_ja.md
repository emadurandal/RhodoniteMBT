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

`emadurandal/rhodonite/app` の `Engine` は `InputState` を所有し、`Engine::input()` で公開する。`Engine::run_render_frame()` はフレーム冒頭で `input.begin_frame()` を呼び、前フレームから enqueue されたイベントを現在フレームの状態へ確定する。

## Phase order

標準 render-frame phase group は入力 phase を update より前に走らせる。

```text
rhodonite/input
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
DOM event listener
  -> engine.input().enqueue_event(...)
requestAnimationFrame
  -> engine.run_render_frame()
     -> input.begin_frame()
     -> rhodonite/input
     -> rhodonite/update
```

Native SDL3:

```text
SDL event polling / SDL_GetMouseState
  -> engine.input().enqueue_event(...)
render loop
  -> engine.run_render_frame()
     -> input.begin_frame()
     -> rhodonite/input
     -> rhodonite/update
```

この順序により、DOM の非同期イベントと SDL の polling はどちらも同じ queue に合流し、app 側は `key_down`, `key_pressed`, `mouse_down`, `pointer_delta_x` などの状態 API だけを読む。

## Adapter placement

現在の adapter は実験段階として、利用箇所に近い場所に置く。

- Browser TypeScript runtime: [`src/app-runtime.ts`](../src/app-runtime.ts) の `installBrowserInput(engine)`。
- Native SDL3 samples: [`moon/rhodonite_examples/src/common/sdl_wgpu_native_demo.mbt`](../moon/rhodonite_examples/src/common/sdl_wgpu_native_demo.mbt) の `run_sdl_metal_webgpu_input_render_loop`。

adapter API と key mapping が安定したら、examples ではなくライブラリ側へ移す。移動先の候補は、DOM/SDL3 依存を公開 facade に閉じ込めたい場合は `emadurandal/rhodonite/app`、platform adapter を個別に公開したい場合は `rhodonite_input_browser` / `rhodonite_input_sdl3` のような専用 package である。`rhodonite_webgpu` へは入れない。入力は WebGPU ではなく window/event source の責務だからである。

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

MoonBit 実装の `ecs-mass-cubes` は `rhodonite_core/ecs` の `OrbitCameraController` component を使う。これは yaw / pitch / pan / dolly / distance、sensitivity、clamp、reset request を保持する CPU component で、`rhodonite/input` phase の handler が `Engine::input()` から mouse drag delta を読んで component を更新する。

camera matrix の生成側は DOM や SDL3 を見ず、camera entity の `Transform3D` / `GlobalTransform` / `CameraLens` を読む。標準経路では `orbit_camera_transform_system` が `OrbitCameraController` と `CameraHomeTransform` から `Transform3D` を更新し、`camera_blob_sync_system` が `GlobalTransform + CameraLens` から builtin `Camera` packed blob を更新する。reset は入力 binding には固定せず、ユーザーまたは sample が `request_orbit_camera_reset` を呼ぶ one-shot request として扱う。

TypeScript 実装の `ts-ecs-mass-cubes` は [`src/orbit-camera-controller.ts`](../src/orbit-camera-controller.ts) で MoonBit 側と同じ byte layout の `OrbitCameraController` / `CameraHomeTransform` / `CameraLens` component を登録し、camera entity に保持する。`Phase.Input` handler が `Engine.input` から `OrbitCameraController` component を更新し、`Phase.PostUpdate` handler が `OrbitCameraController + CameraHomeTransform` から `Transform3D` / `GlobalTransform` を更新する。`Phase.RenderExtract` handler は MassCubes 固有の camera solver を実行して builtin `Camera` blob を更新し、render 側は `drainAndUploadCameraWrites` と draw に集中する。WASM host は host 側で所有する `InputState` の集約済み mouse frame 値だけを WASM import として渡し、WASM 側の `World` が camera entity と `OrbitCameraController` component を所有する。どちらも [`installBrowserInputState`](../src/app-runtime.ts) で browser pointer event を同じ入力モデルへ正規化する。MoonBit native / JS 版の MassCubes も render path ではなく `phase_render_extract()` 相当の custom camera solver で MassCubes 固有の framing を `GlobalTransform` と `Camera` blob に反映し、render では camera writes の upload と draw だけを行う。WASM / WASM-GC 版は host-driven のままだが、WASM export を update / render-extract / render に分け、render-extract で view/proj 生成、`World::set_camera_matrices`、packed camera blob row upload まで行う。host の render phase は WebGPU の render pass を発行する。

controller の操作は、左 button drag が yaw / pitch の orbit、中 button drag が view-space の左右上下 pan、wheel が dolly scale である。中 button drag は右へ動かすと camera view を右へ、下へ動かすと camera view を下へ移動する。既定の dolly scale は `0.01` から `4.0` に clamp され、初期値 `1.0` から 100 倍相当まで寄れる。mass-cubes と scene-graph はどちらも orthographic projection を使うため、wheel の dolly は view-space camera state に加えて ortho 表示範囲にも反映し、前後移動として見た目に分かるようにする。
