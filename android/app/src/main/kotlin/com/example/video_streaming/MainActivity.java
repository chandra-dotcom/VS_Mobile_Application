package com.vs.video_streaming;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;
import android.os.PowerManager;
import android.net.Uri;


public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.vs.batteryOptimization";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("isBatteryOptimized")) {
                    result.success(isIgnoringBatteryOptimizations());
                } else if (call.method.equals("requestBatteryOptimization")) {
                    requestExemptionFromBatteryOptimization(result);
                } else {
                    result.notImplemented();
                }
            });
    }

    private boolean isIgnoringBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PowerManager powerManager = (PowerManager) getSystemService(POWER_SERVICE);
            if (powerManager != null) {
                return powerManager.isIgnoringBatteryOptimizations(getPackageName());
            }
        }
        return true; // For older Android versions, assume the app isn't optimized
    }

    private void requestExemptionFromBatteryOptimization(MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                intent.setData(Uri.parse("package:" + getPackageName()));
                if (intent.resolveActivity(getPackageManager()) != null) {
                    startActivity(intent); // Opens the system settings to request exemption
                    result.success(null);
                } else {
                    result.error("ACTIVITY_NOT_FOUND", "No activity found to handle the intent", null);
                }
            } catch (Exception e) {
                result.error("ERROR", "An error occurred while requesting exemption: " + e.getMessage(), null);
            }
        } else {
            result.error("VERSION_NOT_SUPPORTED", "This feature is not supported on this Android version", null);
        }
    }
}
