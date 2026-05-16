# Input architecture

RhodoniteMBT のユーザー入力は、描画 API から独立した共通状態と、プラットフォーム別 adapter に分ける。

## Goals

- gameplay / app code は browser DOM や SDL3 の型を直接見ない。
- keyboard と mouse を browser / native の両方で同じ `InputState` API から読む。
- WebGPU surface や canvas context の抽象と入力抽象を混ぜない。
- adapter は platform event を薄く正規化するだけにし、状態管理は共通コードに寄せる。

## Packages

`emadurandal/rhodonite_core/input` は依存なしの入力モデルを持つ。

- `KeyCode`: 物理キー名を表す open identifier。browser では `KeyboardEvent.code`、native では SDL scancode 由来の名前をここへ正規化する。
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

共通モデルの `KeyCode` は open string identifier とする。これは enum の網羅性より、platform adapter の段階的な改善と未知キーの保持を優先するためである。

Browser adapter は `KeyboardEvent.code` をそのまま使う。これは `KeyW`, `ArrowLeft`, `Space` などの物理キー名で、keyboard layout による文字差を受けにくい。

Native SDL3 adapter は現在 SDL binding が scancode constants を公開していないため、`SDL_GetScancodeName` を暫定的に使う。安定版 adapter では SDL scancode 値から browser-style physical key name へ明示 mapping する。

Text input / IME は `InputEvent::TextInput` としてイベント列には載せられるが、composition の lifecycle はまだ扱わない。UI text editing を本格的に扱うときに `TextEditingStart`, `TextEditingUpdate`, `TextEditingEnd` などを追加する。

## Mouse model

Pointer coordinates は canvas/window surface 座標で扱う。browser adapter は CSS pixel から canvas backing size へ変換する。native SDL3 adapter は `SDL_GetMouseState` の window-relative 座標を使う。

`pointer_delta_x/y` と `wheel_delta_x/y` はフレームごとに 0 に戻り、そのフレームで適用されたイベントの合計になる。button state はフレームをまたいで保持される。

## ECS sample camera controller

`ecs-scene-graph` と MoonBit 実装の `ecs-mass-cubes` は、サンプル共通 package の [`OrbitCameraController`](../moon/rhodonite_examples/src/common/orbit_camera/orbit_camera_controller.mbt) を使う。これは ECS の CPU component として yaw / pitch / sensitivity / pitch clamp を保持し、`rhodonite/input` phase の handler が `Engine::input()` から mouse drag delta を読んで component を更新する。

camera matrix の生成側は DOM や SDL3 を見ず、camera entity に付いた `OrbitCameraController` の yaw / pitch だけを読む。browser サンプルでは TypeScript entry が pointer event を MoonBit export へ渡し、native サンプルでは既存 SDL adapter が `Engine::input()` へ enqueue するため、同じ controller code を両 target で共有できる。

TypeScript 実装の `ts-ecs-mass-cubes` と、WASM / WASM-GC 実装の `ecs-mass-cubes` host は [`src/orbit-camera-controller.ts`](../src/orbit-camera-controller.ts) の同等 controller を使う。`ts-ecs-mass-cubes` は `Engine.input` を、WASM host は host 側で所有する `InputState` を使い、どちらも [`installBrowserInputState`](../src/app-runtime.ts) で browser pointer event を同じ入力モデルへ正規化する。描画定数、camera uniform、pipeline / buffer 作成、render pass は [`src/ecs-mass-cubes-renderer.ts`](../src/ecs-mass-cubes-renderer.ts) に寄せ、TS ECS backend と WASM backend の transform 更新経路は entry ごとに残す。

この controller は現時点では examples 側の sample utility として置く。複数サンプルやアプリで API と挙動が固まったら、汎用 camera controller component / system としてライブラリ側へ移す候補にする。ただし platform adapter と同様に、controller は入力モデルと ECS / app layer の責務であり、`rhodonite_webgpu` には置かない。
