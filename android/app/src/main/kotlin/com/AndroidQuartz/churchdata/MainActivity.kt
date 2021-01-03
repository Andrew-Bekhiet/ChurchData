package com.AndroidQuartz.churchdata

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkInfo
import android.os.Build
import android.util.Base64
import android.util.Log
import android.view.SurfaceView
import android.view.WindowManager
import androidx.annotation.NonNull
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Source
import com.it_nomads.fluttersecurestorage.ciphers.StorageCipher18Implementation
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.nio.charset.Charset
import java.util.*

const val birthdayAction = "BIRTHDAYS"
var birthdayIntent = false;

const val tanawolAction = "TANAWOL"
var tanawolIntent = false;

const val confessionsAction = "CONFESSIONS"
var confessionsIntent = false;

const val BIG_INTEGER_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy"

class MainActivity: FlutterFragmentActivity() {

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        birthdayIntent = (birthdayAction == intent.action)
        tanawolIntent = (tanawolAction == intent.action)
        confessionsIntent = (confessionsAction == intent.action)
        if (birthdayAction == intent.action) {
            MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, "com.AndroidQuartz.ChurchData/Notifications").invokeMethod("openBirthDays", "")
        }
        if (tanawolAction == intent.action) {
            MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, "com.AndroidQuartz.ChurchData/Notifications").invokeMethod("openTanawol", "")
        }
        if (confessionsAction == intent.action) {
            MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, "com.AndroidQuartz.ChurchData/Notifications").invokeMethod("openConfessions", "")
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        SurfaceView(applicationContext).setSecure(true)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.AndroidQuartz.ChurchData/Notifications").setMethodCallHandler { call, result ->
            when (call.method) {
                "startBirthDay" -> {
                    startBirthdayAlarm(this.applicationContext)
                    result.success(null)
                }
                "startConfessions" -> {
                    startConfessionsAlarm(this.applicationContext)
                    result.success(null)
                }
                "startTanawol" -> {
                    startTanawolAlarm(this.applicationContext)
                    result.success(null)
                }
                "OpenedBirthdays" -> {
                    result.success(birthdayIntent)
                }
                "OpenedConfessions" -> {
                    result.success(confessionsIntent)
                }
                "OpenedTanawol" -> {
                    result.success(tanawolIntent)
                }
                "ClickedNotification" -> {
                    result.success(birthdayIntent || confessionsIntent || tanawolIntent)
                }
                else -> result.notImplemented()
            }
        }
        this.window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        birthdayIntent = (birthdayAction == intent.action)
        tanawolIntent = (tanawolAction == intent.action)
        confessionsIntent = (confessionsAction == intent.action)
    }

    fun startBirthdayAlarm(context: Context) {
        val notificationIntent = Intent(context, ScheduledBirthdayNotifications::class.java)
        val pendingIntent = PendingIntent.getBroadcast(context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)
        val repeatInterval: Long = 86400000 //every day //60000 //every minute
        val c = Calendar.getInstance(TimeZone.getTimeZone("GMT+2:00"))
        c.set(Calendar.HOUR_OF_DAY, context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).getString("flutter.ReminderTimeHours", "-1")!!.toInt())
        c.set(Calendar.MINUTE, context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).getString("flutter.ReminderTimeMinutes", "-1")!!.toInt())
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        val startTimeMilliseconds = c.timeInMillis
        alarmManager.setInexactRepeating(AlarmManager.RTC_WAKEUP, startTimeMilliseconds, repeatInterval, pendingIntent)
    }
    
    fun startConfessionsAlarm(context: Context) {
        val notificationIntent = Intent(context, ScheduledConfessionsNotifications::class.java)
        val pendingIntent = PendingIntent.getBroadcast(context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)
        val repeatInterval: Long = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).getString("flutter.ConfessionsInterval", "604800000")!!.toLong()
        val c = Calendar.getInstance(TimeZone.getTimeZone("GMT+2:00"))
        c.set(Calendar.HOUR_OF_DAY, context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).getString("flutter.ReminderTimeHours", "-1")!!.toInt())
        c.set(Calendar.MINUTE, context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).getString("flutter.ReminderTimeMinutes", "-1")!!.toInt())
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        val startTimeMilliseconds = c.timeInMillis + 1500
        alarmManager.setInexactRepeating(AlarmManager.RTC_WAKEUP, startTimeMilliseconds, repeatInterval, pendingIntent)
    }

    fun startTanawolAlarm(context: Context) {
        val notificationIntent = Intent(context, ScheduledTanawolNotifications::class.java)
        val pendingIntent = PendingIntent.getBroadcast(context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)
        val repeatInterval: Long = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).getString("flutter.TanawolInterval", "604800000")!!.toLong()
        val c = Calendar.getInstance(TimeZone.getTimeZone("GMT+2:00"))
        c.set(Calendar.HOUR_OF_DAY, context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).getString("flutter.ReminderTimeHours", "-1")!!.toInt())
        c.set(Calendar.MINUTE, context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).getString("flutter.ReminderTimeMinutes", "-1")!!.toInt())
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        val startTimeMilliseconds = c.timeInMillis + 3000
        alarmManager.setInexactRepeating(AlarmManager.RTC_WAKEUP, startTimeMilliseconds, repeatInterval, pendingIntent)
    }
}
class ScheduledBirthdayNotifications : BroadcastReceiver() {

    private fun setupBirthdayNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            var notificationChannel = notificationManager.getNotificationChannel("Birthday")
            if (notificationChannel == null) {
                notificationChannel = NotificationChannel("Birthday", "إشعارات أعياد الميلاد", NotificationManager.IMPORTANCE_DEFAULT)
                notificationChannel.setSound(null, null)
                notificationChannel.enableVibration(true)
                notificationChannel.enableLights(true)
                notificationChannel.setShowBadge(true)
                notificationManager.createNotificationChannel(notificationChannel)
            }
        }
    }
    
    private fun isConnectedToInternet(context: Context) : Boolean {
        try{
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val network: Network = connectivityManager.activeNetwork!!
                val capabilities: NetworkCapabilities = connectivityManager.getNetworkCapabilities(network)
                        ?: return false
                if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
                        || capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) {
                    return true
                }
                if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                    return true
                }
            }
            else{
                val info: NetworkInfo = connectivityManager.activeNetworkInfo!!
                if (!info.isConnected) {
                    return false
                }
                return when (info.type) {
                    ConnectivityManager.TYPE_ETHERNET, ConnectivityManager.TYPE_WIFI, ConnectivityManager.TYPE_WIMAX -> true
                    ConnectivityManager.TYPE_MOBILE, ConnectivityManager.TYPE_MOBILE_DUN, ConnectivityManager.TYPE_MOBILE_HIPRI -> true
                    else -> false
                }
            }
        }
        catch (err: Exception){

        }
        return false
    }

    private fun showBirthdayNotification(context: Context, text: String){
        val intent = Intent(context, Class.forName(context.packageManager.getLaunchIntentForPackage(context.packageName)!!.component!!.className))
        intent.action = birthdayAction
        intent.putExtra("payload", "BirthDayNotif")
        val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
        setupBirthdayNotificationChannel(context)
        val builder = NotificationCompat.Builder(context, "Birthday")
                .setContentTitle("أعياد الميلاد")
                .setContentText(text)
                .setAutoCancel(false)
                .setContentIntent(pendingIntent)
                .setPriority(0)
                .setSmallIcon(context.resources.getIdentifier("birthday", "drawable", context.packageName))
        NotificationManagerCompat.from(context).notify(0, builder.build())
    }

    override fun onReceive(context: Context, intent: Intent){
        try{
            if(isConnectedToInternet(context)){
                FirebaseAuth.getInstance().currentUser?.getIdToken(true)?.addOnCompleteListener { task ->
                    if(task.isComplete)
                    {
                        processNotification(context, task.result.claims)
                    }
                }
            }
            else{
                processNotification(context, CurrentUserDataFromCache().getAll(context)!!)
            }
        }
        catch (err: Exception){
        }
    }
    private fun processNotification(context: Context, claims: Map<String, Any>){
        if(claims["birthdayNotify"].toString() != "true") return
        val today = Calendar.getInstance()
        today.clear()
        today.set(1970, Calendar.getInstance().get(Calendar.MONTH), Calendar.getInstance().get(Calendar.DAY_OF_MONTH))
        if (claims["superAccess"].toString() == "true") {
            try {
                if(isConnectedToInternet(context)) {
                    FirebaseFirestore.getInstance().collection("Persons").whereEqualTo("BirthDay", Timestamp(today.time)).get().addOnCompleteListener { task2 ->
                        if (task2.isComplete && task2.result!!.documents.size > 0) {
                            showBirthdayNotification(context, task2.result!!.documents.joinToString { it.getString("Name")!! })
                        }
                    }
                }
                else {
                    FirebaseFirestore.getInstance().collection("Persons").whereEqualTo("BirthDay", Timestamp(today.time)).get(Source.CACHE).addOnCompleteListener { task2 ->
                        if (task2.isComplete && task2.result!!.documents.size > 0) {
                            showBirthdayNotification(context, task2.result!!.documents.joinToString { it.getString("Name")!! });
                        }
                    }
                }
            } catch (err: Exception) {
                showBirthdayNotification(context, "حدث خطأ أثناء الاتصال");
            }
        } else {
            try{
                if(isConnectedToInternet(context)) {
                    FirebaseFirestore.getInstance().collection("Areas").whereArrayContains("Allowed", FirebaseAuth.getInstance().currentUser!!.uid).get().addOnCompleteListener { allowed ->
                        if (allowed.isComplete) {
                            FirebaseFirestore.getInstance().collection("Persons").whereIn("AreaId", allowed.result!!.documents.map { t -> t.reference }).whereEqualTo("BirthDay", Timestamp(today.time)).get().addOnCompleteListener { task2 ->
                                if (task2.isComplete && task2.result!!.documents.size > 0) {
                                    showBirthdayNotification(context, task2.result!!.documents.joinToString { it.getString("Name")!! });
                                }
                            }
                        }
                    }
                }
                else{
                    FirebaseFirestore.getInstance().collection("Areas").whereArrayContains("Allowed", FirebaseAuth.getInstance().currentUser!!.uid).get(Source.CACHE).addOnCompleteListener { allowed ->
                        if (allowed.isComplete) {
                            FirebaseFirestore.getInstance().collection("Persons").whereIn("AreaId", allowed.result!!.documents.map { t -> t.reference }).whereEqualTo("BirthDay", Timestamp(today.time)).get(Source.CACHE).addOnCompleteListener { task2 ->
                                if (task2.isComplete && task2.result!!.documents.size > 0) {
                                    showBirthdayNotification(context, task2.result!!.documents.joinToString { it.getString("Name")!! });
                                }
                            }
                        }
                    }
                }
            }
            catch (err: Exception) {
                showBirthdayNotification(context, "حدث خطأ أثناء الاتصال");
            }
        }
    }
}

class ScheduledConfessionsNotifications : BroadcastReceiver() {

    private fun setupConfessionsNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            var notificationChannel = notificationManager.getNotificationChannel("Confessions")
            if (notificationChannel == null) {
                notificationChannel = NotificationChannel("Confessions", "إشعارات الاعتراف", NotificationManager.IMPORTANCE_DEFAULT)
                notificationChannel.setSound(null, null)
                notificationChannel.enableVibration(true)
                notificationChannel.enableLights(true)
                notificationChannel.setShowBadge(true)
                notificationManager.createNotificationChannel(notificationChannel)
            }
        }
    }
    
    private fun isConnectedToInternet(context: Context) : Boolean {
        try{
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val network: Network = connectivityManager.activeNetwork!!
                val capabilities: NetworkCapabilities = connectivityManager.getNetworkCapabilities(network)
                        ?: return false
                if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
                        || capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) {
                    return true
                }
                if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                    return true
                }
            }
            else{
                val info: NetworkInfo = connectivityManager.activeNetworkInfo!!
                if (!info.isConnected) {
                    return false
                }
                return when (info.type) {
                    ConnectivityManager.TYPE_ETHERNET, ConnectivityManager.TYPE_WIFI, ConnectivityManager.TYPE_WIMAX -> true
                    ConnectivityManager.TYPE_MOBILE, ConnectivityManager.TYPE_MOBILE_DUN, ConnectivityManager.TYPE_MOBILE_HIPRI -> true
                    else -> false
                }
            }
        }
        catch (err: Exception){

        }
        return false
    }

    private fun showConfessionsNotification(context: Context, text: String){
        val intent = Intent(context, Class.forName(context.packageManager.getLaunchIntentForPackage(context.packageName)!!.component!!.className))
        intent.action = confessionsAction
        intent.putExtra("payload", "ConfessionsNotif")
        val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
        setupConfessionsNotificationChannel(context)
        val builder = NotificationCompat.Builder(context, "Confessions")
                .setContentTitle("انذار الاعتراف")
                .setContentText(text)
                .setAutoCancel(false)
                .setContentIntent(pendingIntent)
                .setPriority(0)
                .setSmallIcon(context.resources.getIdentifier("warning", "drawable", context.packageName))
        NotificationManagerCompat.from(context).notify(1, builder.build())
    }
    
    override fun onReceive(context: Context, intent: Intent){
        try{
            if(isConnectedToInternet(context)){
                FirebaseAuth.getInstance().currentUser?.getIdToken(true)?.addOnCompleteListener { task ->
                    if(task.isComplete)
                    {
                        processNotification(context, task.result.claims)
                    }
                }
            }
            else{
                processNotification(context, CurrentUserDataFromCache().getAll(context)!!)
            }
        }
        catch (err: Exception){

        }
    }

    private fun processNotification(context: Context, claims: Map<String, Any>){
        if(claims["confessionsNotify"].toString() != "true") return
        val today = Calendar.getInstance()
        today.clear()
        today.set(Calendar.getInstance().get(Calendar.YEAR), Calendar.getInstance().get(Calendar.MONTH), (Calendar.getInstance().get(Calendar.DAY_OF_MONTH)))
        today.add(Calendar.DAY_OF_MONTH, - (context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).getString("flutter.ConfessionsPInterval", "604800000")!!.toLong() / 86400000).toInt())
        try{
            if (claims["superAccess"].toString() == "true") {
                try {
                    if(isConnectedToInternet(context)) {
                        FirebaseFirestore.getInstance().collection("Persons").whereLessThan("LastConfession", Timestamp(today.time)).get().addOnCompleteListener { task2 ->
                            if (task2.isComplete && task2.result!!.documents.size > 0) {
                                showConfessionsNotification(context, task2.result!!.documents.joinToString { it.getString("Name")!! });
                            }
                        }
                    }
                    else {
                        FirebaseFirestore.getInstance().collection("Persons").whereLessThan("LastConfession", Timestamp(today.time)).get(Source.CACHE).addOnCompleteListener { task2 ->
                            if (task2.isComplete && task2.result!!.documents.size > 0) {
                                showConfessionsNotification(context, task2.result!!.documents.joinToString { it.getString("Name")!! });
                            }
                        }
                    }
                } catch (err: Exception) {
                    showConfessionsNotification(context, "حدث خطأ أثناء الاتصال");
                }
            } else {
                try{
                    if(isConnectedToInternet(context)) {
                        FirebaseFirestore.getInstance().collection("Areas").whereArrayContains("Allowed", FirebaseAuth.getInstance().currentUser!!.uid).get().addOnCompleteListener { allowed ->
                            if (allowed.isComplete) {
                                FirebaseFirestore.getInstance().collection("Persons").whereIn("AreaId", allowed.result!!.documents.map { t -> t.reference }).whereLessThan("LastConfession", Timestamp(today.time)).get().addOnCompleteListener { task2 ->
                                    if (task2.isComplete && task2.result!!.documents.size > 0) {
                                        showConfessionsNotification(context, task2.result!!.documents.joinToString { it.getString("Name")!! });
                                    }
                                }
                            }
                        }
                    }
                    else{
                        FirebaseFirestore.getInstance().collection("Areas").whereArrayContains("Allowed", FirebaseAuth.getInstance().currentUser!!.uid).get(Source.CACHE).addOnCompleteListener { allowed ->
                            if (allowed.isComplete) {
                                FirebaseFirestore.getInstance().collection("Persons").whereIn("AreaId", allowed.result!!.documents.map { t -> t.reference }).whereLessThan("LastConfession", Timestamp(today.time)).get(Source.CACHE).addOnCompleteListener { task2 ->
                                    if (task2.isComplete && task2.result!!.documents.size > 0) {
                                        showConfessionsNotification(context, task2.result!!.documents.joinToString { it.getString("Name")!! });
                                    }
                                }
                            }
                        }
                    }
                }
                catch (err: Exception) {
                    showConfessionsNotification(context, "حدث خطأ أثناء الاتصال");
                }
            }
        }
        catch (err: Exception){

        }
    }
}

class ScheduledTanawolNotifications : BroadcastReceiver() {

    private fun setupConfessionsNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            var notificationChannel = notificationManager.getNotificationChannel("Tanawol")
            if (notificationChannel == null) {
                notificationChannel = NotificationChannel("Tanawol", "إشعارات التناول", NotificationManager.IMPORTANCE_DEFAULT)
                notificationChannel.setSound(null, null)
                notificationChannel.enableVibration(true)
                notificationChannel.enableLights(true)
                notificationChannel.setShowBadge(true)
                notificationManager.createNotificationChannel(notificationChannel)
            }
        }
    }
    
    private fun isConnectedToInternet(context: Context) : Boolean {
        try{
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val network: Network = connectivityManager.activeNetwork!!
                val capabilities: NetworkCapabilities = connectivityManager.getNetworkCapabilities(network)
                        ?: return false
                if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
                        || capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) {
                    return true
                }
                if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                    return true
                }
            }
            else{
                val info: NetworkInfo = connectivityManager.activeNetworkInfo!!
                if (!info.isConnected) {
                    return false
                }
                return when (info.type) {
                    ConnectivityManager.TYPE_ETHERNET, ConnectivityManager.TYPE_WIFI, ConnectivityManager.TYPE_WIMAX -> true
                    ConnectivityManager.TYPE_MOBILE, ConnectivityManager.TYPE_MOBILE_DUN, ConnectivityManager.TYPE_MOBILE_HIPRI -> true
                    else -> false
                }
            }
        }
        catch (err: Exception){

        }
        return false
    }

    private fun showTanawolNotification(context: Context, text: String){
        val intent = Intent(context, Class.forName(context.packageManager.getLaunchIntentForPackage(context.packageName)!!.component!!.className))
        intent.action = tanawolAction
        intent.putExtra("payload", "TanawolNotif")
        val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
        setupConfessionsNotificationChannel(context)
        val builder = NotificationCompat.Builder(context, "Tanawol")
                .setContentTitle("انذار التناول")
                .setContentText(text)
                .setAutoCancel(false)
                .setContentIntent(pendingIntent)
                .setPriority(0)
                .setSmallIcon(context.resources.getIdentifier("warning", "drawable", context.packageName))
        NotificationManagerCompat.from(context).notify(2, builder.build())
    }
    
    override fun onReceive(context: Context, intent: Intent){
        try{
            if(isConnectedToInternet(context)){
                FirebaseAuth.getInstance().currentUser?.getIdToken(true)?.addOnCompleteListener { task ->
                    if(task.isComplete)
                    {
                        processNotification(context, task.result.claims)
                    }
                }
            }
            else{
                processNotification(context, CurrentUserDataFromCache().getAll(context)!!)
            }
        }
        catch (err: Exception){

        }
    }

    private fun processNotification(context: Context, claims: Map<String, Any>){
        if(claims["tanawolNotify"].toString() != "true") return
        val today = Calendar.getInstance()
        today.clear()
        today.set(Calendar.getInstance().get(Calendar.YEAR), Calendar.getInstance().get(Calendar.MONTH), (Calendar.getInstance().get(Calendar.DAY_OF_MONTH)))
        today.add(Calendar.DAY_OF_MONTH, - (context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).getString("flutter.TanawolPInterval", "604800000")!!.toLong() / 86400000).toInt())
        try{
            if (claims["superAccess"].toString() == "true") {
                try {
                    if(isConnectedToInternet(context)) {
                        FirebaseFirestore.getInstance().collection("Persons").whereLessThan("LastTanawol", Timestamp(today.time)).get().addOnCompleteListener { task2 ->
                            if (task2.isComplete && task2.result!!.documents.size > 0) {
                                showTanawolNotification(context, task2.result!!.documents.joinToString { it.getString("Name")!! });
                            }
                        }
                    }
                    else {
                        FirebaseFirestore.getInstance().collection("Persons").whereLessThan("LastTanawol", Timestamp(today.time)).get(Source.CACHE).addOnCompleteListener { task2 ->
                            if (task2.isComplete && task2.result!!.documents.size > 0) {
                                showTanawolNotification(context, task2.result!!.documents.joinToString { it.getString("Name")!! });
                            }
                        }
                    }
                } catch (err: Exception) {
                    showTanawolNotification(context, "حدث خطأ أثناء الاتصال");
                }
            } else {
                try{
                    if(isConnectedToInternet(context)) {
                        FirebaseFirestore.getInstance().collection("Areas").whereArrayContains("Allowed", FirebaseAuth.getInstance().currentUser!!.uid).get().addOnCompleteListener { allowed ->
                            if (allowed.isComplete) {
                                FirebaseFirestore.getInstance().collection("Persons").whereIn("AreaId", allowed.result!!.documents.map { t -> t.reference }).whereLessThan("LastTanawol", Timestamp(today.time)).get().addOnCompleteListener { task2 ->
                                    if (task2.isComplete && task2.result!!.documents.size > 0) {
                                        showTanawolNotification(context, task2.result!!.documents.joinToString { it.getString("Name")!! });
                                    }
                                }
                            }
                        }
                    }
                    else{
                        FirebaseFirestore.getInstance().collection("Areas").whereArrayContains("Allowed", FirebaseAuth.getInstance().currentUser!!.uid).get(Source.CACHE).addOnCompleteListener { allowed ->
                            if (allowed.isComplete) {
                                FirebaseFirestore.getInstance().collection("Persons").whereIn("AreaId", allowed.result!!.documents.map { t -> t.reference }).whereLessThan("LastTanawol", Timestamp(today.time)).get(Source.CACHE).addOnCompleteListener { task2 ->
                                    if (task2.isComplete && task2.result!!.documents.size > 0) {
                                        showTanawolNotification(context, task2.result!!.documents.joinToString { it.getString("Name")!! });
                                    }
                                }
                            }
                        }
                    }
                }
                catch (err: Exception) {
                    showTanawolNotification(context, "حدث خطأ أثناء الاتصال");
                }
            }
        }
        catch (err: Exception){
        }
    }
}

class CurrentUserDataFromCache{
    fun getAll(context: Context): Map<String, String>? {
        val raw = context.getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE).all
        val all: MutableMap<String, String> = HashMap()
        for ((key1, rawValue) in raw) {
            val key = key1.replaceFirst("VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg_", "")
            val value: String = decodeRawValue(context, rawValue as String?)
            all[key] = value
        }
        return all
    }

    private fun decodeRawValue(context: Context, value: String?): String {
        if (value == null) {
            return ""
        }
        val data = Base64.decode(value, 0)
        val result: ByteArray = StorageCipher18Implementation(context).decrypt(data)
        return String(result, Charset.forName("UTF-8"))
    }

    fun get(key: String, context: Context): String? {
        val value = context.getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE).getString(key, null)
        StorageCipher18Implementation.moveSecretFromPreferencesIfNeeded(context.getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE), context)
        if (value == null) {
            return null
        }
        val data = Base64.decode(value, 0)
        val result = StorageCipher18Implementation(context)!!.decrypt(data)
        return String(result, Charset.forName("UTF-8")!!)
    }
}

class ScheduledNotificationBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != null && action == Intent.ACTION_BOOT_COMPLETED) {
            MainActivity().startBirthdayAlarm(context)
            MainActivity().startConfessionsAlarm(context)
            MainActivity().startTanawolAlarm(context)
        }
    }
}
