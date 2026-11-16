/* MS_Playback - playback clock with reduced speed (browser prototype, ES2019). */
(function (root, f) {
  if (typeof module === 'object' && module.exports) {
    module.exports = f();
  } else {
    root.MS_Playback = f();
  }
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  var PRESETS = [0.05, 0.1, 0.25, 0.5, 1, 2];
  var MIN_SPEED = 0.02;
  var MAX_SPEED = 4;

  function clamp(x, min, max) {
    var n = Number(x);
    if (!isFinite(n)) n = min;
    return n < min ? min : (n > max ? max : n);
  }

  function speedLabel(x) {
    var r = Math.round(x * 1e6) / 1e6;
    return String(r) + '\u00d7';
  }

  function create(opts) {
    opts = opts || {};

    var durationFn = opts.duration;
    if (typeof durationFn !== 'function') {
      durationFn = function () { return 0; };
    }

    var endHoldMs = opts.endHoldMs === undefined
      ? 500
      : Math.max(0, Number(opts.endHoldMs) || 0);

    var c = {
      t: 0,
      playing: false,
      speed: clamp(opts.speed === undefined ? 1 : opts.speed, MIN_SPEED, MAX_SPEED),
      loop: opts.loop || 'once',
      dir: 1,
      range: null,
      hold: 0
    };

    function duration() {
      var d = Number(durationFn());
      return isFinite(d) && d > 0 ? d : 0;
    }

    function windowRange() {
      if (c.range) return { lo: c.range.a, hi: c.range.b };
      var d = duration();
      return { lo: 0, hi: d };
    }

    function finishHold() {
      if (c.dir > 0) {
        if (c.loop === 'pingpong') {
          c.dir = -1;
          return false;
        }
        c.t = windowRange().lo;
        return true;
      }
      if (c.loop === 'pingpong') {
        c.dir = 1;
        return false;
      }
      c.t = windowRange().hi;
      return true;
    }

    c.play = function () {
      if (!c.playing) {
        c.playing = true;
        var w = windowRange();
        if (c.dir > 0 && c.loop === 'once' && c.t >= w.hi) {
          c.t = w.lo;
        }
      }
    };

    c.pause = function () {
      c.playing = false;
    };

    c.toggle = function () {
      if (c.playing) c.pause();
      else c.play();
    };

    c.seek = function (ms) {
      c.t = clamp(ms, 0, duration());
      return c.t;
    };

    c.setSpeed = function (x) {
      c.speed = clamp(x, MIN_SPEED, MAX_SPEED);
      return c.speed;
    };

    c.setLoop = function (mode) {
      c.loop = mode;
    };

    c.setRange = function (a, b) {
      var d = duration();
      var lo = clamp(a, 0, d);
      var hi = clamp(b, 0, d);
      if (lo > hi) {
        var tmp = lo;
        lo = hi;
        hi = tmp;
      }
      if (hi - lo < 1) return;
      c.range = { a: lo, b: hi };
    };

    c.clearRange = function () {
      c.range = null;
    };

    c.tick = function (dtRealMs) {
      if (!c.playing) {
        return { t: c.t, playing: false, ended: false, wrapped: false };
      }

      var dt = Number(dtRealMs);
      if (!isFinite(dt) || dt < 0) dt = 0;

      var ended = false;
      var wrapped = false;

      if (c.hold > 0) {
        c.hold -= dt;
        if (c.hold > 0) {
          return { t: c.t, playing: true, ended: false, wrapped: false };
        }
        c.hold = 0;
        wrapped = finishHold();
        return { t: c.t, playing: c.playing, ended: false, wrapped: wrapped };
      }

      var w = windowRange();
      var next = c.t + dt * c.speed * c.dir;

      if (c.dir > 0 && next >= w.hi) {
        c.t = w.hi;
        if (c.loop === 'once') {
          c.playing = false;
          ended = true;
        } else if (endHoldMs > 0) {
          c.hold = endHoldMs;
        } else {
          wrapped = finishHold();
        }
      } else if (c.dir < 0 && next <= w.lo) {
        c.t = w.lo;
        if (c.loop === 'once') {
          c.playing = false;
          ended = true;
        } else if (endHoldMs > 0) {
          c.hold = endHoldMs;
        } else {
          wrapped = finishHold();
        }
      } else {
        c.t = next;
      }

      return { t: c.t, playing: c.playing, ended: ended, wrapped: wrapped };
    };

    c.step = function (frames, fps) {
      fps = (fps === undefined || fps === null) ? 60 : Number(fps);
      if (!isFinite(fps) || fps <= 0) fps = 60;

      c.playing = false;

      var w = windowRange();
      var next = c.t + (Number(frames) || 0) * 1000 / fps;
      if (next < w.lo) next = w.lo;
      if (next > w.hi) next = w.hi;
      c.t = next;
      return c.t;
    };

    c.frame = function (fps) {
      fps = (fps === undefined || fps === null) ? 60 : Number(fps);
      if (!isFinite(fps) || fps <= 0) fps = 60;
      return Math.round(c.t * fps / 1000);
    };

    c.label = function () {
      return speedLabel(c.speed);
    };

    c.nextPreset = function (dir) {
      var out = c.speed;
      var i;
      if (dir > 0) {
        for (i = 0; i < PRESETS.length; i++) {
          if (PRESETS[i] > c.speed + 1e-9) {
            out = PRESETS[i];
            break;
          }
        }
      } else if (dir < 0) {
        for (i = PRESETS.length - 1; i >= 0; i--) {
          if (PRESETS[i] < c.speed - 1e-9) {
            out = PRESETS[i];
            break;
          }
        }
      }
      return c.setSpeed(out);
    };

    return c;
  }

  return {
    create: create,
    PRESETS: PRESETS,
    MIN_SPEED: MIN_SPEED,
    MAX_SPEED: MAX_SPEED
  };
});
