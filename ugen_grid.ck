public class UgenGrid
{
    UGen @ ugens[][];

    fun void init(int width, int height) {
        UGen @ _ugens[width][height] @=> ugens;
    }

    fun void set(int x, int y, UGen @ target) {
        target @=> ugens[x][y];
    }

    fun void op(int x, int y, int v) {
        v => get(x, y).op;
    }

    fun UGen @ get(int x, int y) {
        return ugens[x][y];
    }

    fun int height() {
        return ugens.cap();
    }

    fun int width() {
        return ugens[0].cap();
    }

    fun void patch(UGen @ target) {
        for(0 => int x; x < width(); x++) {
            for(0 => int y; y < height(); y++) {
                patch(x, y, target);
            }
        }
    }

    fun void patch(int x, int y, UGen @ target) {
        get(x, y) => target;
    }

    fun void unpatch(int x, int y, UGen @ target) {
        get(x, y) =< target;
    }

    fun void patch(UgenGrid @ grid) {
        if(grid.height() != height() || grid.width() != width()) {
            return;
        }

        for(0 => int x; x < width(); x++) {
            for(0 => int y; y < height(); y++) {
                patch(x, y, grid.get(x, y));
            }
        }
    }
}
