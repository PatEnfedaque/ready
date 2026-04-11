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
        var dbg = mView.getHrDebugReduction();
        menu.addItem(new WatchUi.MenuItem("Debug HR",    (dbg == 0) ? "Off" : "-" + dbg,                   :hrDebug, null));
        menu.addItem(new WatchUi.MenuItem("Version",      APP_VERSION,                                       :version, null));

        WatchUi.pushView(menu, new SettingsDelegate(mView), WatchUi.SLIDE_UP);
        return true;
    }

    // Swipe up while arrow is visible → open menu (touch devices)
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        if (swipeEvent.getDirection() == WatchUi.SWIPE_UP && mView.isMenuArrowVisible()) {
            mView.hideMenuArrow();
            return openMenu();
        }
        return false;
    }

    // SELECT / screen tap
    function onSelect() as Boolean {
        if (System.getDeviceSettings().isTouchScreen) {
            // Touch: tap shows up-arrow hint; swipe up within 2s opens menu.
            // Stop/resume confirmations take priority while active.
            if (mView.isManualStop()) {
                mView.hideMenuArrow();
                WatchUi.pushView(
                    new WatchUi.Confirmation("Resume monitoring?"),
                    new ResumeConfirmDelegate(mView),
                    WatchUi.SLIDE_IMMEDIATE
                );
                return true;
            }
            if (mView.isRecording()) {
                mView.hideMenuArrow();
                WatchUi.pushView(
                    new WatchUi.Confirmation("Stop activity?"),
                    new StopConfirmDelegate(mView),
                    WatchUi.SLIDE_IMMEDIATE
                );
                return true;
            }
            mView.showMenuArrow();
            return true;
        }

        // Non-touch: SELECT stops/resumes recording
        if (mView.isManualStop()) {
            WatchUi.pushView(
                new WatchUi.Confirmation("Resume monitoring?"),
                new ResumeConfirmDelegate(mView),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (mView.isRecording()) {
            WatchUi.pushView(
                new WatchUi.Confirmation("Stop activity?"),
                new StopConfirmDelegate(mView),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
        return true;
    }

    // BACK — exit app (no confirmation — session is saved on cleanup)
    function onBack() as Boolean {
        mView.cleanup();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
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
        if (response == WatchUi.CONFIRM_YES) {
            mView.manualStop();
        }
        return true;
    }
}
