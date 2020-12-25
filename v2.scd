// v2: factor out `Rand`s to synthdef arguments

// TODO: mouse poll/modulator?

// assumption: Server.default is running
(
var def;
var rand_voice_func;
var server;

server = Server.default;
server.waitForBoot { Routine {

	def = SynthDef.new(\stepper, {
		arg speed=50, top=1000,
		step_div = 1,
		gift_min=1, gift_max=10, gift_step_div=1,
		freq_min=1,

		amp_noise_rate = 15, amp_noise_mul = 0.4, amp_noise_add=0.4,
		amp2_noise_rate = 20, amp2_noise_mul = 0.6,

		hpf_mod_lag = 1,
		hpf_mod_mul = 20,
		hpf_gift_mul = 4,

		trig_div=3, trig2_div = 4,

		rq_noise_rate = 10,
		pulse_freq_mod = 30,

		res_cutoff_base=2000, res_cutoff_mod = 4, res_cutoff_mod_lag=1, res_cutoff_mod_div=75;

		var sound, step, freq, amp,  gift,  sig, trig, trig2, filter, amp2, mod, res_cutoff, rq, hpf;

		trig = Impulse.ar(speed/trig_div);
		trig2 = Impulse.ar(speed/trig2_div);

		step = top/(step_div-speed);

		gift = Stepper.ar(trig:trig2, min:gift_min, max:gift_max, step:step/gift_step_div);
		freq = Stepper.ar(trig:trig, min:freq_min*speed, max:top%speed, step:step);

		amp = LFNoise0.kr(amp_noise_rate-gift, amp_noise_mul, amp_noise_add);
		amp2 = LFNoise0.kr(amp2_noise_rate-gift, amp2_noise_mul);
		rq = LFNoise0.kr(rq_noise_rate-gift, 0.2,  0.2);

		sound = Pulse.ar(freq-(gift*pulse_freq_mod))*amp;

		res_cutoff = res_cutoff_base +top+(gift*res_cutoff_mod)-(Lag.ar(freq, res_cutoff_mod_lag)/res_cutoff_mod_div);
		filter = Resonz.ar(sound, res_cutoff, rq);

		mod = PulseCount.ar(Trig.ar(filter), trig2);
		hpf = RHPF.ar(filter, Lag.ar(mod, hpf_mod_lag)*hpf_mod_mul+(gift*hpf_gift_mul), rq, amp2);
		Pan2.ar(hpf);
	}).send(Server.default);

	rand_voice_func = {
		arg target;
		var synth;
		var controls, specs, args;

		if (target.isNil, { target = Server.default; });

		controls = Dictionary.new;
		def.allControlNames.do({|ctlname|
			var key = ctlname.name;
			//postln("\\"++key++": ControlSpec.new(0, 1),");
			controls[key] = 0;
		});


		/// FIXME: populate these controlspecs with appropriate ranges/warps,
		/// store this spec structure outside of the voice creation function
		specs = (
                        \speed: ControlSpec.new(50, 100),
			\top: ControlSpec.new(220, 4800),
			\step_div: ControlSpec.new(50, 105),
			\gift_min: ControlSpec.new(1, 2),
			\gift_max: ControlSpec.new(4, 48),
			\gift_step_div: ControlSpec.new(2, 6),
			\freq_min: ControlSpec.new(2, 16),
			\amp_noise_rate: ControlSpec.new(10, 24),
			\amp_noise_mul: ControlSpec.new(0.25, 0.55),
			\amp_noise_add: ControlSpec.new(0.25, 0.55),
			\amp2_noise_rate: ControlSpec.new(8, 32),
			\amp2_noise_mul: ControlSpec.new(0.4, 0.8),
			\hpf_mod_lag: ControlSpec.new(0.02, 6),
			\hpf_mod_mul: ControlSpec.new(2, 36),
			\hpf_gift_mul: ControlSpec.new(2, 6),
			\trig_div: ControlSpec.new(2, 8),
			\trig2_div: ControlSpec.new(4, 16),
			\rq_noise_rate: ControlSpec.new(2, 24),
			\pulse_freq_mod: ControlSpec.new(25, 50),
			\res_cutoff_base: ControlSpec.new(1100, 110),
			\res_cutoff_mod: ControlSpec.new(2, 6),
			\res_cutoff_mod_lag: ControlSpec.new(0.02, 6),
			\res_cutoff_mod_div: ControlSpec.new(50, 100),
		);

		/// FIXME: there might be a builtin sugar to flatten a Dictionary to a [k, v..] array?
		args = List.new;
		specs.keys.do({ |k|
			// FIXME: would be better to `.map` a unit random variable to each spec;
			/// this would respect the warp parameters
			controls[k] = rrand(specs[k].minval, specs[k].maxval);
			args.add(k.asSymbol);
			args.add(controls[k]);
		});
		args = args.asArray;
		synth = Synth.new(def.name, args, target);

	};

	server.sync;

	rand_voice_func.value(Server.default);
}.play; // sync routine
} // server waitForBoot

//
// x = nil;
// y = nil;
// r = Routine { inf.do { arg i;
// 	x = rand_voice_func.value(Server.default);
// 	if(y.notNil, { y.free; });
// 	y = x;
// 	0.25.wait;
// }}.play;

)
