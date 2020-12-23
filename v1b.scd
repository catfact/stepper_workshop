// minor formatting changes

(
z = {
	var sound, step, freq, speed, rq, amp, gift, sig, trig, trig2, top, filter, amp2, mod;
	speed = MouseX.kr(1, Rand(50, 100));
	top = MouseY.kr(1, Rand(Rand(220, 880, Rand(1400, Rand(2400, 4800)))));
	trig = Impulse.ar(speed/Rand(2, 8));
	trig2 = Impulse.ar(speed/Rand(4, 16));
	step = top/(Rand(50, 105)-speed);
	gift = Stepper.ar(trig2, 0, 1, Rand(4, Rand(8, 48)), step/Rand(2, 6));
	freq = Stepper.ar(trig, 0, (Rand(2, 16)*speed), (top%speed), step);
	amp = LFNoise0.kr(Rand(10, 24)-gift,  Rand(0.25, 0.55), Rand(0.25, 0.55));
	amp2 = LFNoise0.kr(Rand(8, 32)-gift, Rand(0.4, 0.8));
	rq = LFNoise0.kr(Rand(2, 24)-gift, 0.2,  0.2);
	sound = Pulse.ar(freq-(gift*Rand(25, 50)))*amp;

	filter = Resonz.ar(sound,
		(Rand(Rand(1100,110), Rand(220,880))+top+(gift*Rand(2,6))-(Lag.ar(freq,Rand(0.02,6))/Rand(50,100))),
		rq);

	mod = PulseCount.ar(Trig.ar(filter), trig2);
	RHPF.ar(filter, (Lag.ar(mod, Rand(0.02, 6))*Rand(2, 36)+(gift*Rand(2, 6))), q,  amp2);

}.play
)
