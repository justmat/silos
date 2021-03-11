Engine_Silos : CroneEngine {
  classvar num_voices = 4;

  var pg;
  var <buffers;
  var <recorders;
  var <voices;
  var <phases;
  var <levels;
  var effect;
  var effectBus;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    buffers = Array.fill(num_voices, { arg i;
      var bufferLengthSeconds = 8;

      Buffer.alloc(
        context.server,
        context.server.sampleRate * bufferLengthSeconds,
        bufnum: i
      );
    });

    SynthDef(\recordBuf, { arg bufnum = 0, run = 0, preLevel = 1.0, recLevel = 1.0;
      var in = Mix.new(SoundIn.ar([0, 1]));

      RecordBuf.ar(
        in,
        bufnum,
        recLevel: recLevel,
        preLevel: preLevel,
        loop: 1,
        run: run
      );
    }).add;

    SynthDef(\synth, {
      arg out, effectBus, phase_out, level_out, buf,
      gate=0, pos=0, speed=1, jitter=0,
      size=0.1, density=0, density_mod_amt=0, pitch=1, spread=0, gain=1, envscale=1,
      freeze=0, t_reset_pos=0, send=0;

      var grain_trig;
      var jitter_sig;
      var trig_rnd;
      var density_mod;
      var buf_dur;
      var pan_sig;
      var buf_pos;
      var pos_sig;
      var sig;
      var level;
      
      trig_rnd = LFNoise1.kr(density);
      density_mod = density * (2**(trig_rnd * density_mod_amt));      
      grain_trig = Impulse.kr(density_mod);

      buf_dur = BufDur.kr(buf);

      pan_sig = TRand.kr(
        trig: grain_trig,
        lo: spread.neg,
        hi: spread
      );

      jitter_sig = TRand.kr(
        trig: grain_trig,
        lo: buf_dur.reciprocal.neg * jitter,
        hi: buf_dur.reciprocal * jitter
      );

      buf_pos = Phasor.kr(
        trig: t_reset_pos,
        rate: buf_dur.reciprocal / ControlRate.ir * speed,
        resetPos: pos
      );

      pos_sig = Wrap.kr(Select.kr(freeze, [buf_pos, pos]));
      
      // TODO: add controlled size randomness
      sig = GrainBuf.ar(2, grain_trig, size, buf, pitch, pos_sig + jitter_sig, 2, pan_sig, -1.0, 512.0);

      level = EnvGen.kr(Env.asr(1, 1, 1), gate: gate, timeScale: envscale);

      Out.ar(out, sig * level * gain);

      Out.kr(phase_out, pos_sig);
      Out.kr(level_out, level); // ignore gain for level out
      Out.ar(effectBus, sig * level * send);
    }).add;
    
    SynthDef(\effect, {
      arg in, out, verbgain=1, time=2.0, damp=0.1, verbsize=4.0, diff=0.7, modDepth=0.1, modFreq=0.1, low=0.5, mid=1, high=1, lowcut=5000, highcut=2000;
      var sig = In.ar(in, 2);
      sig = JPverb.ar(sig, time, damp, verbsize, diff, modDepth, modFreq, low, mid, high, lowcut, highcut);
      Out.ar(out, sig * verbgain);
    }).add;

    context.server.sync;
    
    // reverb bus
    effectBus = Bus.audio(context.server, 2);
    
    effect = Synth.new(\effect, [\in, effectBus.index, \out, context.out_b.index], target: context.xg);

    phases = Array.fill(num_voices, { arg i; Bus.control(context.server); });
    levels = Array.fill(num_voices, { arg i; Bus.control(context.server); });

    pg = ParGroup.head(context.xg);

    voices = Array.fill(num_voices, { arg i;
      Synth.new(\synth, [
        \out, context.out_b.index,
        \effectBus, effectBus.index,
        \phase_out, phases[i].index,
        \level_out, levels[i].index,
        \buf, buffers[i],
      ], target: pg);
    });

    recorders = Array.fill(num_voices, { arg i;
      Synth.new(\recordBuf, [
        \bufnum, buffers[i].bufnum,
        \run, 0
      ], target: pg);
    });

    context.server.sync;
    
    this.addCommand("time", "f", { arg msg; effect.set(\delayTime, msg[1]); });
    this.addCommand("damp", "f", { arg msg; effect.set(\damp, msg[1]); });
    this.addCommand("verbsize", "f", { arg msg; effect.set(\verbsize, msg[1]); });
    this.addCommand("diff", "f", { arg msg; effect.set(\diff, msg[1]); });
    this.addCommand("mod_depth", "f", { arg msg; effect.set(\modDepth, msg[1]); });
    this.addCommand("mod_freq", "f", { arg msg; effect.set(\modFreq, msg[1]); });
    this.addCommand("low", "f", { arg msg; effect.set(\low, msg[1]); });
    this.addCommand("mid", "f", { arg msg; effect.set(\mid, msg[1]); });
    this.addCommand("high", "f", { arg msg; effect.set(\high, msg[1]); });
    this.addCommand("lowcut", "f", { arg msg; effect.set(\lowcut, msg[1]); });
    this.addCommand("highcut", "f", { arg msg; effect.set(\highcut, msg[1]); });
    this.addCommand("verbgain", "f", { arg msg; effect.set(\verbgain, msg[1]); });

    this.addCommand("read", "is", { arg msg;
      var voice = msg[1] - 1;
      this.readBuf(voice, msg[2]);
    });

    this.addCommand("record", "ii", { arg msg;
      var voice = msg[1] - 1;
      recorders[voice].set(\run, msg[2]);
    });

    this.addCommand("pre_level", "if", { arg msg;
      var voice = msg[1] - 1;
      recorders[voice].set(\preLevel, msg[2]);
    });

    this.addCommand("rec_level", "if", { arg msg;
      var voice = msg[1] - 1;
      recorders[voice].set(\recLevel, msg[2]);
    });

    this.addCommand("seek", "if", { arg msg;
      var voice = msg[1] - 1;

      voices[voice].set(\pos, msg[2]);
      voices[voice].set(\t_reset_pos, 1);
      voices[voice].set(\freeze, 0);
    });

    this.addCommand("gate", "ii", { arg msg;
      var voice = msg[1] - 1;
      voices[voice].set(\gate, msg[2]);
    });

    this.addCommand("speed", "if", { arg msg;
      var voice = msg[1] - 1;
      voices[voice].set(\speed, msg[2]);
    });

    this.addCommand("jitter", "if", { arg msg;
      var voice = msg[1] - 1;
      voices[voice].set(\jitter, msg[2]);
    });

    this.addCommand("size", "if", { arg msg;
      var voice = msg[1] - 1;
      voices[voice].set(\size, msg[2]);
    });

    this.addCommand("density", "if", { arg msg;
      var voice = msg[1] - 1;
      voices[voice].set(\density, msg[2]);
    });
    
    this.addCommand("density_mod_amt", "if", { arg msg;
      var voice = msg[1] - 1;
      voices[voice].set(\density_mod_amt, msg[2]);
    });

    this.addCommand("pitch", "if", { arg msg;
      var voice = msg[1] - 1;
      voices[voice].set(\pitch, msg[2]);
    });

    this.addCommand("spread", "if", { arg msg;
      var voice = msg[1] - 1;
      voices[voice].set(\spread, msg[2]);
    });

    this.addCommand("gain", "if", { arg msg;
      var voice = msg[1] - 1;
      voices[voice].set(\gain, msg[2]);
    });

    this.addCommand("envscale", "if", { arg msg;
      var voice = msg[1] - 1;
      voices[voice].set(\envscale, msg[2]);
    });
    
    this.addCommand("send", "if", { arg msg;
    var voice = msg[1] -1;
    voices[voice].set(\send, msg[2]);
    });

    num_voices.do({ arg i;
      this.addPoll(("phase_" ++ (i + 1)).asSymbol, {
        var val = phases[i].getSynchronous;
        val
      });

      this.addPoll(("level_" ++ (i + 1)).asSymbol, {
        var val = levels[i].getSynchronous;
        val
      });
    });
  }

  free {
    voices.do({ arg voice; voice.free; });
    phases.do({ arg bus; bus.free; });
    levels.do({ arg bus; bus.free; });
    buffers.do({ arg b; b.free; });
    recorders.do({ arg r; r.free; });
    effect.free;
    effectBus.free;
  }
}
