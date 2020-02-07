package me.yohom.amapbase.map

import android.annotation.SuppressLint
import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Bundle
import android.view.View
import com.amap.api.maps.AMap
import com.amap.api.maps.AMapOptions
import com.amap.api.maps.TextureMapView
import com.amap.api.maps.model.CameraPosition

import com.amap.api.maps.model.Marker
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import me.yohom.amapbase.*
import me.yohom.amapbase.AMapBasePlugin.Companion.registrar
import me.yohom.amapbase.common.parseFieldJson
import me.yohom.amapbase.common.toFieldJson
import org.json.JSONObject
import java.util.concurrent.atomic.AtomicInteger

const val mapChannelName = "me.yohom/map"
const val mapChangeChannelName = "me.yohom/mapview_event"
const val markerClickedChannelName = "me.yohom/marker_event"
const val success = "调用成功"

class AMapFactory(private val activityState: AtomicInteger)
    : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, params: Any?): PlatformView {
        val view = AMapView(
                context,
                id,
                activityState,
                (params as String).parseFieldJson<UnifiedAMapOptions>().toAMapOption()
        )
        view.setup()
        return view
    }
}

@SuppressLint("CheckResult")
class AMapView(context: Context,
               private val id: Int,
               private val activityState: AtomicInteger,
               amapOptions: AMapOptions) : PlatformView, Application.ActivityLifecycleCallbacks {

    private val mapView = TextureMapView(context, amapOptions)
    private var disposed = false
    private val registrarActivityHashCode: Int = AMapBasePlugin.registrar.activity().hashCode()

    override fun getView(): View = mapView

    override fun dispose() {
        if (disposed) {
            return
        }
        disposed = true
        mapView.onDestroy()

        registrar.activity().application.unregisterActivityLifecycleCallbacks(this)
    }

    fun setup() {
        when (activityState.get()) {
            STOPPED -> {
                mapView.onCreate(null)
                mapView.onResume()
                mapView.onPause()
            }
            RESUMED -> {
                mapView.onCreate(null)
                mapView.onResume()
            }
            CREATED -> mapView.onCreate(null)
            DESTROYED -> {
            }
            else -> throw IllegalArgumentException("Cannot interpret " + activityState.get() + " as an activity activityState")
        }

        // 地图相关method channel
        val mapChannel = MethodChannel(registrar.messenger(), "$mapChannelName$id")
        mapChannel.setMethodCallHandler { call, result ->
            MAP_METHOD_HANDLER[call.method]
                    ?.with(mapView.map)
                    ?.onMethodCall(call, result) ?: result.notImplemented()
        }

        // marker click event channel
        var eventSink: EventChannel.EventSink? = null
        val markerClickedEventChannel = EventChannel(registrar.messenger(), "$markerClickedChannelName$id")
        markerClickedEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }

            override fun onCancel(p0: Any?) {}
        })

        var mapChangeEventSink: EventChannel.EventSink? = null
        val mapChangeEventChannel = EventChannel(registrar.messenger(), "$mapChangeChannelName$id")
        mapChangeEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, sink: EventChannel.EventSink?) {
                mapChangeEventSink = sink
            }

            override fun onCancel(p0: Any?) {}
        })

        mapView.map.setOnCameraChangeListener(object: AMap.OnCameraChangeListener {
            override fun onCameraChange(cameraPosition:CameraPosition) {

            }

            override fun onCameraChangeFinish(cameraPosition:CameraPosition ) {
                var o = JSONObject()
                o.put("latitude", cameraPosition.target?.latitude)
                o.put("longitude", cameraPosition.target?.longitude)
                mapChangeEventSink?.success(o.toString());
            }
        });

        mapView.map.setOnMarkerClickListener {
            var o = JSONObject()
            o.put("event", "click")
            o.put("latitude", it.position.latitude)
            o.put("longitude", it.position.longitude)
            o.put("options", UnifiedMarkerOptions(it.options).toFieldJson())

            eventSink?.success(o.toString())
            true
        }

        mapView.map.setOnMarkerDragListener(object: AMap.OnMarkerDragListener{
            override fun onMarkerDragStart(it: Marker?) {
                var o = JSONObject();
                o.put("event", "drag_start");

                if (it != null) {
                    o.put("latitude", it.position.latitude)
                    o.put("longitude", it.position.longitude)
                    o.put("options", UnifiedMarkerOptions(it.options).toFieldJson())
                }
                eventSink?.success(o.toString())
            }

            override fun onMarkerDrag(it: Marker?) {
                var o = JSONObject();
                o.put("event", "drag");
                if (it != null) {
                    o.put("latitude", it.position.latitude)
                    o.put("longitude", it.position.longitude)
                    o.put("options", UnifiedMarkerOptions(it.options).toFieldJson())
                }
                eventSink?.success(o.toString())
            }

            override fun onMarkerDragEnd(it: Marker?) {
                var o = JSONObject();
                o.put("event", "drag_end");
                if (it != null) {
                    o.put("latitude", it.position.latitude)
                    o.put("longitude", it.position.longitude)
                    o.put("options", UnifiedMarkerOptions(it.options).toFieldJson())
                }
                eventSink?.success(o.toString())
            }
        })

        // 注册生命周期
        registrar.activity().application.registerActivityLifecycleCallbacks(this)
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onCreate(savedInstanceState)
    }

    override fun onActivityStarted(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
    }

    override fun onActivityResumed(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onResume()
    }

    override fun onActivityPaused(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onPause()
    }

    override fun onActivityStopped(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
    }

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle?) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onSaveInstanceState(outState)
    }

    override fun onActivityDestroyed(activity: Activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            return
        }
        mapView.onDestroy()
    }
}