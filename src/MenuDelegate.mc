import Toybox.Lang;
import Toybox.WatchUi;

// ── Main menu ─────────────────────────────────────────────────────────────────
(:foreground)
class SettingsDelegate extends WatchUi.Menu2InputDelegate {

    private var mView as MainView;

    function initialize(view as MainView) {
        Menu2InputDelegate.initialize();
        mView = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :addZone) {
            mView.addCurrentLocationAsZone();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id instanceof Number) {
            // Zone index — open zone edit menu
            var idx      = id as Number;
            var zone     = (mView.getZones()[idx]) as Dictionary;
            var sportIdx = zone[:sport]    as Number;
            var autoStop = zone[:autoStop] as Boolean;
            var timeout  = mView.getZoneStopTimeout(idx);
            var menu = new WatchUi.Menu2({:title => "Zone " + (idx + 1)});
            menu.addItem(new WatchUi.MenuItem("Sport",        SPORT_LABELS[sportIdx] as String,   :sport,       null));
            menu.addItem(new WatchUi.MenuItem("Auto Stop",    autoStop ? "On" : "Off",            :autoStop,    null));
            menu.addItem(new WatchUi.MenuItem("Stop Timeout", formatTimeout(timeout),             :stopTimeout, null));
            menu.addItem(new WatchUi.MenuItem("Delete",       null,                              :delete,      null));
            WatchUi.pushView(menu, new ZoneMenuDelegate(mView, idx), WatchUi.SLIDE_UP);
        } else if (id == :hrStart) {
            var menu = new WatchUi.Menu2({:title => "HR Start"});
            var opts = [90, 100, 110, 120, 130, 140, 150] as Array<Number>;
            for (var i = 0; i < opts.size(); i++) {
                var v = opts[i] as Number;
                menu.addItem(new WatchUi.MenuItem(v + " bpm", (v == mView.getHrStart()) ? "current" : null, v, null));
            }
            WatchUi.pushView(menu, new HrStartMenuDelegate(mView), WatchUi.SLIDE_UP);
        } else if (id == :hrStop) {
            var menu = new WatchUi.Menu2({:title => "HR Stop"});
            var opts = [50, 60, 70, 80, 90, 100, 110, 120] as Array<Number>;
            for (var i = 0; i < opts.size(); i++) {
                var v = opts[i] as Number;
                menu.addItem(new WatchUi.MenuItem(v + " bpm", (v == mView.getHrStop()) ? "current" : null, v, null));
            }
            WatchUi.pushView(menu, new HrStopMenuDelegate(mView), WatchUi.SLIDE_UP);
        } else if (id == :radius) {
            var menu = new WatchUi.Menu2({:title => "Zone Radius"});
            var opts = [100, 150, 200, 300, 500] as Array<Number>;
            for (var i = 0; i < opts.size(); i++) {
                var v = opts[i] as Number;
                menu.addItem(new WatchUi.MenuItem(v + "m", (v == mView.getTriggerRadius().toNumber()) ? "current" : null, v, null));
            }
            WatchUi.pushView(menu, new RadiusMenuDelegate(mView), WatchUi.SLIDE_UP);
        } else if (id == :version) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

// ── Zone edit menu ────────────────────────────────────────────────────────────
(:foreground)
class ZoneMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var mView as MainView;
    private var mIdx  as Number;

    function initialize(view as MainView, idx as Number) {
        Menu2InputDelegate.initialize();
        mView = view;
        mIdx  = idx;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :sport) {
            var menu     = new WatchUi.Menu2({:title => "Sport"});
            var curSport = ((mView.getZones()[mIdx]) as Dictionary)[:sport] as Number;
            for (var i = 0; i < SPORT_LABELS.size(); i++) {
                menu.addItem(new WatchUi.MenuItem(
                    SPORT_LABELS[i] as String,
                    (i == curSport) ? "current" : null,
                    i, null));
            }
            WatchUi.pushView(menu, new ZoneSportMenuDelegate(mView, mIdx), WatchUi.SLIDE_UP);
        } else if (id == :autoStop) {
            var cur = ((mView.getZones()[mIdx]) as Dictionary)[:autoStop] as Boolean;
            mView.setZoneAutoStop(mIdx, !cur);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :stopTimeout) {
            var menu = new WatchUi.Menu2({:title => "Stop Timeout"});
            var opts = [15, 30, 60, 120, 300, 600] as Array<Number>;
            var cur  = mView.getZoneStopTimeout(mIdx);
            for (var i = 0; i < opts.size(); i++) {
                var v = opts[i] as Number;
                menu.addItem(new WatchUi.MenuItem(formatTimeout(v), (v == cur) ? "current" : null, v, null));
            }
            WatchUi.pushView(menu, new ZoneTimeoutMenuDelegate(mView, mIdx), WatchUi.SLIDE_UP);
        } else if (id == :delete) {
            WatchUi.pushView(
                new WatchUi.Confirmation("Delete Zone " + (mIdx + 1) + "?"),
                new ZoneDeleteConfirmDelegate(mView, mIdx),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }

    function onBack() as Void { WatchUi.popView(WatchUi.SLIDE_DOWN); }
}

// ── Zone sport menu ───────────────────────────────────────────────────────────
(:foreground)
class ZoneSportMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var mView as MainView;
    private var mIdx  as Number;

    function initialize(view as MainView, idx as Number) {
        Menu2InputDelegate.initialize();
        mView = view;
        mIdx  = idx;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        mView.setZoneSport(mIdx, item.getId() as Number);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void { WatchUi.popView(WatchUi.SLIDE_DOWN); }
}

// ── HR Start sub-menu ─────────────────────────────────────────────────────────
(:foreground)
class HrStartMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var mView as MainView;
    function initialize(view as MainView) { Menu2InputDelegate.initialize(); mView = view; }
    function onSelect(item as WatchUi.MenuItem) as Void {
        mView.setHrStart(item.getId() as Number);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    function onBack() as Void { WatchUi.popView(WatchUi.SLIDE_DOWN); }
}

// ── HR Stop sub-menu ──────────────────────────────────────────────────────────
(:foreground)
class HrStopMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var mView as MainView;
    function initialize(view as MainView) { Menu2InputDelegate.initialize(); mView = view; }
    function onSelect(item as WatchUi.MenuItem) as Void {
        mView.setHrStop(item.getId() as Number);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    function onBack() as Void { WatchUi.popView(WatchUi.SLIDE_DOWN); }
}

// ── Zone Radius sub-menu ──────────────────────────────────────────────────────
(:foreground)
class RadiusMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var mView as MainView;
    function initialize(view as MainView) { Menu2InputDelegate.initialize(); mView = view; }
    function onSelect(item as WatchUi.MenuItem) as Void {
        mView.setTriggerRadius((item.getId() as Number).toDouble());
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    function onBack() as Void { WatchUi.popView(WatchUi.SLIDE_DOWN); }
}

// ── Timeout formatter (shared by zone menu and timeout delegate) ──────────────
(:foreground)
function formatTimeout(secs as Number) as String {
    if (secs < 60)  { return secs + "s"; }
    if (secs < 120) { return "1 min"; }
    return (secs / 60) + " min";
}

// ── Zone stop timeout sub-menu ────────────────────────────────────────────────
(:foreground)
class ZoneTimeoutMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var mView as MainView;
    private var mIdx  as Number;
    function initialize(view as MainView, idx as Number) {
        Menu2InputDelegate.initialize();
        mView = view;
        mIdx  = idx;
    }
    function onSelect(item as WatchUi.MenuItem) as Void {
        mView.setZoneStopTimeout(mIdx, item.getId() as Number);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    function onBack() as Void { WatchUi.popView(WatchUi.SLIDE_DOWN); }
}

// ── Zone delete confirmation ───────────────────────────────────────────────────
(:foreground)
class ZoneDeleteConfirmDelegate extends WatchUi.ConfirmationDelegate {
    private var mView as MainView;
    private var mIdx  as Number;

    function initialize(view as MainView, idx as Number) {
        ConfirmationDelegate.initialize();
        mView = view;
        mIdx  = idx;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            mView.deleteZone(mIdx);
            WatchUi.popView(WatchUi.SLIDE_DOWN); // confirmation
            WatchUi.popView(WatchUi.SLIDE_DOWN); // zone menu
            WatchUi.popView(WatchUi.SLIDE_DOWN); // main menu
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN); // confirmation only
        }
        return true;
    }
}
