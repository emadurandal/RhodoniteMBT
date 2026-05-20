/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `renderPipeline_release`.
pub fn renderPipeline_release(pipeline : GPURenderPipeline) -> Unit {
  pipeline.raw.release()
}
