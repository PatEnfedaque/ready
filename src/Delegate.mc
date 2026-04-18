import Toybox.Lang;
import Toybox.WatchUi;

(:foreground)
class InputDelegate extends WatchUi.BehaviorDelegate {

    private var mView as MainView;

    function initialize(view as MainView) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    // MENU button — non-touch watches open menu directly
    function onMenu() as Boolean {
        return openMenu();
    }

    private function openMenu() as Boolean {
        if (mView.isRecording()) {
            var activeIdx = mView.getActiveZoneIdx();
            var menu = new WatchUi.Menu2({:title => "Recording"});
            menu.addItem(new WatchUi.MenuItem("HR Stop", mView.getHrStop() + " bpm", :hrStop, null));
            if (activeIdx >= 0) {
                var autoStop = (mView.getZones()[activeIdx] as Dictionary)[:autoStop] as Boolean;
                menu.addItem(new WatchUi.MenuItem("Auto Stop", autoStop ? "On" : "Off", :autoStop, null));
            }
            WatchUi.pushView(menu, new RecordingMenuDelegate(mView), WatchUi.SLIDE_UP);
            return true;
        }

        var menu = new WatchUi.Menu2({:title => "Ready"});

        // Add zone option when GPS is ready and slots remain
        if (mView.isGpsReady() && mView.getZoneCount() < MAX_ZONES) {
            menu.addItem(new WatchUi.MenuItem("Add Zone Here", null, :addZone, null));
        }

        // List existing zones
        var zones = mView.getZones();
        for (var i = 0; i < zones.size(); i++) {
            var zone     = zones[i] as Dictionary;
            var sportIdx = zone[:sport]    as Number;
            var autoStop = zone[:autoStop] as Boolean;
            var sub = (SPORT_LABELS[sportIdx] as String) + (autoStop ? " | auto stop" : " | manual stop");
            menu.addItem(new WatchUi.MenuItem("Zone " + (i + 1), sub, i, null));
        }

        menu.addItem(new WatchUi.MenuItem("HR Start",    mView.getHrStart() + " bpm",                      :hrStart, null));
        menu.addItem(new WatchUi.MenuItem("HR Stop",     mView.getHrStop()  + " bpm",                      :hrStop,  null));
        menu.addItem(new WatchUi.MenuItem("Zone Radius", mView.getTriggerRadius().toNumber() + "m",         :radius,  null));
        menu.addItem(new WatchUi.MenuItem("Version",      APP_VERSION,                                       :version, null));

        WatchUi.pushView(menu, new SettingsDelegate(mView), WatchUi.SLIDE_UP);
        return true;
    }

    // Swipe up → open menu (touch devices)
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        if (swipeEvent.getDirection() == WatchUi.SWIPE_UP) {
            return openMenu();
        }
        return false;
    }

    // SELECT / screen tap
    function onSelect() as Boolean {
        if (System.getDeviceSettings().isTouchScreen) {
            if (mView.isManualStop()) {
                mView.setConfirmActive(true);
                WatchUi.pushView(
                    new WatchUi.Confirmation("Resume monitoring?"),
                    new ResumeConfirmDelegate(mView),
                    WatchUi.SLIDE_IMMEDIATE
                );
                return true;
            }
            if (mView.isRecording()) {
                mView.setConfirmActive(true);
                WatchUi.pushView(
                    new WatchUi.Confirmation("Stop activity?"),
                    new StopConfirmDelegate(mView),
                    WatchUi.SLIDE_IMMEDIATE
                );
                return true;
            }
            return true;
        }

        // Non-touch: SELECT stops/resumes recording
        if (mView.isManualStop()) {
            mView.setConfirmActive(true);
            WatchUi.pushView(
                new WatchUi.Confirmation("Resume monitoring?"),
                new ResumeConfirmDelegate(mView),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (mView.isRecording()) {
            mView.setConfirmActive(true);
            WatchUi.pushView(
                new WatchUi.Confirmation("Stop activity?"),
                new StopConfirmDelegate(mView),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
        return true;
    }

    // BACK — confirm before exit; ignore if a confirmation is already showing
    function onBack() as Boolean {
        if (mView.isConfirmActive()) { return true; }
        mView.setConfirmActive(true);
        WatchUi.pushView(
            new WatchUi.Confirmation("Exit Ready?"),
            new ExitConfirmDelegate(mView),
            WatchUi.SLIDE_IMMEDIATE
        );
        return true;
    }
}

(:foreground)
class RecordingMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var mView as MainView;

    function initialize(view as MainView) {
        Menu2InputDelegate.initialize();
        mView = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :hrStop) {
            var menu = new WatchUi.Menu2({:title => "HR Stop"});
            var opts = [50, 60, 70, 80, 90, 100, 110, 120] as Array<Number>;
            for (var i = 0; i < opts.size(); i++) {
                var v = opts[i] as Number;
                menu.addItem(new WatchUi.MenuItem(v + " bpm", (v == mView.getHrStop()) ? "current" : null, v, null));
            }
            WatchUi.pushView(menu, new HrStopMenuDelegate(mView), WatchUi.SLIDE_UP);
        } else if (id == :autoStop) {
            var activeIdx = mView.getActiveZoneIdx();
            if (activeIdx >= 0) {
                var cur = (mView.getZones()[activeIdx] as Dictionary)[:autoStop] as Boolean;
                mView.setZoneAutoStop(activeIdx, !cur);
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    function onBack() as Void { WatchUi.popView(WatchUi.SLIDE_DOWN); }
}

(:foreground)
class ExitConfirmDelegate extends WatchUi.ConfirmationDelegate {

    private var mView as MainView;

    function initialize(view as MainView) {
        ConfirmationDelegate.initialize();
        mView = view;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        mView.setConfirmActive(false);
        if (response == WatchUi.CONFIRM_YES) {
            mView.cleanup();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }
}

(:foreground)
class ResumeConfirmDelegate extends WatchUi.ConfirmationDelegate {

    private var mView as MainView;

    function initialize(view as MainView) {
        ConfirmationDelegate.initialize();
        mView = view;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        mView.setConfirmActive(false);
        if (response == WatchUi.CONFIRM_YES) {
            mView.clearManualStop();
            WatchUi.requestUpdate();
        }
        return true;
    }
}

(:foreground)
class StopConfirmDelegate extends WatchUi.ConfirmationDelegate {

    private var mView as MainView;

    function initialize(view as MainView) {
        ConfirmationDelegate.initialize();
        mView = view;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        mView.setConfirmActive(false);
        if (response == WatchUi.CONFIRM_YES) {
            mView.manualStop();
        }
        return true;
    }
}
