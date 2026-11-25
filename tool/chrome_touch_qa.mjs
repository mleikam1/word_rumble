// Run against a local build of tool/browser_qa.dart with Chrome remote debugging.
// The bridge exposes observations only. Every player action is a browser touch.
import assert from "node:assert/strict";
import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";

const [
  url = "http://127.0.0.1:19449",
  port = "19448",
  captureDir,
  widthArg = "390",
  heightArg = "844",
  scope = "chapter",
] = process.argv.slice(2);
const width = Number(widthArg),
  height = Number(heightArg);
const cdp = "http://127.0.0.1:" + port;
const tab = await (
  await fetch(cdp + "/json/new?about:blank", { method: "PUT" })
).json();
const ws = new WebSocket(tab.webSocketDebuggerUrl);
await new Promise((resolve) =>
  ws.addEventListener("open", resolve, { once: true }),
);
let sequence = 0;
const pending = new Map();
ws.addEventListener("message", ({ data }) => {
  const m = JSON.parse(data);
  const q = pending.get(m.id);
  if (q) {
    pending.delete(m.id);
    if (m.error) q.reject(Error(m.error.message));
    else q.resolve(m.result);
  } else if (m.method === "Runtime.exceptionThrown") {
    console.error(m.params.exceptionDetails);
  }
});
function send(method, params = {}) {
  const id = ++sequence;
  const promise = new Promise((resolve, reject) =>
    pending.set(id, { resolve, reject }),
  );
  ws.send(JSON.stringify({ id, method, params }));
  return promise;
}
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function read() {
  const { result } = await send("Runtime.evaluate", {
    expression: 'typeof readBoard === "function" ? readBoard() : "{}"',
    returnByValue: true,
  });
  return JSON.parse(result.value || "{}");
}
async function until(check, reason, timeout = 7000) {
  const stop = Date.now() + timeout;
  let b;
  do {
    b = await read();
    if (check(b)) return b;
    await sleep(22);
  } while (Date.now() < stop);
  throw Error(reason + " " + JSON.stringify(b));
}
async function touch(type, x, y) {
  await send("Input.dispatchTouchEvent", {
    type,
    touchPoints:
      x == null ? [] : [{ x, y, id: 1, radiusX: 4, radiusY: 4, force: 0.7 }],
  });
}
async function press(key) {
  let b = await until((b) => b[key], key);
  for (let n = 0; n < 5; n++) {
    const [x, y, w, h] = b[key];
    if (y + h / 2 < height - 12 && y + h / 2 > 10) {
      await touch("touchStart", x + w / 2, y + h / 2);
      await sleep(45);
      await touch("touchEnd");
      await sleep(400);
      return;
    }
    await send("Input.dispatchMouseEvent", {
      type: "mouseWheel",
      x: width / 2,
      y: height * 0.65,
      deltaX: 0,
      deltaY: y > 0 ? 300 : -300,
    });
    await sleep(220);
    b = await read();
  }
  throw Error("Control outside viewport: " + key);
}
async function aim(tile, target) {
  await touch("touchStart", tile.x, tile.y);
  await sleep(25);
  for (const t of [0.23, 0.54, 0.82, 1]) {
    await touch(
      "touchMove",
      tile.x + (target.x - tile.x) * t,
      tile.y + (target.y - tile.y) * t,
    );
    await sleep(17);
  }
}
async function shot(name) {
  if (!captureDir) return;
  await mkdir(captureDir, { recursive: true });
  const image = await send("Page.captureScreenshot", { format: "png" });
  await writeFile(
    join(captureDir, name + ".png"),
    Buffer.from(image.data, "base64"),
  );
}
async function land(index, picture, awaitHazard = false) {
  let b = await read();
  const letter = b.word[index];
  const tile = b.tiles.find((t) => !t.latched && t.letter === letter);
  const slot = b.slots[index];
  await aim(tile, slot);
  if (awaitHazard) {
    const blocked = await until(
      (b) => b.cue === "hazard",
      "expected a blocked landing",
      15000,
    );
    assert.equal(blocked.slots[index].letter, null);
    console.log(b.word + " hold: " + blocked.hazard);
    await sleep(150);
    if (b.word === "FIRE") await shot("06-lava-vent");
    if (b.word === "STORM") await shot("07-storm-gust");
  }
  for (let n = 0; n < 100; n++) {
    b = await read();
    if (b.cue === "aligned") break;
    if (b.cue !== "fast" && b.cue !== "hazard") {
      const dest = b.slots[index];
      await touch("touchMove", dest.x, dest.y + tile.width * 0.1);
    }
    await sleep(25);
  }
  assert.equal(b.cue, "aligned", JSON.stringify(b));
  assert.equal(b.slots[index].letter, null, "Holding crossed a berth");
  if (picture) {
    await sleep(160);
    await shot("02-aligned");
  }
  await touch("touchEnd");
  const released = await read();
  // The recorder may be preempted after up. A pending berth never owns a tile.
  if (released.status === "Settling…")
    assert.equal(released.slots[index].letter, null);
  b = await until(
    (b) => b.slots?.[index].letter === letter,
    "missing latch " + letter,
  );
  if (picture) await shot("03-recovered-latch");
  return b;
}
try {
  await send("Page.enable");
  await send("Runtime.enable");
  await send("Network.enable");
  await send("Network.setBypassServiceWorker", { bypass: true });
  await send("Network.setCacheDisabled", { cacheDisabled: true });
  await send("Storage.clearDataForOrigin", {
    origin: new URL(url).origin,
    storageTypes: "all",
  });
  await send("Emulation.setDeviceMetricsOverride", {
    width,
    height,
    screenWidth: width,
    screenHeight: height,
    deviceScaleFactor: 1,
    mobile: width < 800,
  });
  await send("Emulation.setTouchEmulationEnabled", {
    enabled: true,
    maxTouchPoints: 5,
  });
  await send("Page.navigate", { url });
  await until((b) => b["campaign-play"], "home", 30000);
  await press("campaign-play");
  await press("campaign-start");
  let b = await until((b) => b.word === "WATER" && b.ready, "WATER");
  const bounds = b["arena-surface"];
  const tile = b.tiles.find((t) => t.letter === "W");
  const slot = b.slots[0];
  await aim(tile, { x: slot.x, y: slot.y - slot.width * 0.64 });
  await until((b) => b.cue === "edge", "edge cue");
  await touch("touchEnd");
  b = await until((b) => b.misses === 1, "edge miss");
  assert.equal(b.slots[0].letter, null);
  await shot("01-edge-miss");
  const recoveryStart = Date.now();
  await land(0, Boolean(captureDir));
  const recoveryMs = Date.now() - recoveryStart;
  for (let i = 1; i < 5; i++) b = await land(i);
  assert.equal(b.won, true);
  assert.deepEqual(b["arena-surface"], bounds);
  console.log(
    JSON.stringify({
      width,
      height,
      word: b.word,
      misses: b.misses,
      secondsLeft: b.time,
      recoveryMs,
      bounds,
    }),
  );
  await sleep(320);
  await shot("04-water-clear");
  await press("campaign-next");
  b = await until((b) => b.word && b.word !== "WATER" && b.ready, "Next");
  console.log("Next " + b.word + " | " + b.hazard);
  await shot("05-next-round");
  if (scope === "chapter") {
    for (const word of ["SHIP", "BUOY", "FIRE", "EMBER", "GUST", "STORM"]) {
      b = await until((b) => b.word === word && b.ready, "chapter " + word);
      for (let i = 0; i < word.length; i++) {
        const awaitHazard =
          (i === 0 && ["SHIP", "FIRE", "STORM"].includes(word)) ||
          (i === 1 && word === "STORM");
        b = await land(i, false, awaitHazard);
      }
      assert.equal(b.won, true);
      console.log(
        JSON.stringify({ word, secondsLeft: b.time, misses: b.misses }),
      );
      if (word !== "STORM") await press("campaign-next");
    }
  }
} finally {
  ws.close();
  await fetch(cdp + "/json/close/" + tab.id);
}
