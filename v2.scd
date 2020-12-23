(
f = {
	arg speed=50, top=1000, step=1,
	gift_min=1, gift_max=10, gift_step=;

	var sound,  freq,  rq,  amp,  gift,  sig,  trig,  trig2,  top,  filter,  amp2,  mod, cutoff;

	trig = Impulse.ar(speed/Rand(2, 8));
	trig2 = Impulse.ar(speed/Rand(4, 16));

	gift = Stepper.ar(trig:trig2, min:gift_min, max:gift_max, gift_step);
	freq = Stepper.ar(trig:trig, min:Rand(2, 16)*speed, max:top%speed, freq_step);

	amp = LFNoise0.kr(Rand(10,  24)-gift,  Rand(0.25, 0.55), Rand(0.25, 0.55));
	amp2 = LFNoise0.kr(Rand(8, 32)-gift, Rand(0.4, 0.8));
	rq = LFNoise0.kr(Rand(2, 24)-gift, 0.2,  0.2);
	sound = Pulse.ar(freq-(gift*Rand(25, 50)))*amp;

	cutoff = Rand(Rand(1100, 110), Rand(220, 880))+top+(gift*Rand(2, 6))-(Lag.ar(freq, Rand(0.02, 6))/Rand(50, 100));
	filter = Resonz.ar(sound, cutoff, rq);

	mod = PulseCount.ar(Trig.ar(filter), trig2);
	Pan2.ar(RHPF.ar(filter, Lag.ar(mod, Rand(0.02, 6))*Rand(2, 36)+(gift*Rand(2, 6)), rq,  amp2));
};

s = Server.default;
f.play(target:s);

)
