SynthDef.new(\steppers, {
	arg giftOut, freqOut;
	speed=50, top=1000,
	step_div = 1,
	gift_min=1, gift_max=10, gift_step_div=1,
	freq_min=1;

	trig = Impulse.ar(speed/trig_div);
	trig2 = Impulse.ar(speed/trig2_div);

	step = top/(step_div-speed);

	gift = Stepper.ar(trig:trig2, min:gift_min, max:gift_max, step:step/gift_step_div);
	freq = Stepper.ar(trig:trig, min:freq_min*speed, max:top%speed, step:step);
	Out.kr(giftOut, gift);
	Out.kr(freqOut, freq);
}).send(s);


SynthDef.new(\rand_mods, {
	arg giftIn, ampOut, amp2Out, rqOut;
	var amp, amp2, rq;
	amp = LFNoise0.kr(amp_noise_rate-gift, amp_noise_mul, amp_noise_add);
	amp2 = LFNoise0.kr(amp2_noise_rate-gift, amp2_noise_mul);
	rq = LFNoise0.kr(rq_noise_rate-gift, 0.2,  0.2);
	Out.kr(ampOut, amp);
	Out.kr(amp2Out, amp2);
	Out.kr(rqOut, rq);
}).send(s);


SynthDef.new(\generator, {
	arg out;
	sound = Pulse.ar(freq-(gift*pulse_freq_mod))*amp;
	Out.ar(out, sound);
});

SynthDef.new(\filters, {
	arg giftIn;
	res_cutoff = res_cutoff_base +top+(gift*res_cutoff_mod)-(Lag.ar(freq, res_cutoff_mod_lag)/res_cutoff_mod_div);
	filter = Resonz.ar(sound, res_cutoff, rq);

	mod = PulseCount.ar(Trig.ar(filter), trig2);
	hpf_cutoff= Lag.ar(mod, hpf_mod_lag)*hpf_mod_mul+(gift*hpf_gift_mul);
	hpf = RHPF.ar(filter, hpf_cutoff, rq, amp2);
	Out.ar(out, Pan2.ar(hpf));
}).send(s);

~specs =  (
	\speed: ControlSpec.new(50, 100),
	\top: ControlSpec.new(220, 4800, \exp),
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

~new_voice = {
	var synths, busses, controlOutBus, controlInBus, controlMapSynth;
	synths = Dictionary.new;
	//... add to synths
	// .. dict of busses.
	/// wire them up..
	controlOutBus = Dictionary.new;
	controlInBus = Dictionary.new;
	~specs.do({arg key, spec;

		controlOutBus[key] = Bus.control(s);
		/// .map controlOutBus to synth..
		controlInBus[key] = Bus.control(s);
		controlMapSynth[key] = {
			Out.kr(controlOutBus[key].index,
				spec.map(In.kr(controlInBus[key]))
			);
		}.play(s);

	});
	(
		\synths: synths,
		\controlInBus: controlInBus
	)
};

~mod_busses = Array.fill(4, {Bus.control(s)});
~mod_ugens = [MouseX.kr, MouseY.kr, LFNoise1.kr(1), LFTri.kr(1)];
~mod_sources = Array.fill(4, {
	arg i;
	var out;
	out = ~mod_busses[i].index;
	{ Out.kr(out, ~mod_ugens[i]); }.play(s);
});

// @param voice: dictionary returned by ~new_voice.value
~connect = { arg voice;
	arg sourceIndex, targetName;
	~mod_sources[sourceIndex].set(\out, voice['controlInBus'].index);
};

~dummy_bus = Bus.control(1);

~disconnect = { arg voice;
	arg sourceIndex, targetName;
	~mod_sources[sourceIndex].set(\out, ~dummy_bus.index);
};


// /// hm.. this is actually pointless because multiple connections to the same input will be overwritten
// // may as well just set a single connection
/// need another layer of synths/busses for summing..
//
// ~patch_points = Array.fill(~mod_sources.size, {
// 	~specs.collect({ arg key, spec;
// 		{ /* little synth patching mod source to target named controlInBus */ }
// 	});
// });
//
//
// ~connect = { arg sourceIndex, targetName;
// 	~patch_points[sourceIndex][targetName].run(true);
// };
//
// ~disconnect = { arg sourceIndex, targetName;
// 	~patch_points[sourceIndex][targetName].run(false);
// };
//
