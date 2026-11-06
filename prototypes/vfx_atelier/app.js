
    import * as THREE from 'three';
    import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
    import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
    import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';

    // =========================================================================
    // 1. PROCEDURAL WEBAUDIO SYNTHESIZER (ALL 6 MOVES SFX)
    // =========================================================================
    class NocturneAudioEngine {
      constructor() {
        this.ctx = null;
        this.enabled = true;
      }

      init() {
        if (!this.ctx) {
          const AudioCtx = window.AudioContext || window.webkitAudioContext;
          if (AudioCtx) this.ctx = new AudioCtx();
        }
        if (this.ctx && this.ctx.state === 'suspended') {
          this.ctx.resume();
        }
      }

      playMediaWindup() {
        if (!this.enabled) return;
        this.init();
        if (!this.ctx) return;
        const now = this.ctx.currentTime;
        [523.25, 659.25, 783.99, 987.77, 1174.66].forEach((freq, i) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = i % 2 === 0 ? 'sine' : 'triangle';
          osc.frequency.setValueAtTime(freq * 0.5, now + i * 0.06);
          osc.frequency.exponentialRampToValueAtTime(freq, now + i * 0.06 + 0.45);
          gain.gain.setValueAtTime(0.0001, now + i * 0.06);
          gain.gain.linearRampToValueAtTime(0.05, now + i * 0.06 + 0.15);
          gain.gain.exponentialRampToValueAtTime(0.0001, now + 1.8);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(now + i * 0.06);
          osc.stop(now + 1.85);
        });
      }

      playMediaHealPulse() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        [587.33, 880, 1046.5, 1318.5, 1567.98, 2093.0].forEach((freq, idx) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'sine';
          const start = now + idx * 0.05;
          osc.frequency.setValueAtTime(freq, start);
          osc.frequency.exponentialRampToValueAtTime(freq * 1.02, start + 0.55);
          gain.gain.setValueAtTime(0.001, start);
          gain.gain.linearRampToValueAtTime(0.045, start + 0.05);
          gain.gain.exponentialRampToValueAtTime(0.0001, start + 0.9);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(start);
          osc.stop(start + 0.95);
        });
      }

      playMabufulaBlizzard() {
        if (!this.enabled) return;
        this.init();
        if (!this.ctx) return;
        const now = this.ctx.currentTime;
        const bufferSize = Math.floor(this.ctx.sampleRate * 1.7);
        const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) data[i] = Math.random() * 2 - 1;
        const noise = this.ctx.createBufferSource();
        noise.buffer = buffer;
        const filter = this.ctx.createBiquadFilter();
        filter.type = 'bandpass';
        filter.frequency.setValueAtTime(420, now);
        filter.frequency.exponentialRampToValueAtTime(1450, now + 0.65);
        filter.frequency.exponentialRampToValueAtTime(620, now + 1.6);
        filter.Q.value = 3.5;
        const gain = this.ctx.createGain();
        gain.gain.setValueAtTime(0.001, now);
        gain.gain.linearRampToValueAtTime(0.13, now + 0.25);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 1.65);
        noise.connect(filter);
        filter.connect(gain);
        gain.connect(this.ctx.destination);
        noise.start(now);
        noise.stop(now + 1.7);
      }

      playGlacierErupt(pitchOffset = 1.0) {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        const oscLow = this.ctx.createOscillator();
        const gainLow = this.ctx.createGain();
        oscLow.type = 'sawtooth';
        oscLow.frequency.setValueAtTime(150 * pitchOffset, now);
        oscLow.frequency.exponentialRampToValueAtTime(42, now + 0.32);
        gainLow.gain.setValueAtTime(0.1, now);
        gainLow.gain.exponentialRampToValueAtTime(0.001, now + 0.35);
        oscLow.connect(gainLow);
        gainLow.connect(this.ctx.destination);
        oscLow.start(now);
        oscLow.stop(now + 0.36);
      }

      playGlacierShatter() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        const sub = this.ctx.createOscillator();
        const subGain = this.ctx.createGain();
        sub.type = 'sine';
        sub.frequency.setValueAtTime(125, now);
        sub.frequency.exponentialRampToValueAtTime(28, now + 0.55);
        subGain.gain.setValueAtTime(0.25, now);
        subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);
        sub.connect(subGain);
        subGain.connect(this.ctx.destination);
        sub.start(now);
        sub.stop(now + 0.62);

        [1760, 2349, 2793, 3520, 4186].forEach((f, i) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'sine';
          const t = now + i * 0.018;
          osc.frequency.setValueAtTime(f, t);
          osc.frequency.exponentialRampToValueAtTime(f * 0.72, t + 0.28);
          gain.gain.setValueAtTime(0.06, t);
          gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.34);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(t);
          osc.stop(t + 0.36);
        });
      }

      playDigBurrow() {
        if (!this.enabled) return;
        this.init();
        if (!this.ctx) return;
        const now = this.ctx.currentTime;
        for (let i = 0; i < 5; i++) {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'sawtooth';
          const t = now + i * 0.07;
          osc.frequency.setValueAtTime(190 - i * 20, t);
          osc.frequency.exponentialRampToValueAtTime(48, t + 0.14);
          gain.gain.setValueAtTime(0.09, t);
          gain.gain.exponentialRampToValueAtTime(0.001, t + 0.15);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(t);
          osc.stop(t + 0.16);
        }
      }

      playDigTremor() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(92, now);
        osc.frequency.exponentialRampToValueAtTime(36, now + 0.22);
        gain.gain.setValueAtTime(0.13, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.24);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(now);
        osc.stop(now + 0.25);
      }

      playDigEruption() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        const sub = this.ctx.createOscillator();
        const subGain = this.ctx.createGain();
        sub.type = 'sawtooth';
        sub.frequency.setValueAtTime(140, now);
        sub.frequency.exponentialRampToValueAtTime(26, now + 0.65);
        subGain.gain.setValueAtTime(0.26, now);
        subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.68);
        sub.connect(subGain);
        subGain.connect(this.ctx.destination);
        sub.start(now);
        sub.stop(now + 0.7);
      }

      playSandJet() {
        if (!this.enabled) return;
        this.init();
        if (!this.ctx) return;
        const now = this.ctx.currentTime;
        const bufferSize = Math.floor(this.ctx.sampleRate * 1.4);
        const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) data[i] = Math.random() * 2 - 1;
        const noise = this.ctx.createBufferSource();
        noise.buffer = buffer;
        const filter = this.ctx.createBiquadFilter();
        filter.type = 'bandpass';
        filter.frequency.setValueAtTime(900, now);
        filter.frequency.exponentialRampToValueAtTime(2600, now + 0.35);
        filter.frequency.exponentialRampToValueAtTime(1100, now + 1.3);
        filter.Q.value = 2.4;
        const gain = this.ctx.createGain();
        gain.gain.setValueAtTime(0.001, now);
        gain.gain.linearRampToValueAtTime(0.16, now + 0.12);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 1.35);
        noise.connect(filter);
        filter.connect(gain);
        gain.connect(this.ctx.destination);
        noise.start(now);
        noise.stop(now + 1.4);
      }

      playDebuffDown() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        [620, 520, 410, 310].forEach((f, i) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'sawtooth';
          const t = now + i * 0.08;
          osc.frequency.setValueAtTime(f, t);
          osc.frequency.exponentialRampToValueAtTime(f * 0.82, t + 0.14);
          gain.gain.setValueAtTime(0.055, t);
          gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.16);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(t);
          osc.stop(t + 0.17);
        });
      }

      // Move 5 (Rebuilt): Monstrous Draconic Roar, Savage Fireball Hurl & Volcanic Dragon Cataclysm
      playMonstrousDragonRoar() {
        if (!this.enabled) return;
        this.init();
        if (!this.ctx) return;
        const now = this.ctx.currentTime;

        // Guttural Beast Roar (Sawtooth + Sub-bass growl + Roar Noise Formant)
        [65.41, 92.5, 130.81].forEach((freq, i) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'sawtooth';
          osc.frequency.setValueAtTime(freq * 1.35, now);
          osc.frequency.linearRampToValueAtTime(freq * 1.85, now + 0.18);
          osc.frequency.exponentialRampToValueAtTime(freq * 0.52, now + 0.65);
          gain.gain.setValueAtTime(0.001, now);
          gain.gain.linearRampToValueAtTime(0.11 - i * 0.02, now + 0.08);
          gain.gain.exponentialRampToValueAtTime(0.001, now + 0.68);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(now);
          osc.stop(now + 0.7);
        });

        // Roar breath turbulence
        const bufLen = Math.floor(this.ctx.sampleRate * 0.65);
        const buf = this.ctx.createBuffer(1, bufLen, this.ctx.sampleRate);
        const data = buf.getChannelData(0);
        for (let i = 0; i < bufLen; i++) data[i] = Math.random() * 2 - 1;
        const noise = this.ctx.createBufferSource();
        noise.buffer = buf;
        const filter = this.ctx.createBiquadFilter();
        filter.type = 'bandpass';
        filter.frequency.setValueAtTime(320, now);
        filter.frequency.exponentialRampToValueAtTime(780, now + 0.2);
        filter.frequency.exponentialRampToValueAtTime(220, now + 0.62);
        filter.Q.value = 2.2;
        const nGain = this.ctx.createGain();
        nGain.gain.setValueAtTime(0.001, now);
        nGain.gain.linearRampToValueAtTime(0.18, now + 0.1);
        nGain.gain.exponentialRampToValueAtTime(0.001, now + 0.64);
        noise.connect(filter);
        filter.connect(nGain);
        nGain.connect(this.ctx.destination);
        noise.start(now);
        noise.stop(now + 0.65);
      }

      playDragonFireballTear() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        // Heavy scorching fireball jet whoosh
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(240, now);
        osc.frequency.exponentialRampToValueAtTime(58, now + 0.44);
        gain.gain.setValueAtTime(0.2, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.46);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(now);
        osc.stop(now + 0.48);
      }

      playDragonRageCataclysm() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        // Massive monstrous sub-bass impact + crackling firestorm roar
        const sub = this.ctx.createOscillator();
        const subGain = this.ctx.createGain();
        sub.type = 'sawtooth';
        sub.frequency.setValueAtTime(145, now);
        sub.frequency.exponentialRampToValueAtTime(18, now + 0.92);
        subGain.gain.setValueAtTime(0.38, now);
        subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.95);
        sub.connect(subGain);
        subGain.connect(this.ctx.destination);
        sub.start(now);
        sub.stop(now + 0.98);

        // Explosive noise burst for firestorm & shockwave
        const bufLen = Math.floor(this.ctx.sampleRate * 0.85);
        const buf = this.ctx.createBuffer(1, bufLen, this.ctx.sampleRate);
        const data = buf.getChannelData(0);
        for (let i = 0; i < bufLen; i++) data[i] = Math.random() * 2 - 1;
        const noise = this.ctx.createBufferSource();
        noise.buffer = buf;
        const filter = this.ctx.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.setValueAtTime(1800, now);
        filter.frequency.exponentialRampToValueAtTime(180, now + 0.82);
        const nGain = this.ctx.createGain();
        nGain.gain.setValueAtTime(0.28, now);
        nGain.gain.exponentialRampToValueAtTime(0.001, now + 0.84);
        noise.connect(filter);
        filter.connect(nGain);
        nGain.connect(this.ctx.destination);
        noise.start(now);
        noise.stop(now + 0.85);
      }

      // Move 8 (Preserved Psycho Orb): Smooth Pink Psychic Sphere Charge, Launch & Detonation
      playDragonPinkSphereCharge() {
        if (!this.enabled) return;
        this.init();
        if (!this.ctx) return;
        const now = this.ctx.currentTime;
        [130.81, 196.0, 261.63, 392.0].forEach((freq, i) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = i % 2 === 0 ? 'sine' : 'sawtooth';
          osc.frequency.setValueAtTime(freq * 0.55, now);
          osc.frequency.exponentialRampToValueAtTime(freq * 1.9, now + 0.55);
          gain.gain.setValueAtTime(0.001, now);
          gain.gain.linearRampToValueAtTime(0.065, now + 0.25);
          gain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(now);
          osc.stop(now + 0.62);
        });
      }

      playDragonPinkSphereLaunch() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(360, now);
        osc.frequency.exponentialRampToValueAtTime(95, now + 0.44);
        gain.gain.setValueAtTime(0.16, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.46);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(now);
        osc.stop(now + 0.48);
      }

      playDragonPinkExplosion() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        // Deep sub-bass pink plasma detonation
        const sub = this.ctx.createOscillator();
        const subGain = this.ctx.createGain();
        sub.type = 'sawtooth';
        sub.frequency.setValueAtTime(170, now);
        sub.frequency.exponentialRampToValueAtTime(22, now + 0.85);
        subGain.gain.setValueAtTime(0.34, now);
        subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.88);
        sub.connect(subGain);
        subGain.connect(this.ctx.destination);
        sub.start(now);
        sub.stop(now + 0.9);

        // High rose-plasma resonance burst
        [329.63, 493.88, 659.25, 987.77].forEach((f, idx) => {
          const o = this.ctx.createOscillator();
          const g = this.ctx.createGain();
          o.type = idx % 2 === 0 ? 'triangle' : 'sine';
          o.frequency.setValueAtTime(f * 1.2, now);
          o.frequency.exponentialRampToValueAtTime(f * 0.45, now + 0.72);
          g.gain.setValueAtTime(0.065, now);
          g.gain.exponentialRampToValueAtTime(0.0001, now + 0.75);
          o.connect(g);
          g.connect(this.ctx.destination);
          o.start(now);
          o.stop(now + 0.78);
        });
      }

      // Move 7: Psychic Cannon — Psionic Sigil Charge + Ultrasonic Beam + Mind Rupture Supernova
      playPsychicCharge() {
        if (!this.enabled) return;
        this.init();
        if (!this.ctx) return;
        const now = this.ctx.currentTime;
        [110, 164.81, 220, 329.63].forEach((freq, i) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = i % 2 === 0 ? 'sawtooth' : 'triangle';
          osc.frequency.setValueAtTime(freq * 0.6, now);
          osc.frequency.exponentialRampToValueAtTime(freq * 1.65, now + 0.65);
          gain.gain.setValueAtTime(0.001, now);
          gain.gain.linearRampToValueAtTime(0.06, now + 0.25);
          gain.gain.exponentialRampToValueAtTime(0.001, now + 0.75);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(now);
          osc.stop(now + 0.78);
        });
      }

      playPsychicBeamAndBlast() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(520, now);
        osc.frequency.exponentialRampToValueAtTime(140, now + 0.55);
        gain.gain.setValueAtTime(0.14, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(now);
        osc.stop(now + 0.62);
      }

      playPsychicSupernova() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        const sub = this.ctx.createOscillator();
        const subGain = this.ctx.createGain();
        sub.type = 'sine';
        sub.frequency.setValueAtTime(155, now);
        sub.frequency.exponentialRampToValueAtTime(24, now + 0.8);
        subGain.gain.setValueAtTime(0.32, now);
        subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.85);
        sub.connect(subGain);
        subGain.connect(this.ctx.destination);
        sub.start(now);
        sub.stop(now + 0.88);

        [293.66, 440, 587.33, 880].forEach((f) => {
          const o = this.ctx.createOscillator();
          const g = this.ctx.createGain();
          o.type = 'triangle';
          o.frequency.setValueAtTime(f, now);
          o.frequency.exponentialRampToValueAtTime(f * 0.5, now + 0.7);
          g.gain.setValueAtTime(0.06, now);
          g.gain.exponentialRampToValueAtTime(0.0001, now + 0.75);
          o.connect(g);
          g.connect(this.ctx.destination);
          o.start(now);
          o.stop(now + 0.78);
        });
      }

      // Move 6: Splitter Flames — 0.70s Dual Fireball Windup, 0.30s Vortex Release, Pillar Blast & Burn Tick
      playSplitterWindup() {
        if (!this.enabled) return;
        this.init();
        if (!this.ctx) return;
        const now = this.ctx.currentTime;
        // Rising twin-flame harmonic hum over 0.70s
        [196.0, 293.66, 392.0].forEach((f, idx) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = idx === 1 ? 'sawtooth' : 'sine';
          osc.frequency.setValueAtTime(f * 0.75, now);
          osc.frequency.exponentialRampToValueAtTime(f * 1.85, now + 0.7);
          gain.gain.setValueAtTime(0.001, now);
          gain.gain.linearRampToValueAtTime(0.055, now + 0.35);
          gain.gain.exponentialRampToValueAtTime(0.001, now + 0.72);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(now);
          osc.stop(now + 0.74);
        });
      }

      playSplitterRelease() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        // Twin fire vortex launch whoosh
        [0, 0.04].forEach((offset, i) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          osc.type = 'sawtooth';
          osc.frequency.setValueAtTime(640 + i * 120, now + offset);
          osc.frequency.exponentialRampToValueAtTime(160, now + offset + 0.3);
          gain.gain.setValueAtTime(0.11, now + offset);
          gain.gain.exponentialRampToValueAtTime(0.001, now + offset + 0.32);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(now + offset);
          osc.stop(now + offset + 0.34);
        });
      }

      playSplitterImpact(isPillar = true) {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        const sub = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        sub.type = 'sawtooth';
        sub.frequency.setValueAtTime(isPillar ? 160 : 210, now);
        sub.frequency.exponentialRampToValueAtTime(32, now + (isPillar ? 0.65 : 0.42));
        gain.gain.setValueAtTime(isPillar ? 0.26 : 0.18, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + (isPillar ? 0.68 : 0.45));
        sub.connect(gain);
        gain.connect(this.ctx.destination);
        sub.start(now);
        sub.stop(now + 0.7);
      }

      playBurnTick() {
        if (!this.enabled || !this.ctx) return;
        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(880, now);
        osc.frequency.exponentialRampToValueAtTime(420, now + 0.14);
        gain.gain.setValueAtTime(0.055, now);
        gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.16);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(now);
        osc.stop(now + 0.17);
      }
    }

    const sfx = new NocturneAudioEngine();

    // =========================================================================
    // 2. PROCEDURAL TEXTURE ATLAS GENERATOR FOR QUARKS PARTICLES
    // =========================================================================
    function createParticleTexture(type) {
      const canvas = document.createElement('canvas');
      canvas.width = 128;
      canvas.height = 128;
      const ctx = canvas.getContext('2d');
      const cx = 64, cy = 64;

      if(type==='flame'||type==='smoke') {
        const pixels=ctx.createImageData(128,128);
        for(let y=0;y<128;y++)for(let x=0;x<128;x++){
          const u=(x-64)/64,v=y/128;
          const n=Math.sin(x*.19+Math.sin(y*.13)*3)*Math.cos(y*.17+x*.05);
          let a;
          if(type==='flame'){
            const width=.06+Math.sin(v*Math.PI)*.55;
            const axis=Math.sin(v*8)*.17*(1-v);
            const edge=width-Math.abs(u-axis)+n*.07;
            a=Math.max(0,Math.min(1,edge*13))*Math.min(1,v*12)*Math.min(1,(1-v)*12);
          }else{
            const d=Math.hypot(u,(v-.5)*2);
            a=Math.max(0,1-d+n*.12);a=a*a*.65;
          }
          const k=(y*128+x)*4;
          pixels.data[k]=pixels.data[k+1]=pixels.data[k+2]=255;
          pixels.data[k+3]=Math.min(255,a*255);
        }
        ctx.putImageData(pixels,0,0);return new THREE.CanvasTexture(canvas);
      }
      if (type === 'glow') {
        const grad = ctx.createRadialGradient(cx, cy, 2, cx, cy, 60);
        grad.addColorStop(0, 'rgba(255,255,255,1)');
        grad.addColorStop(0.3, 'rgba(255,255,255,0.85)');
        grad.addColorStop(0.7, 'rgba(255,255,255,0.22)');
        grad.addColorStop(1, 'rgba(255,255,255,0)');
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, 128, 128);
      } else if (type === 'sparkle') {
        const grad = ctx.createRadialGradient(cx, cy, 1, cx, cy, 58);
        grad.addColorStop(0, 'rgba(255,255,255,1)');
        grad.addColorStop(0.25, 'rgba(255,255,255,0.68)');
        grad.addColorStop(1, 'rgba(255,255,255,0)');
        ctx.fillStyle = grad;
        ctx.beginPath();
        ctx.moveTo(cx, 4);
        ctx.quadraticCurveTo(cx + 6, cy - 6, 124, cy);
        ctx.quadraticCurveTo(cx + 6, cy + 6, cx, 124);
        ctx.quadraticCurveTo(cx - 6, cy + 6, 4, cy);
        ctx.quadraticCurveTo(cx - 6, cy - 6, cx, 4);
        ctx.closePath();
        ctx.fill();
      } else if (type === 'cross') {
        const grad = ctx.createRadialGradient(cx, cy, 4, cx, cy, 60);
        grad.addColorStop(0, 'rgba(255,255,255,0.95)');
        grad.addColorStop(1, 'rgba(255,255,255,0)');
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, 128, 128);
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(cx - 10, 18, 20, 92);
        ctx.fillRect(18, cy - 10, 92, 20);
      } else if (type === 'shard') {
        ctx.fillStyle = '#ffffff';
        ctx.beginPath();
        ctx.moveTo(cx, 8);
        ctx.lineTo(cx + 28, cy - 8);
        ctx.lineTo(cx + 16, 120);
        ctx.lineTo(cx - 22, cy + 18);
        ctx.closePath();
        ctx.fill();
      } else if (type === 'snowflake') {
        ctx.strokeStyle = '#ffffff';
        ctx.lineWidth = 5;
        ctx.lineCap = 'round';
        for (let i = 0; i < 6; i++) {
          const angle = (i * Math.PI) / 3;
          ctx.save();
          ctx.translate(cx, cy);
          ctx.rotate(angle);
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.lineTo(0, -50);
          ctx.moveTo(0, -28);
          ctx.lineTo(-14, -40);
          ctx.moveTo(0, -28);
          ctx.lineTo(14, -40);
          ctx.stroke();
          ctx.restore();
        }
      } else if (type === 'rock') {
        ctx.fillStyle = '#ffffff';
        ctx.beginPath();
        ctx.moveTo(28, 22);
        ctx.lineTo(88, 14);
        ctx.lineTo(114, 58);
        ctx.lineTo(92, 108);
        ctx.lineTo(38, 112);
        ctx.lineTo(14, 68);
        ctx.closePath();
        ctx.fill();
      } else if (type === 'smoke') {
        const grad = ctx.createRadialGradient(cx, cy, 6, cx, cy, 58);
        grad.addColorStop(0, 'rgba(255,255,255,0.85)');
        grad.addColorStop(0.55, 'rgba(255,255,255,0.38)');
        grad.addColorStop(1, 'rgba(255,255,255,0)');
        ctx.fillStyle = grad;
        ctx.beginPath();
        ctx.arc(cx, cy, 58, 0, Math.PI * 2);
        ctx.fill();
      } else if (type === 'flame') {
        // Stylized tongue of fire / ember flake
        const grad = ctx.createRadialGradient(cx, cy + 8, 4, cx, cy, 56);
        grad.addColorStop(0, 'rgba(255,255,255,1)');
        grad.addColorStop(0.5, 'rgba(255,255,255,0.7)');
        grad.addColorStop(1, 'rgba(255,255,255,0)');
        ctx.fillStyle = grad;
        ctx.beginPath();
        ctx.moveTo(cx, 6);
        ctx.quadraticCurveTo(cx + 42, cy - 4, cx + 26, 112);
        ctx.quadraticCurveTo(cx, 124, cx - 26, 112);
        ctx.quadraticCurveTo(cx - 42, cy - 4, cx, 6);
        ctx.closePath();
        ctx.fill();
      } else if (type === 'ash') {
        // Irregular charred flake for Splitter Flames ash dissipation
        ctx.fillStyle = '#ffffff';
        ctx.beginPath();
        ctx.moveTo(36, 28);
        ctx.lineTo(84, 24);
        ctx.lineTo(102, 66);
        ctx.lineTo(74, 98);
        ctx.lineTo(28, 86);
        ctx.closePath();
        ctx.fill();
      } else if (type === 'xmark') {
        ctx.strokeStyle = '#ffffff';
        ctx.lineWidth = 14;
        ctx.lineCap = 'round';
        ctx.beginPath();
        ctx.moveTo(26, 26);
        ctx.lineTo(102, 102);
        ctx.moveTo(102, 26);
        ctx.lineTo(26, 102);
        ctx.stroke();
      }

      const tex = new THREE.CanvasTexture(canvas);
      tex.needsUpdate = true;
      return tex;
    }

    const PARTICLE_TEXTURES = {
      glow: createParticleTexture('glow'),
      sparkle: createParticleTexture('sparkle'),
      cross: createParticleTexture('cross'),
      shard: createParticleTexture('shard'),
      snowflake: createParticleTexture('snowflake'),
      rock: createParticleTexture('rock'),
      smoke: createParticleTexture('smoke'),
      flame: createParticleTexture('flame'),
      ash: createParticleTexture('ash'),
      xmark: createParticleTexture('xmark')
    };

    // =========================================================================

import * as Q from "three.quarks";
import noiseGLSL from "./noise3D.glsl";
import { OutputPass } from "three/addons/postprocessing/OutputPass.js";
// Real three.quarks batching; the application supplies every simulation step.
class AtelierParticles {
  constructor(parent) {
    this.scene = parent; this.meshes = []; this.systems = [];
    this.materials = new Map(); this.batch = new Q.BatchedRenderer();
    worldScene.add(this.batch); this.activeParticlesCount = 0;
  }
  spawnEmitter(config) {
    const count = Math.max(1, Math.ceil((config.count || 60) * 1.18));
    const c = {...config, size: (config.size || [.6, 1.4]).map(x => x * .66)};
    const key = `${c.texture || 'glow'}:${c.blending ?? THREE.AdditiveBlending}`;
    if (!this.materials.has(key)) this.materials.set(key, new THREE.MeshBasicMaterial({
      map: PARTICLE_TEXTURES[c.texture || 'glow'], transparent: true, depthWrite: false,
      blending: c.blending ?? THREE.AdditiveBlending, side: THREE.DoubleSide,
      toneMapped: false
    }));
    const engine = this; let index = 0;
    const behavior = {
      type: 'AtelierMotion', initialize(p) {
        const s = engine._initParticle(c, c.origin || new THREE.Vector3(), index++, count);
        if(index%4===0){s.sizeStart*=.26;s.vel.multiplyScalar(1.25);}
        p.atelier = s; p.life = s.maxLife + s.delay;
        p.velocity.set(0, 0, 0); p.position.copy(s.pos); p.color.w = 0;
      },
      update(p, dt) {
        const s = p.atelier, age = p.age - s.delay;
        if (age < 0) { p.color.w = 0; return; }
        const t = Math.min(1, age / s.maxLife);
        if (s.orbitSpeed) {
          const angle = s.orbitAngle + s.orbitSpeed * age;
          const radius = Math.max(.05, s.orbitRadius * (1 + s.radialRate * t));
          s.pos.set(s.origin.x + Math.cos(angle) * radius, s.origin.y + s.vel.y * age, s.origin.z + Math.sin(angle) * radius);
        } else {
          s.vel.y -= s.gravity * dt; s.vel.multiplyScalar(Math.pow(s.drag, dt * 60));
          s.pos.addScaledVector(s.vel, dt);
        }
        if (c.bounceFloor && s.pos.y < .08 && s.vel.y < 0) {
          s.pos.y = .08; s.vel.y *= -.45; s.vel.x *= .72; s.vel.z *= .72;
        }
        p.position.copy(s.pos); p.rotation = s.angle + s.spin * age;
        const col = s.colorStart.clone();
        if (s.colorMid) col.copy(t < .5 ? s.colorStart : s.colorMid).lerp(t < .5 ? s.colorMid : s.colorEnd, t < .5 ? t * 2 : (t - .5) * 2);
        else col.lerp(s.colorEnd, t);
        const alpha = t < .1 ? t / .1 : Math.pow((1 - t) / .9, 1.35);
        p.color.set(col.r * 1.22, col.g * 1.22, col.b * 1.22, alpha * (c.opacity ?? 1));
        p.size.setScalar(Math.max(.001, s.sizeStart * (c.sizeBell ? Math.sin(t * Math.PI) : 1 - Math.pow(t, 1.45))));
      }, frameUpdate() {}, reset() {}, clone() { return this; }
    };
    const system = new Q.ParticleSystem({duration: .02, looping: false,
      shape: new Q.SphereEmitter({radius: 0}), startLife: new Q.ConstantValue(1),
      startSpeed: new Q.ConstantValue(0), startSize: new Q.ConstantValue(1),
      startColor: new Q.ConstantColor(new THREE.Vector4(1, 1, 1, 1)),
      emissionOverTime: new Q.ConstantValue(0), emissionBursts: [{time: 0, count: new Q.ConstantValue(count), cycle: 1, interval: 0, probability: 1}],
      worldSpace: false, material: this.materials.get(key), behaviors: [behavior]
    });
    this.scene.add(system.emitter); this.scene.updateMatrixWorld(true);
    this.batch.addSystem(system); this.systems.push(system); return system;
  }
      _initParticle(config, origin, index, total) {
        const shape = config.shape || 'sphere';
        const pos = origin.clone();
        const vel = new THREE.Vector3();

        const radius = config.radius ?? 1.0;
        const speedMin = config.speed?.[0] ?? 1.0;
        const speedMax = config.speed?.[1] ?? 3.0;
        const spd = THREE.MathUtils.lerp(speedMin, speedMax, Math.random());

        let orbitAngle = (index / total) * Math.PI * 2 + Math.random() * 0.5;
        let orbitRadius = radius * (0.35 + 0.65 * Math.random());

        if (shape === 'circle' || shape === 'helix') {
          pos.x += Math.cos(orbitAngle) * orbitRadius;
          pos.z += Math.sin(orbitAngle) * orbitRadius;
          pos.y += (Math.random() - 0.5) * 0.3;
          vel.set(0, spd, 0);
        } else if (shape === 'inward') {
          // Singularity compression emitter (used in Dragon Rage windup)
          const u = Math.random() * Math.PI * 2;
          const v = (Math.random() - 0.5) * 2.0;
          const r = radius * (0.65 + 0.35 * Math.random());
          const offset = new THREE.Vector3(
            Math.cos(u) * Math.sqrt(1 - v * v) * r,
            v * r,
            Math.sin(u) * Math.sqrt(1 - v * v) * r
          );
          pos.add(offset);
          vel.copy(offset).normalize().multiplyScalar(-spd);
        } else if (shape === 'cone') {
          const theta = Math.random() * Math.PI * 2;
          const coneAngle = (config.coneAngle ?? 0.5) * Math.random();
          const dir = new THREE.Vector3(
            Math.sin(coneAngle) * Math.cos(theta),
            Math.cos(coneAngle),
            Math.sin(coneAngle) * Math.sin(theta)
          );
          if (config.direction) {
            const q = new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 1, 0), config.direction.clone().normalize());
            dir.applyQuaternion(q);
          }
          pos.addScaledVector(dir, Math.random() * radius);
          vel.copy(dir).multiplyScalar(spd);
        } else if (shape === 'hemisphere') {
          const u = Math.random();
          const v = Math.random();
          const theta = u * 2.0 * Math.PI;
          const phi = Math.acos(v);
          const dir = new THREE.Vector3(
            Math.sin(phi) * Math.cos(theta),
            Math.abs(Math.cos(phi)),
            Math.sin(phi) * Math.sin(theta)
          );
          pos.addScaledVector(dir, Math.random() * radius * 0.4);
          vel.copy(dir).multiplyScalar(spd);
        } else {
          const u = Math.random();
          const v = Math.random();
          const theta = u * 2.0 * Math.PI;
          const phi = Math.acos(2.0 * v - 1.0);
          const dir = new THREE.Vector3(
            Math.sin(phi) * Math.cos(theta),
            Math.cos(phi),
            Math.sin(phi) * Math.sin(theta)
          );
          pos.addScaledVector(dir, Math.random() * radius * 0.35);
          vel.copy(dir).multiplyScalar(spd);
        }

        const lifeMin = config.life?.[0] ?? 0.6;
        const lifeMax = config.life?.[1] ?? 1.4;

        return {
          origin: origin.clone(),
          pos,
          vel,
          orbitAngle,
          orbitRadius,
          orbitSpeed: config.orbitSpeed ?? 0,
          radialRate: config.radialRate ?? -0.25,
          gravity: config.gravity ?? 0,
          drag: config.drag ?? 0.98,
          delay: config.stagger ? (index / total) * config.stagger : (config.delay ?? 0) * Math.random(),
          age: 0,
          maxLife: THREE.MathUtils.lerp(lifeMin, lifeMax, Math.random()),
          sizeStart: THREE.MathUtils.lerp(config.size?.[0] ?? 0.6, config.size?.[1] ?? 1.4, Math.random()),
          colorStart: new THREE.Color(config.colorStart || '#ffffff'),
          colorMid: config.colorMid ? new THREE.Color(config.colorMid) : null,
          colorEnd: new THREE.Color(config.colorEnd || config.colorStart || '#ffffff'),
          angle: Math.random() * Math.PI * 2,
          spin: (Math.random() - 0.5) * (config.spin ?? 4.0)
        };
      }


  spawnAnimatedMesh(mesh, duration, onUpdate, delay = 0) {
    mesh.visible = delay <= 0; this.scene.add(mesh);
    this.meshes.push({mesh, duration, onUpdate, delay, age: 0}); return mesh;
  }
  update(dt) {
    this.scene.updateMatrixWorld(true); this.batch.update(dt);
    this.activeParticlesCount = 0;
    for (let i = this.systems.length - 1; i >= 0; --i) {
      const s = this.systems[i]; this.activeParticlesCount += s.particleNum;
      if (s.emissionState.time > .02 && s.particleNum === 0) {
        this.batch.deleteSystem(s); s.dispose(); this.systems.splice(i, 1);
      }
    }
    for (const item of [...this.meshes]) {
      item.age += dt;
      if (item.age < item.delay) continue;
      item.mesh.visible = true;
      const activeDt = Math.min(item.age - item.delay, dt);
      item.onUpdate?.(Math.min(1, (item.age - item.delay) / item.duration), item.mesh, activeDt);
      if (item.age >= item.delay + item.duration) {
        item.mesh.removeFromParent(); disposeTree(item.mesh);
        this.meshes.splice(this.meshes.indexOf(item), 1);
      }
    }
  }
  dispose() {
    for (const s of this.systems) { this.batch.deleteSystem(s); s.dispose(); }
    disposeTree(this.batch); this.batch.removeFromParent();
    for (const m of this.materials.values()) m.dispose();
    this.systems.length = 0;
  }
}

function disposeTree(root) {
  const geometries = new Set(), materials = new Set();
  root.traverse(o => { if (o.geometry) geometries.add(o.geometry);
    if (o.material) (Array.isArray(o.material) ? o.material : [o.material]).forEach(m => materials.add(m)); });
  geometries.forEach(g => g.dispose()); materials.forEach(m => m.dispose());
}

// One owner for event time. Split a step exactly at each pending event boundary.
class Timeline {
  constructor() { this.time = 0; this.queue = []; this.nextId = 0; }
  after(ms, fn) { this.queue.push({time: this.time + ms / 1000, fn, id: this.nextId++}); }
  advance(dt, draw) {
    const end = this.time + dt;
    while (true) {
      this.queue.sort((a, b) => a.time - b.time || a.id - b.id);
      const event = this.queue[0];
      if (!event || event.time > end + 1e-9) break;
      const step = Math.max(0, event.time - this.time);
      if (step > 1e-9) draw(step);
      this.time = event.time; this.queue.shift(); event.fn();
    }
    const tail = end - this.time; if (tail > 1e-9) draw(tail); this.time = end;
  }
}
    const container = document.getElementById('canvas-container');
    const scene = new THREE.Scene();
    const BASE_BG_COLOR = new THREE.Color('#061a28');
    scene.background = BASE_BG_COLOR.clone();
    scene.fog = new THREE.FogExp2('#061a28', 0.0195);

    const camera = new THREE.PerspectiveCamera(43, window.innerWidth / window.innerHeight, 0.1, 200);
    const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.0;
    container.appendChild(renderer.domElement);

    // Safe Post-Processing Setup
    let composer = null;
    try {
      composer = new EffectComposer(renderer);
      const renderPass = new RenderPass(scene, camera);
      composer.addPass(renderPass);
      const bloomPass = new UnrealBloomPass(
        new THREE.Vector2(window.innerWidth, window.innerHeight),
        0.30,
        0.32,
        0.95
      );
      composer.addPass(bloomPass);
      composer.addPass(new OutputPass());
    } catch (err) {
      composer = null;
    }

    const worldScene = scene;

    // Arena Lighting
    const ambientLight = new THREE.AmbientLight('#5689a8', 1.35);
    scene.add(ambientLight);

    const dirLight = new THREE.DirectionalLight('#cbeeff', 1.75);
    dirLight.position.set(-10, 22, 14);
    dirLight.castShadow = true;
    dirLight.shadow.mapSize.width = 2048;
    dirLight.shadow.mapSize.height = 2048;
    dirLight.shadow.camera.near = 1;
    dirLight.shadow.camera.far = 65;
    const d = 18;
    dirLight.shadow.camera.left = -d;
    dirLight.shadow.camera.right = d;
    dirLight.shadow.camera.top = d;
    dirLight.shadow.camera.bottom = -d;
    scene.add(dirLight);

    // Dynamic FX PointLight
    const fxLight = new THREE.PointLight('#00ff9d', 0, 28);
    fxLight.position.set(0, 4, 0);
    scene.add(fxLight);

    // Tactical Grid Floor (1:1 Match with Screenshot)
    function createArenaGridTexture() {
      const canvas = document.createElement('canvas');
      canvas.width = 1024;
      canvas.height = 1024;
      const ctx = canvas.getContext('2d');
      const subCells = 8;
      const subSize = 1024 / subCells;

      for (let y = 0; y < subCells; y++) {
        for (let x = 0; x < subCells; x++) {
          ctx.fillStyle = (x + y) % 2 === 0 ? '#0d2232' : '#122c3f';
          ctx.fillRect(x * subSize, y * subSize, subSize, subSize);

          ctx.fillStyle = 'rgba(45, 226, 230, 0.22)';
          ctx.beginPath();
          ctx.arc((x + 0.5) * subSize, (y + 0.5) * subSize, 2.2, 0, Math.PI * 2);
          ctx.fill();
        }
      }

      ctx.strokeStyle = '#2de2e6';
      ctx.lineWidth = 10;
      ctx.strokeRect(0, 0, 1024, 1024);

      ctx.strokeStyle = 'rgba(45, 226, 230, 0.25)';
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(512, 0); ctx.lineTo(512, 1024);
      ctx.moveTo(0, 512); ctx.lineTo(1024, 512);
      ctx.stroke();

      const texture = new THREE.CanvasTexture(canvas);
      texture.wrapS = THREE.RepeatWrapping;
      texture.wrapT = THREE.RepeatWrapping;
      texture.repeat.set(12, 12);
      texture.anisotropy = 8;
      return texture;
    }

    const floorMesh = new THREE.Mesh(
      new THREE.PlaneGeometry(72, 72),
      new THREE.MeshStandardMaterial({
        map: createArenaGridTexture(),
        roughness: 0.72,
        metalness: 0.18
      })
    );
    floorMesh.rotation.x = -Math.PI / 2;
    floorMesh.receiveShadow = true;
    scene.add(floorMesh);

    // Perimeter Monoliths & Sky Motes
    const monolithGroup = new THREE.Group();
    scene.add(monolithGroup);

    const pillarMat = new THREE.MeshStandardMaterial({ color: '#0b1e2d', roughness: 0.85, metalness: 0.15 });
    const orbMat = new THREE.MeshBasicMaterial({ color: '#fff3d1' });
    const floatingCubes = [];

    [
      [-18, -8, 12], [-12, -16, 10], [-7, -21, 9], [-2, -23, 8.5],
      [4, -24, 8], [10, -22, 9.5], [15, -18, 11], [20, -14, 10.5],
      [24, -9, 7], [-22, 2, 13], [-25, -14, 15], [27, -20, 13],
      [-15, -26, 11], [0, -29, 12], [18, -27, 11]
    ].forEach(([px, pz, h], idx) => {
      const pGroup = new THREE.Group();
      pGroup.position.set(px, 0, pz);
      const w = 1.65 + (idx % 3) * 0.35;
      const body = new THREE.Mesh(new THREE.BoxGeometry(w, h, w), pillarMat);
      body.position.y = h / 2;
      pGroup.add(body);

      const roofH = 1.45;
      const roofGeo = new THREE.ConeGeometry(w * 0.72, roofH, 4);
      roofGeo.rotateY(Math.PI / 4);
      const roof = new THREE.Mesh(roofGeo, pillarMat);
      roof.position.y = h + roofH / 2;
      pGroup.add(roof);

      const orb = new THREE.Mesh(new THREE.SphereGeometry(0.19, 12, 12), orbMat);
      orb.position.y = h + roofH + 0.22;
      pGroup.add(orb);

      monolithGroup.add(pGroup);
    });

    for (let i = 0; i < 18; i++) {
      const size = 0.45 + Math.random() * 0.75;
      const cube = new THREE.Mesh(new THREE.BoxGeometry(size, size, size), pillarMat);
      cube.position.set((Math.random() - 0.5) * 48, 3 + Math.random() * 11, -12 - Math.random() * 22);
      cube.rotation.set(Math.random() * 2, Math.random() * 2, Math.random() * 2);
      scene.add(cube);
      floatingCubes.push({
        mesh: cube,
        baseY: cube.position.y,
        speed: 0.6 + Math.random() * 1.2,
        phase: Math.random() * Math.PI * 2
      });
    }

    const bgSlit = new THREE.Mesh(
      new THREE.PlaneGeometry(0.18, 3.4),
      new THREE.MeshBasicMaterial({ color: '#ff6b4a', transparent: true, opacity: 0.75, side: THREE.DoubleSide })
    );
    bgSlit.position.set(-0.6, 3.2, -24);
    scene.add(bgSlit);

    const skyMotesGeo = new THREE.BufferGeometry();
    const motePos = new Float32Array(90 * 3);
    for (let i = 0; i < 90; i++) {
      motePos[i * 3] = (Math.random() - 0.5) * 55;
      motePos[i * 3 + 1] = 1.5 + Math.random() * 18;
      motePos[i * 3 + 2] = -35 + Math.random() * 45;
    }
    skyMotesGeo.setAttribute('position', new THREE.BufferAttribute(motePos, 3));
    scene.add(new THREE.Points(skyMotesGeo, new THREE.PointsMaterial({ color: '#d7f7ff', size: 0.22, transparent: true, opacity: 0.7 })));

    // =========================================================================
    // 5. ARTICULATED 3D MONSTER BUILDERS (ABRA, PANCHAM, GIBLE)
    // =========================================================================
    const ALLY_SLOTS = {
      '-1': new THREE.Vector3(-2.35, 0, 3.85), // ABRA (Foreground Left)
      '+1': new THREE.Vector3(3.15, 0, 3.35)   // PANCHAM (Foreground Right)
    };

    const ENEMY_SLOTS = {
      '-2': new THREE.Vector3(-4.2, 0, -6.2),  // Extra Gible Alpha
      '0':  new THREE.Vector3(1.85, 0, -6.8),  // Main GIBLE
      '+2': new THREE.Vector3(7.4, 0, -6.2)    // Extra Gible Beta
    };

    function createAbraModel() {
      const root = new THREE.Group();
      const bodyGroup = new THREE.Group();
      root.add(bodyGroup);

      const yellowMat = new THREE.MeshStandardMaterial({ color: '#c9b428', roughness: 0.55, metalness: 0.1 });
      const armorMat = new THREE.MeshStandardMaterial({ color: '#4c4637', roughness: 0.65, metalness: 0.2 });
      const darkStripeMat = new THREE.MeshStandardMaterial({ color: '#2e2b22', roughness: 0.7 });

      const torso = new THREE.Mesh(new THREE.CylinderGeometry(0.38, 0.46, 0.95, 10), yellowMat);
      torso.position.y = 1.05;
      torso.castShadow = true;
      bodyGroup.add(torso);

      const leftPad = new THREE.Mesh(new THREE.SphereGeometry(0.36, 10, 10), armorMat);
      leftPad.scale.set(1.15, 0.65, 1.05);
      leftPad.position.set(-0.42, 1.38, 0.05);
      leftPad.rotation.z = 0.35;
      bodyGroup.add(leftPad);

      const rightPad = new THREE.Mesh(new THREE.SphereGeometry(0.36, 10, 10), armorMat);
      rightPad.scale.set(1.15, 0.65, 1.05);
      rightPad.position.set(0.42, 1.38, 0.05);
      rightPad.rotation.z = -0.35;
      bodyGroup.add(rightPad);

      const backPlate = new THREE.Mesh(new THREE.BoxGeometry(0.55, 0.45, 0.35), armorMat);
      backPlate.position.set(0, 1.32, 0.14);
      bodyGroup.add(backPlate);

      const head = new THREE.Mesh(new THREE.ConeGeometry(0.52, 0.75, 6), yellowMat);
      head.rotation.x = Math.PI / 2 + 0.2;
      head.position.set(0, 1.82, -0.1);
      bodyGroup.add(head);

      const earGeo = new THREE.ConeGeometry(0.2, 0.55, 4);
      const leftEar = new THREE.Mesh(earGeo, yellowMat);
      leftEar.position.set(-0.32, 2.22, 0.05);
      leftEar.rotation.set(-0.2, 0, 0.38);
      bodyGroup.add(leftEar);

      const rightEar = new THREE.Mesh(earGeo, yellowMat);
      rightEar.position.set(0.32, 2.22, 0.05);
      rightEar.rotation.set(-0.2, 0, -0.38);
      bodyGroup.add(rightEar);

      const tailGroup = new THREE.Group();
      tailGroup.position.set(0, 0.72, 0.25);
      bodyGroup.add(tailGroup);

      const tailSeg1 = new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.36, 0.85, 10), yellowMat);
      tailSeg1.position.set(-0.22, 0.1, 0.38);
      tailSeg1.rotation.set(0.85, -0.35, 0.45);
      tailGroup.add(tailSeg1);

      const tailBand = new THREE.Mesh(new THREE.CylinderGeometry(0.31, 0.33, 0.24, 10), darkStripeMat);
      tailBand.position.set(-0.42, 0.42, 0.62);
      tailBand.rotation.set(0.45, -0.35, 0.65);
      tailGroup.add(tailBand);

      const tailTip = new THREE.Mesh(new THREE.ConeGeometry(0.3, 0.95, 10), yellowMat);
      tailTip.position.set(-0.56, 0.92, 0.68);
      tailTip.rotation.set(-0.15, 0, 0.35);
      tailGroup.add(tailTip);

      const leftLeg = new THREE.Mesh(new THREE.CylinderGeometry(0.14, 0.12, 0.65, 8), yellowMat);
      leftLeg.position.set(-0.35, 0.62, -0.15);
      leftLeg.rotation.set(0.5, 0, 0.3);
      bodyGroup.add(leftLeg);

      const rightLeg = new THREE.Mesh(new THREE.CylinderGeometry(0.14, 0.12, 0.65, 8), yellowMat);
      rightLeg.position.set(0.42, 0.65, 0.1);
      rightLeg.rotation.set(-0.4, 0.2, -0.5);
      bodyGroup.add(rightLeg);

      const leftArm = new THREE.Mesh(new THREE.CylinderGeometry(0.11, 0.1, 0.6, 8), yellowMat);
      leftArm.position.set(-0.48, 1.12, -0.22);
      leftArm.rotation.set(0.7, 0, 0.4);
      bodyGroup.add(leftArm);

      const rightArm = new THREE.Mesh(new THREE.CylinderGeometry(0.11, 0.1, 0.6, 8), yellowMat);
      rightArm.position.set(0.48, 1.12, -0.22);
      rightArm.rotation.set(0.7, 0, -0.4);
      bodyGroup.add(rightArm);

      return {
        root,
        bodyGroup,
        tailGroup,
        leftArm,
        rightArm,
        materials: [yellowMat, armorMat],
        castAnimTimer: 0
      };
    }

    function createPanchamModel() {
      const root = new THREE.Group();
      const bodyGroup = new THREE.Group();
      root.add(bodyGroup);

      const whiteMat = new THREE.MeshStandardMaterial({ color: '#dce4ec', roughness: 0.6 });
      const darkMat = new THREE.MeshStandardMaterial({ color: '#1e242d', roughness: 0.7 });
      const leafMat = new THREE.MeshStandardMaterial({ color: '#4cd137', roughness: 0.4 });

      const torso = new THREE.Mesh(new THREE.SphereGeometry(0.42, 12, 12), darkMat);
      torso.scale.set(1.0, 1.1, 0.92);
      torso.position.y = 0.62;
      torso.castShadow = true;
      bodyGroup.add(torso);

      const tail = new THREE.Mesh(new THREE.SphereGeometry(0.14, 8, 8), whiteMat);
      tail.position.set(0, 0.46, 0.38);
      bodyGroup.add(tail);

      const head = new THREE.Mesh(new THREE.SphereGeometry(0.48, 14, 14), whiteMat);
      head.position.set(0, 1.28, -0.04);
      head.castShadow = true;
      bodyGroup.add(head);

      const earGeo = new THREE.SphereGeometry(0.18, 10, 10);
      const leftEar = new THREE.Mesh(earGeo, darkMat);
      leftEar.position.set(-0.36, 1.66, 0);
      bodyGroup.add(leftEar);

      const rightEar = new THREE.Mesh(earGeo, darkMat);
      rightEar.position.set(0.36, 1.66, 0);
      bodyGroup.add(rightEar);

      const leaf = new THREE.Mesh(new THREE.ConeGeometry(0.08, 0.38, 4), leafMat);
      leaf.position.set(-0.46, 1.22, -0.22);
      leaf.rotation.set(0.3, 0, 1.25);
      bodyGroup.add(leaf);

      const leftArm = new THREE.Mesh(new THREE.CapsuleGeometry(0.12, 0.28, 4, 8), darkMat);
      leftArm.position.set(-0.46, 0.78, -0.1);
      leftArm.rotation.z = 0.5;
      bodyGroup.add(leftArm);

      const rightArm = new THREE.Mesh(new THREE.CapsuleGeometry(0.12, 0.28, 4, 8), darkMat);
      rightArm.position.set(0.46, 0.78, -0.1);
      rightArm.rotation.z = -0.5;
      bodyGroup.add(rightArm);

      return {
        root,
        bodyGroup,
        leftArm,
        rightArm,
        materials: [whiteMat, darkMat],
        customOverride: false
      };
    }

    function createGibleModel() {
      const root = new THREE.Group();
      const bodyGroup = new THREE.Group();
      root.add(bodyGroup);

      const blueSkinMat = new THREE.MeshStandardMaterial({ color: '#2d455e', roughness: 0.55, metalness: 0.15 });
      const redBellyMat = new THREE.MeshStandardMaterial({ color: '#c23b3b', roughness: 0.6 });
      const hornMat = new THREE.MeshStandardMaterial({ color: '#8fa6bd', roughness: 0.5 });

      const body = new THREE.Mesh(new THREE.SphereGeometry(0.68, 14, 14), blueSkinMat);
      body.scale.set(1.05, 1.12, 0.98);
      body.position.y = 0.86;
      body.castShadow = true;
      bodyGroup.add(body);

      const belly = new THREE.Mesh(new THREE.SphereGeometry(0.52, 12, 12), redBellyMat);
      belly.scale.set(0.85, 0.95, 0.6);
      belly.position.set(0, 0.76, 0.36);
      bodyGroup.add(belly);

      const fin = new THREE.Mesh(new THREE.ConeGeometry(0.28, 0.65, 4), blueSkinMat);
      fin.position.set(0, 1.65, -0.08);
      fin.rotation.x = -0.25;
      bodyGroup.add(fin);

      const hornGeo = new THREE.CylinderGeometry(0.14, 0.18, 0.52, 8);
      const leftHorn = new THREE.Mesh(hornGeo, hornMat);
      leftHorn.position.set(-0.56, 1.25, 0.05);
      leftHorn.rotation.z = Math.PI / 2 - 0.35;
      bodyGroup.add(leftHorn);

      const rightHorn = new THREE.Mesh(hornGeo, hornMat);
      rightHorn.position.set(0.56, 1.25, 0.05);
      rightHorn.rotation.z = -Math.PI / 2 + 0.35;
      bodyGroup.add(rightHorn);

      const eyeMat = new THREE.MeshBasicMaterial({ color: '#ffd32a' });
      const leftEye = new THREE.Mesh(new THREE.SphereGeometry(0.07, 8, 8), eyeMat);
      leftEye.position.set(-0.26, 1.06, 0.6);
      bodyGroup.add(leftEye);

      const rightEye = new THREE.Mesh(new THREE.SphereGeometry(0.07, 8, 8), eyeMat);
      rightEye.position.set(0.26, 1.06, 0.6);
      bodyGroup.add(rightEye);

      const leftFoot = new THREE.Mesh(new THREE.BoxGeometry(0.28, 0.25, 0.38), blueSkinMat);
      leftFoot.position.set(-0.35, 0.15, 0.1);
      bodyGroup.add(leftFoot);

      const rightFoot = new THREE.Mesh(new THREE.BoxGeometry(0.28, 0.25, 0.38), blueSkinMat);
      rightFoot.position.set(0.35, 0.15, 0.1);
      bodyGroup.add(rightFoot);

      return {
        root,
        bodyGroup,
        materials: [blueSkinMat, redBellyMat, hornMat],
        shudderTimer: 0,
        frozenTint: 0,
        burnTint: 0,
        knockupVelY: 0,
        knockupY: 0
      };
    }

    const abra = createAbraModel();
    abra.root.position.copy(ALLY_SLOTS['-1']);
    abra.root.lookAt(ENEMY_SLOTS['0']);
    scene.add(abra.root);

    const pancham = createPanchamModel();
    pancham.root.position.copy(ALLY_SLOTS['+1']);
    pancham.root.lookAt(ENEMY_SLOTS['0']);
    scene.add(pancham.root);

    const gibleMain = createGibleModel();
    gibleMain.root.position.copy(ENEMY_SLOTS['0']);
    gibleMain.root.lookAt(ALLY_SLOTS['-1']);
    scene.add(gibleMain.root);

    const gibleAlpha = createGibleModel();
    gibleAlpha.root.position.copy(ENEMY_SLOTS['-2']);
    gibleAlpha.root.lookAt(ALLY_SLOTS['-1']);
    gibleAlpha.root.visible = false;
    scene.add(gibleAlpha.root);

    const gibleBeta = createGibleModel();
    gibleBeta.root.position.copy(ENEMY_SLOTS['+2']);
    gibleBeta.root.lookAt(ALLY_SLOTS['+1']);
    gibleBeta.root.visible = false;
    scene.add(gibleBeta.root);

    // =========================================================================
const actors = [
  {name:'Abra', team:0, model:abra, maxHp:32},
  {name:'Pancham', team:0, model:pancham, maxHp:45},
  {name:'Gible', team:1, model:gibleMain, maxHp:60},
  {name:'Gible α', team:1, model:gibleAlpha, maxHp:34},
  {name:'Gible β', team:1, model:gibleBeta, maxHp:34}
].map((a,id) => {
  a.id=id; a.hp=a.maxHp; a.home=a.model.root.position.clone(); a.active=id<3;
  a.burnRemaining=0; a.burnTickAccum=0;
  Object.assign(a.model, {castAnimTimer:0, shudderTimer:0, frozenTint:0, burnTint:0, knockupVelY:0, knockupY:0, customOverride:false});
  a.model.materials=[]; a.model.root.traverse(o=>{if(o.isMesh){o.castShadow=true;o.receiveShadow=true;if(o.material?.emissive)a.model.materials.push(o.material);}});
  a.model.materials=[...new Set(a.model.materials)]; return a;
});
const state={speed:1, paused:false, selected:0, target:2, mode:'single', auto:false, autoIndex:0, autoTime:0, clones:false};
const timeline=new Timeline(); let current=null; const sessions=[];
const moveNames=['Media','Mabufula','Dig','Sand Attack','Dragon Rage','Splitter Flames','Psychic Cannon','Psycho Orb'];
const moveIds=['media','mabufula','dig','sand','dragon','splitter','psychic','psycho-orb'];
const $=id=>document.getElementById(id);
function measure(a) {
  a.model.root.updateWorldMatrix(true,true);
  const box=new THREE.Box3().setFromObject(a.model.root), size=box.getSize(new THREE.Vector3());
  return {height:size.y,radius:Math.max(size.x,size.z)*.5,center:box.getCenter(new THREE.Vector3()),foot:a.home.clone()};
}
function actorView(a,frame) {
  const root=new THREE.Object3D(); root.position.copy(frame.worldToLocal(a.model.root.position.clone()));
  root.quaternion.copy(frame.quaternion.clone().invert().multiply(a.model.root.quaternion)); root.visible=a.model.root.visible;
  return new Proxy(a.model,{get:(m,k)=>k==='root'?root:m[k],set:(m,k,v)=>{m[k]=v;return true;}});
}
function makeContext(id) {
  const attacker=actors[state.selected];
  let targets=[actors[state.target],...actors.filter(a=>a.id!==state.target&&a.id!==attacker.id&&a.team!==attacker.team&&a.active)];
  targets=targets.filter(a=>a&&a.active&&a.id!==attacker.id);
  if (!targets.length) return null;
  if(id===5&&state.mode!=='single'&&targets.length<2){setClones(true);targets=[actors[state.target],...actors.filter(a=>a.id!==state.target&&a.id!==attacker.id&&a.team!==attacker.team&&a.active)];}
  if(id===5&&state.mode!=='single'&&targets.length<2) return null;
  // Selection is a fixture concern; effect transforms know only participants.
  const companion=actors.find(a=>a!==attacker&&a.active&&a.team===attacker.team)||attacker;
  const frame=new THREE.Group();
  frame.position.copy(attacker.home);
  const backward=attacker.home.clone().sub(targets[0].home); backward.y=0; backward.normalize();
  frame.quaternion.setFromRotationMatrix(new THREE.Matrix4().makeBasis(new THREE.Vector3(0,1,0).cross(backward).normalize(),new THREE.Vector3(0,1,0),backward));
  // D-334: rigid frame only. Participant bounds locate sockets, never scale VFX.
  scene.add(frame); frame.updateMatrixWorld(true);
  const c={id,attacker,companion,targets,frame,done:false,start:timeline.time,views:new Map(),mode:state.mode};
  for(const a of new Set([attacker,companion,...targets])) c.views.set(a,actorView(a,frame));
  c.view=a=>c.views.get(a); c.point=a=>frame.worldToLocal(a.home.clone());
  c.center=a=>frame.worldToLocal(measure(a).center.clone());
  c.height=a=>measure(a).height/frame.scale.x;
  c.radius=a=>measure(a).radius/frame.scale.x;
  c.socket=(side=0,height=.62,forward=.9)=>c.point(attacker).add(new THREE.Vector3(side*c.radius(attacker),height*c.height(attacker),-forward*c.radius(attacker)));
  c.vfx=new AtelierParticles(frame); c.light=new THREE.PointLight(0xffffff,0,18);frame.add(c.light);
  c.roles=[targets[0],targets[1]||targets[0],targets[2]||targets[1]||targets[0]].map((a,i)=>({
    id:i, name:a.name, model:c.view(a), slotPos:c.point(a), maxHp:a.maxHp,
    get hp(){return a.hp;},set hp(v){a.hp=v;},get active(){return i===0 || (targets.length>=3 ? true : targets.length>=2&&i===2);},
    get burnRemaining(){return a.burnRemaining;},set burnRemaining(v){a.burnRemaining=v;},
    get burnTickAccum(){return a.burnTickAccum;},set burnTickAccum(v){a.burnTickAccum=v;}
  }));
  // Dual mode addresses roles 1 and 2. Use two distinct real participants.
  if(targets.length===2 && id===5 && c.mode!=='single') c.roles[1]=roleFor(targets[0],1,c);
  c.combat={enemies:c.roles, extraClonesActive:targets.length>1, splitterMode:c.mode, timeScale:1,
    get isCasting(){return c.started&&!c.done;},set isCasting(v){if(v)c.started=true;else c.done=true;},
    get abraHp(){return attacker.hp;},set abraHp(v){attacker.hp=v;},abraMaxHp:attacker.maxHp,
    get panchamHp(){return companion.hp;},set panchamHp(v){if(companion!==attacker)companion.hp=v;},panchamMaxHp:companion.maxHp};
  return c;
}
function roleFor(a,id,c){return {id,name:a.name,model:c.view(a),slotPos:c.point(a),maxHp:a.maxHp,active:true,
  get hp(){return a.hp;},set hp(v){a.hp=v;},get burnRemaining(){return a.burnRemaining;},set burnRemaining(v){a.burnRemaining=v;},get burnTickAccum(){return a.burnTickAccum;},set burnTickAccum(v){a.burnTickAccum=v;}};}
function cast(id){
  if(current || state.paused) return false;
  const c=makeContext(id); if(!c)return false;
  current=c;sessions.push(c); c.moves=createMoves(c);c.moves[id]();updateHUD();return true;
}
function setClones(on){if(current)return;state.clones=on;for(const a of actors.slice(3)){a.active=on;a.model.root.visible=on;}refreshSelectors();updateHUD();}
function updateHUD(){
  for(let i=0;i<3;i++){
    const a=current?.targets[i]||actors[i+2], hud=$(`enemy-hud-${i}`);hud.style.display=a?.active?'flex':'none';
    if(!a)continue;
    hud.querySelector('[data-name]').textContent=a.name;
    $(`enemy-${i}-hp-bar`).style.width=`${100*a.hp/a.maxHp}%`;
    if(i===0)$('enemy-0-hp-ghost').style.width=`${100*a.hp/a.maxHp}%`;
    $(`enemy-${i}-hp-text`).textContent=`HP ${a.hp} / ${a.maxHp}`;
    const pill=$(`enemy-${i}-burn-pill`);pill.classList.toggle('hidden',a.burnRemaining<=0);
    $(`enemy-${i}-burn-text`).textContent=`BURN ${a.burnRemaining.toFixed(1)}s`;
  }
  const allies=[current?.attacker||actors[state.selected],current?.companion||actors.find(a=>a.team===actors[state.selected].team&&a.id!==state.selected)||actors[state.selected]];
  allies.forEach((a,i)=>{const p=i?'pancham':'abra';$(`${p}-hp-bar`).style.width=`${100*a.hp/a.maxHp}%`;$(`${p}-hp-text`).textContent=`HP ${a.hp}/${a.maxHp}`;$(`${p}-name`).textContent=a.name;});
  $('clones-state-text').textContent=state.clones?'ON':'OFF';
  document.querySelectorAll('.skill-btn').forEach(b=>b.disabled=!!current);
  for(const id of ['actor-select','target-select','target-size','btn-toggle-clones','btn-mirror'])$(id).disabled=!!current;
}
function refreshSelectors(){
  const fill=(id,list,val)=>{$(id).replaceChildren(...list.map(a=>{const o=document.createElement('option');o.value=a.id;o.textContent=a.name;return o;}));$(id).value=val;};
  fill('actor-select',actors.filter(a=>a.active),state.selected);
  const eligible=actors.filter(a=>a.active&&a.id!==state.selected);
  if(!eligible.some(a=>a.id===state.target))state.target=eligible[0].id;
  fill('target-select',eligible,state.target);
}
function setCamera(mode='cinema'){
  scene.updateMatrixWorld(true);
  const bounds=new THREE.Box3();actors.filter(a=>a.active).forEach(a=>bounds.union(new THREE.Box3().setFromObject(a.model.root)));
  const center=bounds.getCenter(new THREE.Vector3()),size=bounds.getSize(new THREE.Vector3());
  const axis=actors[state.selected].home.clone().sub(actors[state.target].home).setY(0).normalize();
  const side=new THREE.Vector3(0,1,0).cross(axis);
  const radius=Math.max(size.length()*.53,1), fov=mode==='tatica'?46:43;
  const v=THREE.MathUtils.degToRad(fov/2),h=Math.atan(Math.tan(v)*camera.aspect);
  const dist=radius/Math.sin(Math.min(v,h)) * 1.1;
  const direction=axis.clone().multiplyScalar(mode==='tatica'?.65:1).addScaledVector(side,mode==='impacto'?.38:.08).add(new THREE.Vector3(0,mode==='tatica'?1.3:.32,0)).normalize();
  camera.position.copy(center).addScaledVector(direction,dist);camera.fov=fov;camera.updateProjectionMatrix();camera.lookAt(center);
  state.camera=mode;document.querySelectorAll('.cam-btn').forEach(b=>b.classList.toggle('active',b.dataset.cam===mode));
}
function step(dt){
  timeline.advance(dt,delta=>{
    for(const s of sessions){s.vfx.update(delta);if(!s.done){for(const [a,m]of s.views){a.model.root.position.copy(s.frame.localToWorld(m.root.position.clone()));a.model.root.quaternion.copy(s.frame.quaternion).multiply(m.root.quaternion);a.model.root.visible=m.root.visible;}}}
    for(const a of actors){
      const m=a.model;
      if(a.burnRemaining>0){const active=Math.min(delta,a.burnRemaining);a.burnRemaining=Math.max(0,a.burnRemaining-delta);a.burnTickAccum+=active;
        while(a.burnTickAccum+1e-8>=1){a.burnTickAccum-=1;if(a.hp>0)a.hp=Math.max(0,a.hp-2);}if(a.burnRemaining===0)m.burnTint=0;}
      m.castAnimTimer=Math.max(0,m.castAnimTimer-delta);m.shudderTimer=Math.max(0,m.shudderTimer-delta);
      if(m.knockupY>0||m.knockupVelY!==0){m.knockupY+=m.knockupVelY*delta;m.knockupVelY-=22*delta;if(m.knockupY<=0){m.knockupY=0;m.knockupVelY=0;}}
      if(!m.customOverride){m.bodyGroup.position.set(m.shudderTimer>0?Math.sin(timeline.time*90)*.1:0,m.knockupY+Math.sin(timeline.time*2.8+a.id)*.04,0);}
      for(const mat of m.materials){if(m.frozenTint){mat.emissive.set('#00a8ff');mat.emissiveIntensity=.35;}else if(m.burnTint){mat.emissive.set('#ff5722');mat.emissiveIntensity=.25;}else mat.emissiveIntensity=0;}
    }
  });
  if(current?.done){current.attacker.model.root.position.copy(current.attacker.home);current=null;updateHUD();}
  for(let i=sessions.length-1;i>=0;i--){const s=sessions[i];if(s.done&&timeline.time-s.start>8){s.vfx.dispose();disposeTree(s.frame);s.frame.removeFromParent();sessions.splice(i,1);}}
  if(state.auto&&!current){state.autoTime+=dt;if(state.autoTime>1.25){state.autoTime=0;cast(state.autoIndex++%8);}}
}
moveIds.forEach((id,i)=>$(`btn-cast-${id}`).onclick=()=>cast(i));
document.querySelectorAll('.speed-btn').forEach(b=>b.onclick=()=>{state.speed=Number(b.dataset.speed);document.querySelectorAll('.speed-btn').forEach(x=>x.style.color=x===b?'#d8ff00':'#8294a3');});
document.querySelectorAll('.splitter-mode-btn').forEach(b=>b.onclick=()=>{if(current)return;state.mode=b.dataset.sfmode;document.querySelectorAll('.splitter-mode-btn').forEach(x=>x.classList.toggle('active',x===b));if(state.mode!=='single')setClones(true);});
document.querySelectorAll('.cam-btn').forEach(b=>b.onclick=()=>setCamera(b.dataset.cam));
$('actor-select').onchange=e=>{state.selected=Number(e.target.value);refreshSelectors();updateHUD();};
$('target-select').onchange=e=>{state.target=Number(e.target.value);};
$('target-size').onchange=e=>{actors[state.target].model.root.scale.setScalar(Number(e.target.value));setCamera(state.camera);};
$('btn-mirror').onclick=()=>{[state.selected,state.target]=[state.target,state.selected];refreshSelectors();updateHUD();};
$('btn-pause').onclick=()=>{state.paused=!state.paused;$('btn-pause').textContent=state.paused?'▶ Continuar':'Ⅱ Pausar';};
$('btn-toggle-clones').onclick=()=>setClones(!state.clones);
$('btn-sim-damage').onclick=()=>{actors.filter(a=>a.team===actors[state.selected].team).forEach(a=>a.hp=Math.floor(a.maxHp*.4));updateHUD();};
$('btn-auto-loop').onclick=()=>{state.auto=!state.auto;$('loop-state-text').textContent=state.auto?'ON':'OFF';};
$('btn-toggle-sfx').onclick=()=>{sfx.enabled=!sfx.enabled;$('sfx-state-text').textContent=sfx.enabled?'ON':'MUTE';};
window.addEventListener('keydown',e=>{if(e.repeat||/INPUT|SELECT|TEXTAREA/.test(e.target.tagName))return;if(/^[1-8]$/.test(e.key))cast(Number(e.key)-1);if(e.key.toLowerCase()==='c'){const modes=['cinema','tatica','impacto'];setCamera(modes[(modes.indexOf(state.camera)+1)%3]);}});
window.addEventListener('resize',()=>{camera.aspect=innerWidth/innerHeight;renderer.setSize(innerWidth,innerHeight);composer?.setSize(innerWidth,innerHeight);setCamera(state.camera);});
function projectHUD(){for(let i=0;i<3;i++){const a=current?.targets[i]||actors[i+2];if(!a?.active)continue;const pt=measure(a).center;pt.y+=measure(a).height*.6;pt.project(camera);const hud=$(`enemy-hud-${i}`);hud.style.left=`${(pt.x*.5+.5)*innerWidth}px`;hud.style.top=`${(-pt.y*.5+.5)*innerHeight}px`;hud.style.opacity=pt.z<1&&pt.z>-1?'1':'0';}}
let last=null,accumulator=0;
function advanceReal(raw){
  if(state.paused || !Number.isFinite(raw) || raw<=0)return;
  accumulator+=raw*state.speed;
  while(accumulator>=1/120){step(1/120);accumulator-=1/120;}
}
function render(now){requestAnimationFrame(render);const raw=last===null?0:Math.max(0,Math.min((now-last)/1000,.1));last=now;
  advanceReal(raw);
  updateHUD();projectHUD();
  $('particle-count-readout').textContent=`${sessions.reduce((n,s)=>n+s.vfx.activeParticlesCount,0)} PTCL · QUARKS.JS`;
  if(composer)composer.render();else renderer.render(scene,camera);
}
refreshSelectors();updateHUD();setCamera();requestAnimationFrame(render);
// Deterministic stepping and observations for the regression harness.
window.atelier={cast,step,advanceReal,actors,state,timeline,renderer,get current(){return current;},get sessions(){return sessions;},select(a,t){if(current)throw Error('busy');state.selected=a;state.target=t;refreshSelectors();},setClones,setCamera};

function createMoves(context) {
  const scene={add:(...objects)=>context.frame.add(...objects),remove:(...objects)=>{for(const o of objects){o.removeFromParent();disposeTree(o);}}}, vfx=context.vfx, fxLight=context.light;
  // Historical names below are role aliases; any model can occupy either role.
  const abra=context.view(context.attacker);
  const pancham=context.view(context.id===0 ? context.companion : context.attacker);
  const gibleMain=context.roles[0].model, gibleAlpha=context.roles[1].model, gibleBeta=context.roles[2].model;
  const combatState=context.combat;
  const ALLY_SLOTS={'-1':context.point(context.attacker),'+1':context.point(context.id===0?context.companion:context.attacker)};
  const ENEMY_SLOTS={'0':context.roles[0].slotPos,'-2':context.roles[1].slotPos,'+2':context.roles[2].slotPos};
  const setTimeout=(fn,ms)=>timeline.after(ms,fn);
  const updateAllHUDs=updateHUD;
  const setExtraClonesEnabled=()=>{};
  function applyBurnStatus(target){target.burnRemaining=4;target.burnTickAccum=0;target.model.burnTint=1;}
    function showSkillBanner(title, subtitle, accentHex) {
      const banner = document.getElementById('skill-cast-banner');
      banner.className = 'block';
      banner.innerHTML = `
        <div class="bg-[#071420]/95 border-l-4 px-5 py-2 shadow-2xl flex items-center gap-3" style="border-color: ${accentHex}; box-shadow: 0 8px 30px ${accentHex}33;">
          <div class="nocturne-unskew">
            <div class="text-[9px] font-mono-tech uppercase tracking-widest" style="color: ${accentHex}">${subtitle}</div>
            <div class="font-display font-black text-xl tracking-wider text-white uppercase">${title}</div>
          </div>
        </div>
      `;
      setTimeout(() => {
        banner.className = 'hidden';
      }, 2550);
    }

    function setElementalVignette(colorRgba, opacity = 1) {
      const vig = document.getElementById('elemental-vignette');
      if (opacity <= 0) {
        vig.style.opacity = '0';
        return;
      }
      vig.style.background = `radial-gradient(circle at 50% 50%, transparent 48%, ${colorRgba} 100%)`;
      vig.style.opacity = String(opacity * .35);
    }

    function spawnWorldPopup(worldPos, label, sublabel, theme = 'heal') {
      const container = document.getElementById('popups-container');
      const el = document.createElement('div');
      el.className = 'combat-popup';
      el.style.animation = 'none';

      const proj = context.frame.localToWorld(worldPos.clone());
      proj.y += 2.25;
      proj.project(camera);

      const x = (proj.x * 0.5 + 0.5) * window.innerWidth;
      const y = (-(proj.y * 0.5) + 0.5) * window.innerHeight;

      el.style.left = `${x}px`;
      el.style.top = `${y}px`;

      const palettes = {
        heal:    { bg: '#06291f', border: '#00ff9d', sub: '#d8ff00', main: '#00ff9d' },
        ice:     { bg: '#091e32', border: '#2de2e6', sub: '#d8ff00', main: '#6be8ff' },
        earth:   { bg: '#2b1806', border: '#f59e0b', sub: '#fde047', main: '#fbbf24' },
        sand:    { bg: '#261f06', border: '#eab308', sub: '#fef08a', main: '#facc15' },
        dragon:  { bg: '#3b0416', border: '#ff0055', sub: '#ffb3c6', main: '#ff2a70' },
        psychic: { bg: '#1d0d36', border: '#a855f7', sub: '#38bdf8', main: '#e9d5ff' },
        psycho:  { bg: '#380622', border: '#f472b6', sub: '#ffd6eb', main: '#ff66b8' },
        fire:    { bg: '#300f07', border: '#ff5722', sub: '#ffca28', main: '#ff8a65' }
      };
      const pal = palettes[theme] || palettes.heal;

      el.innerHTML = `
        <div class="px-3.5 py-1 border-l-4 shadow-2xl" style="background:${pal.bg}f2; border-color:${pal.border}; box-shadow: 0 0 22px ${pal.border}66;">
          <div class="text-[9.5px] font-mono-tech font-extrabold tracking-widest uppercase" style="color:${pal.sub}">${sublabel}</div>
          <div class="font-display font-black text-2xl leading-none" style="color:${pal.main}">${label}</div>
        </div>
      `;

      container.appendChild(el);
      setTimeout(() => el.remove(), 1700);
    }

    function triggerScreenFlash(colorHex, opacity = 0.35, durationMs = 130) {
      const flash = document.getElementById('screen-flash');
      flash.style.backgroundColor = colorHex;
      flash.style.opacity = String(opacity * .35);
      setTimeout(() => {
        flash.style.opacity = '0';
      }, durationMs);
    }

    function spawnSacredHealCircle(centerPos, radius = 3.2, duration = 2.4) {
      const geo = new THREE.PlaneGeometry(radius * 2, radius * 2);
      const mat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uProgress: { value: 0 },
          uColorPrimary: { value: new THREE.Color('#00ff9d') },
          uColorSecondary: { value: new THREE.Color('#d8ff00') }
        },
        vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = uv * 2.0 - 1.0;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `${noiseGLSL}

          uniform float uTime;
          uniform float uProgress;
          uniform vec3 uColorPrimary;
          uniform vec3 uColorSecondary;
          varying vec2 vUv;
          void main() {
            float r = length(vUv);
            if (r > 1.0) discard;
            float angle = atan(vUv.y, vUv.x);
            float ring1 = (1.0 - smoothstep(0.0, 0.035,  abs(r - 0.92)));
            float ring2 = (1.0 - smoothstep(0.0, 0.025,  abs(r - 0.76)));
            float ring3 = (1.0 - smoothstep(0.0, 0.02,  abs(r - 0.45)));
            float runeBand = step(0.77, r) * step(r, 0.90);
            float runes = step(0.2, sin(angle * 16.0 + uTime * 3.5)) * runeBand * 0.75;
            float starWave = abs(cos(angle * 4.0 - uTime * 2.0)) * 0.28 + 0.46;
            float starLine = (1.0 - smoothstep(0.0, 0.028,  abs(r - starWave)));
            float rippleRadius = fract(uTime * 0.85);
            float ripple = (1.0 - smoothstep(0.0, 0.06,  abs(r - rippleRadius))) * (1.0 - rippleRadius);
            float pattern = ring1 + ring2 + ring3 + runes + starLine + ripple * 0.8;
            float softGlow = (1.0 - r) * 0.25;
            vec3 col = mix(uColorPrimary, uColorSecondary, starLine + runes);
            float fade = sin(clamp(uProgress * 3.14159, 0.0, 3.14159));
            float scaleIn = smoothstep(0.0, 0.18, uProgress);
            gl_FragColor = vec4(col * (pattern * 1.6 + softGlow), (pattern + softGlow) * fade * scaleIn);
          
            float detailNoise = snoise(vec3(vUv * vec2(4.0, 7.0), uTime * .7));
            gl_FragColor.rgb *= .9 + .18 * detailNoise;
            gl_FragColor.a *= .6 + .4 * smoothstep(-.6, .4, detailNoise);
}
        `,
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide
      });

      const mesh = new THREE.Mesh(geo, mat);
      mesh.rotation.x = -Math.PI / 2;
      mesh.position.copy(centerPos);
      mesh.position.y = 0.04;

      vfx.spawnAnimatedMesh(mesh, duration, (progress, m, dt) => {
        mat.uniforms.uTime.value += dt;
        mat.uniforms.uProgress.value = progress;
        const s = progress < 0.2 ? THREE.MathUtils.lerp(0.2, 1.0, progress / 0.2) : 1.0;
        m.scale.setScalar(s);
      });
    }

    function spawnVolumetricHealPillar(targetPos, duration = 1.85, delay = 0.35) {
      const geo = new THREE.CylinderGeometry(1.25, 1.45, 7.5, 32, 1, true);
      const mat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uProgress: { value: 0 },
          uColorBottom: { value: new THREE.Color('#00ff9d') },
          uColorTop: { value: new THREE.Color('#d8ff00') }
        },
        vertexShader: `
          varying vec2 vUv;
          varying vec3 vNormal;
          varying vec3 vViewDir;
          void main() {
            vUv = uv;
            vec4 mvPos = modelViewMatrix * vec4(position, 1.0);
            vNormal = normalize(normalMatrix * normal);
            vViewDir = normalize(-mvPos.xyz);
            gl_Position = projectionMatrix * mvPos;
          }
        `,
        fragmentShader: `${noiseGLSL}

          uniform float uTime;
          uniform float uProgress;
          uniform vec3 uColorBottom;
          uniform vec3 uColorTop;
          varying vec2 vUv;
          varying vec3 vNormal;
          varying vec3 vViewDir;
          void main() {
            float vFade = pow(1.0 - vUv.y, 1.65) * smoothstep(0.0, 0.08, vUv.y);
            float fresnel = abs(dot(normalize(vNormal), normalize(vViewDir)));
            float streaks = 0.55 + 0.45 * sin(vUv.x * 37.699 + uTime * 6.0 - vUv.y * 8.0);
            vec3 col = mix(uColorBottom, uColorTop, vUv.y * 0.7);
            float envelope = sin(uProgress * 3.14159);
            float alpha = vFade * fresnel * streaks * envelope * 0.68;
            gl_FragColor = vec4(col * 1.4, alpha);
          
            float detailNoise = snoise(vec3(vUv * vec2(4.0, 7.0), uTime * .7));
            gl_FragColor.rgb *= .9 + .18 * detailNoise;
            gl_FragColor.a *= .6 + .4 * smoothstep(-.6, .4, detailNoise);
}
        `,
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide
      });

      const mesh = new THREE.Mesh(geo, mat);
      mesh.position.copy(targetPos);
      mesh.position.y = 3.75;

      vfx.spawnAnimatedMesh(mesh, duration, (progress, m, dt) => {
        mat.uniforms.uTime.value += dt;
        mat.uniforms.uProgress.value = progress;
      }, delay);
    }

    function castMedia() {
      if (combatState.isCasting) return;
      combatState.isCasting = true;

      if (combatState.abraHp >= combatState.abraMaxHp && combatState.panchamHp >= combatState.panchamMaxHp) {
        combatState.abraHp = 14;
        combatState.panchamHp = 23;
        updateAllHUDs();
      }

      const newAbraHp = Math.min(combatState.abraMaxHp, combatState.abraHp + 18);
      const newPanchamHp = Math.min(combatState.panchamMaxHp, combatState.panchamHp + 22);
      document.getElementById('abra-hp-heal-preview').style.width = `${(newAbraHp / combatState.abraMaxHp) * 100}%`;
      document.getElementById('pancham-hp-heal-preview').style.width = `${(newPanchamHp / combatState.panchamMaxHp) * 100}%`;

      showSkillBanner('1 - MEDIA', 'ARTE SACRA • CURA EM GRUPO (ALIADOS)', '#00ff9d');
      sfx.playMediaWindup();
      abra.castAnimTimer = 2.3;

      const allies = [
        { model: abra, pos: ALLY_SLOTS['-1'], healAmt: 18 },
        ...(context.companion !== context.attacker ? [{ model: pancham, pos: ALLY_SLOTS['+1'], healAmt: 22 }] : [])
      ];

      spawnSacredHealCircle(ALLY_SLOTS['-1'].clone().lerp(ALLY_SLOTS['+1'], .5), 5.2, 2.4);

      allies.forEach((ally, idx) => {
        spawnSacredHealCircle(ally.pos, 2.2, 2.4);
        spawnVolumetricHealPillar(ally.pos, 1.85, 0.35 + idx * 0.08);

        vfx.spawnEmitter({
          count: 90,
          texture: 'glow',
          shape: 'helix',
          origin: ally.pos.clone().add(new THREE.Vector3(0, 0.1, 0)),
          radius: 1.45,
          orbitSpeed: 4.8,
          speed: [1.8, 3.3],
          life: [1.1, 1.85],
          size: [0.55, 1.15],
          sizeBell: true,
          colorStart: '#00ff9d',
          colorEnd: '#ffe66d',
          stagger: 0.75
        });

        vfx.spawnEmitter({
          count: 34,
          texture: 'cross',
          shape: 'circle',
          origin: ally.pos.clone().add(new THREE.Vector3(0, 0.25, 0)),
          radius: 1.3,
          orbitSpeed: 1.2,
          speed: [1.3, 2.4],
          life: [1.0, 1.65],
          size: [0.45, 0.85],
          sizeBell: true,
          spin: 0.6,
          colorStart: '#7effc5',
          colorEnd: '#d8ff00',
          stagger: 0.85
        });

        vfx.spawnEmitter({
          count: 60,
          texture: 'sparkle',
          shape: 'circle',
          origin: ally.pos.clone().add(new THREE.Vector3(0, 0.2, 0)),
          radius: 1.6,
          orbitSpeed: -2.6,
          speed: [1.5, 3.6],
          life: [0.9, 1.6],
          size: [0.5, 1.05],
          sizeBell: true,
          spin: 3.5,
          colorStart: '#ffffff',
          colorEnd: '#00e5ff',
          stagger: 0.8
        });
      });

      setTimeout(() => {
        setElementalVignette('rgba(0, 255, 157, 0.28)', 1);
        fxLight.color.set('#00ff9d');
        fxLight.position.copy(ALLY_SLOTS['-1']).lerp(ALLY_SLOTS['+1'], .5).add(new THREE.Vector3(0,3.5,0));
        fxLight.intensity = 6.0;
      }, 450);

      setTimeout(() => {
        sfx.playMediaHealPulse();
        triggerScreenFlash('#00ff9d', 0.25, 160);
        combatState.abraHp = newAbraHp;
        combatState.panchamHp = newPanchamHp;
        updateAllHUDs();

        allies.forEach((ally) => {
          spawnWorldPopup(ally.pos, `+${ally.healAmt} HP`, 'RESTAURAÇÃO', 'heal');
          vfx.spawnEmitter({
            count: 50,
            texture: 'sparkle',
            shape: 'sphere',
            origin: ally.pos.clone().add(new THREE.Vector3(0, 1.3, 0)),
            radius: 0.5,
            speed: [2.2, 5.2],
            drag: 0.94,
            life: [0.65, 1.15],
            size: [0.65, 1.25],
            colorStart: '#d8ff00',
            colorEnd: '#00ff9d'
          });
        });
      }, 1400);

      setTimeout(() => {
        setElementalVignette('', 0);
        fxLight.intensity = 0;
        combatState.isCasting = false;
      }, 2450);
    }

    // =========================================================================
    // 9. MOVE 2: "MABUFULA" — MULTI-TARGET MEDIUM ICE MAGIC
    // =========================================================================
    function spawnCryoFrostDecal(centerPos, width = 14, depth = 5.5, duration = 2.4) {
      const geo = new THREE.PlaneGeometry(width, depth);
      const mat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uProgress: { value: 0 },
          uColorCore: { value: new THREE.Color('#80f8ff') },
          uColorEdge: { value: new THREE.Color('#0077ff') }
        },
        vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = uv * 2.0 - 1.0;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `${noiseGLSL}

          uniform float uTime;
          uniform float uProgress;
          uniform vec3 uColorCore;
          uniform vec3 uColorEdge;
          varying vec2 vUv;
          void main() {
            float d = length(vUv * vec2(0.85, 1.15));
            if (d > 1.0) discard;
            float spread = smoothstep(0.0, 0.25, uProgress);
            if (d > spread) discard;
            float a = atan(vUv.y, vUv.x);
            float crystal = abs(sin(a * 6.0 + d * 10.0)) * abs(cos(a * 12.0 - d * 8.0));
            float veins = smoothstep(0.35, 0.85, crystal) * (1.0 - d * 0.7);
            float rim = (1.0 - smoothstep(0.0, 0.08,  abs(d - spread * 0.95)));
            vec3 col = mix(uColorEdge, uColorCore, veins + rim);
            float fadeOut = 1.0 - smoothstep(0.72, 1.0, uProgress);
            gl_FragColor = vec4(col * 1.4, (veins * 0.65 + rim * 0.9 + 0.15) * (1.0 - d) * fadeOut);
          
            float detailNoise = snoise(vec3(vUv * vec2(4.0, 7.0), uTime * .7));
            gl_FragColor.rgb *= .9 + .18 * detailNoise;
            gl_FragColor.a *= .6 + .4 * smoothstep(-.6, .4, detailNoise);
}
        `,
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide
      });

      const mesh = new THREE.Mesh(geo, mat);
      mesh.rotation.x = -Math.PI / 2;
      mesh.position.copy(centerPos);
      mesh.position.y = 0.03;

      vfx.spawnAnimatedMesh(mesh, duration, (p, m, dt) => {
        mat.uniforms.uTime.value += dt;
        mat.uniforms.uProgress.value = p;
      });
    }

    function spawnGlacialSpireCluster(pos, scale = 1.0, delay = 0, shatterTime = 1.15) {
      const cluster = new THREE.Group();
      cluster.position.copy(pos);

      const iceMat = new THREE.ShaderMaterial({
        uniforms: {
          uColorDeep: { value: new THREE.Color('#0066cc') },
          uColorRim: { value: new THREE.Color('#b8ffff') },
          uOpacity: { value: 0.92 }
        },
        vertexShader: `
          varying vec3 vNormal;
          varying vec3 vViewDir;
          varying float vHeight;
          void main() {
            vHeight = position.y;
            vec4 mvPos = modelViewMatrix * vec4(position, 1.0);
            vNormal = normalize(normalMatrix * normal);
            vViewDir = normalize(-mvPos.xyz);
            gl_Position = projectionMatrix * mvPos;
          }
        `,
        fragmentShader: `
          uniform vec3 uColorDeep;
          uniform vec3 uColorRim;
          uniform float uOpacity;
          varying vec3 vNormal;
          varying vec3 vViewDir;
          varying float vHeight;
          void main() {
            float fresnel = pow(1.0 - abs(dot(normalize(vNormal), normalize(vViewDir))), 1.6);
            float heightGlow = clamp(vHeight * 0.35, 0.0, 1.0);
            vec3 col = mix(uColorDeep, uColorRim, fresnel * 0.75 + heightGlow * 0.45);
            gl_FragColor = vec4(col * 1.35, uOpacity);
          }
        `,
        transparent: true,
        side: THREE.DoubleSide
      });

      [
        { r: 0.65, h: 3.6, x: 0, z: 0, rx: 0.08, rz: -0.05 },
        { r: 0.48, h: 2.6, x: -0.55, z: 0.35, rx: 0.22, rz: 0.32 },
        { r: 0.52, h: 2.8, x: 0.58, z: 0.25, rx: 0.18, rz: -0.35 },
        { r: 0.42, h: 2.2, x: -0.38, z: -0.52, rx: -0.28, rz: 0.22 },
        { r: 0.45, h: 2.4, x: 0.42, z: -0.45, rx: -0.25, rz: -0.28 }
      ].forEach(cfg => {
        const geo = new THREE.ConeGeometry(cfg.r * scale, cfg.h * scale, 5);
        geo.translate(0, (cfg.h * scale) / 2, 0);
        const spire = new THREE.Mesh(geo, iceMat);
        spire.position.set(cfg.x * scale, 0, cfg.z * scale);
        spire.rotation.set(cfg.rx, Math.random() * Math.PI, cfg.rz);
        cluster.add(spire);
      });

      vfx.spawnAnimatedMesh(cluster, shatterTime, (progress, m) => {
        if (progress < 0.18) {
          const t = progress / 0.18;
          const easeOutBack = 1 + 1.7 * Math.pow(t - 1, 3) + 0.7 * Math.pow(t - 1, 2);
          m.scale.set(1, Math.max(0.01, easeOutBack), 1);
        } else {
          const vib = progress > 0.75 ? (Math.random() - 0.5) * 0.12 : 0;
          m.position.x = pos.x + vib;
        }
      }, delay);
    }

    function castMabufula() {
      if (combatState.isCasting) return;
      combatState.isCasting = true;

      combatState.enemies.forEach(en => {
        if (en.hp <= 6) en.hp = en.maxHp;
      });
      updateAllHUDs();

      showSkillBanner('2 - MABUFULA', 'MAGIA DE GELO • ERUPÇÃO GLACIAL EM ÁREA', '#2de2e6');
      sfx.playMabufulaBlizzard();
      abra.castAnimTimer = 2.4;

      setElementalVignette('rgba(45, 226, 230, 0.32)', 1);
      fxLight.color.set('#2de2e6');
      fxLight.position.copy(ENEMY_SLOTS['0']).add(new THREE.Vector3(0,3.5,0));
      fxLight.intensity = 7.0;

      const rowCenter = ENEMY_SLOTS['0'].clone();
      spawnCryoFrostDecal(rowCenter, 16.5, 6.2, 2.4);

      vfx.spawnEmitter({
        count: 120,
        texture: 'snowflake',
        shape: 'cone',
        origin: ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(-context.radius(context.targets[0])*3, context.height(context.targets[0])*.8, 0)),
        direction: new THREE.Vector3(1.0, -0.08, -0.15),
        coneAngle: 0.48,
        radius: 1.8,
        speed: [9.5, 16.5],
        life: [0.65, 1.25],
        size: [0.45, 0.95],
        sizeBell: true,
        spin: 8.0,
        colorStart: '#ffffff',
        colorEnd: '#2de2e6',
        stagger: 0.45
      });

      const extent=3.0;
      const wavePoints=[context.targets.length>1?ENEMY_SLOTS['-2'].clone():ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(-extent*2,0,0)), ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(-extent,0,0)), ENEMY_SLOTS['0'].clone(), ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(extent,0,0)), context.targets.length>2?ENEMY_SLOTS['+2'].clone():ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(extent*2,0,0))];

      wavePoints.forEach((pt, idx) => {
        const delaySec = 0.42 + idx * 0.11;
        const shatterSec = 1.55 - delaySec;
        const isMainSlot = idx === 2 || (combatState.extraClonesActive && (idx === 0 || idx === 4));
        spawnGlacialSpireCluster(pt, isMainSlot ? 1.18 : 0.85, delaySec, shatterSec);

        setTimeout(() => {
          sfx.playGlacierErupt(0.85 + idx * 0.08);
          vfx.spawnEmitter({
            count: 42,
            texture: 'shard',
            shape: 'hemisphere',
            origin: pt.clone().add(new THREE.Vector3(0, 0.2, 0)),
            radius: 0.8,
            speed: [3.5, 8.2],
            gravity: 9.8,
            bounceFloor: true,
            life: [0.55, 0.95],
            size: [0.45, 0.95],
            spin: 10.0,
            colorStart: '#e0ffff',
            colorEnd: '#00a8ff'
          });
        }, (delaySec * 1000));
      });

      setTimeout(() => {
        document.getElementById('enemy-0-freeze-pill').classList.remove('hidden');
        combatState.enemies.forEach(en => {
          if (en.active) {
            en.model.shudderTimer = 0.85;
            en.model.frozenTint = 1.0;
          }
        });
      }, 650);

      setTimeout(() => {
        sfx.playGlacierShatter();
        triggerScreenFlash('#7ef9ff', 0.45, 150);

        wavePoints.forEach((pt) => {
          vfx.spawnEmitter({
            count: 48,
            texture: 'shard',
            shape: 'sphere',
            origin: pt.clone().add(new THREE.Vector3(0, 1.4, 0)),
            radius: 0.6,
            speed: [5.5, 13.5],
            gravity: 14.5,
            bounceFloor: true,
            life: [0.65, 1.25],
            size: [0.55, 1.15],
            spin: 14.0,
            colorStart: '#ffffff',
            colorEnd: '#00b4ff'
          });
        });

        combatState.enemies.forEach((en, idx) => {
          if (!en.active) return;
          const dmg = idx === 0 ? 24 : 20;
          en.hp = Math.max(0, en.hp - dmg);
          en.model.shudderTimer = 0.45;
          en.model.frozenTint = 0;
          spawnWorldPopup(en.slotPos, `-${dmg} HP`, 'WEAK! • CRÍTICO GELO', 'ice');
        });
        updateAllHUDs();
      }, 1550);

      setTimeout(() => {
        setElementalVignette('', 0);
        document.getElementById('enemy-0-freeze-pill').classList.add('hidden');
        fxLight.intensity = 0;
        combatState.isCasting = false;
      }, 2500);
    }

    // =========================================================================
    // 10. MOVE 3: "DIG" — SUBTERRANEAN DRILL BURROW & GEOTHERMAL ERUPTION
    // =========================================================================
    function spawnSeismicCraterDecal(pos, radius = 2.1, duration = 2.0) {
      const group = new THREE.Group();
      group.position.copy(pos);

      const geo = new THREE.PlaneGeometry(radius * 2.2, radius * 2.2);
      const mat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uProgress: { value: 0 }
        },
        vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = uv * 2.0 - 1.0;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `${noiseGLSL}

          uniform float uTime;
          uniform float uProgress;
          varying vec2 vUv;
          void main() {
            float r = length(vUv);
            if (r > 1.0) discard;
            float a = atan(vUv.y, vUv.x);
            float abyss = (1.0 - smoothstep(0.15, 0.55,  r));
            float cracks = (1.0 - smoothstep(0.0, 0.12,  abs(sin(a * 7.0 + r * 6.0)))) * (1.0 - smoothstep(0.2, 0.95,  r));
            vec3 magma = mix(vec3(0.95, 0.45, 0.05), vec3(1.0, 0.85, 0.2), cracks);
            vec3 col = mix(magma * cracks * 1.6, vec3(0.05, 0.03, 0.02), abyss);
            float fade = 1.0 - smoothstep(0.75, 1.0, uProgress);
            float alpha = (abyss * 0.9 + cracks * 0.85) * fade;
            gl_FragColor = vec4(col, alpha);
          
            float detailNoise = snoise(vec3(vUv * vec2(4.0, 7.0), uTime * .7));
            gl_FragColor.rgb *= .9 + .18 * detailNoise;
            gl_FragColor.a *= .6 + .4 * smoothstep(-.6, .4, detailNoise);
}
        `,
        transparent: true,
        depthWrite: false,
        side: THREE.DoubleSide
      });

      const plane = new THREE.Mesh(geo, mat);
      plane.rotation.x = -Math.PI / 2;
      plane.position.y = 0.03;
      group.add(plane);

      // 3D Rim Rocks around the crater
      const rockMat = new THREE.MeshStandardMaterial({ color: '#5c4028', roughness: 0.85 });
      for (let i = 0; i < 8; i++) {
        const ang = (i / 8) * Math.PI * 2;
        const rock = new THREE.Mesh(new THREE.DodecahedronGeometry(0.26 + (i % 2) * 0.1, 0), rockMat);
        rock.position.set(Math.cos(ang) * (radius * 0.65), 0.14, Math.sin(ang) * (radius * 0.65));
        rock.rotation.set(i, i * 0.7, 0);
        group.add(rock);
      }

      vfx.spawnAnimatedMesh(group, duration, (p, m, dt) => {
        mat.uniforms.uTime.value += dt;
        mat.uniforms.uProgress.value = p;
      });
    }

    function castDig() {
      if (combatState.isCasting) return;
      combatState.isCasting = true;

      if (combatState.enemies[0].hp <= 8) {
        combatState.enemies[0].hp = combatState.enemies[0].maxHp;
        updateAllHUDs();
      }

      showSkillBanner('3 - DIG', 'ATAQUE SUBTERRÂNEO • ESCAVAÇÃO & ERUPÇÃO SÍSMICA', '#f59e0b');
      sfx.playDigBurrow();
      pancham.customOverride = true;

      const startPos = ALLY_SLOTS['+1'].clone();
      const targetPos = ENEMY_SLOTS['0'].clone();

      // Phase 1 (0.0s - 0.55s): Pancham High-Speed Drill Jump & Burrow into Floor
      const dummyDrill = new THREE.Object3D();
      vfx.spawnAnimatedMesh(dummyDrill, 0.55, (p) => {
        pancham.root.position.copy(startPos);
        if (p < 0.45) {
          const t = p / 0.45;
          pancham.bodyGroup.position.y = Math.sin(t * Math.PI) * 2.2;
          pancham.bodyGroup.rotation.y = p * 28.0;
          pancham.bodyGroup.rotation.x = 0.4;
        } else {
          const t = (p - 0.45) / 0.55;
          pancham.bodyGroup.position.y = THREE.MathUtils.lerp(0.8, -2.4, t);
          pancham.bodyGroup.rotation.y = p * 38.0;
        }
      });

      setTimeout(() => {
        pancham.root.visible = false;
        spawnSeismicCraterDecal(startPos, 2.0, 1.9);

        vfx.spawnEmitter({
          count: 55,
          texture: 'rock',
          shape: 'cone',
          origin: startPos.clone().add(new THREE.Vector3(0, 0.15, 0)),
          direction: new THREE.Vector3(0, 1, 0),
          coneAngle: 0.55,
          radius: 0.6,
          speed: [4.5, 9.5],
          gravity: 15.0,
          bounceFloor: true,
          life: [0.55, 1.05],
          size: [0.45, 0.9],
          spin: 10.0,
          blending: THREE.NormalBlending,
          colorStart: '#a16207',
          colorEnd: '#451a03'
        });

        vfx.spawnEmitter({
          count: 45,
          texture: 'smoke',
          shape: 'circle',
          origin: startPos.clone().add(new THREE.Vector3(0, 0.2, 0)),
          radius: 1.2,
          orbitSpeed: 1.5,
          speed: [0.8, 2.2],
          life: [0.7, 1.2],
          size: [1.4, 2.6],
          sizeBell: true,
          blending: THREE.NormalBlending,
          colorStart: '#d97706',
          colorEnd: '#78350f'
        });
      }, 280);

      // Phase 2 (0.55s - 1.35s): Subterranean Seismic Mounds Travelling across Tactical Grid
      const steps = 6;
      for (let i = 1; i <= steps; i++) {
        const delayMs = 480 + i * 125;
        setTimeout(() => {
          sfx.playDigTremor();
          const frac = i / (steps + 1);
          const moundPos = startPos.clone().lerp(targetPos, frac);

          const moundGeo = new THREE.ConeGeometry(0.85, 0.95, 7);
          moundGeo.translate(0, 0.45, 0);
          const moundMat = new THREE.MeshStandardMaterial({
            color: '#78350f',
            emissive: '#d97706',
            emissiveIntensity: 0.35,
            roughness: 0.85
          });
          const mound = new THREE.Mesh(moundGeo, moundMat);
          mound.position.copy(moundPos);

          vfx.spawnAnimatedMesh(mound, 0.48, (p, m) => {
            const s = Math.sin(p * Math.PI);
            m.scale.set(1.0 + p * 0.3, Math.max(0.01, s), 1.0 + p * 0.3);
          });

          vfx.spawnEmitter({
            count: 24,
            texture: 'rock',
            shape: 'hemisphere',
            origin: moundPos.clone().add(new THREE.Vector3(0, 0.1, 0)),
            radius: 0.5,
            speed: [2.5, 5.8],
            gravity: 13.0,
            bounceFloor: true,
            life: [0.35, 0.65],
            size: [0.35, 0.65],
            blending: THREE.NormalBlending,
            colorStart: '#b45309',
            colorEnd: '#451a03'
          });
        }, delayMs);
      }

      // Phase 3 (1.40s): Geothermal Rock-Spire Eruption & Uppercut under Gible!
      setTimeout(() => {
        sfx.playDigEruption();
        triggerScreenFlash('#f59e0b', 0.38, 150);
        setElementalVignette('rgba(245, 158, 11, 0.3)', 1);

        fxLight.color.set('#f59e0b');
        fxLight.position.copy(targetPos).add(new THREE.Vector3(0, 3.0, 0));
        fxLight.intensity = 7.5;

        spawnSeismicCraterDecal(targetPos, 2.6, 1.4);

        // Erupting 3D Basalt/Magma Rock Spires under Gible
        const spireGroup = new THREE.Group();
        spireGroup.position.copy(targetPos);
        const rockSpireMat = new THREE.MeshStandardMaterial({
          color: '#451a03',
          emissive: '#f59e0b',
          emissiveIntensity: 0.5,
          roughness: 0.7
        });

        for (let k = 0; k < 6; k++) {
          const ang = (k / 6) * Math.PI * 2;
          const h = 2.4 + (k % 2) * 0.8;
          const cone = new THREE.Mesh(new THREE.ConeGeometry(0.48, h, 5), rockSpireMat);
          cone.position.set(Math.cos(ang) * 0.75, h / 2, Math.sin(ang) * 0.75);
          cone.rotation.z = (Math.random() - 0.5) * 0.4;
          spireGroup.add(cone);
        }
        vfx.spawnAnimatedMesh(spireGroup, 0.9, (p, m) => {
          const scaleY = p < 0.2 ? (p / 0.2) : (1.0 - Math.max(0, (p - 0.65) / 0.35));
          m.scale.set(1, Math.max(0.01, scaleY), 1);
        });

        // Fountain of Boulders & Geothermal Magma Sparks
        vfx.spawnEmitter({
          count: 75,
          texture: 'rock',
          shape: 'cone',
          origin: targetPos.clone().add(new THREE.Vector3(0, 0.3, 0)),
          direction: new THREE.Vector3(0, 1, 0),
          coneAngle: 0.6,
          radius: 0.8,
          speed: [6.0, 13.5],
          gravity: 16.0,
          bounceFloor: true,
          life: [0.65, 1.2],
          size: [0.55, 1.15],
          spin: 12.0,
          blending: THREE.NormalBlending,
          colorStart: '#d97706',
          colorEnd: '#451a03'
        });

        vfx.spawnEmitter({
          count: 65,
          texture: 'sparkle',
          shape: 'sphere',
          origin: targetPos.clone().add(new THREE.Vector3(0, 1.0, 0)),
          radius: 0.7,
          speed: [3.5, 9.5],
          life: [0.5, 0.95],
          size: [0.6, 1.2],
          colorStart: '#fef08a',
          colorEnd: '#ea580c'
        });

        // Pancham bursts out of the ground delivering a spinning uppercut and flips back to Slot +1
        pancham.root.visible = true;
        const returnDummy = new THREE.Object3D();
        vfx.spawnAnimatedMesh(returnDummy, 0.95, (p) => {
          if (p < 0.4) {
            const t = p / 0.4;
            pancham.root.position.copy(targetPos).add(new THREE.Vector3(0, 0, 0.9));
            pancham.bodyGroup.position.y = Math.sin(t * Math.PI * 0.5) * 2.6;
            pancham.bodyGroup.rotation.y = t * 18.0;
          } else {
            const t = (p - 0.4) / 0.6;
            pancham.root.position.lerpVectors(targetPos, startPos, t);
            pancham.bodyGroup.position.y = Math.sin((1.0 - t) * Math.PI) * 2.4;
            pancham.bodyGroup.rotation.x = -t * Math.PI * 2;
            pancham.bodyGroup.rotation.y = 0;
          }
        });

        // Knock Gible into the air & deal -28 HP
        const en = combatState.enemies[0];
        en.hp = Math.max(0, en.hp - 28);
        en.model.shudderTimer = 0.65;
        en.model.knockupVelY = 8.8;
        spawnWorldPopup(targetPos, '-28 HP', 'SUPER EFETIVO • TERRA', 'earth');
        updateAllHUDs();
      }, 1380);

      setTimeout(() => {
        pancham.root.position.copy(startPos);
        pancham.bodyGroup.position.set(0, 0, 0);
        pancham.bodyGroup.rotation.set(0, 0, 0);
        pancham.root.lookAt(ENEMY_SLOTS['0']);
        pancham.customOverride = false;
        setElementalVignette('', 0);
        fxLight.intensity = 0;
        combatState.isCasting = false;
      }, 2450);
    }

    // =========================================================================
    // 11. MOVE 4: "SAND ATTACK" — BLINDING SILICA JET & DUST DEVIL VORTEX
    // =========================================================================
    function spawnSandCrescentWave(startPos, targetPos, duration = 0.65) {
      const geo = new THREE.RingGeometry(0.6, 1.45, 32, 1, -Math.PI * 0.45, Math.PI * 0.9);
      const mat = new THREE.ShaderMaterial({
        uniforms: {
          uProgress: { value: 0 },
          uColor: { value: new THREE.Color('#facc15') }
        },
        vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `
          uniform float uProgress;
          uniform vec3 uColor;
          varying vec2 vUv;
          void main() {
            float fade = sin(uProgress * 3.14159);
            gl_FragColor = vec4(uColor * 1.35, fade * 0.85);
          }
        `,
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide
      });

      const mesh = new THREE.Mesh(geo, mat);
      mesh.rotation.x = -Math.PI / 2;
      mesh.rotation.z = Math.PI * 0.15;

      vfx.spawnAnimatedMesh(mesh, duration, (p, m) => {
        mat.uniforms.uProgress.value = p;
        m.position.lerpVectors(startPos, targetPos, p);
        m.position.y = 0.65;
        m.scale.setScalar(0.8 + p * 1.4);
      });
    }

    function spawnDustDevilFunnel(targetPos, duration = 1.65) {
      const geo = new THREE.CylinderGeometry(1.75, 0.55, 3.8, 32, 16, true);
      const mat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uProgress: { value: 0 },
          uColorSand: { value: new THREE.Color('#eab308') },
          uColorDark: { value: new THREE.Color('#78350f') }
        },
        vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `${noiseGLSL}

          uniform float uTime;
          uniform float uProgress;
          uniform vec3 uColorSand;
          uniform vec3 uColorDark;
          varying vec2 vUv;
          void main() {
            float bands = sin(vUv.y * 18.0 - uTime * 12.0 + vUv.x * 12.566);
            float mask = smoothstep(-0.2, 0.8, bands);
            float vFade = sin(vUv.y * 3.14159);
            float env = sin(uProgress * 3.14159);
            vec3 col = mix(uColorDark, uColorSand, mask);
            gl_FragColor = vec4(col * 1.25, (0.35 + mask * 0.5) * vFade * env);
          
            float detailNoise = snoise(vec3(vUv * vec2(4.0, 7.0), uTime * .7));
            gl_FragColor.rgb *= .9 + .18 * detailNoise;
            gl_FragColor.a *= .6 + .4 * smoothstep(-.6, .4, detailNoise);
}
        `,
        transparent: true,
        depthWrite: false,
        side: THREE.DoubleSide
      });

      const mesh = new THREE.Mesh(geo, mat);
      mesh.position.copy(targetPos);
      mesh.position.y = 1.9;

      vfx.spawnAnimatedMesh(mesh, duration, (p, m, dt) => {
        mat.uniforms.uTime.value += dt;
        mat.uniforms.uProgress.value = p;
        m.rotation.y += dt * 8.0;
      });
    }

    function castSandAttack() {
      if (combatState.isCasting) return;
      combatState.isCasting = true;

      showSkillBanner('4 - SAND ATTACK', 'JATO ABRASIVO DE SÍLICA • REDUÇÃO DE PRECISÃO (ACC ↓)', '#eab308');
      sfx.playSandJet();

      const origin = context.socket(0,.27,.5);
      const target = ENEMY_SLOTS['0'].clone();
      const dir = target.clone().sub(origin).normalize();

      spawnSandCrescentWave(origin, target, 0.62);

      // Layer 1: Dense Desert Dust Plume Cone
      vfx.spawnEmitter({
        count: 95,
        texture: 'smoke',
        shape: 'cone',
        origin,
        direction: dir,
        coneAngle: 0.22,
        radius: 0.6,
        speed: [14.0, 22.0],
        life: [0.45, 0.85],
        size: [1.2, 2.4],
        sizeBell: true,
        blending: THREE.NormalBlending,
        colorStart: '#facc15',
        colorEnd: '#78350f',
        stagger: 0.35
      });

      // Layer 2: Glittering Silica & Quartz Micro-Crystals
      vfx.spawnEmitter({
        count: 110,
        texture: 'sparkle',
        shape: 'cone',
        origin,
        direction: dir,
        coneAngle: 0.25,
        radius: 0.5,
        speed: [15.5, 25.0],
        life: [0.4, 0.75],
        size: [0.45, 0.9],
        spin: 9.0,
        colorStart: '#fef08a',
        colorEnd: '#ca8a04',
        stagger: 0.35
      });

      // Layer 3: Bouncing Gravel Stones along the Tactical Floor
      vfx.spawnEmitter({
        count: 45,
        texture: 'rock',
        shape: 'cone',
        origin,
        direction: dir,
        coneAngle: 0.26,
        radius: 0.4,
        speed: [11.0, 18.0],
        gravity: 14.0,
        bounceFloor: true,
        life: [0.55, 0.95],
        size: [0.3, 0.65],
        blending: THREE.NormalBlending,
        colorStart: '#d97706',
        colorEnd: '#451a03',
        stagger: 0.3
      });

      // Phase 2 (0.45s): Swirling Dust Devil Vortex + Accuracy Down 'X' Reticles on Gible
      setTimeout(() => {
        sfx.playDebuffDown();
        setElementalVignette('rgba(234, 179, 8, 0.25)', 1);
        spawnDustDevilFunnel(target, 1.55);

        vfx.spawnEmitter({
          count: 75,
          texture: 'smoke',
          shape: 'helix',
          origin: target.clone().add(new THREE.Vector3(0, 0.2, 0)),
          radius: 1.5,
          orbitSpeed: 6.5,
          speed: [1.5, 2.8],
          life: [0.85, 1.4],
          size: [1.3, 2.2],
          sizeBell: true,
          blending: THREE.NormalBlending,
          colorStart: '#eab308',
          colorEnd: '#713f12',
          stagger: 0.4
        });

        // Holographic Red 'X' Blindness / Accuracy Loss Markers
        vfx.spawnEmitter({
          count: 18,
          texture: 'xmark',
          shape: 'circle',
          origin: target.clone().add(new THREE.Vector3(0, 1.5, 0)),
          radius: 1.15,
          orbitSpeed: -3.5,
          speed: [0.6, 1.4],
          life: [0.85, 1.35],
          size: [0.55, 0.9],
          sizeBell: true,
          spin: 0.5,
          colorStart: '#ff4d4d',
          colorEnd: '#facc15',
          stagger: 0.4
        });

        gibleMain.shudderTimer = 0.9;
        document.getElementById('enemy-0-acc-pill').classList.remove('hidden');
        spawnWorldPopup(target, 'ACC ↓', 'PRECISÃO REDUZIDA • CEGUEIRA', 'sand');
      }, 450);

      setTimeout(() => {
        setElementalVignette('', 0);
        combatState.isCasting = false;
      }, 2150);
    }

    // =========================================================================
    // 12. MOVE 5: "DRAGON RAGE" — REBUILT FROM POKÉMON GAME REFERENCES
    //     (GEN 4–7 & BATTLE REVOLUTION): MONSTROUS DRACONIC FIREBALL,
    //     SPECTRAL DRAGON JAWS, BIO-LIGHTNING & SAVAGE INFERNO (40 FIXED DMG)
    // =========================================================================
    /**
     * Spawns a Spectral Monstrous 3D Dragon Jaw / Maw with Blazing Fangs & Horns
     * that snaps open with a roar as the user condenses the Dragon Rage fireball!
     */
    function spawnSpectralDragonMaw(originPos, lookTarget, duration = 0.72) {
      const mawGroup = new THREE.Group();
      mawGroup.position.copy(originPos);
      mawGroup.lookAt(lookTarget);

      const upperJaw = new THREE.Group();
      const lowerJaw = new THREE.Group();
      mawGroup.add(upperJaw);
      mawGroup.add(lowerJaw);

      const skullMat = new THREE.MeshBasicMaterial({
        color: '#ff0055',
        transparent: true,
        opacity: 0.85,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide
      });
      const fangMat = new THREE.MeshBasicMaterial({
        color: '#ffe4ef',
        transparent: true,
        opacity: 0.95,
        blending: THREE.AdditiveBlending
      });

      // Upper Snout Ridge & Swept Dragon Horns
      const snoutGeo = new THREE.ConeGeometry(0.95, 1.8, 5);
      snoutGeo.rotateX(Math.PI / 2);
      const snout = new THREE.Mesh(snoutGeo, skullMat);
      snout.scale.set(1.2, 0.55, 1.0);
      snout.position.set(0, 0.35, 0.2);
      upperJaw.add(snout);

      [-1, 1].forEach((side) => {
        const hornGeo = new THREE.ConeGeometry(0.22, 1.65, 5);
        const horn = new THREE.Mesh(hornGeo, skullMat);
        horn.position.set(side * 0.78, 0.85, -0.45);
        horn.rotation.set(-0.85, 0, side * -0.42);
        upperJaw.add(horn);

        // Glowing Dragon Eyes
        const eye = new THREE.Mesh(
          new THREE.SphereGeometry(0.14, 8, 8),
          new THREE.MeshBasicMaterial({ color: '#ffea00' })
        );
        eye.scale.set(1.6, 0.55, 0.8);
        eye.position.set(side * 0.55, 0.52, 0.15);
        upperJaw.add(eye);
      });

      // Jagged Upper & Lower Dragon Fangs
      const fangPositions = [-0.68, -0.38, 0.38, 0.68];
      fangPositions.forEach((fx, idx) => {
        const fLen = idx === 0 || idx === 3 ? 0.62 : 0.44;
        const uFang = new THREE.Mesh(new THREE.ConeGeometry(0.11, fLen, 4), fangMat);
        uFang.rotation.x = Math.PI;
        uFang.position.set(fx, 0.12, 0.65);
        upperJaw.add(uFang);

        const lFang = new THREE.Mesh(new THREE.ConeGeometry(0.1, fLen * 0.9, 4), fangMat);
        lFang.position.set(fx * 0.9, -0.12, 0.6);
        lowerJaw.add(lFang);
      });

      vfx.spawnAnimatedMesh(mawGroup, duration, (p, m) => {
        const env = Math.sin(p * Math.PI);
        // Jaws wrench wide open to unleash the monstrous fireball
        const jawOpen = p < 0.75 ? THREE.MathUtils.lerp(0.05, 0.62, p / 0.75) : THREE.MathUtils.lerp(0.62, 0.1, (p - 0.75) / 0.25);
        upperJaw.rotation.x = -jawOpen;
        lowerJaw.rotation.x = jawOpen * 1.15;
        upperJaw.position.y = jawOpen * 0.55;
        lowerJaw.position.y = -jawOpen * 0.55;

        const scale = p < 0.2 ? THREE.MathUtils.lerp(0.3, 1.35, p / 0.2) : (1.35 + p * 0.25);
        m.scale.setScalar(scale);
        skullMat.opacity = env * 0.82;
        fangMat.opacity = env * 0.98;
      });
    }

    /**
     * Builds the Monstrous Draconic Fireball (Fornalha de Fúria Dracônica):
     * NO sci-fi rings! Instead:
     * - Violent spiky/horned GLSL vertex-displaced fireball with molten magma-white core,
     *   seething crimson-pink-magenta dragon fire (#ff0055 / #ff1e68), and abyssal dark-violet scorched edges (#2e0538)
     * - 10 protruding 3D jagged dragon-flame spikes/tongues whipping backwards
     * - Dynamic 3D jagged bio-lightning arcs snapping furiously around the mass
     */
    function createMonstrousDragonRageFireball() {
      const root = new THREE.Group();

      // 1. White-Gold-Crimson Incandescent Beast Core
      const innerCore = new THREE.Mesh(
        new THREE.IcosahedronGeometry(0.66, 3),
        new THREE.MeshBasicMaterial({ color: '#fff0d4' })
      );
      root.add(innerCore);

      // 2. Spiky, Roaring Draconic Fireball Shader Shell
      const monsterFireMat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uColCore: { value: new THREE.Color('#ffea79') },   // White-hot / gold-pink core heat
          uColRage: { value: new THREE.Color('#ff0055') },   // Ferocious Dragon-Rage Crimson-Magenta
          uColPink: { value: new THREE.Color('#ff3385') },   // Intense Pink-Crimson Dragon Flame
          uColAbyss: { value: new THREE.Color('#24002e') }   // Dark Abyssal Dragon-Smoke Crust
        },
        vertexShader: `
          uniform float uTime;
          varying vec3 vNormal;
          varying vec3 vViewDir;
          varying float vSpike;
          void main() {
            // High-frequency jagged flame-spike displacement (monstrous & feral)
            float f1 = sin(position.x * 5.5 - uTime * 18.0) * cos(position.y * 5.5 + uTime * 16.0);
            float f2 = sin(position.z * 7.5 - uTime * 22.0) * sin(position.x * 8.0 + uTime * 14.0);
            float spike = pow(abs(f1 * f2), 0.65) * sign(f1 + 0.2);
            vSpike = spike;

            // Stretch flames backward along +Z (comet tail effect)
            vec3 displaced = position + normal * (spike * 0.34);
            if (position.z < 0.0) {
              displaced.z *= 1.32;
            }
            vec4 mvPos = modelViewMatrix * vec4(displaced, 1.0);
            vNormal = normalize(normalMatrix * normal);
            vViewDir = normalize(-mvPos.xyz);
            gl_Position = projectionMatrix * mvPos;
          }
        `,
        fragmentShader: `
          uniform float uTime;
          uniform vec3 uColCore;
          uniform vec3 uColRage;
          uniform vec3 uColPink;
          uniform vec3 uColAbyss;
          varying vec3 vNormal;
          varying vec3 vViewDir;
          varying float vSpike;
          void main() {
            float fresnel = 1.0 - abs(dot(normalize(vNormal), normalize(vViewDir)));
            // Molten fissures vs dark draconic scale-crust
            vec3 fireCol = mix(uColRage, uColPink, smoothstep(-0.2, 0.45, vSpike));
            fireCol = mix(fireCol, uColCore, smoothstep(0.35, 0.85, vSpike) * (1.0 - fresnel * 0.6));
            // Charred abyssal purple-black rim & flame tips
            vec3 finalCol = mix(fireCol * 1.95, uColAbyss, pow(fresnel, 1.75) * 0.72);
            gl_FragColor = vec4(finalCol, 0.96);
          }
        `,
        transparent: true
      });

      const fireballMesh = new THREE.Mesh(new THREE.IcosahedronGeometry(1.12, 4), monsterFireMat);
      root.add(fireballMesh);

      // 3. Jagged 3D Flame Tongues / Dragon Scale Spikes whipping around the fireball
      const flameSpikesGroup = new THREE.Group();
      root.add(flameSpikesGroup);

      const spikeMat = new THREE.MeshBasicMaterial({
        color: '#ff0055',
        transparent: true,
        opacity: 0.85,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide
      });

      for (let i = 0; i < 12; i++) {
        const coneGeo = new THREE.ConeGeometry(0.28, 1.35, 4);
        coneGeo.translate(0, 0.65, 0);
        const cone = new THREE.Mesh(coneGeo, spikeMat);
        const angle = (i / 12) * Math.PI * 2;
        cone.position.set(Math.cos(angle) * 0.72, Math.sin(angle) * 0.72, -0.15);
        cone.rotation.x = -Math.PI * 0.38;
        cone.rotation.z = -angle + Math.PI / 2;
        flameSpikesGroup.add(cone);
      }

      // 4. Crackling 3D Draconic Bio-Lightning Arcs snapping across the fireball
      const lightningGroup = new THREE.Group();
      root.add(lightningGroup);
      const boltLines = [];
      for (let b = 0; b < 5; b++) {
        const pts = [];
        for (let s = 0; s < 7; s++) pts.push(new THREE.Vector3());
        const lGeo = new THREE.BufferGeometry().setFromPoints(pts);
        const lMat = new THREE.LineBasicMaterial({
          color: b % 2 === 0 ? '#ffd1e6' : '#ff0055',
          transparent: true,
          opacity: 0.95,
          blending: THREE.AdditiveBlending
        });
        const line = new THREE.Line(lGeo, lMat);
        lightningGroup.add(line);
        boltLines.push(line);
      }

      function updateLightning() {
        boltLines.forEach((line) => {
          const posArr = line.geometry.attributes.position.array;
          const theta = Math.random() * Math.PI * 2;
          const phi = Math.random() * Math.PI;
          const rStart = 0.85;
          let cx = Math.sin(phi) * Math.cos(theta) * rStart;
          let cy = Math.cos(phi) * rStart;
          let cz = Math.sin(phi) * Math.sin(theta) * rStart;

          for (let s = 0; s < 7; s++) {
            posArr[s * 3] = cx;
            posArr[s * 3 + 1] = cy;
            posArr[s * 3 + 2] = cz;
            cx += (Math.random() - 0.5) * 0.75;
            cy += (Math.random() - 0.5) * 0.75;
            cz += (Math.random() - 0.5) * 0.75;
          }
          line.geometry.attributes.position.needsUpdate = true;
        });
      }

      return { root, monsterFireMat, flameSpikesGroup, updateLightning };
    }

    /**
     * Spawns a Scorched Molten Dragon-Fissure Ground Decal (Fissuras de Fúria Dracônica)
     */
    function spawnDraconicFissureDecal(pos, radius = 3.6, duration = 1.25) {
      const geo = new THREE.PlaneGeometry(radius * 2, radius * 2);
      const mat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uProgress: { value: 0 },
          uColHot: { value: new THREE.Color('#ffea79') },
          uColRage: { value: new THREE.Color('#ff0055') },
          uColChar: { value: new THREE.Color('#14020c') }
        },
        vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = uv * 2.0 - 1.0;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `${noiseGLSL}

          uniform float uTime;
          uniform float uProgress;
          uniform vec3 uColHot;
          uniform vec3 uColRage;
          uniform vec3 uColChar;
          varying vec2 vUv;
          void main() {
            float r = length(vUv);
            if (r > 1.0) discard;
            float a = atan(vUv.y, vUv.x);
            // Jagged claw/fissure cracks radiating from impact center
            float branch = abs(sin(a * 9.0 + sin(r * 14.0 - uTime * 6.0) * 1.8));
            float crack = (1.0 - smoothstep(0.0, 0.16,  branch)) * (1.0 - smoothstep(0.08, 0.98,  r));
            float charPool = (1.0 - smoothstep(0.15, 0.85,  r));
            vec3 magma = mix(uColRage, uColHot, smoothstep(0.4, 0.95, crack) * (1.0 - r * 0.5));
            vec3 col = mix(uColChar, magma * 2.1, crack);
            float fade = 1.0 - smoothstep(0.68, 1.0, uProgress);
            float alpha = (charPool * 0.78 + crack * 0.95) * fade;
            gl_FragColor = vec4(col, alpha);
          
            float detailNoise = snoise(vec3(vUv * vec2(4.0, 7.0), uTime * .7));
            gl_FragColor.rgb *= .9 + .18 * detailNoise;
            gl_FragColor.a *= .6 + .4 * smoothstep(-.6, .4, detailNoise);
}
        `,
        transparent: true,
        depthWrite: false,
        side: THREE.DoubleSide
      });

      const mesh = new THREE.Mesh(geo, mat);
      mesh.rotation.x = -Math.PI / 2;
      mesh.position.copy(pos);
      mesh.position.y = 0.035;

      vfx.spawnAnimatedMesh(mesh, duration, (p, m, dt) => {
        mat.uniforms.uTime.value += dt;
        mat.uniforms.uProgress.value = p;
      });
    }

    /**
     * Executes MOVE 5: DRAGON RAGE (Rebuilt from Pokémon references: Monstrous Draconic Fireball & Cataclysm — 40 DMG)
     */
    function castDragonRage() {
      if (combatState.isCasting) return;
      combatState.isCasting = true;

      if (combatState.enemies[0].hp <= 40) {
        combatState.enemies[0].hp = combatState.enemies[0].maxHp;
        updateAllHUDs();
      }

      showSkillBanner('5 - DRAGON RAGE', 'CHAMA DE FÚRIA DRACÔNICA • DANO FIXO 40', '#ff0055');
      sfx.playMonstrousDragonRoar();
      abra.castAnimTimer = 2.25;

      const chargePos = context.socket(.15,.72,1.15);
      const impactPos = context.center(context.targets[0]);

      setElementalVignette('rgba(255, 0, 85, 0.38)', 1);
      fxLight.color.set('#ff0055');
      fxLight.position.copy(chargePos);
      fxLight.intensity = 9.0;

      // =======================================================================
      // PHASE 1 (0.0s - 0.56s): SPECTRAL DRAGON JAWS & WRATH FIREBALL CONDENSATION
      // =======================================================================
      spawnSpectralDragonMaw(chargePos.clone().add(new THREE.Vector3(0, 0.1, 0.35)), impactPos, 0.68);
      spawnDraconicFissureDecal(ALLY_SLOTS['-1'], 2.4, 0.85);

      const dragonFireball = createMonstrousDragonRageFireball();
      dragonFireball.root.position.copy(chargePos);
      dragonFireball.root.lookAt(impactPos);
      dragonFireball.root.scale.setScalar(0.06);
      scene.add(dragonFireball.root);

      // Violent crimson-magenta flames & black-violet soot sucked into the Dragon Jaws
      vfx.spawnEmitter({
        count: 95,
        texture: 'flame',
        shape: 'inward',
        origin: chargePos,
        radius: 2.7,
        speed: [3.8, 7.2],
        life: [0.25, 0.5],
        size: [0.75, 1.45],
        sizeBell: true,
        colorStart: '#24002e',
        colorMid: '#ff0055',
        colorEnd: '#ffea79',
        stagger: 0.25
      });

      // Small rocks lifting under the caster from draconic pressure
      vfx.spawnEmitter({
        count: 28,
        texture: 'rock',
        shape: 'circle',
        origin: ALLY_SLOTS['-1'].clone().add(new THREE.Vector3(0, 0.1, 0)),
        radius: 1.65,
        speed: [1.8, 3.6],
        life: [0.4, 0.65],
        size: [0.28, 0.55],
        blending: THREE.NormalBlending,
        colorStart: '#ff0055',
        colorEnd: '#1f1224',
        stagger: 0.2
      });

      const chargeDuration = 0.56;
      const chargeDummy = new THREE.Object3D();
      vfx.spawnAnimatedMesh(chargeDummy, chargeDuration, (p, m, dt) => {
        dragonFireball.monsterFireMat.uniforms.uTime.value += dt;
        dragonFireball.flameSpikesGroup.rotation.z += dt * 14.0;
        dragonFireball.updateLightning();
        const s = THREE.MathUtils.lerp(0.1, 1.18, Math.pow(p, 0.75));
        dragonFireball.root.scale.setScalar(s);
      });

      // =======================================================================
      // PHASE 2 (0.56s - 0.98s): FEROCIOUS DRACONIC FIREBALL COMET FLIGHT
      // =======================================================================
      const flightDuration = 0.42;
      setTimeout(() => {
        sfx.playDragonFireballTear();

        let wakeStep = -1;
        const flightDummy = new THREE.Object3D();
        vfx.spawnAnimatedMesh(flightDummy, flightDuration, (p, m, dt) => {
          dragonFireball.monsterFireMat.uniforms.uTime.value += dt * 1.6;
          dragonFireball.flameSpikesGroup.rotation.z += dt * 22.0;
          dragonFireball.updateLightning();

          // Direct, high-momentum predatory trajectory with slight low predatory dip
          const currentPos = new THREE.Vector3().lerpVectors(chargePos, impactPos, p);
          currentPos.y += Math.sin(p * Math.PI) * 0.35;
          dragonFireball.root.position.copy(currentPos);
          dragonFireball.root.lookAt(impactPos);
          fxLight.position.copy(currentPos);

          const step = Math.floor(p * 9);
          if (step > wakeStep) {
            wakeStep = step;

            // Thick dark-violet/black dragon smoke trail (NormalBlending for weight & menace)
            vfx.spawnEmitter({
              count: 18,
              texture: 'smoke',
              shape: 'sphere',
              origin: currentPos.clone(),
              radius: 0.55,
              speed: [1.0, 2.8],
              life: [0.35, 0.68],
              size: [1.1, 2.0],
              sizeBell: true,
              blending: THREE.NormalBlending,
              colorStart: '#ff0055',
              colorMid: '#3b0764',
              colorEnd: '#09020d'
            });

            // Roaring Crimson-Pink-Gold Dragon Flame Wake
            vfx.spawnEmitter({
              count: 28,
              texture: 'flame',
              shape: 'sphere',
              origin: currentPos.clone(),
              radius: 0.65,
              speed: [1.8, 4.5],
              life: [0.25, 0.52],
              size: [0.85, 1.65],
              sizeBell: true,
              colorStart: '#ffea79',
              colorMid: '#ff0055',
              colorEnd: '#2e0219'
            });
          }
        });
      }, (chargeDuration * 1000));

      // =======================================================================
      // PHASE 3 (0.98s+): MONSTROUS DRACONIC CATACLYSM ON CONTACT (40 DMG)
      // =======================================================================
      setTimeout(() => {
        scene.remove(dragonFireball.root);
        sfx.playDragonRageCataclysm();
        triggerScreenFlash('#ff0055', 0.58, 190);

        fxLight.color.set('#ff0055');
        fxLight.position.copy(impactPos);
        fxLight.intensity = 12.5;

        // 1. Scorched Molten Dragon-Fissure Crater under Gible
        spawnDraconicFissureDecal(ENEMY_SLOTS['0'], 4.4, 1.35);

        // 2. Erupting 3D Jagged Dragon-Flame Spires (Pokémon Gen 6 / Battle Revolution style)
        const clawSpires = new THREE.Group();
        clawSpires.position.copy(ENEMY_SLOTS['0']);

        const spireShaderMat = new THREE.ShaderMaterial({
          uniforms: {
            uTime: { value: 0 },
            uProgress: { value: 0 },
            uColBase: { value: new THREE.Color('#ffea79') },
            uColMid: { value: new THREE.Color('#ff0055') },
            uColTip: { value: new THREE.Color('#1f0024') }
          },
          vertexShader: `
            varying float vY;
            void main() {
              vY = clamp(position.y / 4.2, 0.0, 1.0);
              gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
          `,
          fragmentShader: `
            uniform float uProgress;
            uniform vec3 uColBase;
            uniform vec3 uColMid;
            uniform vec3 uColTip;
            varying float vY;
            void main() {
              vec3 col = mix(uColBase, uColMid, smoothstep(0.0, 0.55, vY));
              col = mix(col, uColTip, smoothstep(0.55, 1.0, vY));
              float env = sin(uProgress * 3.14159);
              gl_FragColor = vec4(col * 1.9, env * 0.92);
            }
          `,
          transparent: true,
          depthWrite: false,
          blending: THREE.AdditiveBlending,
          side: THREE.DoubleSide
        });

        for (let k = 0; k < 10; k++) {
          const ang = (k / 10) * Math.PI * 2;
          const h = 3.2 + (k % 3) * 0.95;
          const r = 0.52 + (k % 2) * 0.18;
          const sGeo = new THREE.ConeGeometry(r, h, 4);
          sGeo.translate(0, h / 2, 0);
          const spire = new THREE.Mesh(sGeo, spireShaderMat);
          const dist = k % 2 === 0 ? 0.65 : 1.35;
          spire.position.set(Math.cos(ang) * dist, 0, Math.sin(ang) * dist);
          spire.rotation.x = Math.sin(ang) * 0.38;
          spire.rotation.z = -Math.cos(ang) * 0.38;
          spire.rotation.y = ang;
          clawSpires.add(spire);
        }

        vfx.spawnAnimatedMesh(clawSpires, 0.92, (p, m, dt) => {
          spireShaderMat.uniforms.uProgress.value = p;
          const sy = p < 0.18 ? THREE.MathUtils.lerp(0.1, 1.25, p / 0.18) : (1.25 - (p - 0.18) * 0.45);
          const sxz = 0.85 + p * 0.55;
          m.scale.set(sxz, Math.max(0.01, sy), sxz);
          m.rotation.y += dt * 2.2;
        });

        // 3. Whipping 3D Draconic Lightning Bolts erupting from the blast
        const blastLightningGroup = new THREE.Group();
        blastLightningGroup.position.copy(impactPos);
        const blastBolts = [];
        for (let b = 0; b < 8; b++) {
          const pts = [];
          for (let s = 0; s < 8; s++) pts.push(new THREE.Vector3());
          const lGeo = new THREE.BufferGeometry().setFromPoints(pts);
          const lMat = new THREE.LineBasicMaterial({
            color: b % 2 === 0 ? '#ffea79' : '#ff0055',
            transparent: true,
            opacity: 0.95,
            blending: THREE.AdditiveBlending
          });
          const line = new THREE.Line(lGeo, lMat);
          blastLightningGroup.add(line);
          blastBolts.push(line);
        }

        vfx.spawnAnimatedMesh(blastLightningGroup, 0.65, () => {
          blastBolts.forEach((line, idx) => {
            const arr = line.geometry.attributes.position.array;
            const ang = (idx / 8) * Math.PI * 2 + (Math.random() - 0.5) * 0.5;
            let x = 0, y = 0, z = 0;
            for (let s = 0; s < 8; s++) {
              arr[s * 3] = x;
              arr[s * 3 + 1] = y;
              arr[s * 3 + 2] = z;
              x += Math.cos(ang) * 0.42 + (Math.random() - 0.5) * 0.45;
              y += 0.35 + (Math.random() - 0.3) * 0.45;
              z += Math.sin(ang) * 0.42 + (Math.random() - 0.5) * 0.45;
            }
            line.geometry.attributes.position.needsUpdate = true;
          });
        });

        // 4. Billowing Dark-Abyssal Smoke Plume (Gives monstrous weight & contrast)
        vfx.spawnEmitter({
          count: 70,
          texture: 'smoke',
          shape: 'hemisphere',
          origin: ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(0, 0.3, 0)),
          radius: 1.25,
          speed: [2.2, 6.5],
          drag: 0.94,
          life: [0.65, 1.25],
          size: [1.5, 2.8],
          sizeBell: true,
          blending: THREE.NormalBlending,
          colorStart: '#ff0055',
          colorMid: '#2e0219',
          colorEnd: '#09020d'
        });

        // 5. Savage Crimson-Magenta-Gold Dragon Flame Inferno Eruption
        vfx.spawnEmitter({
          count: 145,
          texture: 'flame',
          shape: 'cone',
          origin: ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(0, 0.15, 0)),
          direction: new THREE.Vector3(0, 1, 0),
          coneAngle: 0.68,
          radius: 1.15,
          speed: [5.5, 14.0],
          drag: 0.94,
          life: [0.55, 1.15],
          size: [1.05, 2.25],
          sizeBell: true,
          colorStart: '#ffea79',
          colorMid: '#ff0055',
          colorEnd: '#24002e'
        });

        // 6. Scorching Magma Rocks & Draconic Cinders bouncing across the arena floor
        vfx.spawnEmitter({
          count: 65,
          texture: 'rock',
          shape: 'hemisphere',
          origin: impactPos.clone(),
          radius: 0.85,
          speed: [6.5, 15.5],
          gravity: 16.5,
          bounceFloor: true,
          life: [0.65, 1.25],
          size: [0.42, 0.88],
          spin: 12.0,
          blending: THREE.NormalBlending,
          colorStart: '#ff0055',
          colorMid: '#9d174d',
          colorEnd: '#18041c'
        });

        // Apply Fixed 40 Damage Rule of Dragon Rage
        const en = combatState.enemies[0];
        en.hp = Math.max(0, en.hp - 40);
        en.model.shudderTimer = 0.85;
        spawnWorldPopup(ENEMY_SLOTS['0'], '-40 HP', 'DRAGON RAGE • FÚRIA DRACÔNICA 40', 'dragon');
        updateAllHUDs();
      }, ((chargeDuration + flightDuration) * 1000));

      setTimeout(() => {
        setElementalVignette('', 0);
        fxLight.intensity = 0;
        combatState.isCasting = false;
      }, 2250);
    }

    // =========================================================================
    // 12C. MOVE 8: "PSYCHO ORB" — PRESERVED SMOOTH PINK PSYCHIC SPHERE & RINGS
    //      (SAVED FOR REUSE IN PSYCHIC / FAIRY / COSMIC MOVES)
    // =========================================================================
    function createGiantPinkPsychoOrbMesh() {
      const root = new THREE.Group();

      const innerCore = new THREE.Mesh(
        new THREE.SphereGeometry(0.68, 24, 24),
        new THREE.MeshBasicMaterial({ color: '#fff0f8' })
      );
      root.add(innerCore);

      const plasmaMat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uColorCore: { value: new THREE.Color('#ffd6eb') },
          uColorMid: { value: new THREE.Color('#ff1f8e') },
          uColorRim: { value: new THREE.Color('#d946ef') }
        },
        vertexShader: `
          uniform float uTime;
          varying vec3 vNormal;
          varying vec3 vViewDir;
          varying vec3 vPos;
          varying float vWave;
          void main() {
            vPos = position;
            float w = sin(position.x * 4.5 + uTime * 14.0)
                    * cos(position.y * 4.5 - uTime * 12.0)
                    * sin(position.z * 4.5 + uTime * 10.0);
            vWave = w;
            vec3 displaced = position + normal * (w * 0.14);
            vec4 mvPos = modelViewMatrix * vec4(displaced, 1.0);
            vNormal = normalize(normalMatrix * normal);
            vViewDir = normalize(-mvPos.xyz);
            gl_Position = projectionMatrix * mvPos;
          }
        `,
        fragmentShader: `
          uniform float uTime;
          uniform vec3 uColorCore;
          uniform vec3 uColorMid;
          uniform vec3 uColorRim;
          varying vec3 vNormal;
          varying vec3 vViewDir;
          varying vec3 vPos;
          varying float vWave;
          void main() {
            float fresnel = 1.0 - abs(dot(normalize(vNormal), normalize(vViewDir)));
            float veins = smoothstep(-0.25, 0.55, sin(vPos.x * 6.0 - uTime * 10.0) * cos(vPos.y * 6.0 + uTime * 9.0));
            vec3 col = mix(uColorMid, uColorCore, veins * 0.65 + (1.0 - fresnel) * 0.45);
            col = mix(col, uColorRim, pow(fresnel, 1.65));
            float alpha = clamp(0.78 + fresnel * 0.22 + vWave * 0.1, 0.0, 1.0);
            gl_FragColor = vec4(col * 1.75, alpha);
          }
        `,
        transparent: true,
        blending: THREE.AdditiveBlending
      });

      const outerSphere = new THREE.Mesh(new THREE.SphereGeometry(1.15, 32, 32), plasmaMat);
      root.add(outerSphere);

      const ringGeo = new THREE.TorusGeometry(1.38, 0.055, 12, 48);
      const ringMat = new THREE.MeshBasicMaterial({
        color: '#ff80ca',
        transparent: true,
        opacity: 0.85,
        blending: THREE.AdditiveBlending
      });
      const ringA = new THREE.Mesh(ringGeo, ringMat);
      ringA.rotation.x = Math.PI / 3;
      const ringB = new THREE.Mesh(ringGeo, ringMat);
      ringB.rotation.y = Math.PI / 3;
      root.add(ringA);
      root.add(ringB);

      return { root, plasmaMat, ringA, ringB };
    }

    function spawnPinkEnergyGroundRing(pos, radius = 2.8, duration = 0.85) {
      const geo = new THREE.PlaneGeometry(radius * 2, radius * 2);
      const mat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uProgress: { value: 0 },
          uColInner: { value: new THREE.Color('#ffd6eb') },
          uColOuter: { value: new THREE.Color('#ff1f8e') }
        },
        vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = uv * 2.0 - 1.0;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `${noiseGLSL}

          uniform float uTime;
          uniform float uProgress;
          uniform vec3 uColInner;
          uniform vec3 uColOuter;
          varying vec2 vUv;
          void main() {
            float r = length(vUv);
            if (r > 1.0) discard;
            float ring1 = (1.0 - smoothstep(0.0, 0.06,  abs(r - 0.85)));
            float ring2 = (1.0 - smoothstep(0.0, 0.05,  abs(r - fract(r * 2.0 - uTime * 3.0) * 0.8)));
            float coreGlow = (1.0 - smoothstep(0.0, 0.9,  r)) * 0.45;
            vec3 col = mix(uColOuter, uColInner, ring1 + coreGlow);
            float env = sin(uProgress * 3.14159);
            gl_FragColor = vec4(col * 1.75, (ring1 + ring2 * 0.6 + coreGlow) * env);
          
            float detailNoise = snoise(vec3(vUv * vec2(4.0, 7.0), uTime * .7));
            gl_FragColor.rgb *= .9 + .18 * detailNoise;
            gl_FragColor.a *= .6 + .4 * smoothstep(-.6, .4, detailNoise);
}
        `,
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide
      });

      const mesh = new THREE.Mesh(geo, mat);
      mesh.rotation.x = -Math.PI / 2;
      mesh.position.copy(pos);
      mesh.position.y = 0.04;

      vfx.spawnAnimatedMesh(mesh, duration, (p, m, dt) => {
        mat.uniforms.uTime.value += dt;
        mat.uniforms.uProgress.value = p;
      });
    }

    /**
     * Executes MOVE 8: PSYCHO ORB (Preserved Smooth Pink Psychic Sphere + Gyro Rings + Cellular Dome)
     */
    function castPsychoOrb() {
      if (combatState.isCasting) return;
      combatState.isCasting = true;

      if (combatState.enemies[0].hp <= 34) {
        combatState.enemies[0].hp = combatState.enemies[0].maxHp;
        updateAllHUDs();
      }

      showSkillBanner('8 - PSYCHO ORB', 'ESFERA ASTRAL PSÍQUICA • DETONAÇÃO TELECINÉTICA', '#f472b6');
      sfx.playDragonPinkSphereCharge();
      abra.castAnimTimer = 2.2;

      const chargePos = context.socket(.15,.8,1.05);
      const impactPos = context.center(context.targets[0]);

      setElementalVignette('rgba(255, 31, 142, 0.34)', 1);
      fxLight.color.set('#ff2a9d');
      fxLight.position.copy(chargePos);
      fxLight.intensity = 8.0;

      const pinkOrb = createGiantPinkPsychoOrbMesh();
      pinkOrb.root.position.copy(chargePos);
      pinkOrb.root.scale.setScalar(0.05);
      scene.add(pinkOrb.root);

      spawnPinkEnergyGroundRing(ALLY_SLOTS['-1'], 2.6, 0.75);

      vfx.spawnEmitter({
        count: 95,
        texture: 'flame',
        shape: 'inward',
        origin: chargePos,
        radius: 2.6,
        speed: [3.4, 6.2],
        life: [0.28, 0.52],
        size: [0.65, 1.3],
        sizeBell: true,
        colorStart: '#ff1f8e',
        colorMid: '#ff80ca',
        colorEnd: '#ffffff',
        stagger: 0.25
      });

      vfx.spawnEmitter({
        count: 60,
        texture: 'sparkle',
        shape: 'inward',
        origin: chargePos,
        radius: 2.9,
        speed: [4.0, 7.0],
        life: [0.25, 0.48],
        size: [0.55, 1.1],
        sizeBell: true,
        colorStart: '#ffd6eb',
        colorEnd: '#ff1f8e',
        stagger: 0.25
      });

      const chargeDuration = 0.55;
      const chargeDummy = new THREE.Object3D();
      vfx.spawnAnimatedMesh(chargeDummy, chargeDuration, (p, m, dt) => {
        pinkOrb.plasmaMat.uniforms.uTime.value += dt;
        pinkOrb.ringA.rotation.z += dt * 9.0;
        pinkOrb.ringB.rotation.x -= dt * 9.0;
        const s = THREE.MathUtils.lerp(0.08, 1.15, Math.sin(p * Math.PI * 0.5));
        pinkOrb.root.scale.setScalar(s);
      });

      const flightDuration = 0.44;
      setTimeout(() => {
        sfx.playDragonPinkSphereLaunch();

        const arcCtrl = chargePos.clone().lerp(impactPos, 0.5).add(new THREE.Vector3(0, 1.45, 0));
        const ballCurve = new THREE.QuadraticBezierCurve3(chargePos.clone(), arcCtrl, impactPos.clone());

        let wakeStep = -1;
        const flightDummy = new THREE.Object3D();
        vfx.spawnAnimatedMesh(flightDummy, flightDuration, (p, m, dt) => {
          pinkOrb.plasmaMat.uniforms.uTime.value += dt * 1.5;
          pinkOrb.ringA.rotation.z += dt * 14.0;
          pinkOrb.ringB.rotation.x -= dt * 14.0;

          const currentPos = ballCurve.getPoint(p);
          pinkOrb.root.position.copy(currentPos);
          fxLight.position.copy(currentPos);

          const pulse = p > 0.88
            ? THREE.MathUtils.lerp(1.2, 0.65, (p - 0.88) / 0.12)
            : (1.15 + Math.sin(p * Math.PI * 4) * 0.08);
          pinkOrb.root.scale.setScalar(pulse);

          const step = Math.floor(p * 8);
          if (step > wakeStep) {
            wakeStep = step;

            const wakeGeo = new THREE.RingGeometry(0.65, 1.05, 32);
            const wakeMat = new THREE.MeshBasicMaterial({
              color: step % 2 === 0 ? '#ff66b8' : '#ff1f8e',
              transparent: true,
              opacity: 0.9,
              side: THREE.DoubleSide,
              blending: THREE.AdditiveBlending
            });
            const wakeRing = new THREE.Mesh(wakeGeo, wakeMat);
            wakeRing.position.copy(currentPos);
            wakeRing.lookAt(impactPos);
            vfx.spawnAnimatedMesh(wakeRing, 0.36, (rp, rm) => {
              rm.scale.setScalar(0.9 + rp * 1.9);
              wakeMat.opacity = (1.0 - rp) * 0.85;
            });

            vfx.spawnEmitter({
              count: 26,
              texture: 'flame',
              shape: 'sphere',
              origin: currentPos.clone(),
              radius: 0.65,
              speed: [1.2, 3.8],
              life: [0.3, 0.58],
              size: [0.85, 1.55],
              sizeBell: true,
              colorStart: '#ffd6eb',
              colorMid: '#ff1f8e',
              colorEnd: '#86198f'
            });
          }
        });
      }, (chargeDuration * 1000));

      setTimeout(() => {
        scene.remove(pinkOrb.root);
        sfx.playDragonPinkExplosion();
        triggerScreenFlash('#ff66b8', 0.55, 180);

        fxLight.color.set('#ff1f8e');
        fxLight.position.copy(impactPos);
        fxLight.intensity = 11.0;

        spawnPinkEnergyGroundRing(ENEMY_SLOTS['0'], 4.2, 1.15);

        const domeGeo = new THREE.SphereGeometry(2.65, 32, 32);
        const domeMat = new THREE.ShaderMaterial({
          uniforms: {
            uTime: { value: 0 },
            uProgress: { value: 0 },
            uColCore: { value: new THREE.Color('#fff0f8') },
            uColPink: { value: new THREE.Color('#ff1f8e') },
            uColMagenta: { value: new THREE.Color('#a21caf') }
          },
          vertexShader: `
            uniform float uTime;
            varying vec3 vPos;
            varying vec3 vNormal;
            varying vec3 vViewDir;
            void main() {
              vPos = position;
              float disp = sin(position.x * 4.0 + uTime * 15.0) * cos(position.y * 4.0 - uTime * 12.0) * 0.16;
              vec3 p = position + normal * disp;
              vec4 mvPos = modelViewMatrix * vec4(p, 1.0);
              vNormal = normalize(normalMatrix * normal);
              vViewDir = normalize(-mvPos.xyz);
              gl_Position = projectionMatrix * mvPos;
            }
          `,
          fragmentShader: `
            uniform float uTime;
            uniform float uProgress;
            uniform vec3 uColCore;
            uniform vec3 uColPink;
            uniform vec3 uColMagenta;
            varying vec3 vPos;
            varying vec3 vNormal;
            varying vec3 vViewDir;
            void main() {
              float fresnel = 1.0 - abs(dot(normalize(vNormal), normalize(vViewDir)));
              float cells = sin(vPos.x * 4.2 + uTime * 12.0)
                          * cos(vPos.y * 4.2 - uTime * 10.0)
                          * sin(vPos.z * 4.2 + uTime * 8.0);
              vec3 col = mix(uColMagenta, uColPink, smoothstep(-0.3, 0.4, cells));
              col = mix(col, uColCore, smoothstep(0.25, 0.8, cells) * (1.0 - uProgress * 0.5));
              float env = sin(uProgress * 3.14159);
              gl_FragColor = vec4(col * 1.9, (0.65 + fresnel * 0.35) * env);
            }
          `,
          transparent: true,
          depthWrite: false,
          blending: THREE.AdditiveBlending,
          side: THREE.DoubleSide
        });

        const explosionDome = new THREE.Mesh(domeGeo, domeMat);
        explosionDome.position.copy(ENEMY_SLOTS['0']).add(new THREE.Vector3(0, 1.15, 0));
        vfx.spawnAnimatedMesh(explosionDome, 0.92, (p, m, dt) => {
          domeMat.uniforms.uTime.value += dt;
          domeMat.uniforms.uProgress.value = p;
          const s = p < 0.22 ? THREE.MathUtils.lerp(0.35, 1.35, p / 0.22) : (1.35 + (p - 0.22) * 0.45);
          m.scale.setScalar(s);
          m.rotation.y += dt * 4.5;
        });

        for (let r = 0; r < 2; r++) {
          const sRingGeo = new THREE.RingGeometry(0.8, 1.35, 40);
          const sRingMat = new THREE.MeshBasicMaterial({
            color: r === 0 ? '#ff66b8' : '#ffd6eb',
            transparent: true,
            opacity: 0.95,
            side: THREE.DoubleSide,
            blending: THREE.AdditiveBlending
          });
          const sRing = new THREE.Mesh(sRingGeo, sRingMat);
          sRing.position.copy(impactPos);
          sRing.rotation.x = r === 0 ? Math.PI / 2 : Math.PI / 3;
          sRing.rotation.y = r === 0 ? 0 : 0.4;
          vfx.spawnAnimatedMesh(sRing, 0.65, (p, m) => {
            m.scale.setScalar(0.6 + p * 4.2);
            sRingMat.opacity = (1.0 - p) * 0.95;
          });
        }

        vfx.spawnEmitter({
          count: 130,
          texture: 'flame',
          shape: 'sphere',
          origin: impactPos.clone(),
          radius: 1.1,
          speed: [4.0, 11.5],
          drag: 0.94,
          life: [0.55, 1.15],
          size: [1.0, 2.1],
          sizeBell: true,
          colorStart: '#fff0f8',
          colorMid: '#ff1f8e',
          colorEnd: '#701a75'
        });

        vfx.spawnEmitter({
          count: 95,
          texture: 'glow',
          shape: 'hemisphere',
          origin: impactPos.clone(),
          radius: 0.85,
          speed: [6.0, 14.5],
          gravity: 15.0,
          bounceFloor: true,
          life: [0.65, 1.25],
          size: [0.55, 1.15],
          colorStart: '#ffd6eb',
          colorMid: '#ff2a9d',
          colorEnd: '#d946ef'
        });

        const en = combatState.enemies[0];
        en.hp = Math.max(0, en.hp - 34);
        en.model.shudderTimer = 0.75;
        spawnWorldPopup(ENEMY_SLOTS['0'], '-34 HP', 'PSYCHO ORB • ESFERA TELECINÉTICA', 'psycho');
        updateAllHUDs();
      }, ((chargeDuration + flightDuration) * 1000));

      setTimeout(() => {
        setElementalVignette('', 0);
        fxLight.intensity = 0;
        combatState.isCasting = false;
      }, 2200);
    }

    // =========================================================================
    // 12B. MOVE 7: "PSYCHIC CANNON" — SEPARATED PSIONIC BEAM & SINGULARITY
    // =========================================================================
    function spawnPsychicSigil(pos, lookTarget, duration = 0.85) {
      const geo = new THREE.PlaneGeometry(3.2, 3.2);
      const mat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uProgress: { value: 0 },
          uColorCyan: { value: new THREE.Color('#00f5d4') },
          uColorPurple: { value: new THREE.Color('#a855f7') }
        },
        vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = uv * 2.0 - 1.0;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `${noiseGLSL}

          uniform float uTime;
          uniform float uProgress;
          uniform vec3 uColorCyan;
          uniform vec3 uColorPurple;
          varying vec2 vUv;
          void main() {
            float r = length(vUv);
            if (r > 1.0) discard;
            float a = atan(vUv.y, vUv.x);
            float fangs = abs(sin(a * 8.0 + uTime * 4.0)) * 0.14;
            float outerRing = (1.0 - smoothstep(0.0, 0.05,  abs(r - (0.78 - fangs))));
            float innerSlit = (1.0 - smoothstep(0.0, 0.08,  abs(vUv.x) + r * 0.35)) * step(r, 0.55);
            float plasma = (1.0 - smoothstep(0.0, 0.6,  r)) * (0.5 + 0.5 * sin(r * 16.0 - uTime * 10.0));
            vec3 col = mix(uColorPurple, uColorCyan, outerRing + innerSlit);
            float env = sin(uProgress * 3.14159);
            gl_FragColor = vec4(col * 1.8, (outerRing + innerSlit + plasma * 0.5) * env);
          
            float detailNoise = snoise(vec3(vUv * vec2(4.0, 7.0), uTime * .7));
            gl_FragColor.rgb *= .9 + .18 * detailNoise;
            gl_FragColor.a *= .6 + .4 * smoothstep(-.6, .4, detailNoise);
}
        `,
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide
      });

      const mesh = new THREE.Mesh(geo, mat);
      mesh.position.copy(pos);
      mesh.lookAt(lookTarget);

      vfx.spawnAnimatedMesh(mesh, duration, (p, m, dt) => {
        mat.uniforms.uTime.value += dt;
        mat.uniforms.uProgress.value = p;
        m.rotation.z += dt * 2.5;
      });
    }

    function spawnPsychicPlasmaBeam(origin, target, duration = 0.65) {
      const dist = origin.distanceTo(target);
      const mid = origin.clone().add(target).multiplyScalar(0.5);

      const group = new THREE.Group();
      group.position.copy(mid);
      group.lookAt(target);

      const cylGeo = new THREE.CylinderGeometry(0.55, 0.35, dist, 24, 1, true);
      cylGeo.rotateX(Math.PI / 2);
      const cylMat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uProgress: { value: 0 },
          uColorCore: { value: new THREE.Color('#00f5d4') },
          uColorOuter: { value: new THREE.Color('#9333ea') }
        },
        vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `${noiseGLSL}

          uniform float uTime;
          uniform float uProgress;
          uniform vec3 uColorCore;
          uniform vec3 uColorOuter;
          varying vec2 vUv;
          void main() {
            float wave = sin(vUv.y * 28.0 - uTime * 26.0 + sin(vUv.x * 12.566) * 2.0);
            float core = smoothstep(0.1, 0.9, wave);
            vec3 col = mix(uColorOuter, uColorCore, core);
            float env = sin(uProgress * 3.14159);
            gl_FragColor = vec4(col * 1.85, (0.45 + core * 0.55) * env);
          
            float detailNoise = snoise(vec3(vUv * vec2(4.0, 7.0), uTime * .7));
            gl_FragColor.rgb *= .9 + .18 * detailNoise;
            gl_FragColor.a *= .6 + .4 * smoothstep(-.6, .4, detailNoise);
}
        `,
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide
      });

      const beamMesh = new THREE.Mesh(cylGeo, cylMat);
      group.add(beamMesh);

      vfx.spawnAnimatedMesh(group, duration, (p, m, dt) => {
        cylMat.uniforms.uTime.value += dt;
        cylMat.uniforms.uProgress.value = p;
        const thickness = Math.sin(p * Math.PI);
        beamMesh.scale.set(thickness, thickness, 1.0);
      });
    }

    /**
     * Executes MOVE 7: PSYCHIC CANNON (Canhão Psíquico — Separated Psionic Beam Move)
     */
    function castPsychicCannon() {
      if (combatState.isCasting) return;
      combatState.isCasting = true;

      if (combatState.enemies[0].hp <= 36) {
        combatState.enemies[0].hp = combatState.enemies[0].maxHp;
        updateAllHUDs();
      }

      showSkillBanner('7 - PSYCHIC CANNON', 'CANHÃO PSÍQUICO ULTRASSÔNICO • RUPTURA MENTAL', '#a855f7');
      sfx.playPsychicCharge();
      abra.castAnimTimer = 2.2;

      const origin = context.socket(0,.6,.75);
      const target = context.center(context.targets[0]);

      setElementalVignette('rgba(147, 51, 234, 0.34)', 1);
      fxLight.color.set('#a855f7');
      fxLight.position.copy(origin);
      fxLight.intensity = 7.0;

      spawnPsychicSigil(origin, target, 0.7);

      vfx.spawnEmitter({
        count: 85,
        texture: 'flame',
        shape: 'inward',
        origin,
        radius: 2.2,
        speed: [3.2, 5.5],
        life: [0.35, 0.6],
        size: [0.55, 1.1],
        sizeBell: true,
        colorStart: '#38bdf8',
        colorMid: '#8b5cf6',
        colorEnd: '#ffffff',
        stagger: 0.25
      });

      setTimeout(() => {
        sfx.playPsychicBeamAndBlast();
        spawnPsychicPlasmaBeam(origin, target, 0.62);

        const orbGeo = new THREE.SphereGeometry(0.62, 18, 18);
        const orbMat = new THREE.MeshBasicMaterial({ color: '#00f5d4' });
        const psyOrb = new THREE.Mesh(orbGeo, orbMat);

        let lastRingStep = -1;
        vfx.spawnAnimatedMesh(psyOrb, 0.48, (p, m) => {
          m.position.lerpVectors(origin, target, p);
          fxLight.position.copy(m.position);

          const step = Math.floor(p * 6);
          if (step > lastRingStep) {
            lastRingStep = step;
            const ringGeo = new THREE.RingGeometry(0.45, 0.72, 32);
            const ringMat = new THREE.MeshBasicMaterial({
              color: step % 2 === 0 ? '#00f5d4' : '#c084fc',
              transparent: true,
              opacity: 0.95,
              side: THREE.DoubleSide,
              blending: THREE.AdditiveBlending
            });
            const ring = new THREE.Mesh(ringGeo, ringMat);
            ring.position.copy(m.position);
            ring.lookAt(target);
            vfx.spawnAnimatedMesh(ring, 0.45, (rp, rm) => {
              rm.scale.setScalar(1.0 + rp * 3.2);
              ringMat.opacity = (1.0 - rp) * 0.95;
            });

            vfx.spawnEmitter({
              count: 22,
              texture: 'flame',
              shape: 'sphere',
              origin: m.position.clone(),
              radius: 0.4,
              speed: [1.2, 3.5],
              life: [0.35, 0.65],
              size: [0.7, 1.35],
              colorStart: '#00f5d4',
              colorMid: '#3b82f6',
              colorEnd: '#9333ea'
            });
          }
        });
      }, 580);

      setTimeout(() => {
        sfx.playPsychicSupernova();
        triggerScreenFlash('#c084fc', 0.5, 170);
        fxLight.color.set('#00f5d4');
        fxLight.position.copy(target);
        fxLight.intensity = 9.0;

        const domeGeo = new THREE.SphereGeometry(2.35, 28, 28);
        const domeMat = new THREE.ShaderMaterial({
          uniforms: {
            uTime: { value: 0 },
            uProgress: { value: 0 },
            uCol1: { value: new THREE.Color('#00f5d4') },
            uCol2: { value: new THREE.Color('#7e22ce') }
          },
          vertexShader: `
            varying vec3 vNormal;
            varying vec3 vPos;
            void main() {
              vNormal = normal;
              vPos = position;
              gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }
          `,
          fragmentShader: `
            uniform float uTime;
            uniform float uProgress;
            uniform vec3 uCol1;
            uniform vec3 uCol2;
            varying vec3 vNormal;
            varying vec3 vPos;
            void main() {
              float n = sin(vPos.x * 4.5 + uTime * 10.0) * cos(vPos.y * 4.5 - uTime * 8.0) * sin(vPos.z * 4.5);
              vec3 col = mix(uCol2, uCol1, smoothstep(-0.3, 0.6, n));
              float env = sin(uProgress * 3.14159);
              gl_FragColor = vec4(col * 1.75, env * 0.85);
            }
          `,
          transparent: true,
          depthWrite: false,
          blending: THREE.AdditiveBlending,
          side: THREE.DoubleSide
        });

        const dome = new THREE.Mesh(domeGeo, domeMat);
        dome.position.copy(ENEMY_SLOTS['0']).add(new THREE.Vector3(0, 1.1, 0));
        vfx.spawnAnimatedMesh(dome, 0.85, (p, m, dt) => {
          domeMat.uniforms.uTime.value += dt;
          domeMat.uniforms.uProgress.value = p;
          m.scale.setScalar(0.4 + p * 1.45);
          m.rotation.y += dt * 5.0;
        });

        vfx.spawnEmitter({
          count: 110,
          texture: 'flame',
          shape: 'helix',
          origin: ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(0, 0.2, 0)),
          radius: 2.1,
          orbitSpeed: 7.5,
          speed: [2.8, 6.2],
          life: [0.65, 1.25],
          size: [0.85, 1.65],
          sizeBell: true,
          colorStart: '#00f5d4',
          colorMid: '#3b82f6',
          colorEnd: '#a855f7'
        });

        vfx.spawnEmitter({
          count: 75,
          texture: 'sparkle',
          shape: 'sphere',
          origin: target,
          radius: 0.8,
          speed: [4.5, 11.5],
          drag: 0.93,
          life: [0.55, 1.05],
          size: [0.65, 1.3],
          colorStart: '#ffffff',
          colorEnd: '#00f5d4'
        });

        const en = combatState.enemies[0];
        en.hp = Math.max(0, en.hp - 36);
        en.model.shudderTimer = 0.7;
        spawnWorldPopup(ENEMY_SLOTS['0'], '-36 HP', 'PSYCHIC CANNON • RUPTURA MENTAL', 'psychic');
        updateAllHUDs();
      }, 1080);

      setTimeout(() => {
        setElementalVignette('', 0);
        fxLight.intensity = 0;
        combatState.isCasting = false;
      }, 2250);
    }

    // =========================================================================
    // 13. MOVE 6: "SPLITTER FLAMES" — STRICT CRAWLMON FIRE SPECIFICATION
    // =========================================================================
    /**
     * Creates a Turbulent GLSL Fireball Mesh used for the Left and Right Projectiles
     */
    function createShaderFireballMesh() {
      const group = new THREE.Group();

      const coreMat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: Math.random() * 10 },
          uColorCore: { value: new THREE.Color('#fffbeb') },
          uColorMid: { value: new THREE.Color('#ff9800') },
          uColorRim: { value: new THREE.Color('#e65100') }
        },
        vertexShader: `
          uniform float uTime;
          varying vec3 vNormal;
          varying vec3 vViewDir;
          varying float vNoise;
          void main() {
            float n = sin(position.x * 6.0 + uTime * 14.0) * cos(position.y * 6.0 - uTime * 12.0);
            vNoise = n;
            vec3 displaced = position + normal * (n * 0.08);
            vec4 mvPos = modelViewMatrix * vec4(displaced, 1.0);
            vNormal = normalize(normalMatrix * normal);
            vViewDir = normalize(-mvPos.xyz);
            gl_Position = projectionMatrix * mvPos;
          }
        `,
        fragmentShader: `
          uniform vec3 uColorCore;
          uniform vec3 uColorMid;
          uniform vec3 uColorRim;
          varying vec3 vNormal;
          varying vec3 vViewDir;
          varying float vNoise;
          void main() {
            float fresnel = 1.0 - abs(dot(normalize(vNormal), normalize(vViewDir)));
            vec3 col = mix(uColorCore, uColorMid, clamp(fresnel * 1.3 + vNoise * 0.3, 0.0, 1.0));
            col = mix(col, uColorRim, pow(fresnel, 2.0));
            gl_FragColor = vec4(col * 1.65, 0.96);
          }
        `,
        transparent: true
      });

      const sphere = new THREE.Mesh(new THREE.SphereGeometry(0.42, 20, 20), coreMat);
      group.add(sphere);

      return { group, coreMat };
    }

    /**
     * Spawns the Stationary Fire Vortex at the projectile origin upon Release
     * Spec: "No instante do disparo, surgem dois vórtices de fogo estacionários nos pontos de origem dos projéteis.
     * Os vórtices se expandem durante 0,30 segundo e desaparecem suavemente."
     */
    function spawnStationaryOriginFireVortex(originPos, lookTarget) {
      const geo = new THREE.RingGeometry(0.18, 0.88, 32, 2);
      const mat = new THREE.ShaderMaterial({
        uniforms: {
          uTime: { value: 0 },
          uProgress: { value: 0 },
          uColorInner: { value: new THREE.Color('#ffeb3b') },
          uColorOuter: { value: new THREE.Color('#ff3d00') }
        },
        vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = uv * 2.0 - 1.0;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `${noiseGLSL}

          uniform float uTime;
          uniform float uProgress;
          uniform vec3 uColorInner;
          uniform vec3 uColorOuter;
          varying vec2 vUv;
          void main() {
            float r = length(vUv);
            float a = atan(vUv.y, vUv.x);
            float spiral = sin(a * 6.0 - r * 10.0 + uTime * 22.0);
            float mask = smoothstep(-0.2, 0.7, spiral);
            vec3 col = mix(uColorOuter, uColorInner, mask * (1.0 - r * 0.4));
            // Smooth fade-out over the 0.30s expansion
            float turbulence=snoise(vec3(vUv*4.0,uTime*3.0));
            float alpha=(1.0-pow(uProgress,1.4))*smoothstep(.05,.6,mask+turbulence*.35)*smoothstep(.15,.3,r)*(1.0-smoothstep(.65,1.0,r));
            gl_FragColor = vec4(col * 1.75, alpha);
          
            float detailNoise = snoise(vec3(vUv * vec2(4.0, 7.0), uTime * .7));
            gl_FragColor.rgb *= .9 + .18 * detailNoise;
            gl_FragColor.a *= .6 + .4 * smoothstep(-.6, .4, detailNoise);
}
        `,
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
        side: THREE.DoubleSide
      });

      const vortexMesh = new THREE.Mesh(geo, mat);
      vortexMesh.position.copy(originPos);
      vortexMesh.lookAt(lookTarget);

      // Exact 0.30 second expansion & smooth disappearance
      vfx.spawnAnimatedMesh(vortexMesh, 0.30, (p, m, dt) => {
        mat.uniforms.uTime.value += dt;
        mat.uniforms.uProgress.value = p;
        const scale = 0.45 + p * 2.15;
        m.scale.setScalar(scale);
        m.rotation.z += dt * 12.0;
      });

      // Swirling vortex embers at origin for 0.30s
      vfx.spawnEmitter({
        count: 26,
        texture: 'flame',
        shape: 'circle',
        origin: originPos.clone(),
        radius: 0.45,
        orbitSpeed: 10.0,
        radialRate: 1.4,
        speed: [0.3, 1.2],
        life: [0.18, 0.30],
        size: [0.35, 0.75],
        colorStart: '#ffeb3b',
        colorMid: '#ff5722',
        colorEnd: '#3f3f46'
      });
    }

    /**
     * Spawns the Pillar-Shaped Fire Explosion (Alvo Único / Convergence) or Individual Explosion (Dois Alvos)
     * that subsequently dissipates into falling charcoal ashes!
     */
    function spawnSplitterFireExplosion(impactPos, isPillar = true) {
      sfx.playSplitterImpact(isPillar);
      triggerScreenFlash('#ff7043', isPillar ? 0.42 : 0.28, 140);

      if (isPillar) {
        // Volumetric Pillar of Fire (Explosão em forma de pilar)
        const cylGeo = new THREE.CylinderGeometry(1.1, 1.45, 6.8, 32, 1, true);
        const cylMat = new THREE.ShaderMaterial({
          uniforms: {
            uTime: { value: 0 },
            uProgress: { value: 0 },
            uColBottom: { value: new THREE.Color('#ffeb3b') },
            uColMid: { value: new THREE.Color('#ff5722') },
            uColAsh: { value: new THREE.Color('#27272a') }
          },
          vertexShader: `
            varying vec2 vUv;
            varying vec3 vNormal;
            varying vec3 vViewDir;
            void main() {
              vUv = uv;
              vec4 mvPos = modelViewMatrix * vec4(position, 1.0);
              vNormal = normalize(normalMatrix * normal);
              vViewDir = normalize(-mvPos.xyz);
              gl_Position = projectionMatrix * mvPos;
            }
          `,
          fragmentShader: `${noiseGLSL}

            uniform float uTime;
            uniform float uProgress;
            uniform vec3 uColBottom;
            uniform vec3 uColMid;
            uniform vec3 uColAsh;
            varying vec2 vUv;
            varying vec3 vNormal;
            varying vec3 vViewDir;
            void main() {
              float vFade = pow(1.0 - vUv.y, 1.35) * smoothstep(0.0, 0.08, vUv.y);
              float fresnel = abs(dot(normalize(vNormal), normalize(vViewDir)));
              float flames = 0.5 + 0.5 * sin(vUv.x * 31.415 + uTime * 14.0 - vUv.y * 12.0);
              vec3 fireCol = mix(uColBottom, uColMid, vUv.y * 0.8 + (1.0 - flames) * 0.3);
              // Transition to dark ash in the final 35% of pillar life
              vec3 finalCol = mix(fireCol * 1.6, uColAsh, smoothstep(0.6, 0.95, uProgress));
              float env = sin(uProgress * 3.14159);
              gl_FragColor = vec4(finalCol, vFade * fresnel * flames * env * 0.88);
            
            float detailNoise = snoise(vec3(vUv * vec2(4.0, 7.0), uTime * .7));
            gl_FragColor.rgb *= .9 + .18 * detailNoise;
            gl_FragColor.a *= .6 + .4 * smoothstep(-.6, .4, detailNoise);
}
          `,
          transparent: true,
          depthWrite: false,
          blending: THREE.AdditiveBlending,
          side: THREE.DoubleSide
        });

        const pillar = new THREE.Mesh(cylGeo, cylMat);
        pillar.position.copy(impactPos);
        pillar.position.y = 3.4;

        vfx.spawnAnimatedMesh(pillar, 1.05, (p, m, dt) => {
          cylMat.uniforms.uTime.value += dt;
          cylMat.uniforms.uProgress.value = p;
          const sXZ = p < 0.2 ? THREE.MathUtils.lerp(0.3, 1.15, p / 0.2) : (1.15 - (p - 0.2) * 0.3);
          m.scale.set(sXZ, 1.0, sXZ);
        });

        // Upward Pillar Flame Burst
        vfx.spawnEmitter({
          count: 90,
          texture: 'flame',
          shape: 'cone',
          origin: impactPos.clone().add(new THREE.Vector3(0, 0.2, 0)),
          direction: new THREE.Vector3(0, 1, 0),
          coneAngle: 0.32,
          radius: 0.9,
          speed: [5.5, 11.5],
          life: [0.55, 1.05],
          size: [0.85, 1.65],
          sizeBell: true,
          colorStart: '#fff59d',
          colorMid: '#ff5722',
          colorEnd: '#27272a'
        });
      } else {
        // Individual Fire Explosion (Dois Alvos)
        vfx.spawnEmitter({
          count: 65,
          texture: 'flame',
          shape: 'sphere',
          origin: impactPos.clone().add(new THREE.Vector3(0, 1.0, 0)),
          radius: 0.6,
          speed: [3.2, 7.5],
          life: [0.5, 0.95],
          size: [0.75, 1.45],
          sizeBell: true,
          colorStart: '#ffee58',
          colorMid: '#ff5722',
          colorEnd: '#27272a'
        });
      }

      // Ash Dissipation Shower ("que posteriormente se dissipa em cinzas")
      setTimeout(() => {
        vfx.spawnEmitter({
          count: isPillar ? 75 : 48,
          texture: 'ash',
          shape: 'sphere',
          origin: impactPos.clone().add(new THREE.Vector3(0, isPillar ? 2.4 : 1.5, 0)),
          radius: isPillar ? 1.35 : 0.95,
          speed: [0.6, 2.2],
          gravity: 2.8, // Slow drifting ash gravity
          drag: 0.95,
          life: [0.85, 1.55],
          size: [0.35, 0.72],
          spin: 5.0,
          blending: THREE.NormalBlending,
          colorStart: '#fb923c',
          colorMid: '#3f3f46',
          colorEnd: '#18181b'
        });
      }, 240);
    }

    /**
     * Executes MOVE 6: SPLITTER FLAMES (Ficha 02 — Crawlmon Fire Spec)
     */
    function castSplitterFlames() {
      if (combatState.isCasting) return;
      combatState.isCasting = true;

      const mode = combatState.splitterMode; // 'single' | 'dual' | 'retarget'

      // If Dual or Retarget mode is selected, ensure extra targets (-2 and +2) are visible & alive
      if (mode === 'dual' || mode === 'retarget') {
        if (!combatState.extraClonesActive) {
          setExtraClonesEnabled(true);
        }
        combatState.enemies[1].hp = combatState.enemies[1].maxHp;
        combatState.enemies[2].hp = combatState.enemies[2].maxHp;
        document.getElementById('enemy-1-ko-pill').classList.add('hidden');
      } else {
        if (combatState.enemies[0].hp <= 8) {
          combatState.enemies[0].hp = combatState.enemies[0].maxHp;
        }
      }
      updateAllHUDs();

      const modeLabelMap = {
        single: 'ALVO ÚNICO • CONVERGÊNCIA EM PILAR (20 + MAG = 30)',
        dual: 'DOIS ALVOS • DIVISÃO DE ARCOS ((20 + MAG)/2 = 15)',
        retarget: 'REDIRECIONAMENTO ESPECIAL • MORTE DE ALVO EM VOO'
      };
      showSkillBanner('6 - SPLITTER FLAMES', modeLabelMap[mode], '#ff5722');
      sfx.playSplitterWindup();
      abra.castAnimTimer = 2.4;

      setElementalVignette('rgba(255, 87, 34, 0.28)', 1);

      // Left & Right Hand Projectile Origins relative to Caster (Abra at Slot -1)
      const leftOrigin = context.socket(-1,.65,.5);
      const rightOrigin = context.socket(1,.65,.5);

      const leftBall = createShaderFireballMesh();
      const rightBall = createShaderFireballMesh();
      leftBall.group.position.copy(leftOrigin);
      rightBall.group.position.copy(rightOrigin);
      leftBall.group.scale.setScalar(0.01);
      rightBall.group.scale.setScalar(0.01);
      scene.add(leftBall.group);
      scene.add(rightBall.group);

      // Show 0.70s Windup Cast Telemetry Widget
      const castWidget = document.getElementById('cast-timer-widget');
      const castStageLabel = document.getElementById('cast-stage-label');
      const castTimeNum = document.getElementById('cast-time-numeric');
      const castFill = document.getElementById('cast-progress-fill');
      castWidget.classList.remove('hidden');
      castStageLabel.textContent = 'WINDUP • 2 ESFERAS DE FOGO';

      // =======================================================================
      // PHASE 1: WINDUP (Exact 0.70s progressive growth in both hands)
      // =======================================================================
      const windupDuration = 0.70;
      const windupDummy = new THREE.Object3D();

      // Orbiting windup sparks around both hands
      [leftOrigin, rightOrigin].forEach((handPos) => {
        vfx.spawnEmitter({
          count: 35,
          texture: 'flame',
          shape: 'inward',
          origin: handPos,
          radius: 1.15,
          speed: [1.5, 3.0],
          life: [0.25, 0.55],
          size: [0.35, 0.75],
          colorStart: '#ffeb3b',
          colorMid: '#ff5722',
          colorEnd: '#b71c1c',
          stagger: 0.45
        });
      });

      vfx.spawnAnimatedMesh(windupDummy, windupDuration, (p, m, dt) => {
        leftBall.coreMat.uniforms.uTime.value += dt;
        rightBall.coreMat.uniforms.uTime.value += dt;
        const growScale = THREE.MathUtils.lerp(0.05, 1.05, p);
        leftBall.group.scale.setScalar(growScale);
        rightBall.group.scale.setScalar(growScale);

        castTimeNum.textContent = `${(p * windupDuration).toFixed(2)}s / 0.70s`;
        castFill.style.width = `${p * 100}%`;
      });

      // =======================================================================
      // PHASE 2: RELEASE (0.30s Stationary Vortices + Left/Right Curved Arcs)
      // =======================================================================
      setTimeout(() => {
        sfx.playSplitterRelease();
        castStageLabel.textContent = 'RELEASE • VÓRTICES 0.30s & VOO EM ARCO';

        // Determine initial targets for Left and Right fireballs
        const singleTargetPos = context.center(context.targets[0]);
        const leftTargetInitial = (mode === 'single')
          ? singleTargetPos.clone()
          : context.center(context.targets[1] || context.targets[0]);
        const rightTargetInitial = (mode === 'single')
          ? singleTargetPos.clone()
          : context.center(context.targets[2] || context.targets[1] || context.targets[0]);

        // Spawn the two stationary fire vortices at the projectile origins (0.30s expansion + smooth fade)
        spawnStationaryOriginFireVortex(leftOrigin, leftTargetInitial);
        spawnStationaryOriginFireVortex(rightOrigin, rightTargetInitial);

        // Construct Quadratic Bézier curves:
        // Left ball bows wide to the LEFT; Right ball bows wide to the RIGHT
        const leftCtrl = leftOrigin.clone().lerp(leftTargetInitial, 0.5).add(new THREE.Vector3(-leftOrigin.distanceTo(leftTargetInitial)*.34, 1.35, 0));
        const rightCtrl = rightOrigin.clone().lerp(rightTargetInitial, 0.5).add(new THREE.Vector3(rightOrigin.distanceTo(rightTargetInitial)*.34, 1.35, 0));

        let leftCurve = new THREE.QuadraticBezierCurve3(leftOrigin.clone(), leftCtrl, leftTargetInitial);
        const rightCurve = new THREE.QuadraticBezierCurve3(rightOrigin.clone(), rightCtrl, rightTargetInitial);

        const flightDuration = 0.68;
        let retargetTriggered = false;
        let trailAccum = 0;

        if(mode === 'retarget') setTimeout(() => {
            retargetTriggered = true;
            // Target 1 (Gible Alpha at Slot -2) dies mid-flight!
            combatState.enemies[1].hp = 0;
            combatState.enemies[1].model.shudderTimer = 0.4;
            document.getElementById('enemy-1-ko-pill').classList.remove('hidden');
            updateAllHUDs();
            spawnWorldPopup(ENEMY_SLOTS['-2'], 'MORTE EM VOO!', 'REDIRECIONANDO PROJÉTIL ESQUERDO ➔', 'fire');

            // Dynamically rebuild Left Fireball curve from its current mid-air position to surviving Target 2 (Gible Beta at +2)
            const currentMidAirPos = leftBall.group.position.clone();
            const newRedirectCtrl = currentMidAirPos.clone().lerp(rightTargetInitial, 0.5).add(new THREE.Vector3(0, 2.2, -1.5));
            leftCurve = new THREE.QuadraticBezierCurve3(currentMidAirPos, newRedirectCtrl, rightTargetInitial.clone());
          
        }, flightDuration * .42 * 1000);
        const flightDummy = new THREE.Object3D();
        vfx.spawnAnimatedMesh(flightDummy, flightDuration, (p, m, dt) => {
          leftBall.coreMat.uniforms.uTime.value += dt;
          rightBall.coreMat.uniforms.uTime.value += dt;

          // Update 0.30s Vortex Timer Indicator on HUD
          const vortexTime = Math.min(0.30, p * flightDuration);
          castTimeNum.textContent = `VÓRTICE ${vortexTime.toFixed(2)}s / 0.30s`;

          // SPECIAL REDIRECTION RULE ("Se um dos alvos selecionados morrer durante o voo...")

          // Sample positions along curves
          const leftT = (mode === 'retarget' && retargetTriggered)
            ? Math.min(1.0, (p - 0.42) / 0.58)
            : p;
          const posL = leftCurve.getPoint(leftT);
          const posR = rightCurve.getPoint(p);

          leftBall.group.position.copy(posL);
          rightBall.group.position.copy(posR);

          // Continuous Flame Trail that cools & transforms into falling Charcoal Ashes
          trailAccum += dt;
          if (trailAccum >= 0.028) {
            trailAccum = 0;
            [posL, posR].forEach((ballPos) => {
              // Flame-to-Ash Trail Emitter
              vfx.spawnEmitter({
                count: 8,
                texture: 'flame',
                shape: 'sphere',
                origin: ballPos.clone(),
                radius: 0.22,
                speed: [0.4, 1.3],
                gravity: 2.2, // Ash sinks slowly
                life: [0.35, 0.68],
                size: [0.48, 0.85],
                blending: THREE.NormalBlending,
                colorStart: '#ffeb3b',
                colorMid: '#ff5722',
                colorEnd: '#27272a' // Residual flames turn into dark charcoal ash
              });
            });
          }
        });

        // =====================================================================
        // PHASE 3: IMPACT, PILLAR / INDIVIDUAL EXPLOSION, ASHES & BURN 4s
        // =====================================================================
        setTimeout(() => {
          scene.remove(leftBall.group);
          scene.remove(rightBall.group);
          castWidget.classList.add('hidden');

          if (mode === 'single') {
            // Single Target Convergence: Both trajectories cross at Gible 0 -> Pillar Explosion -> Ash Dissipation
            const hitPos = ENEMY_SLOTS['0'];
            spawnSplitterFireExplosion(hitPos, true);

            const en = combatState.enemies[0];
            en.hp = Math.max(0, en.hp - 30); // 20 + MAG(10) = 30
            en.model.shudderTimer = 0.65;
            applyBurnStatus(en);
            spawnWorldPopup(hitPos, '-30 HP', 'CONVERGÊNCIA EM PILAR • BURN (4s)', 'fire');
          } else if (mode === 'dual') {
            // Dual Target Split: Left hits Slot -2 (15 DMG), Right hits Slot +2 (15 DMG)
            const hitLeft = ENEMY_SLOTS['-2'];
            const hitRight = ENEMY_SLOTS['+2'];
            spawnSplitterFireExplosion(hitLeft, false);
            spawnSplitterFireExplosion(hitRight, false);

            [1, 2].forEach((enemyIdx) => {
              const en = combatState.enemies[enemyIdx];
              en.hp = Math.max(0, en.hp - 15); // (20 + MAG 10) / 2 = 15
              en.model.shudderTimer = 0.55;
              applyBurnStatus(en);
              spawnWorldPopup(en.slotPos, '-15 HP', 'IMPACTO DIVIDIDO • BURN (4s)', 'fire');
            });
          } else if (mode === 'retarget') {
            // Retarget Mode: Both balls converge onto surviving Gible Beta (+2) after Gible Alpha died mid-flight
            const hitSurviving = ENEMY_SLOTS['+2'];
            spawnSplitterFireExplosion(hitSurviving, true);

            const en = combatState.enemies[2];
            en.hp = Math.max(0, en.hp - 30);
            en.model.shudderTimer = 0.65;
            applyBurnStatus(en);
            spawnWorldPopup(hitSurviving, '-30 HP (2x HIT)', 'REDIRECIONAMENTO CONCLUÍDO • BURN (4s)', 'fire');
          }

          updateAllHUDs();
        }, (flightDuration * 1000));

        setTimeout(() => {
          setElementalVignette('', 0);
          fxLight.intensity = 0;
          combatState.isCasting = false;
        }, ((flightDuration + 1.1) * 1000));

      }, (windupDuration * 1000));
    }

    // =========================================================================

return [castMedia,castMabufula,castDig,castSandAttack,castDragonRage,castSplitterFlames,castPsychicCannon,castPsychoOrb];
}
