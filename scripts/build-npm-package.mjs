// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import {
  cpSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import path from "node:path";
import ts from "typescript";
import { fileURLToPath } from "node:url";

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const packageRoot = path.join(root, "packages/rhodonite-mbt");
const buildSrc = path.join(packageRoot, ".build-src");
const dist = path.join(packageRoot, "dist");

const sources = {
  math: path.join(root, "moon/rhodonite_core/src/math/ts"),
  ecs: path.join(root, "moon/rhodonite_core/src/ecs/ts"),
  app: path.join(root, "moon/rhodonite/src/app/ts"),
};

const bridgeSources = {
  math: {
    build: path.join(
      root,
      "_build/js/release/build/emadurandal/rhodonite_core/math/js_bridge",
    ),
    types: path.join(sources.math, "math-bridge.d.ts"),
  },
  ecs: {
    build: path.join(
      root,
      "_build/js/release/build/emadurandal/rhodonite_core/ecs/js_bridge",
    ),
    types: [
      path.join(sources.ecs, "ecs-bridge.d.ts"),
      path.join(sources.ecs, "ecs-bridge-history.d.ts"),
    ],
  },
};

function ensureMoonBridgeBuilt(kind) {
  const bridgeFile = path.join(bridgeSources[kind].build, "js_bridge.js");
  if (!existsSync(bridgeFile)) {
    throw new Error(
      `Missing ${kind} MoonBit JS bridge at ${bridgeFile}. Run pnpm run build:core:js first.`,
    );
  }
}

function copyWrapperSource(kind) {
  cpSync(sources[kind], path.join(buildSrc, kind), {
    recursive: true,
    filter: (source) =>
      !source.endsWith(".test.ts") &&
      !path.basename(source).includes("-bridge") &&
      !source.split(path.sep).includes("test-support"),
  });
}

function rewriteTsFile(filePath) {
  let text = readFileSync(filePath, "utf8");
  text = text.replaceAll(
    '"@moon/rhodonite_core/math/js_bridge"',
    '"../internal/math/js_bridge.js"',
  );
  text = text.replaceAll(
    '"@moon/rhodonite_core/ecs/js_bridge"',
    '"../internal/ecs/js_bridge.js"',
  );
  text = text.replaceAll(
    '"../../../../rhodonite_core/src/ecs/ts/index.ts"',
    '"../ecs/index.ts"',
  );
  text = text.replaceAll(/(from\s+["'][^"']+)\.ts(["'])/g, "$1.js$2");
  text = text.replaceAll(/(export\s+[^"']*from\s+["'][^"']+)\.ts(["'])/g, "$1.js$2");
  writeFileSync(filePath, text);
}

function rewriteCopiedSources(dir) {
  const entries = cpList(dir);
  for (const file of entries) {
    if (file.endsWith(".ts")) {
      rewriteTsFile(file);
    }
  }
}

function cpList(dir) {
  const result = [];
  const stack = [dir];
  while (stack.length > 0) {
    const current = stack.pop();
    for (const entry of readdirSync(current)) {
      const fullPath = path.join(current, entry);
      if (statSync(fullPath).isDirectory()) {
        stack.push(fullPath);
      } else {
        result.push(fullPath);
      }
    }
  }
  return result;
}

function extractAmbientModuleBody(filePath) {
  const text = readFileSync(filePath, "utf8");
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end < 0 || end <= start) {
    throw new Error(`Unable to extract ambient module body from ${filePath}`);
  }
  return text
    .slice(start + 1, end)
    .split("\n")
    .map((line) => (line.startsWith("\t") ? line.slice(1) : line))
    .join("\n")
    .trimStart();
}

function extractAmbientModuleBodies(filePaths) {
  const paths = Array.isArray(filePaths) ? filePaths : [filePaths];
  return paths.map((filePath) => extractAmbientModuleBody(filePath)).join("\n");
}

function writeInternalBridgeTypes(kind) {
  const outDir = path.join(buildSrc, "internal", kind);
  mkdirSync(outDir, { recursive: true });
  writeFileSync(
    path.join(outDir, "js_bridge.d.ts"),
    extractAmbientModuleBodies(bridgeSources[kind].types),
  );
}

function copyBuiltBridge(kind) {
  const sourceDir = bridgeSources[kind].build;
  const targetDir = path.join(dist, "internal", kind);
  mkdirSync(targetDir, { recursive: true });
  for (const file of ["js_bridge.js", "js_bridge.js.map", "moonbit.d.ts"]) {
    const sourceFile = path.join(sourceDir, file);
    if (existsSync(sourceFile)) {
      cpSync(sourceFile, path.join(targetDir, file));
    }
  }
  cpSync(
    path.join(buildSrc, "internal", kind, "js_bridge.d.ts"),
    path.join(targetDir, "js_bridge.d.ts"),
  );
}

function writeEntrypoints() {
  writeFileSync(
    path.join(buildSrc, "index.ts"),
    [
      'export * from "./math/index.js";',
      'export * from "./ecs/global-transform-blob.js";',
      'export * from "./ecs/camera-control.js";',
      'export * from "./ecs/history-archive.js";',
      'export * from "./ecs/history-ui-state.js";',
      'export * from "./ecs/query.js";',
      'export { CommandBuffer, System, SystemContext, SystemPhasePlan, SystemPlanBatch, SystemPlanSystem, SystemRunner, createTransformPropagationSystem } from "./ecs/system.js";',
      'export type { SystemCallback } from "./ecs/system.js";',
      'export { PhaseKey as EcsPhaseKey } from "./ecs/system.js";',
      'export * from "./ecs/types.js";',
      'export * from "./ecs/views.js";',
      'export * from "./ecs/world.js";',
      'export * from "./ecs/wgsl.js";',
      'export * from "./app/index.js";',
      "",
    ].join("\n"),
  );
  writeFileSync(
    path.join(buildSrc, "math/index.ts"),
    [
      'export * from "./matrix33.js";',
      'export * from "./matrix44.js";',
      'export * from "./vector3.js";',
      'export * from "./vector4.js";',
      "",
    ].join("\n"),
  );
}

function runTsc() {
  const configPath = path.join(packageRoot, "tsconfig.build.json");
  const configFile = ts.readConfigFile(configPath, ts.sys.readFile);
  if (configFile.error) {
    reportTsDiagnostics([configFile.error]);
    throw new Error("TypeScript npm package build failed.");
  }
  const parsed = ts.parseJsonConfigFileContent(
    configFile.config,
    ts.sys,
    packageRoot,
    undefined,
    configPath,
  );
  if (parsed.errors.length > 0) {
    reportTsDiagnostics(parsed.errors);
    throw new Error("TypeScript npm package build failed.");
  }
  const program = ts.createProgram(parsed.fileNames, parsed.options);
  const emitResult = program.emit();
  const diagnostics = ts.getPreEmitDiagnostics(program).concat(emitResult.diagnostics);
  if (diagnostics.length > 0) {
    reportTsDiagnostics(diagnostics);
  }
  if (
    emitResult.emitSkipped ||
    diagnostics.some((diagnostic) => diagnostic.category === ts.DiagnosticCategory.Error)
  ) {
    throw new Error("TypeScript npm package build failed.");
  }
}

function reportTsDiagnostics(diagnostics) {
  const host = {
    getCanonicalFileName: (fileName) => fileName,
    getCurrentDirectory: () => root,
    getNewLine: () => "\n",
  };
  process.stderr.write(ts.formatDiagnosticsWithColorAndContext(diagnostics, host));
}

function prependWebGpuTypeReferences() {
  for (const declarationFile of [
    path.join(dist, "index.d.ts"),
    path.join(dist, "app/index.d.ts"),
  ]) {
    if (!existsSync(declarationFile)) {
      continue;
    }
    const text = readFileSync(declarationFile, "utf8");
    if (!text.includes('@webgpu/types')) {
      writeFileSync(
        declarationFile,
        `/// <reference types="@webgpu/types" />\n${text}`,
      );
    }
  }
}

for (const kind of ["math", "ecs"]) {
  ensureMoonBridgeBuilt(kind);
}

rmSync(buildSrc, { recursive: true, force: true });
rmSync(dist, { recursive: true, force: true });
mkdirSync(buildSrc, { recursive: true });

for (const kind of ["math", "ecs", "app"]) {
  copyWrapperSource(kind);
  rewriteCopiedSources(path.join(buildSrc, kind));
}
for (const kind of ["math", "ecs"]) {
  writeInternalBridgeTypes(kind);
}
writeEntrypoints();

runTsc();
prependWebGpuTypeReferences();

for (const kind of ["math", "ecs"]) {
  copyBuiltBridge(kind);
}
