import org.rrd4j.core.RrdDb;
import java.io.FileOutputStream;

public class DumpRRD {
    public static void main(String[] args) {
        if (args.length < 2) {
            System.out.println("Usage: java DumpRRD <input.rrd> <output.xml>");
            return;
        }
        try {
            RrdDb rrd = new RrdDb(args[0]);
            rrd.exportXml(args[1]);
            rrd.close();
            System.out.println("Erfolgreich exportiert nach " + args[1]);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
