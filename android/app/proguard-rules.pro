# Razorpay keep rules
-keep class com.razorpay.** { *; }
-keep interface com.razorpay.** { *; }
-keepattributes *Annotation*

# Optional: Prevent removing annotation classes if used
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }
# Razorpay and Google Pay integration
-keep class com.google.android.apps.nbu.paisa.** { *; }
-keep interface com.google.android.apps.nbu.paisa.** { *; }

# Keep Proguard annotations
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }

# Razorpay SDK
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# GPay Integration via Razorpay
-keep class com.google.android.gms.wallet.** { *; }
-dontwarn com.google.android.gms.wallet.**