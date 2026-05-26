// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs/promises";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(new URL("../package.json", import.meta.url)));
const distDir = path.join(root, "dist");
const verbose = process.env.RHODONITE_BROWSER_VERBOSE === "1" ||
	process.env.RHODONITE_BROWSER_INTERACTION_VERBOSE === "1";
const headless = process.env.RHODONITE_BROWSER_HEADLESS !== "0";

const browser = findBrowser();
if (!browser) {
	console.log("interaction_regression(browser): SKIP Chrome/Chromium browser not found");
	process.exit(0);
}

let browserProcess;
let resultServer;
let distServer;

let resolveResult;
let rejectResult;
const resultPromise = new Promise((resolve, reject) => {
	resolveResult = resolve;
	rejectResult = reject;
});

resultServer = http.createServer((req, res) => {
	res.setHeader("access-control-allow-origin", "*");
	res.setHeader("access-control-allow-headers", "content-type");
	res.setHeader("access-control-allow-methods", "POST, OPTIONS");
	if (req.method === "OPTIONS") {
		res.statusCode = 204;
		res.end();
		return;
	}
	if (req.method !== "POST") {
		res.statusCode = 405;
		res.end("method not allowed");
		return;
	}
	let body = "";
	req.setEncoding("utf8");
	req.on("data", (chunk) => {
		body += chunk;
	});
	req.on("end", () => {
		try {
			const message = JSON.parse(body);
			if (message?.type === "status") {
				if (verbose) {
					console.log(`interaction_regression(browser): ${message.message}`);
				}
				res.statusCode = 204;
				res.end();
				return;
			}
			resolveResult(message);
			res.statusCode = 204;
			res.end();
		} catch (error) {
			rejectResult(error);
			res.statusCode = 400;
			res.end("invalid json");
		}
	});
	req.on("error", rejectResult);
});

try {
	await assertDistExists();
	await listen(resultServer);
	const resultAddress = resultServer.address();
	const resultPort = typeof resultAddress === "object" && resultAddress
		? resultAddress.port
		: 0;
	const resultEndpoint = `http://127.0.0.1:${resultPort}/`;
	distServer = createDistServer(resultEndpoint);
	await listen(distServer);
	const distAddress = distServer.address();
	const distPort = typeof distAddress === "object" && distAddress ? distAddress.port : 0;
	const url = `http://127.0.0.1:${distPort}/__rhodonite_interaction_regression__.html?result=${encodeURIComponent(resultEndpoint)}`;
	if (verbose) {
		console.log(`interaction_regression(browser): launching ${browser}`);
		console.log(`interaction_regression(browser): opening ${url}`);
	}
	const userDataDir = await fs.mkdtemp(
		path.join(os.tmpdir(), "rhodonite-browser-interaction-"),
	);
	let browserStdout = "";
	let browserStderr = "";
	const browserArgs = [
		"--disable-dev-shm-usage",
		"--no-sandbox",
		"--disable-background-networking",
		"--disable-component-update",
		"--disable-sync",
		"--no-proxy-server",
		"--no-first-run",
		"--no-default-browser-check",
		"--remote-debugging-port=0",
		`--user-data-dir=${userDataDir}`,
		url,
	];
	if (headless) {
		browserArgs.unshift("--headless=new");
	}
	browserProcess = spawn(browser, browserArgs, {
		stdio: ["ignore", "pipe", "pipe"],
	});
	browserProcess.stdout.on("data", (data) => {
		browserStdout = appendOutputTail(browserStdout, data);
		if (verbose) {
			process.stdout.write(data);
		}
	});
	browserProcess.stderr.on("data", (data) => {
		browserStderr = appendOutputTail(browserStderr, data);
		if (verbose) {
			process.stderr.write(data);
		}
	});
	browserProcess.on("error", rejectResult);
	browserProcess.on("exit", (code, signal) => {
		rejectResult(
			new Error(
				`browser exited before reporting results (code=${code ?? "null"} signal=${signal ?? "null"})` +
					formatBrowserDiagnostics(browserStdout, browserStderr),
			),
		);
	});

	const result = await withTimeout(
		resultPromise,
		45000,
		"browser interaction regression timed out",
	).catch((error) => {
		return {
			ok: false,
			skipped: false,
			results: [],
			failures: [
				{
					name: "browser interaction regression",
					message: formatBrowserFailure(error, browserStdout, browserStderr),
				},
			],
		};
	});
	if (result.skipped) {
		console.log(`interaction_regression(browser): SKIP ${result.reason}`);
		process.exitCode = 0;
	} else if (result.ok) {
		for (const r of result.results ?? []) {
			console.log(`interaction_regression(browser): PASS ${r.name}`);
		}
		process.exitCode = 0;
	} else {
		for (const failure of result.failures ?? []) {
			console.error(
				`interaction_regression(browser): FAIL ${failure.name}: ${failure.message}`,
			);
		}
		process.exitCode = 1;
	}
} finally {
	if (browserProcess && !browserProcess.killed) {
		browserProcess.kill("SIGTERM");
	}
	if (distServer) {
		await closeServer(distServer);
	}
	if (resultServer) {
		await closeServer(resultServer);
	}
}

async function assertDistExists() {
	try {
		await fs.access(path.join(distDir, "samples/html/ts-undo-redo-interaction.html"));
	} catch {
		throw new Error("dist samples are missing; run pnpm run build before interaction regression");
	}
}

function createDistServer(resultEndpoint) {
	return http.createServer(async (req, res) => {
		try {
			const requestUrl = new URL(req.url ?? "/", "http://127.0.0.1");
			if (requestUrl.pathname === "/__rhodonite_interaction_regression__.html") {
				res.setHeader("content-type", "text/html; charset=utf-8");
				res.end(createHarnessHtml(resultEndpoint));
				return;
			}
			let pathname = decodeURIComponent(requestUrl.pathname);
			if (pathname === "/") {
				pathname = "/samples/html/ts-undo-redo-interaction.html";
			}
			const filePath = path.normalize(path.join(distDir, pathname));
			if (!filePath.startsWith(distDir + path.sep)) {
				res.statusCode = 403;
				res.end("forbidden");
				return;
			}
			const data = await fs.readFile(filePath);
			res.setHeader("content-type", contentType(filePath));
			res.end(data);
		} catch {
			res.statusCode = 404;
			res.end("not found");
		}
	});
}

function createHarnessHtml(resultEndpoint) {
	return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>RhodoniteMBT Browser Interaction Regression</title>
    <style>
      body { margin: 0; background: #111827; color: #e5e7eb; font-family: system-ui, sans-serif; }
      iframe { width: 1000px; height: 820px; border: 0; display: block; }
    </style>
  </head>
  <body>
    <script>
      const resultEndpoint = ${JSON.stringify(resultEndpoint)};
      const results = [];
      const failures = [];

      window.addEventListener("error", (event) => {
        postResult({ ok: false, skipped: false, results, failures: [{ name: "browser harness", message: event.message }] });
      });
      window.addEventListener("unhandledrejection", (event) => {
        const reason = event.reason;
        postResult({
          ok: false,
          skipped: false,
          results,
          failures: [{ name: "browser harness", message: reason instanceof Error ? reason.message : String(reason) }],
        });
      });

      void main();

      async function main() {
        await postStatus("loaded");
        await runTest("undo redo interaction page shows controls", async () => {
          const page = await loadUndoRedoPage();
          assertStatus(page, "undo=0 redo=0");
          assertValue(page, "value=0");
          page.destroy();
        });
        for (const key of ["m", " ", "Enter"]) {
          await runTest("move shortcut " + labelForKey(key), async () => {
            const page = await loadUndoRedoPage();
            dispatchKey(page, { key });
            await waitForStatus(page, "undo=1 redo=0");
            await waitForValue(page, "value=1");
            page.destroy();
          });
          await runTest("repeat move shortcut " + labelForKey(key) + " is ignored", async () => {
            const page = await loadUndoRedoPage();
            dispatchKey(page, { key, repeat: true });
            await delay(150);
            assertStatus(page, "undo=0 redo=0");
            assertValue(page, "value=0");
            page.destroy();
          });
        }
        await runTest("move after undo resumes from restored value", async () => {
          const page = await loadUndoRedoPage();
          dispatchKey(page, { key: "m" });
          await waitForValue(page, "value=1");
          dispatchKey(page, { key: "m" });
          await waitForValue(page, "value=2");
          dispatchKey(page, { key: "z", ctrlKey: true });
          await waitForStatus(page, "undo=1 redo=1");
          await waitForValue(page, "value=1");
          dispatchKey(page, { key: "m" });
          await waitForStatus(page, "undo=2 redo=0");
          await waitForValue(page, "value=2");
          page.destroy();
        });
        for (const command of ["ctrl", "meta"]) {
          await runTest(command + "+z undoes", async () => {
            const page = await loadUndoRedoPage();
            dispatchKey(page, { key: "m" });
            await waitForStatus(page, "undo=1 redo=0");
            dispatchKey(page, commandEvent(command, { key: "z" }));
            await waitForStatus(page, "undo=0 redo=1");
            await waitForValue(page, "value=0");
            page.destroy();
          });
          await runTest(command + "+shift+z redoes", async () => {
            const page = await loadUndoRedoPage();
            await createRedoState(page);
            dispatchKey(page, commandEvent(command, { key: "z", shiftKey: true }));
            await waitForStatus(page, "undo=1 redo=0");
            await waitForValue(page, "value=1");
            page.destroy();
          });
          await runTest(command + "+y redoes", async () => {
            const page = await loadUndoRedoPage();
            await createRedoState(page);
            dispatchKey(page, commandEvent(command, { key: "y" }));
            await waitForStatus(page, "undo=1 redo=0");
            await waitForValue(page, "value=1");
            page.destroy();
          });
          await runTest("repeat " + command + "+z is ignored", async () => {
            const page = await loadUndoRedoPage();
            dispatchKey(page, { key: "m" });
            await waitForStatus(page, "undo=1 redo=0");
            dispatchKey(page, commandEvent(command, { key: "z", repeat: true }));
            await delay(150);
            assertStatus(page, "undo=1 redo=0");
            assertValue(page, "value=1");
            page.destroy();
          });
          await runTest("repeat " + command + "+y is ignored", async () => {
            const page = await loadUndoRedoPage();
            await createRedoState(page);
            dispatchKey(page, commandEvent(command, { key: "y", repeat: true }));
            await delay(150);
            assertStatus(page, "undo=0 redo=1");
            assertValue(page, "value=0");
            page.destroy();
          });
          await runTest("repeat " + command + "+shift+z is ignored", async () => {
            const page = await loadUndoRedoPage();
            await createRedoState(page);
            dispatchKey(page, commandEvent(command, { key: "z", shiftKey: true, repeat: true }));
            await delay(150);
            assertStatus(page, "undo=0 redo=1");
            assertValue(page, "value=0");
            page.destroy();
          });
        }
        for (const key of ["z", "y"]) {
          await runTest("plain " + key + " is ignored", async () => {
            const page = await loadUndoRedoPage();
            dispatchKey(page, { key });
            await delay(150);
            assertStatus(page, "undo=0 redo=0");
            assertValue(page, "value=0");
            page.destroy();
          });
        }
        await postResult({
          ok: failures.length === 0,
          skipped: false,
          results,
          failures,
        });
      }

      async function runTest(name, body) {
        try {
          await postStatus("running " + name);
          await body();
          results.push({ name });
        } catch (error) {
          failures.push({ name, message: error instanceof Error ? error.message : String(error) });
        }
      }

      async function loadUndoRedoPage() {
        const page = await loadPage("/samples/html/ts-undo-redo-interaction.html");
        await waitFor(() => page.doc.querySelector(".sample-status"), 10000, "undo/redo controls did not appear");
        return page;
      }

      function loadPage(path) {
        return new Promise((resolve, reject) => {
          const frame = document.createElement("iframe");
          const timer = window.setTimeout(() => reject(new Error(path + " load timed out")), 10000);
          frame.addEventListener("load", () => {
            window.clearTimeout(timer);
            resolve({
              frame,
              win: frame.contentWindow,
              doc: frame.contentDocument,
              destroy: () => frame.remove(),
            });
          }, { once: true });
          frame.src = path;
          document.body.append(frame);
        });
      }

      async function createRedoState(page) {
        dispatchKey(page, { key: "m" });
        await waitForStatus(page, "undo=1 redo=0");
        await waitForValue(page, "value=1");
        dispatchKey(page, { key: "z", ctrlKey: true });
        await waitForStatus(page, "undo=0 redo=1");
        await waitForValue(page, "value=0");
      }

      function dispatchKey(page, options) {
        const event = new KeyboardEvent("keydown", {
          key: options.key,
          ctrlKey: options.ctrlKey ?? false,
          metaKey: options.metaKey ?? false,
          shiftKey: options.shiftKey ?? false,
          repeat: options.repeat ?? false,
          bubbles: true,
          cancelable: true,
        });
        page.win.dispatchEvent(event);
      }

      function commandEvent(command, options) {
        return {
          ...options,
          ctrlKey: command === "ctrl",
          metaKey: command === "meta",
        };
      }

      async function waitForStatus(page, expected) {
        await waitFor(() => statusText(page) === expected, 2000, "expected status " + expected + ", got " + statusText(page));
      }

      async function waitForValue(page, expected) {
        await waitFor(() => valueText(page) === expected, 2000, "expected value " + expected + ", got " + valueText(page));
      }

      function assertStatus(page, expected) {
        assert(statusText(page) === expected, "expected status " + expected + ", got " + statusText(page));
      }

      function assertValue(page, expected) {
        assert(valueText(page) === expected, "expected value " + expected + ", got " + valueText(page));
      }

      function statusText(page) {
        return page.doc.querySelector(".sample-status")?.textContent?.trim() ?? "";
      }

      function valueText(page) {
        return page.doc.querySelector(".sample-value")?.textContent?.trim() ?? "";
      }

      function labelForKey(key) {
        if (key === " ") {
          return "space";
        }
        return key.toLowerCase();
      }

      async function waitFor(predicate, ms, message) {
        const deadline = performance.now() + ms;
        while (performance.now() < deadline) {
          if (predicate()) {
            return;
          }
          await delay(25);
        }
        throw new Error(message);
      }

      function delay(ms) {
        return new Promise((resolve) => window.setTimeout(resolve, ms));
      }

      function assert(condition, message) {
        if (!condition) {
          throw new Error(message);
        }
      }

      async function postResult(body) {
        await fetch(resultEndpoint, {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ type: "result", ...body }),
        });
      }

      async function postStatus(message) {
        await fetch(resultEndpoint, {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ type: "status", message }),
        });
      }
    </script>
  </body>
</html>`;
}

function contentType(filePath) {
	const ext = path.extname(filePath).toLowerCase();
	switch (ext) {
		case ".html":
			return "text/html; charset=utf-8";
		case ".js":
			return "application/javascript; charset=utf-8";
		case ".css":
			return "text/css; charset=utf-8";
		case ".wasm":
			return "application/wasm";
		case ".svg":
			return "image/svg+xml";
		default:
			return "application/octet-stream";
	}
}

function findBrowser() {
	const fromEnv = process.env.RHODONITE_BROWSER || process.env.CHROME;
	if (fromEnv && isExecutable(fromEnv)) {
		return fromEnv;
	}
	const macCandidates = [
		"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
		"/Applications/Chromium.app/Contents/MacOS/Chromium",
		"/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
	];
	for (const candidate of macCandidates) {
		if (isExecutable(candidate)) {
			return candidate;
		}
	}
	for (const name of [
		"google-chrome",
		"google-chrome-stable",
		"chromium",
		"chromium-browser",
		"microsoft-edge",
	]) {
		const found = which(name);
		if (found) {
			return found;
		}
	}
	return undefined;
}

function isExecutable(candidate) {
	return spawnSync(candidate, ["--version"], { stdio: "ignore" }).status === 0;
}

function which(name) {
	const result = spawnSync("which", [name], { encoding: "utf8" });
	if (result.status !== 0) {
		return undefined;
	}
	return result.stdout.trim() || undefined;
}

function withTimeout(promise, ms, message) {
	let timer;
	const timeout = new Promise((_, reject) => {
		timer = setTimeout(() => reject(new Error(message)), ms);
	});
	return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

function appendOutputTail(existing, data) {
	const next = existing + data.toString();
	return next.length > 8000 ? next.slice(next.length - 8000) : next;
}

function formatBrowserDiagnostics(stdout, stderr) {
	const parts = [];
	if (stderr.trim()) {
		parts.push(`browser stderr:\n${stderr.trim()}`);
	}
	if (stdout.trim()) {
		parts.push(`browser stdout:\n${stdout.trim()}`);
	}
	return parts.length === 0 ? "" : `\n${parts.join("\n")}`;
}

function formatBrowserFailure(error, stdout, stderr) {
	const message = error instanceof Error ? error.message : String(error);
	if (message.includes("browser stderr:") || message.includes("browser stdout:")) {
		return message;
	}
	return message + formatBrowserDiagnostics(stdout, stderr);
}

function listen(server) {
	return new Promise((resolve, reject) => {
		server.once("error", reject);
		server.listen(0, "127.0.0.1", () => {
			server.off("error", reject);
			resolve();
		});
	});
}

function closeServer(server) {
	return new Promise((resolve, reject) => {
		server.close((error) => {
			if (error?.code === "ERR_SERVER_NOT_RUNNING") {
				resolve();
			} else if (error) {
				reject(error);
			} else {
				resolve();
			}
		});
	});
}
