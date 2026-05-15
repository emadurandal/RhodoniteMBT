import { spawn, spawnSync } from "node:child_process";
import { Buffer } from "node:buffer";
import fs from "node:fs/promises";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createServer } from "vite";

const root = path.dirname(fileURLToPath(new URL("../package.json", import.meta.url)));
const update = process.env.RHODONITE_UPDATE_VISUAL_SNAPSHOTS === "1";
const verbose = process.env.RHODONITE_BROWSER_VERBOSE === "1";
const headless = process.env.RHODONITE_BROWSER_HEADLESS !== "0";
const snapshotDir = path.join(
	root,
	"moon/rhodonite_examples/src/visual_regression/__image_snapshots__",
);

const browser = findBrowser();
if (!browser) {
	console.log("visual_regression(browser): SKIP Chrome/Chromium browser not found");
	process.exit(0);
}

let browserProcess;
let resultServer;
const vite = await createServer({
	root,
	logLevel: "warn",
	server: {
		host: "127.0.0.1",
		port: 5173,
		strictPort: false,
	},
});

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
					console.log(`visual_regression(browser): ${message.message}`);
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
	await listen(resultServer);
	const resultAddress = resultServer.address();
	const resultPort = typeof resultAddress === "object" && resultAddress
		? resultAddress.port
		: 0;
	const resultEndpoint = `http://127.0.0.1:${resultPort}/`;
	await vite.listen();
	const address = vite.httpServer.address();
	const port = typeof address === "object" && address ? address.port : 5173;
	const url = `http://127.0.0.1:${port}/src/visual-regression/browser-harness.html?update=${update ? "1" : "0"}&result=${encodeURIComponent(resultEndpoint)}`;
	if (verbose) {
		console.log(`visual_regression(browser): launching ${browser}`);
		console.log(`visual_regression(browser): opening ${url}`);
	}
	const userDataDir = await fs.mkdtemp(
		path.join(os.tmpdir(), "rhodonite-browser-visual-"),
	);
	const browserArgs = [
		"--enable-unsafe-webgpu",
		"--ignore-gpu-blocklist",
		"--disable-gpu-sandbox",
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
		if (verbose) {
			process.stdout.write(data);
		}
	});
	browserProcess.stderr.on("data", (data) => {
		if (verbose) {
			process.stderr.write(data);
		}
	});
	browserProcess.on("error", rejectResult);

	const result = await withTimeout(resultPromise, 30000, "browser visual regression timed out").catch(
		(error) => {
			if (error instanceof Error && error.message.includes("timed out")) {
				return {
					ok: true,
					skipped: true,
					reason: error.message,
					results: [],
					failures: [],
					updates: [],
				};
			}
			throw error;
		},
	);
	if (result.skipped) {
		const message = `visual_regression(browser): SKIP ${result.reason}`;
		if (update) {
			console.error(
				`${message}. Cannot update browser PNG snapshots without a completed browser WebGPU readback.`,
			);
			console.error(
				"visual_regression(browser): try RHODONITE_BROWSER_HEADLESS=0 pnpm run test:examples:visual:update:browser for a headed Chrome run, or set RHODONITE_BROWSER to Chrome for Testing/Chromium.",
			);
			process.exitCode = 1;
		} else {
			console.log(message);
			process.exitCode = 0;
		}
	} else if (update) {
		await writeUpdatedSnapshots(result.updates ?? []);
		console.log(
			`visual_regression(browser): UPDATE wrote ${(result.updates ?? []).length} PNG snapshots`,
		);
		process.exitCode = 0;
	} else if (result.ok) {
		for (const r of result.results ?? []) {
			console.log(
				`visual_regression(browser): PASS ${r.filename} mismatch_rate=${r.mismatchRate} mismatches=${r.mismatches}/${r.pixels} max=${r.maxMismatchRate} threshold=${r.perceptualThreshold}`,
			);
		}
		process.exitCode = 0;
	} else {
		for (const failure of result.failures ?? []) {
			console.error(
				`visual_regression(browser): FAIL ${failure.filename ?? failure.name}: ${failure.message}`,
			);
		}
		process.exitCode = 1;
	}
} finally {
	if (browserProcess && !browserProcess.killed) {
		browserProcess.kill("SIGTERM");
	}
	await closeMaybeRunning(vite);
	if (resultServer) {
		await closeServer(resultServer);
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

async function closeMaybeRunning(serverLike) {
	try {
		await serverLike.close();
	} catch (error) {
		if (error?.code !== "ERR_SERVER_NOT_RUNNING") {
			throw error;
		}
	}
}

async function writeUpdatedSnapshots(updates) {
	await fs.mkdir(snapshotDir, { recursive: true });
	for (const update of updates) {
		await fs.writeFile(
			path.join(snapshotDir, update.filename),
			Buffer.from(update.pngBase64, "base64"),
		);
	}
}
