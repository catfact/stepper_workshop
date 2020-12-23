// v2: factor out `Rand`s to synthdef arguments

// TODO: randomize
// TODO: controlspecs?
// TODO: mouse poll?

(
var synth_func;
var rand_voice_func;

synth_func = {
	arg speed=50, top=1000, step=1,
	gift_min=1, gift_max=10, gift_step=1,
	freq_min=1, freq_max=10, freq_step=1,

	amp_noise_rate = 15, amp_noise_mul = 0.4, amp_noise_add=0.4,
	amp2_noise_rate = 20, amp2_noise_mul = 0.6,

	hpf_mod_lag = 1,
	hpf_mod_mul = 20,
	hpf_gift_mul = 4,


	trig_div=3, trig2_div = 4,

	rq_noise_rate = 10,
	pulse_freq_mod = 30,

	res_cutoff_base=2000, res_cutoff_mod = 4, res_cutoff_mod_lag=1, res_cutoff_mod_div=75;

	var sound, freq, amp,  gift,  sig,  trig,  trig2, filter, amp2, mod, res_cutoff, rq, hpf;

	trig = Impulse.ar(speed/trig_div);
	trig2 = Impulse.ar(speed/trig2_div);

	gift = Stepper.ar(trig:trig2, min:gift_min, max:gift_max, step:gift_step);
	freq = Stepper.ar(trig:trig, min:freq_min, max:freq_max, step:freq_step);

	amp = LFNoise0.kr(amp_noise_rate-gift, amp_noise_mul, amp_noise_add);
	amp2 = LFNoise0.kr(amp2_noise_rate-gift, amp2_noise_mul);
	rq = LFNoise0.kr(rq_noise_rate-gift, 0.2,  0.2);
	sound = Pulse.ar(freq-(gift*pulse_freq_mod))*amp;

	res_cutoff = res_cutoff_base +top+(gift*res_cutoff_mod)-(Lag.ar(freq, res_cutoff_mod_lag)/res_cutoff_mod_div);
	filter = Resonz.ar(sound, res_cutoff, rq);

	mod = PulseCount.ar(Trig.ar(filter), trig2);
	hpf = RHPF.ar(filter, Lag.ar(mod, hpf_mod_lag)*hpf_mod_mul+(gift*hpf_gift_mul), rq, amp2);
	Pan2.ar(hpf);
};

rand_voice_func = {
	arg target;
	var synth,
	speed, top, step,
	gift_min, gift_max, gift_step,
	freq_min, freq_max, freq_step;
	/// ... etc..

	// TODO: randomize

	synth = synth_func.play(
		// args: [...],
		target:target);
	synth
};

rand_voice_func.value(Server.default);

)