import org.rrd4j.core.RrdDb;
import org.rrd4j.core.RrdRandomAccessFileBackendFactory;

public class DumpRRD {
    public static void main(String[] args) {
        if (args.length < 2) {
            System.out.println("Usage: java DumpRRD <input.rrd> <output.xml>");
            return;
        }
        try {
            RrdDb rrd = RrdDb.getBuilder().setPath(args[0]).setReadOnly(true).setBackendFactory(new RrdRandomAccessFileBackendFactory()).build();
            rrd.exportXml(args[1]);
            rrd.close();
            System.out.println("Erfolgreich exportiert nach " + args[1]);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
