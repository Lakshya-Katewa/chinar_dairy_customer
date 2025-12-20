package com.chinardairy.app

import io.flutter.embedding.android.FlutterFragmentActivity
import com.google.firebase.FirebaseApp
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory
import android.os.Bundle
import android.util.Log
import com.chinardairy.app.BuildConfig

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        try {
            FirebaseApp.initializeApp(this)
            val firebaseAppCheck = FirebaseAppCheck.getInstance()
            
            if (BuildConfig.DEBUG) {
                Log.d("FirebaseAppCheck", "Using DEBUG provider")
                firebaseAppCheck.installAppCheckProviderFactory(
                    DebugAppCheckProviderFactory.getInstance()
                )
            } else {
                Log.d("FirebaseAppCheck", "Using Play Integrity provider")
                firebaseAppCheck.installAppCheckProviderFactory(
                    PlayIntegrityAppCheckProviderFactory.getInstance()
                )
            }
        } catch (e: Exception) {
            Log.e("FirebaseAppCheck", "Initialization failed", e)
        }
    }
}