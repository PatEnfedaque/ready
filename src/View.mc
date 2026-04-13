import Toybox.Application;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.Timer;
import Toybox.Math;

// Sport definitions — index-matched, alphabetical
(:foreground)
const SPORT_LABELS = [
    "Am. Football",   "Alpine Skiing",  "Auto Racing",
    "Baseball",       "Basketball",     "Boating",
    "Boxing",         "Cricket",        "XC Skiing",
    "Cycling",        "Disc Golf",      "Driving",
    "E-Biking",       "Fishing",        "Fitness Equip.",
    "Flying",         "Floor Climbing", "Generic",
    "Golf",           "Grinding",       "Hang Gliding",
    "Health Monitor", "Hiking",         "HIIT",
    "Hockey",         "Horseback",      "Hunting",
    "Ice Skating",    "Inline Skating", "Jumpmaster",
    "Kayaking",       "Kitesurfing",    "Lacrosse",
    "Marine",         "Meditation",     "Motorcycling",
    "Mountaineering", "Multisport",     "Paddling",
    "Para Sport",     "Racket",         "Rafting",
    "Rock Climbing",  "Rowing",         "Rugby",
    "Running",        "Sailing",        "Shooting",
    "Sky Diving",     "Snowboarding",   "Snowmobiling",
    "Snowshoeing",    "Soccer",         "Softball Fast",
    "Softball Slow",  "SUP",            "Surfing",
    "Swimming",       "Tactical",       "Team Sport",
    "Tennis",         "Training",       "Transition",
    "Video Gaming",   "Volleyball",     "Wakeboarding",
    "Wakesurfing",    "Walking",        "Water Skiing",
    "Water Tubing",   "Wheelchair Run", "Wheelchair Walk",
    "Windsurfing",    "Winter Sport"
] as Array<String>;

(:foreground)
const SPORT_SPORTS = [
    Activity.SPORT_AMERICAN_FOOTBALL,       Activity.SPORT_ALPINE_SKIING,        Activity.SPORT_AUTO_RACING,
    Activity.SPORT_BASEBALL,                Activity.SPORT_BASKETBALL,           Activity.SPORT_BOATING,
    Activity.SPORT_BOXING,                  Activity.SPORT_CRICKET,              Activity.SPORT_CROSS_COUNTRY_SKIING,
    Activity.SPORT_CYCLING,                 Activity.SPORT_DISC_GOLF,            Activity.SPORT_DRIVING,
    Activity.SPORT_E_BIKING,                Activity.SPORT_FISHING,              Activity.SPORT_FITNESS_EQUIPMENT,
    Activity.SPORT_FLYING,                  Activity.SPORT_FLOOR_CLIMBING,       Activity.SPORT_GENERIC,
    Activity.SPORT_GOLF,                    Activity.SPORT_GRINDING,             Activity.SPORT_HANG_GLIDING,
    Activity.SPORT_HEALTH_MONITORING,       Activity.SPORT_HIKING,               Activity.SPORT_HIIT,
    Activity.SPORT_HOCKEY,                  Activity.SPORT_HORSEBACK_RIDING,     Activity.SPORT_HUNTING,
    Activity.SPORT_ICE_SKATING,             Activity.SPORT_INLINE_SKATING,       Activity.SPORT_JUMPMASTER,
    Activity.SPORT_KAYAKING,                Activity.SPORT_KITESURFING,          Activity.SPORT_LACROSSE,
    Activity.SPORT_MARINE,                  Activity.SPORT_MEDITATION,           Activity.SPORT_MOTORCYCLING,
    Activity.SPORT_MOUNTAINEERING,          Activity.SPORT_MULTISPORT,           Activity.SPORT_PADDLING,
    Activity.SPORT_PARA_SPORT,              Activity.SPORT_RACKET,               Activity.SPORT_RAFTING,
    Activity.SPORT_ROCK_CLIMBING,           Activity.SPORT_ROWING,               Activity.SPORT_RUGBY,
    Activity.SPORT_RUNNING,                 Activity.SPORT_SAILING,              Activity.SPORT_SHOOTING,
    Activity.SPORT_SKY_DIVING,              Activity.SPORT_SNOWBOARDING,         Activity.SPORT_SNOWMOBILING,
    Activity.SPORT_SNOWSHOEING,             Activity.SPORT_SOCCER,               Activity.SPORT_SOFTBALL_FAST_PITCH,
    Activity.SPORT_SOFTBALL_SLOW_PITCH,     Activity.SPORT_STAND_UP_PADDLEBOARDING, Activity.SPORT_SURFING,
    Activity.SPORT_SWIMMING,                Activity.SPORT_TACTICAL,             Activity.SPORT_TEAM_SPORT,
    Activity.SPORT_TENNIS,                  Activity.SPORT_TRAINING,             Activity.SPORT_TRANSITION,
    Activity.SPORT_VIDEO_GAMING,            Activity.SPORT_VOLLEYBALL,           Activity.SPORT_WAKEBOARDING,
    Activity.SPORT_WAKESURFING,             Activity.SPORT_WALKING,              Activity.SPORT_WATER_SKIING,
    Activity.SPORT_WATER_TUBING,            Activity.SPORT_WHEELCHAIR_PUSH_RUN,  Activity.SPORT_WHEELCHAIR_PUSH_WALK,
    Activity.SPORT_WINDSURFING,             Activity.SPORT_WINTER_SPORT
] as Array<Number>;


(:foreground)
class MainView extends WatchUi.View {

    // Session state
    private var mSession     as ActivityRecording.Session? = null;
    private var mIsRecording as Boolean = false;

    // Sensor readings
    private var mHeartRate as Number  = 0;
    private var mLat       as Double  = 0.0d;
    private var mLon       as Double  = 0.0d;
    private var mGpsReady  as Boolean = false;

    // HR thresholds
    private var mHrStart          as Number = 120;
    private var mHrStop           as Number = 100;
    private var mHrDebugReduction as Number = 0;

    // Auto-start/stop counters
    private var mHighHrSeconds as Number = 0;
    private var mLowHrSeconds  as Number = 0;

    // Manual-stop pause (suppresses auto-start; clears on SELECT, zone exit, or HR < HrStop)
    private var mManualStop as Boolean = false;

    // Zones and active zone
    private var mZones          as Array<Dictionary> = [];
    private var mActiveZoneIdx  as Number  = -1;
    private var mPrevActiveZone as Boolean = false;  // for edge-triggered zone-entry vibration

    // Global trigger radius
    private var mTriggerRadius as Double = DEFAULT_RADIUS;

    // UI
    private var mTimer           as Timer.Timer? = null;
    private var mStatus          as String  = "Waiting for GPS...";
    private var mMenuArrowVisible as Boolean = false;
    private var mMenuArrowSeconds as Number  = 0;

    // Confirmation dialog auto-dismiss — dedicated timer so it fires while MainView is hidden
    private var mConfirmActive as Boolean      = false;
    private var mConfirmTimer  as Timer.Timer? = null;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
        // Confirmation was dismissed externally — cancel the timer and clear the flag
        setConfirmActive(false);
        loadSettings();
        Sensor.setEnabledSensors([ Sensor.SENSOR_HEARTRATE ]);
        Sensor.enableSensorEvents(method(:onSensor));
        Position.enableLocationEvents(
            { :acquisitionType => Position.LOCATION_CONTINUOUS },
            method(:onPosition)
        );
        mTimer = new Timer.Timer();
        mTimer.start(method(:onTimer), 1000, true);
        checkAutoLogic();
        WatchUi.requestUpdate();
    }

    function onHide() as Void {
        if (mTimer != null) { mTimer.stop(); mTimer = null; }
        Sensor.enableSensorEvents(null);
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
    }

    // ── Settings persistence ───────────────────────────────────────────────
    private function loadSettings() as Void {
        var radius = Application.Properties.getValue("TriggerRadius");
        if (radius instanceof Float) { mTriggerRadius = (radius as Float).toDouble(); }

        var hrStart = Application.Properties.getValue("HrStart");
        if (hrStart instanceof Number) { mHrStart = hrStart as Number; }
        var hrStop = Application.Properties.getValue("HrStop");
        if (hrStop instanceof Number) { mHrStop = hrStop as Number; }
        var hrDbg = Application.Properties.getValue("HrDebugReduction");
        if (hrDbg instanceof Number) { mHrDebugReduction = hrDbg as Number; }

        mZones = [];
        var count = Application.Properties.getValue("ZoneCount");
        if (count instanceof Number) {
            var n = count as Number;
            for (var i = 0; i < n && i < MAX_ZONES; i++) {
                var latVal  = Application.Properties.getValue("Zone" + i + "Lat");
                var lonVal  = Application.Properties.getValue("Zone" + i + "Lon");
                var sportV  = Application.Properties.getValue("Zone" + i + "Sport");
                var stopV   = Application.Properties.getValue("Zone" + i + "AutoStop");
                if (latVal instanceof String && lonVal instanceof String) {
                    var lat = (latVal as String).toDouble();
                    var lon = (lonVal as String).toDouble();
                    if (lat != null && lon != null) {
                        var sport       = (sportV instanceof Number)  ? sportV as Number  : 0;
                        var autoStop    = (stopV  instanceof Boolean) ? stopV  as Boolean : true;
                        var timeoutV    = Application.Properties.getValue("Zone" + i + "StopTimeout");
                        var stopTimeout = (timeoutV instanceof Number) ? timeoutV as Number : 30;
                        mZones.add({:lat => lat as Double, :lon => lon as Double,
                                    :sport => sport, :autoStop => autoStop, :stopTimeout => stopTimeout});
                    }
                }
            }
        }

        if (!mIsRecording) {
            mStatus = (mZones.size() == 0) ? "No zones set" : "Waiting for GPS...";
        }
    }

    function saveZones() as Void {
        Application.Properties.setValue("ZoneCount", mZones.size());
        for (var i = 0; i < mZones.size(); i++) {
            var zone = mZones[i] as Dictionary;
            Application.Properties.setValue("Zone" + i + "Lat",     (zone[:lat] as Double).format("%.6f"));
            Application.Properties.setValue("Zone" + i + "Lon",     (zone[:lon] as Double).format("%.6f"));
            Application.Properties.setValue("Zone" + i + "Sport",       zone[:sport]       as Number);
            Application.Properties.setValue("Zone" + i + "AutoStop",    zone[:autoStop]    as Boolean);
            Application.Properties.setValue("Zone" + i + "StopTimeout", zone[:stopTimeout] as Number);
        }
    }

    // ── Getters ───────────────────────────────────────────────────────────
    function getHrStart()          as Number           { return mHrStart; }
    function getHrStop()           as Number           { return mHrStop; }
    function getTriggerRadius()    as Double           { return mTriggerRadius; }
    function getHrDebugReduction() as Number           { return mHrDebugReduction; }
    function getZones()            as Array<Dictionary> { return mZones; }
    function getZoneCount()        as Number           { return mZones.size(); }
    function isGpsReady()          as Boolean          { return mGpsReady; }
    function isRecording()         as Boolean          { return mIsRecording; }

    // ── Setters ───────────────────────────────────────────────────────────
    function setHrStart(val as Number) as Void {
        mHrStart = val;
        Application.Properties.setValue("HrStart", val);
    }
    function setHrStop(val as Number) as Void {
        mHrStop = val;
        Application.Properties.setValue("HrStop", val);
    }
    function setTriggerRadius(val as Double) as Void {
        mTriggerRadius = val;
        Application.Properties.setValue("TriggerRadius", val.toFloat());
    }
    function setHrDebugReduction(val as Number) as Void {
        mHrDebugReduction = val;
        Application.Properties.setValue("HrDebugReduction", val);
    }

    // ── Zone management ───────────────────────────────────────────────────
    function addCurrentLocationAsZone() as Void {
        if (!mGpsReady || mZones.size() >= MAX_ZONES) { return; }
        mZones.add({:lat => mLat, :lon => mLon, :sport => 0, :autoStop => true, :stopTimeout => 30});
        saveZones();
        mStatus = "Zone " + mZones.size() + " added!";
    }

    function setZoneSport(idx as Number, sport as Number) as Void {
        if (idx < 0 || idx >= mZones.size()) { return; }
        var zone = mZones[idx] as Dictionary;
        zone[:sport] = sport;
        saveZones();
    }

    function setZoneAutoStop(idx as Number, autoStop as Boolean) as Void {
        if (idx < 0 || idx >= mZones.size()) { return; }
        var zone = mZones[idx] as Dictionary;
        zone[:autoStop] = autoStop;
        saveZones();
    }

    function getZoneStopTimeout(idx as Number) as Number {
        if (idx < 0 || idx >= mZones.size()) { return 30; }
        return (mZones[idx] as Dictionary)[:stopTimeout] as Number;
    }

    function setZoneStopTimeout(idx as Number, val as Number) as Void {
        if (idx < 0 || idx >= mZones.size()) { return; }
        var zone = mZones[idx] as Dictionary;
        zone[:stopTimeout] = val;
        saveZones();
    }

    function deleteZone(idx as Number) as Void {
        if (idx < 0 || idx >= mZones.size()) { return; }
        var newZones = [] as Array<Dictionary>;
        for (var i = 0; i < mZones.size(); i++) {
            if (i != idx) { newZones.add(mZones[i] as Dictionary); }
        }
        mZones = newZones;
        saveZones();
        if (mZones.size() == 0) { mStatus = "No zones set"; }
    }

    // ── Sensor callback ───────────────────────────────────────────────────
    function onSensor(sensorInfo as Sensor.Info) as Void {
        if (sensorInfo.heartRate != null) {
            mHeartRate = sensorInfo.heartRate as Number;
        }
        checkAutoLogic();
    }

    // ── Position callback ─────────────────────────────────────────────────
    function onPosition(posInfo as Position.Info) as Void {
        var pos = posInfo.position;
        if (pos != null) {
            var coords = pos.toDegrees();
            mLat      = coords[0] as Double;
            mLon      = coords[1] as Double;
            mGpsReady = true;
        }
        checkAutoLogic();
    }

    // ── Confirmation dialog tracking ──────────────────────────────────────
    function setConfirmActive(active as Boolean) as Void {
        mConfirmActive = active;
        if (active) {
            mConfirmTimer = new Timer.Timer();
            mConfirmTimer.start(method(:onConfirmTimeout), 5000, false);
        } else {
            if (mConfirmTimer != null) { mConfirmTimer.stop(); mConfirmTimer = null; }
        }
    }

    function onConfirmTimeout() as Void {
        mConfirmActive = false;
        mConfirmTimer  = null;
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function isConfirmActive() as Boolean { return mConfirmActive; }

    // ── Timer ─────────────────────────────────────────────────────────────
    function onTimer() as Void {
        // Detect externally-invalidated session
        if (mIsRecording && (mSession == null || !mSession.isRecording())) {
            teardownSession();
        }

        if (mMenuArrowVisible) {
            mMenuArrowSeconds--;
            if (mMenuArrowSeconds <= 0) { mMenuArrowVisible = false; }
        }

        var effHrStop    = mHrStop - mHrDebugReduction;
        var zoneAutoStop = mActiveZoneIdx >= 0 && mActiveZoneIdx < mZones.size()
            && ((mZones[mActiveZoneIdx] as Dictionary)[:autoStop] as Boolean);

        if (mIsRecording && zoneAutoStop && mHeartRate > 0 && mHeartRate < effHrStop) {
            mLowHrSeconds++;
            var stopTimeout = (mZones[mActiveZoneIdx] as Dictionary)[:stopTimeout] as Number;
            if (mLowHrSeconds >= stopTimeout) {
                stopActivity();
            }
        } else {
            mLowHrSeconds = 0;
        }

        var effHrStart = mHrStart - mHrDebugReduction;
        if (!mIsRecording && mHeartRate >= effHrStart) {
            mHighHrSeconds++;
        } else {
            mHighHrSeconds = 0;
        }
        checkAutoLogic();
        WatchUi.requestUpdate();
    }

    // ── Auto-start / auto-stop logic ──────────────────────────────────────
    private function checkAutoLogic() as Void {
        if (!mGpsReady) {
            mStatus = "Waiting for GPS...";
            return;
        }
        if (mZones.size() == 0) {
            mStatus = "No zones set";
            return;
        }
        if (mIsRecording) { return; }

        // Find nearest zone in range
        var nearestIdx  = -1;
        var nearestDist = mTriggerRadius + 1.0d;
        var minDist     = -1.0d;

        for (var i = 0; i < mZones.size(); i++) {
            var zone = mZones[i] as Dictionary;
            var dist = haversineMetres(mLat, mLon, zone[:lat] as Double, zone[:lon] as Double);
            if (minDist < 0.0d || dist < minDist) { minDist = dist; }
            if (dist <= mTriggerRadius && dist < nearestDist) {
                nearestDist = dist;
                nearestIdx  = i;
            }
        }

        if (nearestIdx == -1) {
            mManualStop     = false;  // left zone — clear pause
            mActiveZoneIdx  = -1;
            mPrevActiveZone = false;
            if (minDist >= 1000.0d) {
                mStatus = (minDist / 1000.0d).format("%.1f") + "km away";
            } else {
                mStatus = minDist.format("%d") + "m away";
            }
        } else {
            var justEntered = !mPrevActiveZone;
            mPrevActiveZone = true;
            mActiveZoneIdx  = nearestIdx;
            if (justEntered) {
                if (Attention has :vibrate) {
                    Attention.vibrate([
                        new Attention.VibeProfile(100, 500),
                        new Attention.VibeProfile(0,   200),
                        new Attention.VibeProfile(100, 500)
                    ]);
                }
            }
            if (mManualStop) {
                var effStop = mHrStop - mHrDebugReduction;
                if (mHeartRate > 0 && mHeartRate < effStop) {
                    mManualStop = false;  // HR dropped low — clear pause
                } else {
                    mStatus = "Monitoring paused";
                    return;
                }
            }
            var zone       = mZones[nearestIdx] as Dictionary;
            var sportIdx   = zone[:sport] as Number;
            var sportLabel = SPORT_LABELS[sportIdx] as String;
            var effStart   = mHrStart - mHrDebugReduction;
            if (mHeartRate >= effStart) {
                if (mHighHrSeconds >= 5) {
                    startActivity();
                } else {
                    mStatus = sportLabel + " starting in " + (5 - mHighHrSeconds) + "s";
                }
            } else {
                mStatus = sportLabel + " at " + effStart + "bpm";
            }
        }
    }

    // ── Start session ─────────────────────────────────────────────────────
    private function startActivity() as Void {
        if (mIsRecording || mActiveZoneIdx < 0 || mActiveZoneIdx >= mZones.size()) { return; }

        var zone     = mZones[mActiveZoneIdx] as Dictionary;
        var sportIdx = zone[:sport] as Number;

        mSession = ActivityRecording.createSession({
            :name     => SPORT_LABELS[sportIdx] as String,
            :sport    => SPORT_SPORTS[sportIdx] as Activity.Sport,
            :subSport => Activity.SUB_SPORT_GENERIC
        });
        mSession.start();
        mIsRecording   = true;
        mHighHrSeconds = 0;
        mLowHrSeconds  = 0;
        mStatus       = "Recording " + (SPORT_LABELS[sportIdx] as String);
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, 800)]);
        }
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
    }

    // ── Shared teardown ───────────────────────────────────────────────────
    private function teardownSession() as Void {
        mIsRecording  = false;
        mLowHrSeconds = 0;
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 200),
                new Attention.VibeProfile(0,   100),
                new Attention.VibeProfile(100, 200),
                new Attention.VibeProfile(0,   100),
                new Attention.VibeProfile(100, 200)
            ]);
        }

        if (mSession != null) {
            try {
                if (mSession.isRecording()) { mSession.stop(); }
                mSession.save();
                mStatus = "Saved! Monitoring...";
            } catch (ex instanceof Lang.Exception) {
                mStatus = "Monitoring...";
            }
            mSession = null;
        }

        Position.enableLocationEvents(
            { :acquisitionType => Position.LOCATION_CONTINUOUS },
            method(:onPosition)
        );
    }

    // ── Auto-stop ─────────────────────────────────────────────────────────
    private function stopActivity() as Void {
        if (!mIsRecording || mSession == null) { return; }
        teardownSession();
    }

    // ── Manual stop ───────────────────────────────────────────────────────
    function manualStop() as Void {
        if (!mIsRecording || mSession == null) { return; }
        mManualStop = true;
        teardownSession();
    }

    function isManualStop()   as Boolean { return mManualStop; }
    function clearManualStop() as Void   { mManualStop = false; }

    function showMenuArrow() as Void {
        mMenuArrowVisible = true;
        mMenuArrowSeconds = 2;
        WatchUi.requestUpdate();
    }

    function isMenuArrowVisible() as Boolean { return mMenuArrowVisible; }

    function hideMenuArrow() as Void {
        mMenuArrowVisible = false;
        WatchUi.requestUpdate();
    }

    // ── Full teardown on exit ─────────────────────────────────────────────
    function cleanup() as Void {
        if (mTimer != null) { mTimer.stop(); mTimer = null; }
        if (mConfirmTimer != null) { mConfirmTimer.stop(); mConfirmTimer = null; }
        Sensor.enableSensorEvents(null);
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        if (mIsRecording && mSession != null) {
            try {
                if (mSession.isRecording()) { mSession.stop(); }
                mSession.save();
            } catch (ex instanceof Lang.Exception) {}
            mSession     = null;
            mIsRecording = false;
        }
    }

    // ── Draw ──────────────────────────────────────────────────────────────
    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        var ps = w / 48;  // pixel size scales with screen (8 @ 390px, 5 @ 260px, 9 @ 454px)

        // Glow at button position — purple while recording, green while paused
        var outerR  = w / 2 - 2;
        var innerR  = outerR - outerR / 5;
        var depth   = outerR - innerR;
        var steps   = 60;
        var _isRound = false;
        try { _isRound = System.getDeviceSettings().screenShape == 1; } catch (ex instanceof Lang.Exception) {}
        if ((mIsRecording || mManualStop) && _isRound) {
            var cr = mIsRecording ? 172 : 130;
            var cg = mIsRecording ? 120 : 175;
            var cb = mIsRecording ? 157 : 120;
            for (var i = 0; i < steps; i++) {
                var t = i * 255 / (steps - 1);
                var b = t * t / 255;
                dc.setColor(((b * cr / 255) << 16) | ((b * cg / 255) << 8) | (b * cb / 255), Graphics.COLOR_TRANSPARENT);
                dc.drawArc(cx, cy, innerR + depth * i / steps, Graphics.ARC_CLOCKWISE, 45, 15);
            }
        }

        drawPixelHR(dc, cx, cy - ps * 8, ps);

        dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        var statusText = (mIsRecording && mLowHrSeconds > 0)
            ? "Stop in " + (((mZones[mActiveZoneIdx] as Dictionary)[:stopTimeout] as Number) - mLowHrSeconds) + "s"
            : mStatus;
        dc.drawText(cx, cy + ps * 5, Graphics.FONT_XTINY, statusText,
            Graphics.TEXT_JUSTIFY_CENTER);

        if (mMenuArrowVisible) {
            drawMenuArrow(dc, cx, h - ps * 8, ps);
        }
    }

    // Upward-pointing pixel chevron (^) — tip at top, two diverging sides, no base
    private function drawMenuArrow(dc as Graphics.Dc, cx as Number, y as Number, ps as Number) as Void {
        var rows = 4;
        for (var i = 0; i < rows; i++) {
            var py = y + i * (ps + 2);
            if (i == 0) {
                drawArrowPixel(dc, cx - ps / 2, py, ps, i, 0);
            } else {
                var offset = i * (ps + 2);
                drawArrowPixel(dc, cx - offset - ps / 2, py, ps, i, 0);
                drawArrowPixel(dc, cx + offset - ps / 2, py, ps, i, 1);
            }
        }
    }

    private function drawArrowPixel(dc as Graphics.Dc, px as Number, py as Number, ps as Number, row as Number, side as Number) as Void {
        var hh = row * 37 + side * 13;
        var r  = 120 + hh % 60;
        var g  = 120 + (hh * 3 + 25) % 60;
        var b  = 120 + (hh * 7 + 50) % 60;
        dc.setColor(((r / 6) << 16) | ((g / 6) << 8) | (b / 6), Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(px - 1, py - 1, ps + 2, ps + 2);
        dc.setColor((r << 16) | (g << 8) | b, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(px, py, ps, ps);
    }

    // ── Pixel font ────────────────────────────────────────────────────────
    private function getCharRows(d as Number) as Array<Number> {
        if (d == 0) { return [0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E]; }
        if (d == 1) { return [0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E]; }
        if (d == 2) { return [0x0E, 0x11, 0x01, 0x06, 0x08, 0x10, 0x1F]; }
        if (d == 3) { return [0x0E, 0x01, 0x01, 0x06, 0x01, 0x01, 0x0E]; }
        if (d == 4) { return [0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02]; }
        if (d == 5) { return [0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E]; }
        if (d == 6) { return [0x0E, 0x10, 0x10, 0x1E, 0x11, 0x11, 0x0E]; }
        if (d == 7) { return [0x1F, 0x01, 0x02, 0x04, 0x04, 0x04, 0x04]; }
        if (d == 8) { return [0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E]; }
        if (d == 9) { return [0x0E, 0x11, 0x11, 0x0E, 0x01, 0x01, 0x0E]; }
        return      [0x00, 0x00, 0x00, 0x0E, 0x00, 0x00, 0x00]; // dash
    }

    private function drawPixelChar(dc as Graphics.Dc, d as Number, x as Number, y as Number, ps as Number) as Void {
        var rows = getCharRows(d);
        for (var row = 0; row < 7; row++) {
            var pattern = rows[row] as Number;
            for (var col = 0; col < 5; col++) {
                if (((pattern >> (4 - col)) & 1) == 1) {
                    var px = x + col * (ps + 1);
                    var py = y + row * (ps + 1);
                    var hh = d * 37 + row * 13 + col * 7;
                    var r  = 120 + hh % 60;
                    var g  = 120 + (hh * 3 + 25) % 60;
                    var b  = 120 + (hh * 7 + 50) % 60;
                    dc.setColor(((r / 6) << 16) | ((g / 6) << 8) | (b / 6), Graphics.COLOR_TRANSPARENT);
                    dc.fillRectangle(px - 1, py - 1, ps + 2, ps + 2);
                    dc.setColor((r << 16) | (g << 8) | b, Graphics.COLOR_TRANSPARENT);
                    dc.fillRectangle(px, py, ps, ps);
                }
            }
        }
    }

    private function drawPixelHR(dc as Graphics.Dc, cx as Number, y as Number, ps as Number) as Void {
        var step  = ps * 6;              // inter-character step
        var charW = 5 * ps + 4;          // pixel width of one character
        var x2    = cx - step / 2 - charW / 2;   // left edge for 2-digit
        var x3    = cx - step     - charW / 2;   // left edge for 3-digit

        if (mHeartRate <= 0) {
            drawPixelChar(dc, 10, x2, y, ps);
            drawPixelChar(dc, 10, x2 + step, y, ps);
        } else {
            var hr = mHeartRate;
            if (hr >= 100) {
                drawPixelChar(dc, hr / 100,       x3,          y, ps);
                drawPixelChar(dc, (hr / 10) % 10, x3 + step,   y, ps);
                drawPixelChar(dc, hr % 10,         x3 + step * 2, y, ps);
            } else {
                drawPixelChar(dc, hr / 10, x2,          y, ps);
                drawPixelChar(dc, hr % 10, x2 + step,   y, ps);
            }
        }
    }

}
