'use strict';

const assert = require('node:assert');
const P = require('./playback.js');

function near(actual, expected, eps) {
  const e = eps === undefined ? 1e-9 : eps;
  assert.ok(Math.abs(actual - expected) <= e,
    'expected ' + actual + ' to be near ' + expected);
}

assert.deepStrictEqual(P.PRESETS, [0.05, 0.1, 0.25, 0.5, 1, 2]);
assert.strictEqual(P.MIN_SPEED, 0.02);
assert.strictEqual(P.MAX_SPEED, 4);

// tick advances scaled by speed
{
  const c = P.create({ duration: () => 1000, speed: 0.25 });
  c.play();
  let r = c.tick(1000);
  near(r.t, 250);
  assert.strictEqual(r.playing, true);
  assert.strictEqual(r.ended, false);
  assert.strictEqual(r.wrapped, false);
  r = c.tick(2000);
  near(r.t, 750);
  near(c.t, 750);
}
{
  const c = P.create({ duration: () => 10000, speed: 2 });
  c.play();
  c.tick(100);
  near(c.t, 200);
  assert.strictEqual(c.frame(60), 12);
}

// once ends and stops
{
  const c = P.create({ duration: () => 1000, speed: 1, loop: 'once' });
  c.play();
  let r = c.tick(600);
  near(r.t, 600);
  assert.strictEqual(r.playing, true);
  r = c.tick(1000);
  near(r.t, 1000);
  assert.strictEqual(r.playing, false);
  assert.strictEqual(r.ended, true);
  r = c.tick(100);
  near(r.t, 1000);
  assert.strictEqual(r.playing, false);
  assert.strictEqual(r.ended, false);
  assert.strictEqual(r.wrapped, false);
}

// play at the end restarts from lo
{
  const c = P.create({ duration: () => 1000, loop: 'once' });
  c.play();
  c.tick(5000);
  near(c.t, 1000);
  assert.strictEqual(c.playing, false);
  c.play();
  assert.strictEqual(c.playing, true);
  near(c.t, 0);
}
{
  const c = P.create({ duration: () => 1000, loop: 'once' });
  c.setRange(200, 800);
  c.seek(800);
  c.play();
  near(c.t, 200);
  c.tick(100);
  near(c.t, 300);
}

// pause / toggle
{
  const c = P.create({ duration: () => 1000 });
  c.play();
  assert.strictEqual(c.playing, true);
  c.toggle();
  assert.strictEqual(c.playing, false);
  c.toggle();
  assert.strictEqual(c.playing, true);
  c.pause();
  assert.strictEqual(c.playing, false);
}

// loop with hold, then wraps
{
  const c = P.create({ duration: () => 1000, speed: 1, loop: 'loop', endHoldMs: 500 });
  c.play();
  let r = c.tick(1000);
  near(c.t, 1000);
  assert.strictEqual(r.playing, true);
  assert.strictEqual(r.wrapped, false);
  assert.strictEqual(c.hold, 500);
  r = c.tick(200);
  near(c.t, 1000);
  assert.strictEqual(c.hold, 300);
  assert.strictEqual(r.wrapped, false);
  r = c.tick(200);
  assert.strictEqual(c.hold, 100);
  r = c.tick(100);
  near(r.t, 0);
  assert.strictEqual(r.wrapped, true);
  assert.strictEqual(c.hold, 0);
  assert.strictEqual(r.playing, true);
  r = c.tick(100);
  near(r.t, 100);
}

// pingpong reverses and returns
{
  const c = P.create({ duration: () => 1000, speed: 1, loop: 'pingpong', endHoldMs: 100 });
  c.play();
  c.tick(400);
  near(c.t, 400);
  let r = c.tick(1000);
  near(c.t, 1000);
  assert.strictEqual(c.hold, 100);
  assert.strictEqual(c.dir, 1);
  r = c.tick(100);
  assert.strictEqual(c.dir, -1);
  near(c.t, 1000);
  assert.strictEqual(r.wrapped, false);
  r = c.tick(300);
  near(r.t, 700);
  r = c.tick(1000);
  near(c.t, 0);
  assert.strictEqual(c.hold, 100);
  assert.strictEqual(c.dir, -1);
  r = c.tick(100);
  assert.strictEqual(c.dir, 1);
  near(c.t, 0);
  r = c.tick(250);
  near(r.t, 250);
}

// range limits
{
  const c = P.create({ duration: () => 1000, speed: 1, loop: 'once' });
  c.setRange(600, 200);
  assert.deepStrictEqual(c.range, { a: 200, b: 600 });
  c.setRange(200.0, 200.5);
  assert.deepStrictEqual(c.range, { a: 200, b: 600 });
  c.setRange(2000, 3000);
  assert.deepStrictEqual(c.range, { a: 200, b: 600 });
  c.seek(500);
  c.play();
  const r = c.tick(300);
  near(r.t, 600);
  near(c.t, 600);
  assert.strictEqual(r.ended, true);
  assert.strictEqual(c.playing, false);
  c.clearRange();
  assert.strictEqual(c.range, null);
}
{
  const c = P.create({ duration: () => 1000 });
  c.setRange(-500, 400);
  assert.deepStrictEqual(c.range, { a: 0, b: 400 });
}

// step clamps
{
  const c = P.create({ duration: () => 1000 });
  c.play();
  assert.strictEqual(c.step(600), 1000);
  assert.strictEqual(c.playing, false);
  assert.strictEqual(c.step(-600), 0);
  assert.strictEqual(c.step(6), 100);
}
{
  const c = P.create({ duration: () => 1000 });
  c.setRange(200, 600);
  c.seek(300);
  assert.strictEqual(c.step(1000), 600);
  assert.strictEqual(c.step(-1000), 200);
}

// seek clamps
{
  const c = P.create({ duration: () => 1000 });
  assert.strictEqual(c.seek(-50), 0);
  assert.strictEqual(c.seek(400), 400);
  assert.strictEqual(c.seek(5000), 1000);
  assert.strictEqual(c.t, 1000);
}

// setSpeed clamps
{
  const c = P.create({ duration: () => 1000, speed: 1 });
  assert.strictEqual(c.setSpeed(10), 4);
  assert.strictEqual(c.speed, 4);
  assert.strictEqual(c.setSpeed(0.001), 0.02);
  assert.strictEqual(c.speed, 0.02);
  assert.strictEqual(c.setSpeed(0.5), 0.5);
}

// nextPreset
{
  const c = P.create({ duration: () => 1000 });
  assert.strictEqual(c.speed, 1);
  assert.strictEqual(c.nextPreset(1), 2);
  assert.strictEqual(c.speed, 2);
  assert.strictEqual(c.nextPreset(1), 2);
  assert.strictEqual(c.nextPreset(-1), 1);
  assert.strictEqual(c.nextPreset(-1), 0.5);
  c.setSpeed(0.3);
  assert.strictEqual(c.nextPreset(1), 0.5);
  assert.strictEqual(c.nextPreset(-1), 0.25);
  c.setSpeed(0.02);
  assert.strictEqual(c.nextPreset(-1), 0.02);
}

// label() drops trailing zeros
{
  const c = P.create({ duration: () => 1000 });
  assert.strictEqual(c.label(), '1\u00d7');
  c.setSpeed(0.5);
  assert.strictEqual(c.label(), '0.5\u00d7');
  c.setSpeed(0.25);
  assert.strictEqual(c.label(), '0.25\u00d7');
  c.setSpeed(0.1);
  assert.strictEqual(c.label(), '0.1\u00d7');
  c.setSpeed(2);
  assert.strictEqual(c.label(), '2\u00d7');
  c.setSpeed(1.75);
  assert.strictEqual(c.label(), '1.75\u00d7');
}

// duration function changing at runtime
{
  let d = 1000;
  const c = P.create({ duration: () => d, speed: 1, loop: 'once' });
  c.play();
  let r = c.tick(5000);
  assert.strictEqual(r.ended, true);
  near(c.t, 1000);
  d = 2000;
  assert.strictEqual(c.seek(5000), 2000);
  assert.strictEqual(c.seek(1000), 1000);
  c.play();
  r = c.tick(1000);
  near(r.t, 2000);
  assert.strictEqual(r.ended, true);
  assert.strictEqual(c.playing, false);
}

console.log('ok');
