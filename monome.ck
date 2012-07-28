public class Monome
{
    string         prefix;
    OscSend        send;
    OscRecv        recv;
    MonomeKeyEvent e;

    fun void init(string _prefix, int recv_port, string hostname, int send_port) {
        _prefix => prefix;
        recv_port => recv.port;
        send.setHost(hostname, send_port);
        recv.listen();
        spork ~ listen();
    }

    fun void toggle(int x, int y, int v) {
        if(v != 0 && v != 1) return;
        send.startMsg(prefix+"/grid/led/set", "iii");
        send.addInt(x);
        send.addInt(y);
        send.addInt(v);
    }

    fun void set(int x, int y, int v) {
        if(v == 0) { toggle(x, y, 0); }
        else       { toggle(x, y, 1); }

        send.startMsg(prefix+"/grid/led/set", "iii");
        send.addInt(x);
        send.addInt(y);
        send.addInt(v);
    }

    fun void keyPress(int x, int y, int v) {
        x => e.x;
        y => e.y;
        v => e.v;
        e.broadcast();
        me.yield();
    }

    fun void listen() {
        int x;
        int y;
        int v;
        prefix + "/grid/key" => string path;
        <<< "[monome] listening for monome with prefix " + prefix, "" >>>;
        recv.event(path, "iii") @=> OscEvent oe;
        while(true) {
            oe => now;
            while(oe.nextMsg() != 0) {
                oe.getInt() => x;
                oe.getInt() => y;
                oe.getInt() => v;
                <<< "[monome] " + path, x, y, v >>>;
                keyPress(x, y, v);
            }
        }
    }
}
