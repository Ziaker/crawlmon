'use strict';

var assert = require('assert');
var P = require('./parts.js');

function whichKept(parts, p) {
  var out = [];
  for (var i = 0; i < parts.length; i++) {
    if (P.keeps(parts[i].planes, p)) out.push(i);
  }
  return out;
}

// --- wedges ---
var w = P.wedges(4);
assert.strictEqual(w.length, 4);
assert.strictEqual(w[0].mid, 45);
assert.strictEqual(w[1].mid, 135);
assert.strictEqual(w[2].mid, 225);
assert.strictEqual(w[3].mid, 315);

var ang = 45 * Math.PI / 180;
var p45 = [0.3 * Math.cos(ang), 0.3 * Math.sin(ang), 0];
assert.deepStrictEqual(whichKept(w, p45), [0]);

var w2 = P.wedges(2);
assert.strictEqual(w2.length, 2);
assert.strictEqual(w2[0].planes.length, 1);
assert.strictEqual(w2[1].planes.length, 1);
assert.strictEqual(P.keeps(w2[0].planes, [0, 0.3, 0]), true);
assert.strictEqual(P.keeps(w2[1].planes, [0, 0.3, 0]), false);

// --- slabs ---
var s = P.slabs(3, 'x');
assert.strictEqual(s.length, 3);
assert.strictEqual(s[0].axis, 'x');
assert.deepStrictEqual(whichKept(s, [-0.4, 0, 0]), [0]);
assert.deepStrictEqual(whichKept(s, [0, 0, 0]), [1]);
assert.deepStrictEqual(whichKept(s, [0.4, 0, 0]), [2]);

// --- offset: radial ---
var wr = P.wedges(4, 45);
assert.strictEqual(wr[0].mid, 90);
var orad = P.offset(wr[0], { separation: 0.2, shiftH: 0, shiftV: 0, stagger: 'none' }, wr.length);
assert.ok(Math.abs(orad[0]) < 1e-9);
assert.ok(Math.abs(orad[1] - 0.2) < 1e-12);
assert.strictEqual(orad[2], 0);

// --- offset: slab axis ---
var osMid = P.offset(s[1], { separation: 0.5, shiftH: 0, shiftV: 0, stagger: 'none' }, s.length);
assert.deepStrictEqual(osMid, [0, 0, 0]);
var osLast = P.offset(s[2], { separation: 0.2, shiftH: 0, shiftV: 0, stagger: 'none' }, s.length);
assert.ok(Math.abs(osLast[0] - 0.2) < 1e-12);

// --- offset: stagger ---
var oAlt = P.offset(s[1], { separation: 0, shiftH: 0.1, shiftV: 0.2, stagger: 'alternate' }, s.length);
assert.ok(Math.abs(oAlt[0] - (-0.1)) < 1e-12);
assert.ok(Math.abs(oAlt[1] - (-0.2)) < 1e-12);

var oProgFirst = P.offset(s[0], { separation: 0, shiftH: 0.1, shiftV: 0.2, stagger: 'progressive' }, s.length);
assert.ok(Math.abs(oProgFirst[0] - (-0.1)) < 1e-12);
assert.ok(Math.abs(oProgFirst[1] - (-0.2)) < 1e-12);

var oProgLast = P.offset(s[2], { separation: 0, shiftH: 0.1, shiftV: 0.2, stagger: 'progressive' }, s.length);
assert.ok(Math.abs(oProgLast[0] - 0.1) < 1e-12);
assert.ok(Math.abs(oProgLast[1] - 0.2) < 1e-12);

var oNone = P.offset(s[0], { separation: 0, shiftH: 0.1, shiftV: -0.1, stagger: 'none' }, s.length);
assert.ok(Math.abs(oNone[0] - 0.1) < 1e-12);
assert.ok(Math.abs(oNone[1] - (-0.1)) < 1e-12);

// --- lerpParams ---
var A = { separation: 0, shiftH: 0, shiftV: 0, stagger: 'alternate' };
var B = { separation: 0.4, shiftH: 1, shiftV: -1, stagger: 'progressive' };
var L0 = P.lerpParams(A, B, 0);
assert.strictEqual(L0.separation, 0);
assert.strictEqual(L0.shiftH, 0);
assert.strictEqual(L0.shiftV, 0);
assert.strictEqual(L0.stagger, 'alternate');
var L1 = P.lerpParams(A, B, 1);
assert.strictEqual(L1.separation, 0.4);
assert.strictEqual(L1.shiftH, 1);
assert.strictEqual(L1.shiftV, -1);
assert.strictEqual(L1.stagger, 'progressive');
var Lh = P.lerpParams(A, B, 0.5);
assert.ok(Math.abs(Lh.separation - 0.2) < 1e-12);
assert.ok(Math.abs(Lh.shiftH - 0.5) < 1e-12);
assert.ok(Math.abs(Lh.shiftV - (-0.5)) < 1e-12);
assert.strictEqual(Lh.stagger, 'progressive');

console.log('ok');
