function _M0TP411moonbitlang5async8internal9coroutine9Scheduler(param0, param1, param2, param3) {
  this.coro_id = param0;
  this.curr_coro = param1;
  this.blocking = param2;
  this.run_later = param3;
}
function _M0TPB13StringBuilder(param0) {
  this.val = param0;
}
function $compare_int(a, b) {
  return (a >= b) - (a <= b);
}
class $PanicError extends Error {}
function $panic() {
  throw new $PanicError();
}
function _M0TPC16string10StringView(param0, param1, param2) {
  this.str = param0;
  this.start = param1;
  this.end = param2;
}
function $bound_check(arr, index) {
  if (index < 0 || index >= arr.length) throw new Error("Index out of bounds");
}
function $make_array_len_and_init(a, b) {
  const arr = new Array(a);
  arr.fill(b);
  return arr;
}
function _M0TPC13set3SetGRP411moonbitlang5async8internal9coroutine9CoroutineE(param0, param1, param2, param3, param4, param5, param6) {
  this.entries = param0;
  this.size = param1;
  this.capacity = param2;
  this.capacity_mask = param3;
  this.grow_at = param4;
  this.head = param5;
  this.tail = param6;
}
function _M0TPB8MutLocalGORPC13set5EntryGRP411moonbitlang5async8internal9coroutine9CoroutineEE(param0) {
  this.val = param0;
}
function _M0TPC15deque5DequeGRP411moonbitlang5async8internal9coroutine9CoroutineE(param0, param1, param2) {
  this.buf = param0;
  this.len = param1;
  this.head = param2;
}
function _M0DTP411moonbitlang5async8internal9coroutine5State4Done() {}
_M0DTP411moonbitlang5async8internal9coroutine5State4Done.prototype.$tag = 0;
const _M0DTP411moonbitlang5async8internal9coroutine5State4Done__ = new _M0DTP411moonbitlang5async8internal9coroutine5State4Done();
function _M0DTP411moonbitlang5async8internal9coroutine5State4Fail(param0) {
  this._0 = param0;
}
_M0DTP411moonbitlang5async8internal9coroutine5State4Fail.prototype.$tag = 1;
function _M0DTP411moonbitlang5async8internal9coroutine5State7Running() {}
_M0DTP411moonbitlang5async8internal9coroutine5State7Running.prototype.$tag = 2;
const _M0DTP411moonbitlang5async8internal9coroutine5State7Running__ = new _M0DTP411moonbitlang5async8internal9coroutine5State7Running();
function _M0DTP411moonbitlang5async8internal9coroutine5State7Suspend(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP411moonbitlang5async8internal9coroutine5State7Suspend.prototype.$tag = 3;
function _M0DTPC15error5Error51moonbitlang_2fasync_2fjs__async_2eJsError_2eJsError(param0) {
  this._0 = param0;
}
_M0DTPC15error5Error51moonbitlang_2fasync_2fjs__async_2eJsError_2eJsError.prototype.$tag = 1;
function _M0DTPC15error5Error66moonbitlang_2fasync_2finternal_2fcoroutine_2eCancelled_2eCancelled() {}
_M0DTPC15error5Error66moonbitlang_2fasync_2finternal_2fcoroutine_2eCancelled_2eCancelled.prototype.$tag = 0;
const _M0DTPC15error5Error66moonbitlang_2fasync_2finternal_2fcoroutine_2eCancelled_2eCancelled__ = new _M0DTPC15error5Error66moonbitlang_2fasync_2finternal_2fcoroutine_2eCancelled_2eCancelled();
function _M0DTPC16result6ResultGOuRPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGOuRPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok.prototype.$tag = 1;
function _M0DTP411moonbitlang5async8internal9coroutine55_24moonbitlang_2fasync_2finternal_2fcoroutine_2esuspendL5State18_2adefer__try_2f66(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP411moonbitlang5async8internal9coroutine55_24moonbitlang_2fasync_2finternal_2fcoroutine_2esuspendL5State18_2adefer__try_2f66.prototype.$tag = 0;
function _M0DTP411moonbitlang5async8internal9coroutine55_24moonbitlang_2fasync_2finternal_2fcoroutine_2esuspendL5State8State__1(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP411moonbitlang5async8internal9coroutine55_24moonbitlang_2fasync_2finternal_2fcoroutine_2esuspendL5State8State__1.prototype.$tag = 1;
function _M0DTP411moonbitlang5async8internal9coroutine55_24moonbitlang_2fasync_2finternal_2fcoroutine_2esuspendL5State11_2aarm_2f72(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
_M0DTP411moonbitlang5async8internal9coroutine55_24moonbitlang_2fasync_2finternal_2fcoroutine_2esuspendL5State11_2aarm_2f72.prototype.$tag = 2;
function _M0TP411moonbitlang5async8internal9coroutine9Coroutine(param0, param1, param2, param3, param4, param5) {
  this.coro_id = param0;
  this.state = param1;
  this.shielded = param2;
  this.cancelled = param3;
  this.ready = param4;
  this.downstream = param5;
}
function _M0DTP411moonbitlang5async8internal9coroutine79_24moonbitlang_2fasync_2finternal_2fcoroutine_2espawn_2erun_2f17_2elambda_2f190L5State8State__0(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP411moonbitlang5async8internal9coroutine79_24moonbitlang_2fasync_2finternal_2fcoroutine_2espawn_2erun_2f17_2elambda_2f190L5State8State__0.prototype.$tag = 0;
function _M0DTP411moonbitlang5async8internal9coroutine79_24moonbitlang_2fasync_2finternal_2fcoroutine_2espawn_2erun_2f17_2elambda_2f190L5State11_2atry_2f78(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP411moonbitlang5async8internal9coroutine79_24moonbitlang_2fasync_2finternal_2fcoroutine_2espawn_2erun_2f17_2elambda_2f190L5State11_2atry_2f78.prototype.$tag = 1;
function _M0DTP411moonbitlang5async8internal9coroutine79_24moonbitlang_2fasync_2finternal_2fcoroutine_2espawn_2erun_2f17_2elambda_2f190L5State8State__2(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP411moonbitlang5async8internal9coroutine79_24moonbitlang_2fasync_2finternal_2fcoroutine_2espawn_2erun_2f17_2elambda_2f190L5State8State__2.prototype.$tag = 2;
function _M0DTP411moonbitlang5async8internal9coroutine77_24moonbitlang_2fasync_2finternal_2fcoroutine_2eprotect__from__cancel_2einnerL5StateGuE19_2adefer__try_2f138(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP411moonbitlang5async8internal9coroutine77_24moonbitlang_2fasync_2finternal_2fcoroutine_2eprotect__from__cancel_2einnerL5StateGuE19_2adefer__try_2f138.prototype.$tag = 0;
function _M0DTP411moonbitlang5async8internal9coroutine77_24moonbitlang_2fasync_2finternal_2fcoroutine_2eprotect__from__cancel_2einnerL5StateGuE8State__1(param0, param1, param2, param3) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
}
_M0DTP411moonbitlang5async8internal9coroutine77_24moonbitlang_2fasync_2finternal_2fcoroutine_2eprotect__from__cancel_2einnerL5StateGuE8State__1.prototype.$tag = 1;
function _M0DTP411moonbitlang5async8internal9coroutine77_24moonbitlang_2fasync_2finternal_2fcoroutine_2eprotect__from__cancel_2einnerL5StateGuE12_2aarm_2f141(param0, param1, param2, param3, param4) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
}
_M0DTP411moonbitlang5async8internal9coroutine77_24moonbitlang_2fasync_2finternal_2fcoroutine_2eprotect__from__cancel_2einnerL5StateGuE12_2aarm_2f141.prototype.$tag = 2;
const _M0FP411moonbitlang5async8internal11event__loop12set__timeout = (duration, f) => setTimeout(f, duration);
const _M0MP311moonbitlang5async9js__async15AbortController5abort = (controller) => controller.abort();
const _M0MP311moonbitlang5async9js__async7JsValue4then = (p, resolve, reject) => p.then(resolve, reject);
function _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects9GPUDeviceRPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects9GPUDeviceRPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects9GPUDeviceRPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects9GPUDeviceRPC15error5ErrorE2Ok.prototype.$tag = 1;
function _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE18_2adefer__try_2f83(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE18_2adefer__try_2f83.prototype.$tag = 0;
function _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE8State__1(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
_M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE8State__1.prototype.$tag = 1;
function _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE11_2atry_2f84(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
_M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE11_2atry_2f84.prototype.$tag = 2;
function _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE11_2aarm_2f87(param0, param1, param2, param3, param4) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
}
_M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE11_2aarm_2f87.prototype.$tag = 3;
function _M0DTPC16option6OptionGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE4None() {}
_M0DTPC16option6OptionGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE4None.prototype.$tag = 0;
const _M0DTPC16option6OptionGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE4None__ = new _M0DTPC16option6OptionGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE4None();
function _M0DTPC16option6OptionGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE4Some(param0) {
  this._0 = param0;
}
_M0DTPC16option6OptionGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE4Some.prototype.$tag = 1;
function _M0TP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL6WaiterGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE(param0, param1, param2) {
  this.coro = param0;
  this.ret = param1;
  this.err = param2;
}
const _M0MP311moonbitlang5async9js__async11AbortSignal9on__abort = (signal, f) => signal.addEventListener('abort', f, { once: true });
const _M0MP311moonbitlang5async9js__async7JsValue12abort__error = () => {
   const err = new Error()
   err.name = 'AbortError'
   return err
 };
const _M0MP311moonbitlang5async9js__async7JsValue12new__promise = (f) => new Promise(f);
function _M0DTP311moonbitlang5async9js__async85_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3afrom__async_2elambda_2elambda_2f297L5StateGuE12_2atry_2f130(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP311moonbitlang5async9js__async85_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3afrom__async_2elambda_2elambda_2f297L5StateGuE12_2atry_2f130.prototype.$tag = 0;
function _M0DTP311moonbitlang5async9js__async85_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3afrom__async_2elambda_2elambda_2f297L5StateGuE8State__1(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTP311moonbitlang5async9js__async85_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3afrom__async_2elambda_2elambda_2f297L5StateGuE8State__1.prototype.$tag = 1;
const _M0MP311moonbitlang5async9js__async7JsValue10to__string = (v) => v.toString();
function _M0TP311emadurandal6WebGPU15webgpu__objects26WebGPURenderPassDescriptor(param0, param1) {
  this.colorAttachments = param0;
  this.depthStencilAttachment = param1;
}
function _M0TP311emadurandal6WebGPU15webgpu__objects31WebGPURenderPassColorAttachment(param0, param1, param2, param3) {
  this.view = param0;
  this.clearValue = param1;
  this.loadOp = param2;
  this.storeOp = param3;
}
const _M0FP311emadurandal6WebGPU15webgpu__objects12navigatorGPU = () => navigator.gpu;
const _M0FP311emadurandal6WebGPU15webgpu__objects18canvas__getContext = (canvas) => {
   const context = canvas.getContext("webgpu");
   if (!context) {
     throw new Error("Failed to get WebGPU context");
   }
   return context;
 };
const _M0FP311emadurandal6WebGPU15webgpu__objects19gpu__requestAdapter = (gpu) =>
   gpu.requestAdapter().then((a) => {
     if (a) return a;
     throw new Error("No WebGPU adapter (requestAdapter returned null)");
   });
const _M0FP311emadurandal6WebGPU15webgpu__objects18gpu__requestDevice = (adapter) => adapter.requestDevice();
const _M0FP311emadurandal6WebGPU15webgpu__objects29gpu__getPreferredCanvasFormat = (gpu) => gpu.getPreferredCanvasFormat();
const _M0FP311emadurandal6WebGPU15webgpu__objects16device__getQueue = (device) => device.queue;
const _M0FP311emadurandal6WebGPU15webgpu__objects26device__createShaderModule = (device, code) => device.createShaderModule({ code });
const _M0FP311emadurandal6WebGPU15webgpu__objects28device__createRenderPipeline = (device, vertex, fragment, topologyTag, formats, vertexBuffers, depthStencilFormat) => {
   const TOPOLOGY_NAMES = [
     'point-list', 'line-list', 'line-strip', 'triangle-list', 'triangle-strip',
   ];
   const VERTEX_FORMAT_NAMES = ['float32x2', 'float32x3', 'float32x4'];
   const STEP_NAMES = ['vertex', 'instance'];
   const vbuf = vertexBuffers.map((b) => ({
     arrayStride: b.arrayStride,
     stepMode: STEP_NAMES[b.stepModeTag] ?? 'vertex',
     attributes: b.attributes.map((a) => ({
       format: VERTEX_FORMAT_NAMES[a.formatTag] ?? 'float32x2',
       offset: a.offset,
       shaderLocation: a.shaderLocation,
     })),
   }));
   const desc = {
     layout: 'auto',
     vertex: {
       module: vertex,
       entryPoint: 'vertexMain',
       buffers: vbuf,
     },
     fragment: {
       module: fragment,
       entryPoint: 'fragmentMain',
       targets: formats.map(format => ({ format }))
     },
     primitive: {
       topology: TOPOLOGY_NAMES[topologyTag]
     }
   };
   if (depthStencilFormat && depthStencilFormat.length > 0) {
     desc.depthStencil = {
       format: depthStencilFormat,
       depthWriteEnabled: true,
       depthCompare: 'less',
     };
   }
   return device.createRenderPipeline(desc);
 };
const _M0FP311emadurandal6WebGPU15webgpu__objects28device__createCommandEncoder = (device) => device.createCommandEncoder();
const _M0FP311emadurandal6WebGPU15webgpu__objects18context__configure = (context, device, format) => {
   context.configure({
     device,
     format,
     alphaMode: 'opaque'
   });
 };
const _M0FP311emadurandal6WebGPU15webgpu__objects26context__getCurrentTexture = (context) => context.getCurrentTexture();
const _M0FP311emadurandal6WebGPU15webgpu__objects19texture__createView = (texture) => texture.createView();
const _M0FP311emadurandal6WebGPU15webgpu__objects24encoder__beginRenderPass = (encoder, descriptor) => {
   const LOAD_LOAD = 0;
   const LOAD_CLEAR = 1;
   const STORE_STORE = 0;
   const STORE_DISCARD = 1;
   const mapLoad = (x) => (x === LOAD_CLEAR ? 'clear' : 'load');
   const mapStore = (x) => (x === STORE_DISCARD ? 'discard' : 'store');
   const colorAttachments = descriptor.colorAttachments.map((a) => {
     if (!a) return a;
     return {
       view: a.view,
       clearValue: a.clearValue,
       loadOp: mapLoad(a.loadOp),
       storeOp: mapStore(a.storeOp),
     };
   });
   const ds = descriptor.depthStencilAttachment;
   let depthStencilAttachment = undefined;
   if (ds && ds.view) {
     const dv = ds.depthClearValue;
     let depthClearValue = 1.0;
     if (dv !== undefined && dv !== null && typeof dv === 'number' && Number.isFinite(dv)) {
       depthClearValue = dv;
     }
     const loadOp =
       typeof ds.depthLoadOp === 'string' && ds.depthLoadOp.length > 0
         ? ds.depthLoadOp
         : 'clear';
     const storeOp =
       typeof ds.depthStoreOp === 'string' && ds.depthStoreOp.length > 0
         ? ds.depthStoreOp
         : 'store';
     depthStencilAttachment = {
       view: ds.view,
       depthClearValue,
       depthLoadOp: loadOp,
       depthStoreOp: storeOp,
     };
   }
   return encoder.beginRenderPass({
     colorAttachments,
     depthStencilAttachment,
   });
 };
const _M0FP311emadurandal6WebGPU15webgpu__objects15encoder__finish = (encoder) => encoder.finish();
const _M0FP311emadurandal6WebGPU15webgpu__objects23renderPass__setPipeline = (pass, pipeline) => pass.setPipeline(pipeline);
const _M0FP311emadurandal6WebGPU15webgpu__objects16renderPass__draw = (pass, vertexCount) => pass.draw(vertexCount);
const _M0FP311emadurandal6WebGPU15webgpu__objects15renderPass__end = (pass) => pass.end();
const _M0FP311emadurandal6WebGPU15webgpu__objects13queue__submit = (queue, commandBuffer) => queue.submit([commandBuffer]);
function _M0TP311emadurandal6WebGPU15webgpu__objects13WebGPUContext(param0, param1, param2, param3) {
  this.device = param0;
  this.context = param1;
  this.format = param2;
  this.queue = param3;
}
function _M0TP311emadurandal6WebGPU15webgpu__objects13WebGPUTexture(param0) {
  this.texture = param0;
}
function _M0TP311emadurandal6WebGPU15webgpu__objects23WebGPURenderPassEncoder(param0) {
  this.encoder = param0;
}
function _M0TP311emadurandal6WebGPU15webgpu__objects11WebGPUQueue(param0) {
  this.queue = param0;
}
function _M0TP311emadurandal6WebGPU15webgpu__objects14WebGPUInstance(param0) {
  this.instance = param0;
}
function _M0TP311emadurandal6WebGPU15webgpu__objects13WebGPUAdapter(param0) {
  this.adapter = param0;
}
function _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects13WebGPUAdapterRPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects13WebGPUAdapterRPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects13WebGPUAdapterRPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects13WebGPUAdapterRPC15error5ErrorE2Ok.prototype.$tag = 1;
function _M0DTPC16option6OptionGRP311moonbitlang5async9js__async15AbortControllerE4None() {}
_M0DTPC16option6OptionGRP311moonbitlang5async9js__async15AbortControllerE4None.prototype.$tag = 0;
const _M0DTPC16option6OptionGRP311moonbitlang5async9js__async15AbortControllerE4None__ = new _M0DTPC16option6OptionGRP311moonbitlang5async9js__async15AbortControllerE4None();
function _M0DTPC16option6OptionGRP311moonbitlang5async9js__async15AbortControllerE4Some(param0) {
  this._0 = param0;
}
_M0DTPC16option6OptionGRP311moonbitlang5async9js__async15AbortControllerE4Some.prototype.$tag = 1;
function _M0DTP311emadurandal6WebGPU15webgpu__objects78_24emadurandal_2fWebGPU_2fwebgpu__objects_2ewebgpu__instance__request__adapterL5State8State__0(param0) {
  this._0 = param0;
}
_M0DTP311emadurandal6WebGPU15webgpu__objects78_24emadurandal_2fWebGPU_2fwebgpu__objects_2ewebgpu__instance__request__adapterL5State8State__0.prototype.$tag = 0;
function _M0TP311emadurandal6WebGPU15webgpu__objects18VertexAttributeFFI(param0, param1, param2) {
  this.formatTag = param0;
  this.offset = param1;
  this.shaderLocation = param2;
}
function _M0TP311emadurandal6WebGPU15webgpu__objects21VertexBufferLayoutFFI(param0, param1, param2) {
  this.arrayStride = param0;
  this.stepModeTag = param1;
  this.attributes = param2;
}
function _M0TP311emadurandal6WebGPU15webgpu__objects12WebGPUDevice(param0) {
  this.device = param0;
}
function _M0TP311emadurandal6WebGPU15webgpu__objects20WebGPUCommandEncoder(param0) {
  this.encoder = param0;
}
function _M0TP311emadurandal6WebGPU15webgpu__objects19WebGPUCanvasContext(param0) {
  this.context = param0;
}
function _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects12WebGPUDeviceRPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects12WebGPUDeviceRPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects12WebGPUDeviceRPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects12WebGPUDeviceRPC15error5ErrorE2Ok.prototype.$tag = 1;
function _M0DTP311emadurandal6WebGPU15webgpu__objects76_24emadurandal_2fWebGPU_2fwebgpu__objects_2ewebgpu__adapter__request__deviceL5State8State__0(param0) {
  this._0 = param0;
}
_M0DTP311emadurandal6WebGPU15webgpu__objects76_24emadurandal_2fWebGPU_2fwebgpu__objects_2ewebgpu__adapter__request__deviceL5State8State__0.prototype.$tag = 0;
function _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUAdapterRPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUAdapterRPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUAdapterRPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUAdapterRPC15error5ErrorE2Ok.prototype.$tag = 1;
function _M0TP311emadurandal6WebGPU6webgpu10GPUAdapter(param0) {
  this.raw = param0;
}
function _M0DTP311emadurandal6WebGPU6webgpu68_40emadurandal_2fWebGPU_2fwebgpu_2eGPUInstance_3a_3arequest__adapterL5State8State__0(param0) {
  this._0 = param0;
}
_M0DTP311emadurandal6WebGPU6webgpu68_40emadurandal_2fWebGPU_2fwebgpu_2eGPUInstance_3a_3arequest__adapterL5State8State__0.prototype.$tag = 0;
function _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu9GPUDeviceRPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu9GPUDeviceRPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu9GPUDeviceRPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu9GPUDeviceRPC15error5ErrorE2Ok.prototype.$tag = 1;
function _M0TP311emadurandal6WebGPU6webgpu9GPUDevice(param0) {
  this.raw = param0;
}
function _M0DTP311emadurandal6WebGPU6webgpu66_40emadurandal_2fWebGPU_2fwebgpu_2eGPUAdapter_3a_3arequest__deviceL5State8State__0(param0) {
  this._0 = param0;
}
_M0DTP311emadurandal6WebGPU6webgpu66_40emadurandal_2fWebGPU_2fwebgpu_2eGPUAdapter_3a_3arequest__deviceL5State8State__0.prototype.$tag = 0;
function _M0TP311emadurandal6WebGPU6webgpu8GPUQueue(param0) {
  this.raw = param0;
}
function _M0TP311emadurandal6WebGPU6webgpu17GPURenderPipeline(param0) {
  this.raw = param0;
}
function _M0TP311emadurandal6WebGPU6webgpu17GPUCommandEncoder(param0) {
  this.raw = param0;
}
function _M0TP311emadurandal6WebGPU6webgpu10GPUTexture(param0) {
  this.raw = param0;
}
function _M0TP311emadurandal6WebGPU6webgpu16GPUCanvasContext(param0) {
  this.raw = param0;
}
function _M0TP311emadurandal6WebGPU6webgpu20GPURenderPassEncoder(param0) {
  this.raw = param0;
}
function _M0TP311emadurandal6WebGPU6webgpu11GPUInstance(param0) {
  this.raw = param0;
}
function _M0TP311emadurandal6WebGPU6webgpu10GPUContext(param0) {
  this.raw = param0;
}
function _M0TP311emadurandal6WebGPU6webgpu27GPURenderPipelineDescriptor(param0, param1, param2, param3, param4, param5) {
  this.vertex = param0;
  this.fragment = param1;
  this.topology = param2;
  this.formats = param3;
  this.vertex_buffers = param4;
  this.depth_stencil_format = param5;
}
function _M0TP411emadurandal17WebGPU_2dexamples16basic_2dtriangle6common14WebGPURenderer(param0, param1, param2, param3) {
  this.context = param0;
  this.device = param1;
  this.queue = param2;
  this.pipeline = param3;
}
function _M0TP311emadurandal6WebGPU6webgpu23GPURenderPassDescriptor(param0, param1) {
  this.color_attachments = param0;
  this.depth_stencil_attachment = param1;
}
function _M0TP311emadurandal6WebGPU6webgpu28GPURenderPassColorAttachment(param0, param1, param2, param3) {
  this.view = param0;
  this.clear_value = param1;
  this.load_op = param2;
  this.store_op = param3;
}
function _M0TP311emadurandal6WebGPU13webgpu__enums8GPUColor(param0, param1, param2, param3) {
  this.r = param0;
  this.g = param1;
  this.b = param2;
  this.a = param3;
}
function _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUContextRPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUContextRPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUContextRPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUContextRPC15error5ErrorE2Ok.prototype.$tag = 1;
function _M0DTP411emadurandal17WebGPU_2dexamples6common7browser88_24emadurandal_2fWebGPU_2dexamples_2fcommon_2fbrowser_2egpu__context__from__html__canvasL5State8State__0(param0, param1, param2, param3) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
}
_M0DTP411emadurandal17WebGPU_2dexamples6common7browser88_24emadurandal_2fWebGPU_2dexamples_2fcommon_2fbrowser_2egpu__context__from__html__canvasL5State8State__0.prototype.$tag = 0;
function _M0DTP411emadurandal17WebGPU_2dexamples6common7browser88_24emadurandal_2fWebGPU_2dexamples_2fcommon_2fbrowser_2egpu__context__from__html__canvasL5State8State__1(param0, param1, param2, param3, param4) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
}
_M0DTP411emadurandal17WebGPU_2dexamples6common7browser88_24emadurandal_2fWebGPU_2dexamples_2fcommon_2fbrowser_2egpu__context__from__html__canvasL5State8State__1.prototype.$tag = 1;
function _M0DTP511emadurandal17WebGPU_2dexamples16basic_2dtriangle2js4main99_24emadurandal_2fWebGPU_2dexamples_2fbasic_2dtriangle_2fjs_2fmain_2ecreate__webgpu__renderer__asyncL5State8State__0(param0) {
  this._0 = param0;
}
_M0DTP511emadurandal17WebGPU_2dexamples16basic_2dtriangle2js4main99_24emadurandal_2fWebGPU_2dexamples_2fbasic_2dtriangle_2fjs_2fmain_2ecreate__webgpu__renderer__asyncL5State8State__0.prototype.$tag = 0;
function _M0DTPC16option6OptionGRP311moonbitlang5async9js__async11AbortSignalE4None() {}
_M0DTPC16option6OptionGRP311moonbitlang5async9js__async11AbortSignalE4None.prototype.$tag = 0;
const _M0DTPC16option6OptionGRP311moonbitlang5async9js__async11AbortSignalE4None__ = new _M0DTPC16option6OptionGRP311moonbitlang5async9js__async11AbortSignalE4None();
function _M0DTPC16option6OptionGRP311moonbitlang5async9js__async11AbortSignalE4Some(param0) {
  this._0 = param0;
}
_M0DTPC16option6OptionGRP311moonbitlang5async9js__async11AbortSignalE4Some.prototype.$tag = 1;
const _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger = { method_0: _M0IPB13StringBuilderPB6Logger13write__string, method_1: _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE, method_2: _M0IPB13StringBuilderPB6Logger11write__view, method_3: _M0IPB13StringBuilderPB6Logger11write__char };
function _M0FP15Error10to__string(_e) {
  if (_e.$tag === 0) {
    return _M0IP016_24default__implPB4Show10to__stringGRP411moonbitlang5async8internal9coroutine9CancelledE(_e);
  } else {
    return _M0IP016_24default__implPB4Show10to__stringGRP311moonbitlang5async9js__async7JsErrorE(_e);
  }
}
const _M0FP411emadurandal17WebGPU_2dexamples16basic_2dtriangle6common22triangle__shader__code = "struct VertexOutput {\n  @builtin(position) position: vec4<f32>,\n  @location(0) color: vec3<f32>,\n};\n\n@vertex\nfn vertexMain(@builtin(vertex_index) vertexIndex: u32) -> VertexOutput {\n  var pos = array<vec2<f32>, 3>(\n    vec2<f32>(0.0, 0.5),\n    vec2<f32>(-0.5, -0.5),\n    vec2<f32>(0.5, -0.5),\n  );\n  var colors = array<vec3<f32>, 3>(\n    vec3<f32>(1.0, 0.0, 0.0),\n    vec3<f32>(0.0, 1.0, 0.0),\n    vec3<f32>(0.0, 0.0, 1.0),\n  );\n  var output: VertexOutput;\n  output.position = vec4<f32>(pos[vertexIndex], 0.0, 1.0);\n  output.color = colors[vertexIndex];\n  return output;\n}\n\n@fragment\nfn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {\n  return vec4<f32>(color, 1.0);\n}\n";
const _M0FP411moonbitlang5async8internal9coroutine9scheduler = new _M0TP411moonbitlang5async8internal9coroutine9Scheduler(0, undefined, 0, _M0MPC15deque5Deque11new_2einnerGRP411moonbitlang5async8internal9coroutine9CoroutineE(0));
function _M0MPB18UninitializedArray6lengthGRP411moonbitlang5async8internal9coroutine9CoroutineE(self) {
  return self.length;
}
function _M0MPB13StringBuilder11new_2einner(size_hint) {
  return new _M0TPB13StringBuilder("");
}
function _M0MPB13StringBuilder10to__string(self) {
  return self.val;
}
function _M0IPB13StringBuilderPB6Logger11write__char(self, ch) {
  self.val = `${self.val}${String.fromCodePoint(ch)}`;
}
function _M0MPC16uint166UInt1623is__trailing__surrogate(self) {
  return _M0IP016_24default__implPB7Compare6op__geGkE(self, 56320) && _M0IP016_24default__implPB7Compare6op__leGkE(self, 57343);
}
function _M0IPB13StringBuilderPB6Logger13write__string(self, str) {
  self.val = `${self.val}${str}`;
}
function _M0IPC16uint166UInt16PB7Compare7compare(self, that) {
  return $compare_int(self, that);
}
function _M0IP016_24default__implPB7Compare6op__leGkE(x, y) {
  return _M0IPC16uint166UInt16PB7Compare7compare(x, y) <= 0;
}
function _M0IP016_24default__implPB7Compare6op__geGkE(x, y) {
  return _M0IPC16uint166UInt16PB7Compare7compare(x, y) >= 0;
}
function _M0MPC16string6String11sub_2einner(self, start, end) {
  const len = self.length;
  let end$2;
  if (end === undefined) {
    end$2 = len;
  } else {
    const _Some = end;
    const _end = _Some;
    end$2 = _end < 0 ? len + _end | 0 : _end;
  }
  const start$2 = start < 0 ? len + start | 0 : start;
  if (start$2 >= 0 && (start$2 <= end$2 && end$2 <= len)) {
    if (start$2 < len) {
      if (!_M0MPC16uint166UInt1623is__trailing__surrogate(self.charCodeAt(start$2))) {
      } else {
        $panic();
      }
    }
    if (end$2 < len) {
      if (!_M0MPC16uint166UInt1623is__trailing__surrogate(self.charCodeAt(end$2))) {
      } else {
        $panic();
      }
    }
    return new _M0TPC16string10StringView(self, start$2, end$2);
  } else {
    return $panic();
  }
}
function _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE(self, value, start, len) {
  _M0IPB13StringBuilderPB6Logger11write__view(self, _M0MPC16string6String11sub_2einner(value, start, start + len | 0));
}
function _M0IP016_24default__implPB4Show10to__stringGRPC15error5ErrorE(self) {
  const logger = _M0MPB13StringBuilder11new_2einner(0);
  _M0IPC15error5ErrorPB4Show6output(self, { self: logger, method_table: _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
  return _M0MPB13StringBuilder10to__string(logger);
}
function _M0IP016_24default__implPB4Show10to__stringGRP411moonbitlang5async8internal9coroutine9CancelledE(self) {
  const logger = _M0MPB13StringBuilder11new_2einner(0);
  _M0IP411moonbitlang5async8internal9coroutine9CancelledPB4Show6output(self, { self: logger, method_table: _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
  return _M0MPB13StringBuilder10to__string(logger);
}
function _M0IP016_24default__implPB4Show10to__stringGRP311moonbitlang5async9js__async7JsErrorE(self) {
  const logger = _M0MPB13StringBuilder11new_2einner(0);
  _M0IP311moonbitlang5async9js__async7JsErrorPB4Show6output(self, { self: logger, method_table: _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
  return _M0MPB13StringBuilder10to__string(logger);
}
function _M0MPB4Iter4nextGRP411moonbitlang5async8internal9coroutine9CoroutineE(self) {
  const _func = self;
  return _func();
}
function _M0MPB4Iter3newGRP411moonbitlang5async8internal9coroutine9CoroutineE(f) {
  return f;
}
function _M0IPC16string10StringViewPB4Show10to__string(self) {
  return self.str.substring(self.start, self.end);
}
function _M0IPB13StringBuilderPB6Logger11write__view(self, str) {
  self.val = `${self.val}${_M0IPC16string10StringViewPB4Show10to__string(str)}`;
}
function _M0IPC16string6StringPB4Show10to__string(self) {
  return self;
}
function _M0MPC16option6Option6unwrapGRP411moonbitlang5async8internal9coroutine9CoroutineE(self) {
  if (self === undefined) {
    return $panic();
  } else {
    const _Some = self;
    return _Some;
  }
}
function _M0MPC16option6Option6unwrapGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE(self) {
  if (self.$tag === 0) {
    return $panic();
  } else {
    const _Some = self;
    return _Some._0;
  }
}
function _M0MPC13int3Int20next__power__of__two(self) {
  if (self >= 0) {
    if (self <= 1) {
      return 1;
    }
    if (self > 1073741824) {
      return 1073741824;
    }
    return (2147483647 >> (Math.clz32(self - 1 | 0) - 1 | 0)) + 1 | 0;
  } else {
    return $panic();
  }
}
function _M0MPC15array10FixedArray12fill_2einnerGORPC13set5EntryGRP411moonbitlang5async8internal9coroutine9CoroutineEE(self, value, start, end) {
  const array_length = self.length;
  if (array_length > 0) {
    if (start >= 0 && start < array_length) {
      let length;
      if (end === undefined) {
        length = array_length - start | 0;
      } else {
        const _Some = end;
        const _e = _Some;
        length = _e >= start && _e <= array_length ? _e - start | 0 : $panic();
      }
      self.fill(value, start, start + length);
      return;
    } else {
      $panic();
      return;
    }
  } else {
    return;
  }
}
function _M0MPC15array5Array3mapGORP311emadurandal6WebGPU6webgpu28GPURenderPassColorAttachmentORP311emadurandal6WebGPU15webgpu__objects31WebGPURenderPassColorAttachmentE(self, f) {
  const arr = new Array(self.length);
  const _bind = self.length;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      const v = self[i];
      arr[i] = f(v);
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return arr;
}
function _M0MPC15array5Array3mapGRP311emadurandal6WebGPU13webgpu__enums21GPUVertexBufferLayoutRP311emadurandal6WebGPU15webgpu__objects21VertexBufferLayoutFFIE(self, f) {
  const arr = new Array(self.length);
  const _bind = self.length;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      const v = self[i];
      arr[i] = f(v);
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return arr;
}
function _M0MPC15array5Array3mapGRP311emadurandal6WebGPU13webgpu__enums18GPUVertexAttributeRP311emadurandal6WebGPU15webgpu__objects18VertexAttributeFFIE(self, f) {
  const arr = new Array(self.length);
  const _bind = self.length;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      const v = self[i];
      arr[i] = f(v);
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return arr;
}
function _M0FPB7printlnGsE(input) {
  console.log(_M0IPC16string6StringPB4Show10to__string(input));
}
function _M0IPC15error5ErrorPB4Show6output(self, logger) {
  logger.method_table.method_0(logger.self, _M0FP15Error10to__string(self));
}
function _M0FPC13set21calc__grow__threshold(capacity) {
  if (16 === 0) {
    $panic();
  }
  return (Math.imul(capacity, 13) | 0) / 16 | 0;
}
function _M0MPC13set3Set11new_2einnerGRP411moonbitlang5async8internal9coroutine9CoroutineE(capacity) {
  const capacity$2 = _M0MPC13int3Int20next__power__of__two(capacity);
  const _bind = capacity$2 - 1 | 0;
  const _bind$2 = _M0FPC13set21calc__grow__threshold(capacity$2);
  const _bind$3 = $make_array_len_and_init(capacity$2, undefined);
  const _bind$4 = undefined;
  return new _M0TPC13set3SetGRP411moonbitlang5async8internal9coroutine9CoroutineE(_bind$3, 0, capacity$2, _bind, _bind$2, _bind$4, -1);
}
function _M0MPC13set3Set5clearGRP411moonbitlang5async8internal9coroutine9CoroutineE(self) {
  _M0MPC15array10FixedArray12fill_2einnerGORPC13set5EntryGRP411moonbitlang5async8internal9coroutine9CoroutineEE(self.entries, undefined, 0, undefined);
  self.size = 0;
  self.head = undefined;
  self.tail = -1;
}
function _M0MPC13set3Set4iterGRP411moonbitlang5async8internal9coroutine9CoroutineE(self) {
  const curr_entry = new _M0TPB8MutLocalGORPC13set5EntryGRP411moonbitlang5async8internal9coroutine9CoroutineEE(self.head);
  return _M0MPB4Iter3newGRP411moonbitlang5async8internal9coroutine9CoroutineE(() => {
    const _bind = curr_entry.val;
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _x = _Some;
      const _key = _x.key;
      const _next = _x.next;
      curr_entry.val = _next;
      return _key;
    }
  });
}
function _M0MPC15deque5Deque11new_2einnerGRP411moonbitlang5async8internal9coroutine9CoroutineE(capacity) {
  return new _M0TPC15deque5DequeGRP411moonbitlang5async8internal9coroutine9CoroutineE(new Array(capacity), 0, 0);
}
function _M0MPC15deque5Deque9is__emptyGRP411moonbitlang5async8internal9coroutine9CoroutineE(self) {
  return self.len === 0;
}
function _M0MPC15deque5Deque6lengthGRP411moonbitlang5async8internal9coroutine9CoroutineE(self) {
  return self.len;
}
function _M0MPC15deque5Deque7reallocGRP411moonbitlang5async8internal9coroutine9CoroutineE(self) {
  const old_cap = _M0MPB18UninitializedArray6lengthGRP411moonbitlang5async8internal9coroutine9CoroutineE(self.buf);
  const new_cap = old_cap === 0 ? 8 : Math.imul(old_cap, 2) | 0;
  const new_buf = new Array(new_cap);
  const _bind = self.len;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      if (old_cap === 0) {
        $panic();
      }
      const src_idx = (self.head + i | 0) % old_cap | 0;
      const _tmp$2 = self.buf;
      $bound_check(_tmp$2, src_idx);
      $bound_check(new_buf, i);
      new_buf[i] = _tmp$2[src_idx];
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  self.head = 0;
  self.buf = new_buf;
}
function _M0MPC15deque5Deque10push__backGRP411moonbitlang5async8internal9coroutine9CoroutineE(self, value) {
  if (self.len === _M0MPB18UninitializedArray6lengthGRP411moonbitlang5async8internal9coroutine9CoroutineE(self.buf)) {
    _M0MPC15deque5Deque7reallocGRP411moonbitlang5async8internal9coroutine9CoroutineE(self);
  }
  const cap = _M0MPB18UninitializedArray6lengthGRP411moonbitlang5async8internal9coroutine9CoroutineE(self.buf);
  if (cap === 0) {
    $panic();
  }
  const write_idx = (self.head + self.len | 0) % cap | 0;
  const _tmp = self.buf;
  $bound_check(_tmp, write_idx);
  _tmp[write_idx] = value;
  self.len = self.len + 1 | 0;
}
function _M0MPC15deque5Deque10pop__frontGRP411moonbitlang5async8internal9coroutine9CoroutineE(self) {
  if (self.len > 0) {
    const _tmp = self.buf;
    const _tmp$2 = self.head;
    $bound_check(_tmp, _tmp$2);
    const value = _tmp[_tmp$2];
    const _tmp$3 = self.buf;
    const _tmp$4 = self.head;
    $bound_check(_tmp$3, _tmp$4);
    _tmp$3[_tmp$4] = null;
    const cap = _M0MPB18UninitializedArray6lengthGRP411moonbitlang5async8internal9coroutine9CoroutineE(self.buf);
    if (cap === 0) {
      $panic();
    }
    self.head = (self.head + 1 | 0) % cap | 0;
    self.len = self.len - 1 | 0;
    return value;
  } else {
    return undefined;
  }
}
function _M0MP311emadurandal6WebGPU13webgpu__enums17GPUVertexStepMode11to__js__tag(self) {
  if (self === 0) {
    return 0;
  } else {
    return 1;
  }
}
function _M0MP311emadurandal6WebGPU13webgpu__enums15GPUVertexFormat11to__js__tag(self) {
  switch (self) {
    case 0: {
      return 0;
    }
    case 1: {
      return 1;
    }
    default: {
      return 2;
    }
  }
}
function _M0MP311emadurandal6WebGPU13webgpu__enums20GPUPrimitiveTopology11to__js__tag(self) {
  switch (self) {
    case 0: {
      return 0;
    }
    case 1: {
      return 1;
    }
    case 2: {
      return 2;
    }
    case 3: {
      return 3;
    }
    default: {
      return 4;
    }
  }
}
function _M0FP411moonbitlang5async8internal9coroutine18current__coroutine() {
  return _M0MPC16option6Option6unwrapGRP411moonbitlang5async8internal9coroutine9CoroutineE(_M0FP411moonbitlang5async8internal9coroutine9scheduler.curr_coro);
}
function _M0FP411moonbitlang5async8internal9coroutine29has__immediately__ready__task() {
  return !_M0MPC15deque5Deque9is__emptyGRP411moonbitlang5async8internal9coroutine9CoroutineE(_M0FP411moonbitlang5async8internal9coroutine9scheduler.run_later);
}
function _M0FP411moonbitlang5async8internal9coroutine14no__more__work() {
  return _M0FP411moonbitlang5async8internal9coroutine9scheduler.blocking === 0 && _M0MPC15deque5Deque9is__emptyGRP411moonbitlang5async8internal9coroutine9CoroutineE(_M0FP411moonbitlang5async8internal9coroutine9scheduler.run_later);
}
function _M0FP411moonbitlang5async8internal9coroutine10reschedule() {
  const n = _M0MPC15deque5Deque6lengthGRP411moonbitlang5async8internal9coroutine9CoroutineE(_M0FP411moonbitlang5async8internal9coroutine9scheduler.run_later);
  const _bind = 0;
  let _tmp = _bind;
  while (true) {
    const _ = _tmp;
    if (_ < n) {
      let coro;
      _L: {
        const _bind$2 = _M0MPC15deque5Deque10pop__frontGRP411moonbitlang5async8internal9coroutine9CoroutineE(_M0FP411moonbitlang5async8internal9coroutine9scheduler.run_later);
        if (_bind$2 === undefined) {
          return;
        } else {
          const _Some = _bind$2;
          const _coro = _Some;
          coro = _coro;
          break _L;
        }
      }
      coro.ready = false;
      let ok_cont;
      let err_cont;
      _L$2: {
        _L$3: {
          const _bind$2 = coro.state;
          if (_bind$2.$tag === 3) {
            const _Suspend = _bind$2;
            const _ok_cont = _Suspend._0;
            const _err_cont = _Suspend._1;
            ok_cont = _ok_cont;
            err_cont = _err_cont;
            break _L$3;
          }
          break _L$2;
        }
        coro.state = _M0DTP411moonbitlang5async8internal9coroutine5State7Running__;
        const last_coro = _M0FP411moonbitlang5async8internal9coroutine9scheduler.curr_coro;
        _M0FP411moonbitlang5async8internal9coroutine9scheduler.curr_coro = coro;
        if (coro.cancelled && !coro.shielded) {
          err_cont(_M0DTPC15error5Error66moonbitlang_2fasync_2finternal_2fcoroutine_2eCancelled_2eCancelled__);
        } else {
          ok_cont(undefined);
        }
        _M0FP411moonbitlang5async8internal9coroutine9scheduler.curr_coro = last_coro;
      }
      _tmp = _ + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0IP411moonbitlang5async8internal9coroutine9CancelledPB4Show6output(_self, logger) {
  logger.method_table.method_0(logger.self, "Cancelled");
}
function _M0MP411moonbitlang5async8internal9coroutine9Coroutine4wake(self) {
  if (!self.ready) {
    self.ready = true;
    _M0MPC15deque5Deque10push__backGRP411moonbitlang5async8internal9coroutine9CoroutineE(_M0FP411moonbitlang5async8internal9coroutine9scheduler.run_later, self);
    return;
  } else {
    return;
  }
}
function _M0FP411moonbitlang5async8internal9coroutine20is__being__cancelled() {
  const coro = _M0FP411moonbitlang5async8internal9coroutine18current__coroutine();
  return coro.cancelled && !coro.shielded;
}
function _M0MP411moonbitlang5async8internal9coroutine9Coroutine6cancel(self) {
  self.cancelled = true;
  if (!self.shielded) {
    _M0MP411moonbitlang5async8internal9coroutine9Coroutine4wake(self);
    return;
  } else {
    return;
  }
}
function _M0FP411moonbitlang5async8internal9coroutine7suspend(_cont, _err_cont) {
  const _async_driver = (_state) => {
    switch (_state.$tag) {
      case 0: {
        const _$42$defer_try$47$66 = _state;
        const _defer = _$42$defer_try$47$66._1;
        const _err = _$42$defer_try$47$66._0;
        _defer();
        return new _M0DTPC16result6ResultGOuRPC15error5ErrorE3Err(_err);
      }
      case 1: {
        const _State_1 = _state;
        const _defer$2 = _State_1._1;
        const _cont_param = _State_1._0;
        const _defer_result = _cont_param;
        _defer$2();
        return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok(_defer_result);
      }
      default: {
        const _$42$arm$47$72 = _state;
        const _err_cont$2 = _$42$arm$47$72._2;
        const _cont$2 = _$42$arm$47$72._1;
        const coro = _$42$arm$47$72._0;
        if (coro.cancelled && !coro.shielded) {
          return new _M0DTPC16result6ResultGOuRPC15error5ErrorE3Err(_M0DTPC15error5Error66moonbitlang_2fasync_2finternal_2fcoroutine_2eCancelled_2eCancelled__);
        }
        _M0FP411moonbitlang5async8internal9coroutine9scheduler.blocking = _M0FP411moonbitlang5async8internal9coroutine9scheduler.blocking + 1 | 0;
        const _defer$3 = () => {
          _M0FP411moonbitlang5async8internal9coroutine9scheduler.blocking = _M0FP411moonbitlang5async8internal9coroutine9scheduler.blocking - 1 | 0;
        };
        const ok_cont = (_cont_param$2) => {
          let _err$2;
          _L: {
            const _bind = _async_driver(new _M0DTP411moonbitlang5async8internal9coroutine55_24moonbitlang_2fasync_2finternal_2fcoroutine_2esuspendL5State8State__1(_cont_param$2, _defer$3));
            let _bind$2;
            if (_bind.$tag === 1) {
              const _ok = _bind;
              _bind$2 = _ok._0;
            } else {
              const _err$3 = _bind;
              _err$2 = _err$3._0;
              break _L;
            }
            if (_bind$2 === -1) {
              return;
            } else {
              const _Some = _bind$2;
              const _payload = _Some;
              _cont$2(_payload);
              return;
            }
          }
          _err_cont$2(_err$2);
        };
        const err_cont = (_cont_param$2) => {
          let _err$2;
          _L: {
            const _bind = _async_driver(new _M0DTP411moonbitlang5async8internal9coroutine55_24moonbitlang_2fasync_2finternal_2fcoroutine_2esuspendL5State18_2adefer__try_2f66(_cont_param$2, _defer$3));
            let _bind$2;
            if (_bind.$tag === 1) {
              const _ok = _bind;
              _bind$2 = _ok._0;
            } else {
              const _err$3 = _bind;
              _err$2 = _err$3._0;
              break _L;
            }
            if (_bind$2 === -1) {
              return;
            } else {
              const _Some = _bind$2;
              const _payload = _Some;
              _cont$2(_payload);
              return;
            }
          }
          _err_cont$2(_err$2);
        };
        const _bind = coro.state;
        if (_bind.$tag === 2) {
          coro.state = new _M0DTP411moonbitlang5async8internal9coroutine5State7Suspend(ok_cont, err_cont);
        } else {
          $panic();
        }
        return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok(-1);
      }
    }
  };
  const _bind = _M0FP411moonbitlang5async8internal9coroutine9scheduler.curr_coro;
  if (_bind === undefined) {
    return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok($panic());
  } else {
    const _Some = _bind;
    const _coro = _Some;
    return _async_driver(new _M0DTP411moonbitlang5async8internal9coroutine55_24moonbitlang_2fasync_2finternal_2fcoroutine_2esuspendL5State11_2aarm_2f72(_coro, _cont, _err_cont));
  }
}
function _M0FP411moonbitlang5async8internal9coroutine5spawn(f) {
  _M0FP411moonbitlang5async8internal9coroutine9scheduler.coro_id = _M0FP411moonbitlang5async8internal9coroutine9scheduler.coro_id + 1 | 0;
  const _bind = _M0DTP411moonbitlang5async8internal9coroutine5State7Running__;
  const _bind$2 = true;
  const _bind$3 = true;
  const _bind$4 = _M0MPC13set3Set11new_2einnerGRP411moonbitlang5async8internal9coroutine9CoroutineE(8);
  const _bind$5 = _M0FP411moonbitlang5async8internal9coroutine9scheduler.coro_id;
  const _bind$6 = false;
  const coro = new _M0TP411moonbitlang5async8internal9coroutine9Coroutine(_bind$5, _bind, _bind$3, _bind$6, _bind$2, _bind$4);
  const run = (_discard_) => {
    const _cont = (_param) => {
    };
    const _async_driver = (_state) => {
      let _tmp = _state;
      _L: while (true) {
        const _state$2 = _tmp;
        switch (_state$2.$tag) {
          case 0: {
            const _State_0 = _state$2;
            const coro$2 = _State_0._1;
            const _it = _M0MPC13set3Set4iterGRP411moonbitlang5async8internal9coroutine9CoroutineE(coro$2.downstream);
            while (true) {
              let coro$3;
              _L$2: {
                const _bind$7 = _M0MPB4Iter4nextGRP411moonbitlang5async8internal9coroutine9CoroutineE(_it);
                if (_bind$7 === undefined) {
                  break;
                } else {
                  const _Some = _bind$7;
                  const _coro = _Some;
                  coro$3 = _coro;
                  break _L$2;
                }
              }
              _M0MP411moonbitlang5async8internal9coroutine9Coroutine4wake(coro$3);
              continue;
            }
            return _M0MPC13set3Set5clearGRP411moonbitlang5async8internal9coroutine9CoroutineE(coro$2.downstream);
          }
          case 1: {
            const _$42$try$47$78 = _state$2;
            const coro$3 = _$42$try$47$78._1;
            const _try_err = _$42$try$47$78._0;
            const err = _try_err;
            coro$3.state = new _M0DTP411moonbitlang5async8internal9coroutine5State4Fail(err);
            _tmp = new _M0DTP411moonbitlang5async8internal9coroutine79_24moonbitlang_2fasync_2finternal_2fcoroutine_2espawn_2erun_2f17_2elambda_2f190L5State8State__0(undefined, coro$3);
            continue _L;
          }
          default: {
            const _State_2 = _state$2;
            const coro$4 = _State_2._1;
            coro$4.state = _M0DTP411moonbitlang5async8internal9coroutine5State4Done__;
            _tmp = new _M0DTP411moonbitlang5async8internal9coroutine79_24moonbitlang_2fasync_2finternal_2fcoroutine_2espawn_2erun_2f17_2elambda_2f190L5State8State__0(undefined, coro$4);
            continue _L;
          }
        }
      }
    };
    coro.shielded = false;
    let _err;
    _L: {
      _L$2: {
        const _bind$7 = f((_cont_param) => {
          const _bind$8 = _async_driver(new _M0DTP411moonbitlang5async8internal9coroutine79_24moonbitlang_2fasync_2finternal_2fcoroutine_2espawn_2erun_2f17_2elambda_2f190L5State8State__2(_cont_param, coro));
          if (_bind$8 === -1) {
            return;
          } else {
            const _Some = _bind$8;
            const _payload = _Some;
            _cont(_payload);
            return;
          }
        }, (_cont_param) => {
          const _bind$8 = _async_driver(new _M0DTP411moonbitlang5async8internal9coroutine79_24moonbitlang_2fasync_2finternal_2fcoroutine_2espawn_2erun_2f17_2elambda_2f190L5State11_2atry_2f78(_cont_param, coro));
          if (_bind$8 === -1) {
            return;
          } else {
            const _Some = _bind$8;
            const _payload = _Some;
            _cont(_payload);
            return;
          }
        });
        let _bind$8;
        if (_bind$7.$tag === 1) {
          const _ok = _bind$7;
          _bind$8 = _ok._0;
        } else {
          const _err$2 = _bind$7;
          _err = _err$2._0;
          break _L$2;
        }
        if (_bind$8 === -1) {
        } else {
          const _Some = _bind$8;
          const _payload = _Some;
          _async_driver(new _M0DTP411moonbitlang5async8internal9coroutine79_24moonbitlang_2fasync_2finternal_2fcoroutine_2espawn_2erun_2f17_2elambda_2f190L5State8State__2(_payload, coro));
        }
        break _L;
      }
      _async_driver(new _M0DTP411moonbitlang5async8internal9coroutine79_24moonbitlang_2fasync_2finternal_2fcoroutine_2espawn_2erun_2f17_2elambda_2f190L5State11_2atry_2f78(_err, coro));
    }
  };
  coro.state = new _M0DTP411moonbitlang5async8internal9coroutine5State7Suspend(run, (_discard_) => {
  });
  _M0MPC15deque5Deque10push__backGRP411moonbitlang5async8internal9coroutine9CoroutineE(_M0FP411moonbitlang5async8internal9coroutine9scheduler.run_later, coro);
  return coro;
}
function _M0FP411moonbitlang5async8internal9coroutine29protect__from__cancel_2einnerGuE(f, resume_on_cancel, _cont, _err_cont) {
  const _async_driver = (_state) => {
    let _tmp = _state;
    _L: while (true) {
      const _state$2 = _tmp;
      switch (_state$2.$tag) {
        case 0: {
          const _$42$defer_try$47$138 = _state$2;
          const _defer = _$42$defer_try$47$138._1;
          const _err = _$42$defer_try$47$138._0;
          _defer();
          return new _M0DTPC16result6ResultGOuRPC15error5ErrorE3Err(_err);
        }
        case 1: {
          const _State_1 = _state$2;
          const _defer$2 = _State_1._3;
          const coro = _State_1._2;
          const resume_on_cancel$2 = _State_1._1;
          const _cont_param = _State_1._0;
          const result = _cont_param;
          if (!resume_on_cancel$2 && coro.cancelled) {
            _tmp = new _M0DTP411moonbitlang5async8internal9coroutine77_24moonbitlang_2fasync_2finternal_2fcoroutine_2eprotect__from__cancel_2einnerL5StateGuE19_2adefer__try_2f138(_M0DTPC15error5Error66moonbitlang_2fasync_2finternal_2fcoroutine_2eCancelled_2eCancelled__, _defer$2);
            continue _L;
          }
          const _defer_result = result;
          _defer$2();
          return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok(_defer_result);
        }
        default: {
          const _$42$arm$47$141 = _state$2;
          const _err_cont$2 = _$42$arm$47$141._4;
          const _cont$2 = _$42$arm$47$141._3;
          const resume_on_cancel$3 = _$42$arm$47$141._2;
          const f$2 = _$42$arm$47$141._1;
          const coro$2 = _$42$arm$47$141._0;
          if (coro$2.shielded) {
            return f$2(_cont$2, _err_cont$2);
          } else {
            coro$2.shielded = true;
            const _defer$3 = () => {
              coro$2.shielded = false;
            };
            let _err$2;
            _L$2: {
              const _bind = f$2((_cont_param$2) => {
                let _err$3;
                _L$3: {
                  const _bind$2 = _async_driver(new _M0DTP411moonbitlang5async8internal9coroutine77_24moonbitlang_2fasync_2finternal_2fcoroutine_2eprotect__from__cancel_2einnerL5StateGuE8State__1(_cont_param$2, resume_on_cancel$3, coro$2, _defer$3));
                  let _bind$3;
                  if (_bind$2.$tag === 1) {
                    const _ok = _bind$2;
                    _bind$3 = _ok._0;
                  } else {
                    const _err$4 = _bind$2;
                    _err$3 = _err$4._0;
                    break _L$3;
                  }
                  if (_bind$3 === -1) {
                    return;
                  } else {
                    const _Some = _bind$3;
                    const _payload = _Some;
                    _cont$2(_payload);
                    return;
                  }
                }
                _err_cont$2(_err$3);
              }, (_cont_param$2) => {
                let _err$3;
                _L$3: {
                  const _bind$2 = _async_driver(new _M0DTP411moonbitlang5async8internal9coroutine77_24moonbitlang_2fasync_2finternal_2fcoroutine_2eprotect__from__cancel_2einnerL5StateGuE19_2adefer__try_2f138(_cont_param$2, _defer$3));
                  let _bind$3;
                  if (_bind$2.$tag === 1) {
                    const _ok = _bind$2;
                    _bind$3 = _ok._0;
                  } else {
                    const _err$4 = _bind$2;
                    _err$3 = _err$4._0;
                    break _L$3;
                  }
                  if (_bind$3 === -1) {
                    return;
                  } else {
                    const _Some = _bind$3;
                    const _payload = _Some;
                    _cont$2(_payload);
                    return;
                  }
                }
                _err_cont$2(_err$3);
              });
              let _bind$2;
              if (_bind.$tag === 1) {
                const _ok = _bind;
                _bind$2 = _ok._0;
              } else {
                const _err$3 = _bind;
                _err$2 = _err$3._0;
                break _L$2;
              }
              if (_bind$2 === -1) {
                return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok(-1);
              } else {
                const _Some = _bind$2;
                const _payload = _Some;
                _tmp = new _M0DTP411moonbitlang5async8internal9coroutine77_24moonbitlang_2fasync_2finternal_2fcoroutine_2eprotect__from__cancel_2einnerL5StateGuE8State__1(_payload, resume_on_cancel$3, coro$2, _defer$3);
                continue _L;
              }
            }
            _tmp = new _M0DTP411moonbitlang5async8internal9coroutine77_24moonbitlang_2fasync_2finternal_2fcoroutine_2eprotect__from__cancel_2einnerL5StateGuE19_2adefer__try_2f138(_err$2, _defer$3);
            continue _L;
          }
        }
      }
    }
  };
  const _bind = _M0FP411moonbitlang5async8internal9coroutine9scheduler.curr_coro;
  if (_bind === undefined) {
    return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok($panic());
  } else {
    const _Some = _bind;
    const _coro = _Some;
    return _async_driver(new _M0DTP411moonbitlang5async8internal9coroutine77_24moonbitlang_2fasync_2finternal_2fcoroutine_2eprotect__from__cancel_2einnerL5StateGuE12_2aarm_2f141(_coro, f, resume_on_cancel, _cont, _err_cont));
  }
}
function _M0FP411moonbitlang5async8internal11event__loop10reschedule() {
  if (!_M0FP411moonbitlang5async8internal9coroutine14no__more__work()) {
    _M0FP411moonbitlang5async8internal9coroutine10reschedule();
    if (_M0FP411moonbitlang5async8internal9coroutine29has__immediately__ready__task()) {
      _M0FP411moonbitlang5async8internal11event__loop12set__timeout(0, _M0FP411moonbitlang5async8internal11event__loop10reschedule);
      return;
    } else {
      return;
    }
  } else {
    return;
  }
}
function _M0MP311moonbitlang5async9js__async7Promise4waitGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE(promise, abort_controller, _cont, _err_cont) {
  const _async_driver = (_state) => {
    let _tmp = _state;
    _L: while (true) {
      const _state$2 = _tmp;
      switch (_state$2.$tag) {
        case 0: {
          const _$42$defer_try$47$83 = _state$2;
          const _defer = _$42$defer_try$47$83._1;
          const _err = _$42$defer_try$47$83._0;
          _defer();
          return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects9GPUDeviceRPC15error5ErrorE3Err(_err);
        }
        case 1: {
          const _State_1 = _state$2;
          const _defer$2 = _State_1._2;
          const waiter = _State_1._1;
          let _defer_result;
          let err;
          _L$2: {
            _L$3: {
              const _bind = waiter.err;
              if (_bind === undefined) {
                _defer_result = _M0MPC16option6Option6unwrapGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE(waiter.ret);
              } else {
                const _Some = _bind;
                const _err$2 = _Some;
                err = _err$2;
                break _L$3;
              }
              break _L$2;
            }
            _tmp = new _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE18_2adefer__try_2f83(err, _defer$2);
            continue _L;
          }
          _defer$2();
          return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects9GPUDeviceRPC15error5ErrorE2Ok(new _M0DTPC16option6OptionGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE4Some(_defer_result));
        }
        case 2: {
          const _$42$try$47$84 = _state$2;
          const _defer$3 = _$42$try$47$84._2;
          const controller = _$42$try$47$84._1;
          const _try_err = _$42$try$47$84._0;
          const err$2 = _try_err;
          _M0MP311moonbitlang5async9js__async15AbortController5abort(controller);
          _tmp = new _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE18_2adefer__try_2f83(err$2, _defer$3);
          continue _L;
        }
        default: {
          const _$42$arm$47$87 = _state$2;
          const _err_cont$2 = _$42$arm$47$87._4;
          const _cont$2 = _$42$arm$47$87._3;
          const _defer$4 = _$42$arm$47$87._2;
          const waiter$2 = _$42$arm$47$87._1;
          const controller$2 = _$42$arm$47$87._0;
          let _err$2;
          _L$3: {
            const _bind = _M0FP411moonbitlang5async8internal9coroutine7suspend((_cont_param) => {
              let _err$3;
              _L$4: {
                const _bind$2 = _async_driver(new _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE8State__1(_cont_param, waiter$2, _defer$4));
                let _tmp$2;
                if (_bind$2.$tag === 1) {
                  const _ok = _bind$2;
                  _tmp$2 = _ok._0;
                } else {
                  const _err$4 = _bind$2;
                  _err$3 = _err$4._0;
                  break _L$4;
                }
                const _tmp$3 = _tmp$2;
                if (_tmp$3.$tag === 1) {
                  const _Some = _tmp$3;
                  const _payload = _Some._0;
                  _cont$2(_payload);
                  return;
                } else {
                  return;
                }
              }
              _err_cont$2(_err$3);
            }, (_cont_param) => {
              let _err$3;
              _L$4: {
                const _bind$2 = _async_driver(new _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE11_2atry_2f84(_cont_param, controller$2, _defer$4));
                let _tmp$2;
                if (_bind$2.$tag === 1) {
                  const _ok = _bind$2;
                  _tmp$2 = _ok._0;
                } else {
                  const _err$4 = _bind$2;
                  _err$3 = _err$4._0;
                  break _L$4;
                }
                const _tmp$3 = _tmp$2;
                if (_tmp$3.$tag === 1) {
                  const _Some = _tmp$3;
                  const _payload = _Some._0;
                  _cont$2(_payload);
                  return;
                } else {
                  return;
                }
              }
              _err_cont$2(_err$3);
            });
            let _bind$2;
            if (_bind.$tag === 1) {
              const _ok = _bind;
              _bind$2 = _ok._0;
            } else {
              const _err$3 = _bind;
              _err$2 = _err$3._0;
              break _L$3;
            }
            if (_bind$2 === -1) {
              return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects9GPUDeviceRPC15error5ErrorE2Ok(_M0DTPC16option6OptionGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE4None__);
            } else {
              const _Some = _bind$2;
              const _payload = _Some;
              _tmp = new _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE8State__1(_payload, waiter$2, _defer$4);
              continue _L;
            }
          }
          _tmp = new _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE11_2atry_2f84(_err$2, controller$2, _defer$4);
          continue _L;
        }
      }
    }
  };
  const waiter = new _M0TP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL6WaiterGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE(_M0FP411moonbitlang5async8internal9coroutine18current__coroutine(), _M0DTPC16option6OptionGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE4None__, undefined);
  const resolve = (value) => {
    waiter.ret = new _M0DTPC16option6OptionGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE4Some(value);
    let coro;
    _L: {
      const _bind = waiter.coro;
      if (_bind === undefined) {
        return;
      } else {
        const _Some = _bind;
        const _coro = _Some;
        coro = _coro;
        break _L;
      }
    }
    _M0MP411moonbitlang5async8internal9coroutine9Coroutine4wake(coro);
    _M0FP411moonbitlang5async8internal11event__loop10reschedule();
  };
  const reject = (err) => {
    waiter.err = new _M0DTPC15error5Error51moonbitlang_2fasync_2fjs__async_2eJsError_2eJsError(err);
    let coro;
    _L: {
      const _bind = waiter.coro;
      if (_bind === undefined) {
        return;
      } else {
        const _Some = _bind;
        const _coro = _Some;
        coro = _coro;
        break _L;
      }
    }
    _M0MP411moonbitlang5async8internal9coroutine9Coroutine4wake(coro);
    _M0FP411moonbitlang5async8internal11event__loop10reschedule();
  };
  _M0MP311moonbitlang5async9js__async7JsValue4then(promise, resolve, reject);
  const _defer = () => {
    waiter.coro = undefined;
  };
  if (abort_controller.$tag === 1) {
    const _Some = abort_controller;
    const _controller = _Some._0;
    return _async_driver(new _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE11_2aarm_2f87(_controller, waiter, _defer, _cont, _err_cont));
  } else {
    let _err;
    _L: {
      const _bind = _M0FP411moonbitlang5async8internal9coroutine29protect__from__cancel_2einnerGuE(_M0FP411moonbitlang5async8internal9coroutine7suspend, false, (_cont_param) => {
        let _err$2;
        _L$2: {
          const _bind$2 = _async_driver(new _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE8State__1(_cont_param, waiter, _defer));
          let _tmp;
          if (_bind$2.$tag === 1) {
            const _ok = _bind$2;
            _tmp = _ok._0;
          } else {
            const _err$3 = _bind$2;
            _err$2 = _err$3._0;
            break _L$2;
          }
          const _tmp$2 = _tmp;
          if (_tmp$2.$tag === 1) {
            const _Some = _tmp$2;
            const _payload = _Some._0;
            _cont(_payload);
            return;
          } else {
            return;
          }
        }
        _err_cont(_err$2);
      }, (_cont_param) => {
        let _err$2;
        _L$2: {
          const _bind$2 = _async_driver(new _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE18_2adefer__try_2f83(_cont_param, _defer));
          let _tmp;
          if (_bind$2.$tag === 1) {
            const _ok = _bind$2;
            _tmp = _ok._0;
          } else {
            const _err$3 = _bind$2;
            _err$2 = _err$3._0;
            break _L$2;
          }
          const _tmp$2 = _tmp;
          if (_tmp$2.$tag === 1) {
            const _Some = _tmp$2;
            const _payload = _Some._0;
            _cont(_payload);
            return;
          } else {
            return;
          }
        }
        _err_cont(_err$2);
      });
      let _bind$2;
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _bind$2 = _ok._0;
      } else {
        const _err$2 = _bind;
        _err = _err$2._0;
        break _L;
      }
      if (_bind$2 === -1) {
        return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects9GPUDeviceRPC15error5ErrorE2Ok(_M0DTPC16option6OptionGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE4None__);
      } else {
        const _Some = _bind$2;
        const _payload = _Some;
        return _async_driver(new _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE8State__1(_payload, waiter, _defer));
      }
    }
    return _async_driver(new _M0DTP311moonbitlang5async9js__async54_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3awaitL5StateGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE18_2adefer__try_2f83(_err, _defer));
  }
}
function _M0MP311moonbitlang5async9js__async7Promise11from__asyncGuE(f, abort_signal) {
  const promise = _M0MP311moonbitlang5async9js__async7JsValue12new__promise((resolve, reject) => {
    const coro = _M0FP411moonbitlang5async8internal9coroutine5spawn((_cont, _err_cont) => {
      const _async_driver = (_state) => {
        if (_state.$tag === 0) {
          const _$42$try$47$130 = _state;
          const reject$2 = _$42$try$47$130._1;
          const _try_err = _$42$try$47$130._0;
          let err;
          _L: {
            if (_try_err.$tag === 0) {
              if (_M0FP411moonbitlang5async8internal9coroutine20is__being__cancelled()) {
                return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok(reject$2(_M0MP311moonbitlang5async9js__async7JsValue12abort__error()));
              } else {
                err = _try_err;
                break _L;
              }
            } else {
              err = _try_err;
              break _L;
            }
          }
          return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok(reject$2(_M0IP016_24default__implPB4Show10to__stringGRPC15error5ErrorE(err)));
        } else {
          const _State_1 = _state;
          const resolve$2 = _State_1._1;
          const _cont_param = _State_1._0;
          const _bind = _cont_param;
          const ret = _bind;
          return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok(resolve$2(ret));
        }
      };
      let _err;
      _L: {
        const _bind = f((_cont_param) => {
          let _err$2;
          _L$2: {
            const _bind$2 = _async_driver(new _M0DTP311moonbitlang5async9js__async85_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3afrom__async_2elambda_2elambda_2f297L5StateGuE8State__1(_cont_param, resolve));
            let _bind$3;
            if (_bind$2.$tag === 1) {
              const _ok = _bind$2;
              _bind$3 = _ok._0;
            } else {
              const _err$3 = _bind$2;
              _err$2 = _err$3._0;
              break _L$2;
            }
            if (_bind$3 === -1) {
              return;
            } else {
              const _Some = _bind$3;
              const _payload = _Some;
              _cont(_payload);
              return;
            }
          }
          _err_cont(_err$2);
        }, (_cont_param) => {
          let _err$2;
          _L$2: {
            const _bind$2 = _async_driver(new _M0DTP311moonbitlang5async9js__async85_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3afrom__async_2elambda_2elambda_2f297L5StateGuE12_2atry_2f130(_cont_param, reject));
            let _bind$3;
            if (_bind$2.$tag === 1) {
              const _ok = _bind$2;
              _bind$3 = _ok._0;
            } else {
              const _err$3 = _bind$2;
              _err$2 = _err$3._0;
              break _L$2;
            }
            if (_bind$3 === -1) {
              return;
            } else {
              const _Some = _bind$3;
              const _payload = _Some;
              _cont(_payload);
              return;
            }
          }
          _err_cont(_err$2);
        });
        let _bind$2;
        if (_bind.$tag === 1) {
          const _ok = _bind;
          _bind$2 = _ok._0;
        } else {
          const _err$2 = _bind;
          _err = _err$2._0;
          break _L;
        }
        if (_bind$2 === -1) {
          return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok(-1);
        } else {
          const _Some = _bind$2;
          const _payload = _Some;
          return _async_driver(new _M0DTP311moonbitlang5async9js__async85_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3afrom__async_2elambda_2elambda_2f297L5StateGuE8State__1(_payload, resolve));
        }
      }
      return _async_driver(new _M0DTP311moonbitlang5async9js__async85_40moonbitlang_2fasync_2fjs__async_2ePromise_3a_3afrom__async_2elambda_2elambda_2f297L5StateGuE12_2atry_2f130(_err, reject));
    });
    let signal;
    _L: {
      if (abort_signal.$tag === 1) {
        const _Some = abort_signal;
        const _signal = _Some._0;
        signal = _signal;
        break _L;
      } else {
        return;
      }
    }
    _M0MP311moonbitlang5async9js__async11AbortSignal9on__abort(signal, () => {
      _M0MP411moonbitlang5async8internal9coroutine9Coroutine6cancel(coro);
    });
  });
  _M0FP411moonbitlang5async8internal9coroutine10reschedule();
  return promise;
}
function _M0IP311moonbitlang5async9js__async7JsErrorPB4Show6output(self, logger) {
  let value;
  _L: {
    const _JsError = self;
    const _value = _JsError._0;
    value = _value;
    break _L;
  }
  logger.method_table.method_0(logger.self, _M0MP311moonbitlang5async9js__async7JsValue10to__string(value));
}
function _M0FP311emadurandal6WebGPU15webgpu__objects21shaderModule__release(shaderModule) {}
function _M0MP311emadurandal6WebGPU15webgpu__objects26WebGPURenderPassDescriptor3new(colorAttachments, depthStencilAttachment) {
  return new _M0TP311emadurandal6WebGPU15webgpu__objects26WebGPURenderPassDescriptor(colorAttachments, depthStencilAttachment);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects32create__render__pass__descriptor(colorAttachments, depthStencilAttachment) {
  return _M0MP311emadurandal6WebGPU15webgpu__objects26WebGPURenderPassDescriptor3new(colorAttachments, depthStencilAttachment);
}
function _M0MP311emadurandal6WebGPU15webgpu__objects31WebGPURenderPassColorAttachment3new(view, clearValue, loadOp, storeOp) {
  return new _M0TP311emadurandal6WebGPU15webgpu__objects31WebGPURenderPassColorAttachment(view, clearValue, loadOp, storeOp);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects39create__render__pass__color__attachment(view, clearValue, loadOp, storeOp) {
  return _M0MP311emadurandal6WebGPU15webgpu__objects31WebGPURenderPassColorAttachment3new(view, clearValue, loadOp, storeOp);
}
function _M0MP311emadurandal6WebGPU15webgpu__objects13WebGPUContext3new(device, context, format, queue) {
  return new _M0TP311emadurandal6WebGPU15webgpu__objects13WebGPUContext(device, context, format, queue);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects23create__webgpu__context(device, context, format, queue) {
  return _M0MP311emadurandal6WebGPU15webgpu__objects13WebGPUContext3new(device, context, format, queue);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects20webgpu__context__get(context) {
  return { _0: context.device, _1: context.context, _2: context.format, _3: context.queue };
}
function _M0MP311emadurandal6WebGPU15webgpu__objects13WebGPUTexture3new(texture) {
  return new _M0TP311emadurandal6WebGPU15webgpu__objects13WebGPUTexture(texture);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects29webgpu__texture__create__view(texture) {
  return _M0FP311emadurandal6WebGPU15webgpu__objects19texture__createView(texture.texture);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects20textureView__release(view) {}
function _M0MP311emadurandal6WebGPU15webgpu__objects23WebGPURenderPassEncoder3new(encoder) {
  return new _M0TP311emadurandal6WebGPU15webgpu__objects23WebGPURenderPassEncoder(encoder);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects44webgpu__render__pass__encoder__set__pipeline(renderPass, pipeline) {
  _M0FP311emadurandal6WebGPU15webgpu__objects23renderPass__setPipeline(renderPass.encoder, pipeline);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects35webgpu__render__pass__encoder__draw(renderPass, vertexCount) {
  _M0FP311emadurandal6WebGPU15webgpu__objects16renderPass__draw(renderPass.encoder, vertexCount);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects34webgpu__render__pass__encoder__end(renderPass) {
  _M0FP311emadurandal6WebGPU15webgpu__objects15renderPass__end(renderPass.encoder);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects38webgpu__render__pass__encoder__release(renderPass) {}
function _M0MP311emadurandal6WebGPU15webgpu__objects11WebGPUQueue3new(queue) {
  return new _M0TP311emadurandal6WebGPU15webgpu__objects11WebGPUQueue(queue);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects21webgpu__queue__submit(queue, commandBuffer) {
  _M0FP311emadurandal6WebGPU15webgpu__objects13queue__submit(queue.queue, commandBuffer);
}
function _M0MP311emadurandal6WebGPU15webgpu__objects14WebGPUInstance3new(instance) {
  return new _M0TP311emadurandal6WebGPU15webgpu__objects14WebGPUInstance(instance);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects24create__webgpu__instance(instance) {
  return _M0MP311emadurandal6WebGPU15webgpu__objects14WebGPUInstance3new(instance);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects62webgpu__instance__get__preferred__canvas__format__for__surface(instance, adapter, canvas) {
  return _M0FP311emadurandal6WebGPU15webgpu__objects29gpu__getPreferredCanvasFormat(instance.instance);
}
function _M0MP311emadurandal6WebGPU15webgpu__objects13WebGPUAdapter3new(adapter) {
  return new _M0TP311emadurandal6WebGPU15webgpu__objects13WebGPUAdapter(adapter);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects34webgpu__instance__request__adapter(instance, _cont, _err_cont) {
  const _async_driver = (_state) => {
    const _State_0 = _state;
    const _cont_param = _State_0._0;
    const adapter = _cont_param;
    return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects13WebGPUAdapterRPC15error5ErrorE2Ok(_M0MP311emadurandal6WebGPU15webgpu__objects13WebGPUAdapter3new(adapter));
  };
  const _bind = _M0MP311moonbitlang5async9js__async7Promise4waitGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE(_M0FP311emadurandal6WebGPU15webgpu__objects19gpu__requestAdapter(instance.instance), _M0DTPC16option6OptionGRP311moonbitlang5async9js__async15AbortControllerE4None__, (_cont_param) => {
    let _err;
    _L: {
      const _bind$2 = _async_driver(new _M0DTP311emadurandal6WebGPU15webgpu__objects78_24emadurandal_2fWebGPU_2fwebgpu__objects_2ewebgpu__instance__request__adapterL5State8State__0(_cont_param));
      let _bind$3;
      if (_bind$2.$tag === 1) {
        const _ok = _bind$2;
        _bind$3 = _ok._0;
      } else {
        const _err$2 = _bind$2;
        _err = _err$2._0;
        break _L;
      }
      if (_bind$3 === undefined) {
        return;
      } else {
        const _Some = _bind$3;
        const _payload = _Some;
        _cont(_payload);
        return;
      }
    }
    _err_cont(_err);
  }, _err_cont);
  let _tmp;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    _tmp = _ok._0;
  } else {
    return _bind;
  }
  const _tmp$2 = _tmp;
  if (_tmp$2.$tag === 1) {
    const _Some = _tmp$2;
    const _payload = _Some._0;
    return _async_driver(new _M0DTP311emadurandal6WebGPU15webgpu__objects78_24emadurandal_2fWebGPU_2fwebgpu__objects_2ewebgpu__instance__request__adapterL5State8State__0(_payload));
  } else {
    return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects13WebGPUAdapterRPC15error5ErrorE2Ok(undefined);
  }
}
function _M0FP311emadurandal6WebGPU15webgpu__objects23vertex__layout__to__ffi(lb) {
  const attrs = _M0MPC15array5Array3mapGRP311emadurandal6WebGPU13webgpu__enums18GPUVertexAttributeRP311emadurandal6WebGPU15webgpu__objects18VertexAttributeFFIE(lb.attributes, (a) => new _M0TP311emadurandal6WebGPU15webgpu__objects18VertexAttributeFFI(_M0MP311emadurandal6WebGPU13webgpu__enums15GPUVertexFormat11to__js__tag(a.format), Number(BigInt.asUintN(32, a.offset)) | 0, a.shader_location));
  return new _M0TP311emadurandal6WebGPU15webgpu__objects21VertexBufferLayoutFFI(Number(BigInt.asUintN(32, lb.array_stride)) | 0, _M0MP311emadurandal6WebGPU13webgpu__enums17GPUVertexStepMode11to__js__tag(lb.step_mode), attrs);
}
function _M0MP311emadurandal6WebGPU15webgpu__objects12WebGPUDevice3new(device) {
  return new _M0TP311emadurandal6WebGPU15webgpu__objects12WebGPUDevice(device);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects19webgpu__device__get(device) {
  return device.device;
}
function _M0FP311emadurandal6WebGPU15webgpu__objects26webgpu__device__get__queue(device) {
  return _M0MP311emadurandal6WebGPU15webgpu__objects11WebGPUQueue3new(_M0FP311emadurandal6WebGPU15webgpu__objects16device__getQueue(device.device));
}
function _M0FP311emadurandal6WebGPU15webgpu__objects38webgpu__device__create__shader__module(device, code) {
  return _M0FP311emadurandal6WebGPU15webgpu__objects26device__createShaderModule(device.device, code);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects40webgpu__device__create__render__pipeline(device, vertex, fragment, topology, formats, vertex_buffers, depth_stencil_format) {
  const vffi = _M0MPC15array5Array3mapGRP311emadurandal6WebGPU13webgpu__enums21GPUVertexBufferLayoutRP311emadurandal6WebGPU15webgpu__objects21VertexBufferLayoutFFIE(vertex_buffers, (lb) => _M0FP311emadurandal6WebGPU15webgpu__objects23vertex__layout__to__ffi(lb));
  return _M0FP311emadurandal6WebGPU15webgpu__objects28device__createRenderPipeline(device.device, vertex, fragment, _M0MP311emadurandal6WebGPU13webgpu__enums20GPUPrimitiveTopology11to__js__tag(topology), formats, vffi, depth_stencil_format);
}
function _M0MP311emadurandal6WebGPU15webgpu__objects20WebGPUCommandEncoder3new(encoder) {
  return new _M0TP311emadurandal6WebGPU15webgpu__objects20WebGPUCommandEncoder(encoder);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects40webgpu__device__create__command__encoder(device) {
  return _M0MP311emadurandal6WebGPU15webgpu__objects20WebGPUCommandEncoder3new(_M0FP311emadurandal6WebGPU15webgpu__objects28device__createCommandEncoder(device.device));
}
function _M0FP311emadurandal6WebGPU15webgpu__objects45webgpu__command__encoder__begin__render__pass(encoder, descriptor) {
  return _M0MP311emadurandal6WebGPU15webgpu__objects23WebGPURenderPassEncoder3new(_M0FP311emadurandal6WebGPU15webgpu__objects24encoder__beginRenderPass(encoder.encoder, descriptor));
}
function _M0FP311emadurandal6WebGPU15webgpu__objects32webgpu__command__encoder__finish(encoder) {
  return _M0FP311emadurandal6WebGPU15webgpu__objects15encoder__finish(encoder.encoder);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects33webgpu__command__encoder__release(encoder) {}
function _M0MP311emadurandal6WebGPU15webgpu__objects19WebGPUCanvasContext3new(context) {
  return new _M0TP311emadurandal6WebGPU15webgpu__objects19WebGPUCanvasContext(context);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects23create__canvas__context(context) {
  return _M0MP311emadurandal6WebGPU15webgpu__objects19WebGPUCanvasContext3new(context);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects34webgpu__canvas__context__configure(context, device, format) {
  _M0FP311emadurandal6WebGPU15webgpu__objects18context__configure(context.context, device, format);
}
function _M0FP311emadurandal6WebGPU15webgpu__objects46webgpu__canvas__context__get__current__texture(context) {
  return _M0MP311emadurandal6WebGPU15webgpu__objects13WebGPUTexture3new(_M0FP311emadurandal6WebGPU15webgpu__objects26context__getCurrentTexture(context.context));
}
function _M0FP311emadurandal6WebGPU15webgpu__objects32webgpu__canvas__context__present(context) {}
function _M0FP311emadurandal6WebGPU15webgpu__objects32webgpu__adapter__request__device(adapter, _cont, _err_cont) {
  const _async_driver = (_state) => {
    const _State_0 = _state;
    const _cont_param = _State_0._0;
    const device = _cont_param;
    return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects12WebGPUDeviceRPC15error5ErrorE2Ok(_M0MP311emadurandal6WebGPU15webgpu__objects12WebGPUDevice3new(device));
  };
  const _bind = _M0MP311moonbitlang5async9js__async7Promise4waitGRP311emadurandal6WebGPU15webgpu__objects9GPUDeviceE(_M0FP311emadurandal6WebGPU15webgpu__objects18gpu__requestDevice(adapter.adapter), _M0DTPC16option6OptionGRP311moonbitlang5async9js__async15AbortControllerE4None__, (_cont_param) => {
    let _err;
    _L: {
      const _bind$2 = _async_driver(new _M0DTP311emadurandal6WebGPU15webgpu__objects76_24emadurandal_2fWebGPU_2fwebgpu__objects_2ewebgpu__adapter__request__deviceL5State8State__0(_cont_param));
      let _bind$3;
      if (_bind$2.$tag === 1) {
        const _ok = _bind$2;
        _bind$3 = _ok._0;
      } else {
        const _err$2 = _bind$2;
        _err = _err$2._0;
        break _L;
      }
      if (_bind$3 === undefined) {
        return;
      } else {
        const _Some = _bind$3;
        const _payload = _Some;
        _cont(_payload);
        return;
      }
    }
    _err_cont(_err);
  }, _err_cont);
  let _tmp;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    _tmp = _ok._0;
  } else {
    return _bind;
  }
  const _tmp$2 = _tmp;
  if (_tmp$2.$tag === 1) {
    const _Some = _tmp$2;
    const _payload = _Some._0;
    return _async_driver(new _M0DTP311emadurandal6WebGPU15webgpu__objects76_24emadurandal_2fWebGPU_2fwebgpu__objects_2ewebgpu__adapter__request__deviceL5State8State__0(_payload));
  } else {
    return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU15webgpu__objects12WebGPUDeviceRPC15error5ErrorE2Ok(undefined);
  }
}
function _M0MP311emadurandal6WebGPU6webgpu11GPUInstance44get__preferred__canvas__format__for__surface(self, adapter, canvas) {
  return _M0FP311emadurandal6WebGPU15webgpu__objects62webgpu__instance__get__preferred__canvas__format__for__surface(self.raw, adapter.raw, canvas.raw);
}
function _M0MP311emadurandal6WebGPU6webgpu11GPUInstance16request__adapter(self, _cont, _err_cont) {
  const _async_driver = (_state) => {
    const _State_0 = _state;
    const _cont_param = _State_0._0;
    return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUAdapterRPC15error5ErrorE2Ok(new _M0TP311emadurandal6WebGPU6webgpu10GPUAdapter(_cont_param));
  };
  const _bind = _M0FP311emadurandal6WebGPU15webgpu__objects34webgpu__instance__request__adapter(self.raw, (_cont_param) => {
    let _err;
    _L: {
      const _bind$2 = _async_driver(new _M0DTP311emadurandal6WebGPU6webgpu68_40emadurandal_2fWebGPU_2fwebgpu_2eGPUInstance_3a_3arequest__adapterL5State8State__0(_cont_param));
      let _bind$3;
      if (_bind$2.$tag === 1) {
        const _ok = _bind$2;
        _bind$3 = _ok._0;
      } else {
        const _err$2 = _bind$2;
        _err = _err$2._0;
        break _L;
      }
      if (_bind$3 === undefined) {
        return;
      } else {
        const _Some = _bind$3;
        const _payload = _Some;
        _cont(_payload);
        return;
      }
    }
    _err_cont(_err);
  }, _err_cont);
  let _bind$2;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    _bind$2 = _ok._0;
  } else {
    return _bind;
  }
  if (_bind$2 === undefined) {
    return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUAdapterRPC15error5ErrorE2Ok(undefined);
  } else {
    const _Some = _bind$2;
    const _payload = _Some;
    return _async_driver(new _M0DTP311emadurandal6WebGPU6webgpu68_40emadurandal_2fWebGPU_2fwebgpu_2eGPUInstance_3a_3arequest__adapterL5State8State__0(_payload));
  }
}
function _M0MP311emadurandal6WebGPU6webgpu10GPUAdapter15request__device(self, _cont, _err_cont) {
  const _async_driver = (_state) => {
    const _State_0 = _state;
    const _cont_param = _State_0._0;
    return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu9GPUDeviceRPC15error5ErrorE2Ok(new _M0TP311emadurandal6WebGPU6webgpu9GPUDevice(_cont_param));
  };
  const _bind = _M0FP311emadurandal6WebGPU15webgpu__objects32webgpu__adapter__request__device(self.raw, (_cont_param) => {
    let _err;
    _L: {
      const _bind$2 = _async_driver(new _M0DTP311emadurandal6WebGPU6webgpu66_40emadurandal_2fWebGPU_2fwebgpu_2eGPUAdapter_3a_3arequest__deviceL5State8State__0(_cont_param));
      let _bind$3;
      if (_bind$2.$tag === 1) {
        const _ok = _bind$2;
        _bind$3 = _ok._0;
      } else {
        const _err$2 = _bind$2;
        _err = _err$2._0;
        break _L;
      }
      if (_bind$3 === undefined) {
        return;
      } else {
        const _Some = _bind$3;
        const _payload = _Some;
        _cont(_payload);
        return;
      }
    }
    _err_cont(_err);
  }, _err_cont);
  let _bind$2;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    _bind$2 = _ok._0;
  } else {
    return _bind;
  }
  if (_bind$2 === undefined) {
    return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu9GPUDeviceRPC15error5ErrorE2Ok(undefined);
  } else {
    const _Some = _bind$2;
    const _payload = _Some;
    return _async_driver(new _M0DTP311emadurandal6WebGPU6webgpu66_40emadurandal_2fWebGPU_2fwebgpu_2eGPUAdapter_3a_3arequest__deviceL5State8State__0(_payload));
  }
}
function _M0MP311emadurandal6WebGPU6webgpu9GPUDevice10get__queue(self) {
  return new _M0TP311emadurandal6WebGPU6webgpu8GPUQueue(_M0FP311emadurandal6WebGPU15webgpu__objects26webgpu__device__get__queue(self.raw));
}
function _M0MP311emadurandal6WebGPU6webgpu9GPUDevice22create__shader__module(self, code) {
  return _M0FP311emadurandal6WebGPU15webgpu__objects38webgpu__device__create__shader__module(self.raw, code);
}
function _M0MP311emadurandal6WebGPU6webgpu9GPUDevice24create__render__pipeline(self, descriptor) {
  const _tmp = self.raw;
  const _tmp$2 = descriptor.vertex;
  const _tmp$3 = descriptor.fragment;
  const _tmp$4 = descriptor.topology;
  const _tmp$5 = descriptor.formats;
  const _tmp$6 = descriptor.vertex_buffers;
  let _tmp$7;
  const _bind = descriptor.depth_stencil_format;
  if (_bind === undefined) {
    _tmp$7 = "";
  } else {
    const _Some = _bind;
    const _s = _Some;
    _tmp$7 = _s;
  }
  return new _M0TP311emadurandal6WebGPU6webgpu17GPURenderPipeline(_M0FP311emadurandal6WebGPU15webgpu__objects40webgpu__device__create__render__pipeline(_tmp, _tmp$2, _tmp$3, _tmp$4, _tmp$5, _tmp$6, _tmp$7));
}
function _M0MP311emadurandal6WebGPU6webgpu9GPUDevice24create__command__encoder(self) {
  return new _M0TP311emadurandal6WebGPU6webgpu17GPUCommandEncoder(_M0FP311emadurandal6WebGPU15webgpu__objects40webgpu__device__create__command__encoder(self.raw));
}
function _M0MP311emadurandal6WebGPU6webgpu16GPUCanvasContext9configure(self, device, format) {
  _M0FP311emadurandal6WebGPU15webgpu__objects34webgpu__canvas__context__configure(self.raw, _M0FP311emadurandal6WebGPU15webgpu__objects19webgpu__device__get(device.raw), format);
}
function _M0MP311emadurandal6WebGPU6webgpu16GPUCanvasContext21get__current__texture(self) {
  return new _M0TP311emadurandal6WebGPU6webgpu10GPUTexture(_M0FP311emadurandal6WebGPU15webgpu__objects46webgpu__canvas__context__get__current__texture(self.raw));
}
function _M0MP311emadurandal6WebGPU6webgpu16GPUCanvasContext7present(self) {
  _M0FP311emadurandal6WebGPU15webgpu__objects32webgpu__canvas__context__present(self.raw);
}
function _M0MP311emadurandal6WebGPU6webgpu10GPUContext3get(self) {
  let format;
  let device;
  let context;
  let queue;
  _L: {
    const _bind = _M0FP311emadurandal6WebGPU15webgpu__objects20webgpu__context__get(self.raw);
    const _device = _bind._0;
    const _context = _bind._1;
    const _format = _bind._2;
    const _queue = _bind._3;
    format = _format;
    device = _device;
    context = _context;
    queue = _queue;
    break _L;
  }
  return { _0: new _M0TP311emadurandal6WebGPU6webgpu9GPUDevice(device), _1: new _M0TP311emadurandal6WebGPU6webgpu16GPUCanvasContext(context), _2: format, _3: new _M0TP311emadurandal6WebGPU6webgpu8GPUQueue(queue) };
}
function _M0MP311emadurandal6WebGPU6webgpu10GPUTexture12create__view(self) {
  return _M0FP311emadurandal6WebGPU15webgpu__objects29webgpu__texture__create__view(self.raw);
}
function _M0FP311emadurandal6WebGPU6webgpu43render__pass__color__attachment__from__desc(att) {
  let c;
  _L: {
    const _bind = att.clear_value;
    if (_bind === undefined) {
      return _M0FP311emadurandal6WebGPU15webgpu__objects39create__render__pass__color__attachment(att.view, undefined, att.load_op, att.store_op);
    } else {
      const _Some = _bind;
      const _c = _Some;
      c = _c;
      break _L;
    }
  }
  return _M0FP311emadurandal6WebGPU15webgpu__objects39create__render__pass__color__attachment(att.view, c, att.load_op, att.store_op);
}
function _M0FP311emadurandal6WebGPU6webgpu33render__pass__descriptor__to__raw(desc) {
  const mapped = _M0MPC15array5Array3mapGORP311emadurandal6WebGPU6webgpu28GPURenderPassColorAttachmentORP311emadurandal6WebGPU15webgpu__objects31WebGPURenderPassColorAttachmentE(desc.color_attachments, (opt) => {
    let att;
    _L: {
      if (opt === undefined) {
        return undefined;
      } else {
        const _Some = opt;
        const _att = _Some;
        att = _att;
        break _L;
      }
    }
    return _M0FP311emadurandal6WebGPU6webgpu43render__pass__color__attachment__from__desc(att);
  });
  let ds;
  _L: {
    const _bind = desc.depth_stencil_attachment;
    if (_bind === undefined) {
      return _M0FP311emadurandal6WebGPU15webgpu__objects32create__render__pass__descriptor(mapped, undefined);
    } else {
      const _Some = _bind;
      const _ds = _Some;
      ds = _ds;
      break _L;
    }
  }
  return _M0FP311emadurandal6WebGPU15webgpu__objects32create__render__pass__descriptor(mapped, ds);
}
function _M0MP311emadurandal6WebGPU6webgpu17GPUCommandEncoder19begin__render__pass(self, descriptor) {
  const raw_desc = _M0FP311emadurandal6WebGPU6webgpu33render__pass__descriptor__to__raw(descriptor);
  return new _M0TP311emadurandal6WebGPU6webgpu20GPURenderPassEncoder(_M0FP311emadurandal6WebGPU15webgpu__objects45webgpu__command__encoder__begin__render__pass(self.raw, raw_desc));
}
function _M0MP311emadurandal6WebGPU6webgpu17GPUCommandEncoder6finish(self) {
  return _M0FP311emadurandal6WebGPU15webgpu__objects32webgpu__command__encoder__finish(self.raw);
}
function _M0MP311emadurandal6WebGPU6webgpu17GPUCommandEncoder7release(self) {
  _M0FP311emadurandal6WebGPU15webgpu__objects33webgpu__command__encoder__release(self.raw);
}
function _M0MP311emadurandal6WebGPU6webgpu8GPUQueue6submit(self, command_buffer) {
  _M0FP311emadurandal6WebGPU15webgpu__objects21webgpu__queue__submit(self.raw, command_buffer);
}
function _M0MP311emadurandal6WebGPU6webgpu20GPURenderPassEncoder13set__pipeline(self, pipeline) {
  _M0FP311emadurandal6WebGPU15webgpu__objects44webgpu__render__pass__encoder__set__pipeline(self.raw, pipeline.raw);
}
function _M0MP311emadurandal6WebGPU6webgpu20GPURenderPassEncoder4draw(self, vertex_count) {
  _M0FP311emadurandal6WebGPU15webgpu__objects35webgpu__render__pass__encoder__draw(self.raw, vertex_count);
}
function _M0MP311emadurandal6WebGPU6webgpu20GPURenderPassEncoder3end(self) {
  _M0FP311emadurandal6WebGPU15webgpu__objects34webgpu__render__pass__encoder__end(self.raw);
}
function _M0MP311emadurandal6WebGPU6webgpu20GPURenderPassEncoder7release(self) {
  _M0FP311emadurandal6WebGPU15webgpu__objects38webgpu__render__pass__encoder__release(self.raw);
}
function _M0FP311emadurandal6WebGPU6webgpu12navigatorGPU() {
  return _M0FP311emadurandal6WebGPU15webgpu__objects12navigatorGPU();
}
function _M0FP311emadurandal6WebGPU6webgpu18canvas__getContext(canvas) {
  return _M0FP311emadurandal6WebGPU15webgpu__objects18canvas__getContext(canvas);
}
function _M0FP311emadurandal6WebGPU6webgpu24create__webgpu__instance(gpu) {
  return new _M0TP311emadurandal6WebGPU6webgpu11GPUInstance(_M0FP311emadurandal6WebGPU15webgpu__objects24create__webgpu__instance(gpu));
}
function _M0FP311emadurandal6WebGPU6webgpu23create__canvas__context(context) {
  return new _M0TP311emadurandal6WebGPU6webgpu16GPUCanvasContext(_M0FP311emadurandal6WebGPU15webgpu__objects23create__canvas__context(context));
}
function _M0FP311emadurandal6WebGPU6webgpu23create__webgpu__context(device, context, format, queue) {
  return new _M0TP311emadurandal6WebGPU6webgpu10GPUContext(_M0FP311emadurandal6WebGPU15webgpu__objects23create__webgpu__context(device.raw, context.raw, format, queue.raw));
}
function _M0FP311emadurandal6WebGPU6webgpu21shaderModule__release(shaderModule) {
  _M0FP311emadurandal6WebGPU15webgpu__objects21shaderModule__release(shaderModule);
}
function _M0FP311emadurandal6WebGPU6webgpu20textureView__release(view) {
  _M0FP311emadurandal6WebGPU15webgpu__objects20textureView__release(view);
}
function _M0FP411emadurandal17WebGPU_2dexamples16basic_2dtriangle6common16create__pipeline(device, format) {
  const shader = _M0MP311emadurandal6WebGPU6webgpu9GPUDevice22create__shader__module(device, _M0FP411emadurandal17WebGPU_2dexamples16basic_2dtriangle6common22triangle__shader__code);
  const pipeline_descriptor = new _M0TP311emadurandal6WebGPU6webgpu27GPURenderPipelineDescriptor(shader, shader, 3, [format], [], undefined);
  const pipeline = _M0MP311emadurandal6WebGPU6webgpu9GPUDevice24create__render__pipeline(device, pipeline_descriptor);
  _M0FP311emadurandal6WebGPU6webgpu21shaderModule__release(shader);
  return pipeline;
}
function _M0FP411emadurandal17WebGPU_2dexamples16basic_2dtriangle6common16create__renderer(context) {
  let format;
  let device;
  let canvas_context;
  let queue;
  _L: {
    const _bind = _M0MP311emadurandal6WebGPU6webgpu10GPUContext3get(context);
    const _device = _bind._0;
    const _canvas_context = _bind._1;
    const _format = _bind._2;
    const _queue = _bind._3;
    format = _format;
    device = _device;
    canvas_context = _canvas_context;
    queue = _queue;
    break _L;
  }
  const pipeline = _M0FP411emadurandal17WebGPU_2dexamples16basic_2dtriangle6common16create__pipeline(device, format);
  return new _M0TP411emadurandal17WebGPU_2dexamples16basic_2dtriangle6common14WebGPURenderer(canvas_context, device, queue, pipeline);
}
function _M0FP411emadurandal17WebGPU_2dexamples16basic_2dtriangle6common28render__frame__with__options(renderer, clearColor, vertex_count) {
  const texture = _M0MP311emadurandal6WebGPU6webgpu16GPUCanvasContext21get__current__texture(renderer.context);
  const view = _M0MP311emadurandal6WebGPU6webgpu10GPUTexture12create__view(texture);
  const encoder = _M0MP311emadurandal6WebGPU6webgpu9GPUDevice24create__command__encoder(renderer.device);
  const render_pass = _M0MP311emadurandal6WebGPU6webgpu17GPUCommandEncoder19begin__render__pass(encoder, new _M0TP311emadurandal6WebGPU6webgpu23GPURenderPassDescriptor([new _M0TP311emadurandal6WebGPU6webgpu28GPURenderPassColorAttachment(view, clearColor, 1, 0)], undefined));
  _M0MP311emadurandal6WebGPU6webgpu20GPURenderPassEncoder13set__pipeline(render_pass, renderer.pipeline);
  _M0MP311emadurandal6WebGPU6webgpu20GPURenderPassEncoder4draw(render_pass, vertex_count);
  _M0MP311emadurandal6WebGPU6webgpu20GPURenderPassEncoder3end(render_pass);
  _M0MP311emadurandal6WebGPU6webgpu20GPURenderPassEncoder7release(render_pass);
  const command_buffer = _M0MP311emadurandal6WebGPU6webgpu17GPUCommandEncoder6finish(encoder);
  _M0MP311emadurandal6WebGPU6webgpu8GPUQueue6submit(renderer.queue, command_buffer);
  _M0MP311emadurandal6WebGPU6webgpu17GPUCommandEncoder7release(encoder);
  _M0FP311emadurandal6WebGPU6webgpu20textureView__release(view);
  _M0MP311emadurandal6WebGPU6webgpu16GPUCanvasContext7present(renderer.context);
}
function _M0FP411emadurandal17WebGPU_2dexamples16basic_2dtriangle6common13render__frame(renderer) {
  _M0FP411emadurandal17WebGPU_2dexamples16basic_2dtriangle6common28render__frame__with__options(renderer, new _M0TP311emadurandal6WebGPU13webgpu__enums8GPUColor(0, 0, 0.2, 1), 3);
}
function _M0FP411emadurandal17WebGPU_2dexamples6common7browser32gpu__context__from__html__canvas(canvas, _cont, _err_cont) {
  const _async_driver = (_state) => {
    let _tmp = _state;
    while (true) {
      const _state$2 = _tmp;
      if (_state$2.$tag === 0) {
        const _State_0 = _state$2;
        const adapter = _State_0._3;
        const instance = _State_0._2;
        const canvas$2 = _State_0._1;
        const _cont_param = _State_0._0;
        const device = _cont_param;
        const webgpu_canvas_context = _M0FP311emadurandal6WebGPU6webgpu23create__canvas__context(_M0FP311emadurandal6WebGPU6webgpu18canvas__getContext(canvas$2));
        const format = _M0MP311emadurandal6WebGPU6webgpu11GPUInstance44get__preferred__canvas__format__for__surface(instance, adapter, webgpu_canvas_context);
        _M0MP311emadurandal6WebGPU6webgpu16GPUCanvasContext9configure(webgpu_canvas_context, device, format);
        const queue = _M0MP311emadurandal6WebGPU6webgpu9GPUDevice10get__queue(device);
        return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUContextRPC15error5ErrorE2Ok(_M0FP311emadurandal6WebGPU6webgpu23create__webgpu__context(device, webgpu_canvas_context, format, queue));
      } else {
        const _State_1 = _state$2;
        const _err_cont$2 = _State_1._4;
        const _cont$2 = _State_1._3;
        const instance = _State_1._2;
        const canvas$2 = _State_1._1;
        const _cont_param = _State_1._0;
        const adapter = _cont_param;
        const _bind = _M0MP311emadurandal6WebGPU6webgpu10GPUAdapter15request__device(adapter, (_cont_param$2) => {
          let _err;
          _L: {
            const _bind$2 = _async_driver(new _M0DTP411emadurandal17WebGPU_2dexamples6common7browser88_24emadurandal_2fWebGPU_2dexamples_2fcommon_2fbrowser_2egpu__context__from__html__canvasL5State8State__0(_cont_param$2, canvas$2, instance, adapter));
            let _bind$3;
            if (_bind$2.$tag === 1) {
              const _ok = _bind$2;
              _bind$3 = _ok._0;
            } else {
              const _err$2 = _bind$2;
              _err = _err$2._0;
              break _L;
            }
            if (_bind$3 === undefined) {
              return;
            } else {
              const _Some = _bind$3;
              const _payload = _Some;
              _cont$2(_payload);
              return;
            }
          }
          _err_cont$2(_err);
        }, _err_cont$2);
        let _bind$2;
        if (_bind.$tag === 1) {
          const _ok = _bind;
          _bind$2 = _ok._0;
        } else {
          return _bind;
        }
        if (_bind$2 === undefined) {
          return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUContextRPC15error5ErrorE2Ok(undefined);
        } else {
          const _Some = _bind$2;
          const _payload = _Some;
          _tmp = new _M0DTP411emadurandal17WebGPU_2dexamples6common7browser88_24emadurandal_2fWebGPU_2dexamples_2fcommon_2fbrowser_2egpu__context__from__html__canvasL5State8State__0(_payload, canvas$2, instance, adapter);
          continue;
        }
      }
    }
  };
  const instance = _M0FP311emadurandal6WebGPU6webgpu24create__webgpu__instance(_M0FP311emadurandal6WebGPU6webgpu12navigatorGPU());
  const _bind = _M0MP311emadurandal6WebGPU6webgpu11GPUInstance16request__adapter(instance, (_cont_param) => {
    let _err;
    _L: {
      const _bind$2 = _async_driver(new _M0DTP411emadurandal17WebGPU_2dexamples6common7browser88_24emadurandal_2fWebGPU_2dexamples_2fcommon_2fbrowser_2egpu__context__from__html__canvasL5State8State__1(_cont_param, canvas, instance, _cont, _err_cont));
      let _bind$3;
      if (_bind$2.$tag === 1) {
        const _ok = _bind$2;
        _bind$3 = _ok._0;
      } else {
        const _err$2 = _bind$2;
        _err = _err$2._0;
        break _L;
      }
      if (_bind$3 === undefined) {
        return;
      } else {
        const _Some = _bind$3;
        const _payload = _Some;
        _cont(_payload);
        return;
      }
    }
    _err_cont(_err);
  }, _err_cont);
  let _bind$2;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    _bind$2 = _ok._0;
  } else {
    return _bind;
  }
  if (_bind$2 === undefined) {
    return new _M0DTPC16result6ResultGORP311emadurandal6WebGPU6webgpu10GPUContextRPC15error5ErrorE2Ok(undefined);
  } else {
    const _Some = _bind$2;
    const _payload = _Some;
    return _async_driver(new _M0DTP411emadurandal17WebGPU_2dexamples6common7browser88_24emadurandal_2fWebGPU_2dexamples_2fcommon_2fbrowser_2egpu__context__from__html__canvasL5State8State__1(_payload, canvas, instance, _cont, _err_cont));
  }
}
function _M0FP511emadurandal17WebGPU_2dexamples16basic_2dtriangle2js4main31create__webgpu__renderer__async(canvas, _cont, _err_cont) {
  const _async_driver = (_state) => {
    const _State_0 = _state;
    const _cont_param = _State_0._0;
    const ctx = _cont_param;
    let renderer;
    _L: {
      const _bind = _M0FP411emadurandal17WebGPU_2dexamples16basic_2dtriangle6common16create__renderer(ctx);
      if (_bind === undefined) {
        return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok(_M0FPB7printlnGsE("Failed to create renderer"));
      } else {
        const _Some = _bind;
        const _renderer = _Some;
        renderer = _renderer;
        break _L;
      }
    }
    _M0FP411emadurandal17WebGPU_2dexamples16basic_2dtriangle6common13render__frame(renderer);
    return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok(_M0FPB7printlnGsE("WebGPU triangle rendered successfully!"));
  };
  const _bind = _M0FP411emadurandal17WebGPU_2dexamples6common7browser32gpu__context__from__html__canvas(canvas, (_cont_param) => {
    let _err;
    _L: {
      const _bind$2 = _async_driver(new _M0DTP511emadurandal17WebGPU_2dexamples16basic_2dtriangle2js4main99_24emadurandal_2fWebGPU_2dexamples_2fbasic_2dtriangle_2fjs_2fmain_2ecreate__webgpu__renderer__asyncL5State8State__0(_cont_param));
      let _bind$3;
      if (_bind$2.$tag === 1) {
        const _ok = _bind$2;
        _bind$3 = _ok._0;
      } else {
        const _err$2 = _bind$2;
        _err = _err$2._0;
        break _L;
      }
      if (_bind$3 === -1) {
        return;
      } else {
        const _Some = _bind$3;
        const _payload = _Some;
        _cont(_payload);
        return;
      }
    }
    _err_cont(_err);
  }, _err_cont);
  let _bind$2;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    _bind$2 = _ok._0;
  } else {
    return _bind;
  }
  if (_bind$2 === undefined) {
    return new _M0DTPC16result6ResultGOuRPC15error5ErrorE2Ok(-1);
  } else {
    const _Some = _bind$2;
    const _payload = _Some;
    return _async_driver(new _M0DTP511emadurandal17WebGPU_2dexamples16basic_2dtriangle2js4main99_24emadurandal_2fWebGPU_2dexamples_2fbasic_2dtriangle_2fjs_2fmain_2ecreate__webgpu__renderer__asyncL5State8State__0(_payload));
  }
}
function _M0FP511emadurandal17WebGPU_2dexamples16basic_2dtriangle2js4main24create__webgpu__renderer(canvas) {
  return _M0MP311moonbitlang5async9js__async7Promise11from__asyncGuE((_cont, _err_cont) => _M0FP511emadurandal17WebGPU_2dexamples16basic_2dtriangle2js4main31create__webgpu__renderer__async(canvas, _cont, _err_cont), _M0DTPC16option6OptionGRP311moonbitlang5async9js__async11AbortSignalE4None__);
}
(() => {
  _M0FPB7printlnGsE("Hello");
})();
export { _M0FP511emadurandal17WebGPU_2dexamples16basic_2dtriangle2js4main24create__webgpu__renderer as create_webgpu_renderer }
//# sourceMappingURL=main.js.map
