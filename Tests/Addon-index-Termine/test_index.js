/* Fokussierter DOM-Mock für die echte index.js, kein Browserersatz. */
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const source = fs.readFileSync("Addon/src/heizkalender/www/index.js", "utf8");

class Element {
  constructor(attrs = {}) {
    this.attrs = { ...attrs }; this.listeners = {}; this.open = true;
    this.checked = true; this.indeterminate = false;
  }
  getAttribute(name) { return this.attrs[name] ?? null; }
  setAttribute(name, value) { this.attrs[name] = value; }
  removeAttribute(name) { delete this.attrs[name]; }
  addEventListener(name, callback) { (this.listeners[name] ||= []).push(callback); }
  emit(name) { for (const callback of this.listeners[name] || []) callback(); }
}

function page({ count = 2, inputMissing = false, tableMissing = false, loading = false } = {}) {
  const details = Array.from({ length: count }, () => new Element());
  const foreign = new Element();
  foreign.open = false;
  const box = new Element({ type: "checkbox", checked: "" });
  const control = new Element({ hidden: "" });
  const table = { querySelectorAll(selector) {
    assert.equal(selector, "details.hk-termin-details");
    return details;
  } };
  const elements = { "hk-termine-toggle": inputMissing ? null : box,
    "hk-termine-tabelle": tableMissing ? null : table, "hk-termine-control": control };
  const document = new Element();
  document.readyState = loading ? "loading" : "complete";
  document.getElementById = id => elements[id] || null;
  vm.runInNewContext(source, { document }, { filename: "index.js" });
  return { details, foreign, box, control, document };
}

function change(box) {
  // Native Aktivierung wird nur durch diesen expliziten Zustandswechsel modelliert.
  box.checked = !box.checked;
  box.indeterminate = false;
  box.emit("change");
}

function state(box, checked, indeterminate) {
  assert.equal(box.checked, checked);
  assert.equal(box.indeterminate, indeterminate);
}

for (const loading of [false, true]) {
  const p = page({ loading });
  if (loading) {
    assert.ok("hidden" in p.control.attrs);
    p.document.emit("DOMContentLoaded");
  }
  assert.ok(!("hidden" in p.control.attrs));
  assert.ok(p.details.every(d => d.open));
  state(p.box, true, false);
  change(p.box);
  assert.ok(p.details.every(d => !d.open));
  state(p.box, false, false);
  change(p.box);
  assert.ok(p.details.every(d => d.open));
  state(p.box, true, false);
  p.details[0].open = false;
  p.details[0].emit("toggle");
  state(p.box, false, true);
  change(p.box);
  assert.ok(p.details.every(d => d.open));
  state(p.box, true, false);
  p.details[1].open = false;
  p.details[1].emit("toggle");
  state(p.box, false, true);
  p.details[1].open = true;
  p.details[1].emit("toggle");
  state(p.box, true, false);
  for (const detail of p.details) {
    detail.open = false;
    detail.emit("toggle");
  }
  state(p.box, false, false);
  p.details[0].open = true;
  p.details[0].emit("toggle");
  state(p.box, false, true);
  change(p.box);
  assert.ok(p.details.every(d => d.open));
  state(p.box, true, false);
  assert.equal(p.foreign.open, false);
  assert.deepEqual(p.foreign.listeners, {});
  change(p.box);
  const fresh = page();
  assert.ok(fresh.details.every(d => d.open));
  state(fresh.box, true, false);
}
for (const options of [{ inputMissing: true }, { tableMissing: true }, { count: 0 }]) {
  const p = page(options);
  assert.ok("hidden" in p.control.attrs);
  assert.deepEqual(p.box.listeners, {});
}
console.log("OK: Checkbox initial markiert, Sammel-/Einzelumschaltung, Mischzustand, fremde Details, fehlende Elemente, Neuinitialisierung");
