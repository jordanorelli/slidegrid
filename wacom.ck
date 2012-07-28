"/wacom/1/pen/0" => string prefix;
9000 => int port;
110.0 => float base_freq;

"/example" => string monome_prefix;
34601 => int monome_port;
"localhost" => string monome_host;
17102 => int monome_send;

Gain gain => PRCRev reverb => dac;;
0.0 => reverb.mix;
false => int down;
0 => float x_init;
0 => float y_init;

fun void handle(float x, float y, float tilt_x, float tilt_y, float pressure) {
    if(down) {
        if(pressure == 0) { // exit down state
            <<< "UP", x, y >>>;
            zeroPitches();
            false => down;
        } else {
            pitchShift(y_init - y);
            x => reverb.mix;
        }
    } else { // if not down
        if(pressure > 0) { // entered down state
            x => x_init;
            y => y_init;
            <<< "DOWN", x_init, y_init >>>;
            true => down;
        }
    }
    pressure => gain.gain;
}

fun void listen() {
    OscRecv recv;
    port => recv.port;
    recv.listen();
    recv.event(prefix, "fffff") @=> OscEvent e;
    while(true) {
        e => now;
        while(e.nextMsg() != 0) {
            e.getFloat() => float x;
            e.getFloat() => float y;
            e.getFloat() => float tilt_x;
            e.getFloat() => float tilt_y;
            e.getFloat() => float pressure;
            handle(x, y, tilt_x, tilt_y, pressure);
        }
    }
}
spork ~ listen();

PitchCalculator.grid(8, 8, 5, 1, base_freq, 12.0) @=> float pitches[][];
UgenGrid voices;
voices.init(8, 8);
for(0 => int x; x < voices.width(); x++) {
    for(0 => int y; y < voices.height(); y++) {
        SinOsc voice;
        voices.set(x, y, voice);
    }
}

fun void zeroPitches() {
    for(0 => int x; x < voices.width(); x++) {
        for(0 => int y; y < voices.height(); y++) {
            voices.get(x, y) $ SinOsc @=> SinOsc s;
            pitches[x][y] => s.freq;
        }
    }
}
zeroPitches();

UgenGrid envelopes;
envelopes.init(8, 8);
for(0 => int x; x < envelopes.width(); x++) {
    for(0 => int y; y < envelopes.height(); y++) {
        ADSR envelope;
        envelope.set(2::ms, 2::ms, 1.0, 100::ms);
        envelope.keyOff();
        envelopes.set(x, y, envelope);
    }
}

voices.patch(envelopes);
envelopes.patch(gain);

fun void pitchShift(int x, int y, float pitch_delta) {
    if(x > 8 || y > 8) return;
    voices.get(x, y) $ SinOsc @=> SinOsc s;
    pitches[x][y] * (1 - pitch_delta) => s.freq;
}

fun void pitchShift(float pitch_delta) {
    <<< "SHIFT", pitch_delta >>>;
    for(0 => int x; x < voices.width(); x++) {
        for(0 => int y; y < voices.height(); y++) {
            pitchShift(x, y, pitch_delta);
        }
    }
}

Monome monome;
monome.init(monome_prefix, monome_port, monome_host, monome_send);

monome.e @=> MonomeKeyEvent e;
while(true) {
    e => now;
    monome.set(e.x, e.y, e.v);
    envelopes.get(e.x, e.y) $ ADSR @=> ADSR envelope;
    if(e.v == 0) {
        envelope.keyOff();
    } else {
        envelope.keyOn();
    }
}


while(true) { 1::hour => now; }

