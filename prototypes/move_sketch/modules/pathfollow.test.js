'use strict';

var assert = require('node:assert');
var P = require('./pathfollow.js');

function near(actual, expected, tol, msg) {
  tol = tol === undefined ? 1e-9 : tol;
  assert.ok(Math.abs(actual - expected) <= tol,
    (msg || 'near') + ': expected ' + expected + ', got ' + actual);
}

function nearVec(actual, expected, tol, msg) {
  tol = tol === undefined ? 1e-9 : tol;
  assert.strictEqual(actual.length, 3, (msg || 'nearVec') + ': length');
  for (var i = 0; i < 3; i++) {
    assert.ok(Math.abs(actual[i] - expected[i]) <= tol,
      (msg || 'nearVec') + ': component ' + i + ' expected ' + expected[i] +
      ', got ' + actual[i]);
  }
}

function dist3(a, b) {
  var dx = a[0] - b[0], dy = a[1] - b[1], dz = a[2] - b[2];
  return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

function rotate(q, v) {
  var x = q[0], y = q[1], z = q[2], w = q[3];
  var tx = 2 * (y * v[2] - z * v[1]);
  var ty = 2 * (z * v[0] - x * v[2]);
  var tz = 2 * (x * v[1] - y * v[0]);
  return [
    v[0] + w * tx + (y * tz - z * ty),
    v[1] + w * ty + (z * tx - x * tz),
    v[2] + w * tz + (x * ty - y * tx)
  ];
}

var line = P.build([[0, 0, 0], [10, 0, 0]]);
near(line.length, 10, 1e-12, 'straight length');
assert.deepStrictEqual(line.cum, [0, 10], 'straight cum');
assert.strictEqual(line.pts.length, 2, 'straight pts');

var mid = P.at(line, 0.5);
nearVec(mid.pos, [5, 0, 0], 1e-9, 'straight midpoint pos');
nearVec(mid.tangent, [1, 0, 0], 1e-9, 'straight midpoint tangent');
near(mid.s, 5, 1e-12, 'straight midpoint s');

var start = P.at(line, 0);
nearVec(start.pos, [0, 0, 0], 1e-9, 'straight start pos');
nearVec(start.tangent, [1, 0, 0], 1e-9, 'straight start tangent');

var end = P.at(line, 1);
nearVec(end.pos, [10, 0, 0], 1e-9, 'straight end pos');
nearVec(end.tangent, [1, 0, 0], 1e-9, 'straight end tangent');

nearVec(P.at(line, 2).pos, [10, 0, 0], 1e-9, 'straight u > 1 clamps');
nearVec(P.at(line, -1).pos, [0, 0, 0], 1e-9, 'straight u < 0 clamps');

var dedup = P.build([[0, 0, 0], [0, 0, 0], [4, 0, 0], [4, 0, 0]]);
assert.strictEqual(dedup.pts.length, 2, 'dedupe consecutive');
near(dedup.length, 4, 1e-12, 'dedupe length');

var L = P.build([[0, 0, 0], [10, 0, 0], [10, 0, 10]]);
near(L.length, 20, 1e-12, 'L length');
assert.deepStrictEqual(L.cum, [0, 10, 20], 'L cum');

nearVec(P.at(L, 0.25).pos, [5, 0, 0], 1e-9, 'L first side pos');
nearVec(P.at(L, 0.25).tangent, [1, 0, 0], 1e-9, 'L first side tangent');

var corner = P.at(L, 0.5);
nearVec(corner.pos, [10, 0, 0], 1e-9, 'L corner pos');
assert.ok(corner.tangent[0] > 0.5 && corner.tangent[2] > 0.5,
  'L corner tangent blends both sides');

nearVec(P.at(L, 0.75).pos, [10, 0, 5], 1e-9, 'L second side pos');
nearVec(P.at(L, 0.75).tangent, [0, 0, 1], 1e-9, 'L second side tangent');

nearVec(P.at(L, 0.3).pos, [6, 0, 0], 1e-9, 'L stays on first side');
nearVec(P.at(L, 0.3).tangent, [1, 0, 0], 1e-9, 'L first side tangent mid');

nearVec(P.at(L, 0.8).pos, [10, 0, 6], 1e-9, 'L after corner pos');
nearVec(P.at(L, 0.8).tangent, [0, 0, 1], 1e-9, 'L after corner tangent');

var rs = P.resample([[0, 0, 0], [10, 0, 0]], 5);
assert.strictEqual(rs.length, 5, 'resample count');
nearVec(rs[0], [0, 0, 0], 1e-12, 'resample first endpoint');
nearVec(rs[4], [10, 0, 0], 1e-12, 'resample last endpoint');
for (var i = 0; i < 4; i++) {
  near(dist3(rs[i], rs[i + 1]), 2.5, 1e-9, 'resample equal spacing ' + i);
}

var rsL = P.resample([[0, 0, 0], [10, 0, 0], [10, 0, 10]], 5);
nearVec(rsL[0], [0, 0, 0], 1e-12, 'resample L first');
nearVec(rsL[2], [10, 0, 0], 1e-9, 'resample L corner');
nearVec(rsL[3], [10, 0, 5], 1e-9, 'resample L fourth');
nearVec(rsL[4], [10, 0, 10], 1e-12, 'resample L last');

var sm0 = [[0, 0, 0], [3, 3, 3], [9, 9, 9]];
var sm1 = P.smooth(sm0, 1);
nearVec(sm1[0], [0, 0, 0], 1e-12, 'smooth endpoint start fixed');
nearVec(sm1[2], [9, 9, 9], 1e-12, 'smooth endpoint end fixed');
nearVec(sm1[1], [4, 4, 4], 1e-12, 'smooth interior average');
nearVec(sm0[1], [3, 3, 3], 1e-12, 'smooth does not mutate input');

var multi = P.smooth([[0, 0, 0], [0, 0, 0], [3, 0, 0], [6, 0, 0], [6, 0, 0]], 2);
nearVec(multi[0], [0, 0, 0], 1e-12, 'smooth multi endpoint start');
nearVec(multi[4], [6, 0, 0], 1e-12, 'smooth multi endpoint end');
assert.strictEqual(multi.length, 5, 'smooth multi length');

var q = P.quatAlignX([0, 1, 0]);
var ql = Math.sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3]);
near(ql, 1, 1e-9, 'quatAlignX unit length');
nearVec(rotate(q, [1, 0, 0]), [0, 1, 0], 1e-9, 'quatAlignX maps +X to +Y');

var qi = P.quatAlignX([1, 0, 0]);
nearVec(rotate(qi, [1, 0, 0]), [1, 0, 0], 1e-9, 'quatAlignX +X axis');
nearVec(rotate(qi, [0, 1, 0]), [0, 1, 0], 1e-9, 'quatAlignX +X keeps +Y');

var qx = P.quatAlignX([0.6, 0, 0.8]);
nearVec(rotate(qx, [1, 0, 0]), [0.6, 0, 0.8], 1e-9, 'quatAlignX oblique tangent');

var qUp = P.quatAlignX([0, 1, 0], [0, 1, 0]);
nearVec(rotate(qUp, [1, 0, 0]), [0, 1, 0], 1e-9, 'quatAlignX parallel up fallback');

nearVec(P.eulerFromQuat([0, 0, 0, 1]), [0, 0, 0], 1e-9, 'euler identity');

var s45 = Math.sin(Math.PI / 4);
var c45 = Math.cos(Math.PI / 4);
nearVec(P.eulerFromQuat([0, s45, 0, c45]), [0, 90, 0], 1e-6, 'euler +90 about Y');

var tr = P.trail(line, 0.5, { count: 6, lagU: 0.04 });
assert.strictEqual(tr.length, 6, 'trail count');
assert.strictEqual(tr[0].i, 0, 'trail head index');
near(tr[0].u, 0.5, 1e-12, 'trail head u');
nearVec(tr[0].pos, [5, 0, 0], 1e-9, 'trail head pos');
nearVec(tr[0].tangent, [1, 0, 0], 1e-9, 'trail head tangent');
near(tr[0].alpha, 1, 1e-12, 'trail head alpha');
near(tr[1].u, 0.46, 1e-12, 'trail second u');
near(tr[1].alpha, 1 - 1 / 6, 1e-12, 'trail second alpha');
near(tr[5].u, 0.3, 1e-12, 'trail tail u');
near(tr[5].alpha, 1 - 5 / 6, 1e-12, 'trail tail alpha');
nearVec(tr[5].pos, [3, 0, 0], 1e-9, 'trail tail pos');

var trClamp = P.trail(line, 0.05, { count: 4, lagU: 0.05 });
near(trClamp[0].u, 0.05, 1e-12, 'trail clamp head');
near(trClamp[1].u, 0, 1e-12, 'trail clamp second');
near(trClamp[3].u, 0, 1e-12, 'trail clamp fourth');
nearVec(trClamp[3].pos, [0, 0, 0], 1e-9, 'trail clamp pos');

var trNone = P.trail(line, 0.5, { count: 3, lagU: 0.1, fade: 'none' });
near(trNone[0].alpha, 1, 1e-12, 'trail fade none 0');
near(trNone[1].alpha, 1, 1e-12, 'trail fade none 1');
near(trNone[2].alpha, 1, 1e-12, 'trail fade none 2');

var trDefault = P.trail(line, 0.5);
assert.strictEqual(trDefault.length, 6, 'trail default count');

var one = P.build([[1, 2, 3]]);
near(one.length, 0, 1e-12, 'single point length');
var oneAt = P.at(one, 0.3);
nearVec(oneAt.pos, [1, 2, 3], 1e-12, 'single point pos');
nearVec(oneAt.tangent, [1, 0, 0], 1e-12, 'single point tangent');
near(oneAt.s, 0, 1e-12, 'single point s');

var oneTrail = P.trail(one, 0.5, { count: 3, lagU: 0.2 });
assert.strictEqual(oneTrail.length, 3, 'single point trail count');
nearVec(oneTrail[0].pos, [1, 2, 3], 1e-12, 'single point trail pos');

var rsOne = P.resample([[1, 2, 3]], 4);
assert.strictEqual(rsOne.length, 4, 'single point resample count');
nearVec(rsOne[3], [1, 2, 3], 1e-12, 'single point resample pos');

var empty = P.build([]);
near(empty.length, 0, 1e-12, 'empty length');
nearVec(P.at(empty, 0.5).pos, [0, 0, 0], 1e-12, 'empty pos');
nearVec(P.at(empty, 0.5).tangent, [1, 0, 0], 1e-12, 'empty tangent');

console.log('ok');
