import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class App extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    (:typecheck(false))
    function getInitialView() {
        var view = new MainView();
        return [view, new InputDelegate(view)];
    }
}

(:typecheck(false))
function getApp() {
    return Application.getApp() as App;
}
