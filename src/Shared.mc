import Toybox.Lang;
import Toybox.Math;

const MAX_ZONES      = 5;
const DEFAULT_RADIUS = 200.0d;

(:foreground)
const APP_VERSION = "1.0.2";

// Haversine great-circle distance in metres
function haversineMetres(
    lat1 as Double, lon1 as Double,
    lat2 as Double, lon2 as Double
) as Double {
    var R    = 6371000.0d;
    var phi1 = Math.toRadians(lat1);
    var phi2 = Math.toRadians(lat2);
    var dPhi = Math.toRadians(lat2 - lat1);
    var dLam = Math.toRadians(lon2 - lon1);

    var a = Math.sin(dPhi / 2.0d) * Math.sin(dPhi / 2.0d)
          + Math.cos(phi1) * Math.cos(phi2)
          * Math.sin(dLam / 2.0d) * Math.sin(dLam / 2.0d);

    return R * 2.0d * Math.atan2(Math.sqrt(a), Math.sqrt(1.0d - a));
}
