"/wacom/1/pen/0" => string prefix;
9000 => int port;

"/example" => string monome_prefix;
34601 => int monome_port;
"localhost" => string monome_host;
17102 => int monome_send;

Gain gain => dac;
fun void handle(float x, float y, float tilt_x, float tilt_y, float pressure) {
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

PitchCalculator.grid(8, 8, 5, 1, 55.0, 12.0) @=> float pitches[][];
UgenGrid voices;
voices.init(8, 8);
for(0 => int x; x < voices.width(); x++) {
    for(0 => int y; y < voices.height(); y++) {
        SinOsc voice;
        pitches[x][y] => voice.freq;
        voices.set(x, y, voice);
    }
}

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
gain => dac;

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

