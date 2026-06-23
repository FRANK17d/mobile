package com.tokeplus.app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (en lugar de FlutterActivity) es requisito de
// `local_auth` para mostrar el prompt biométrico nativo en Android.
class MainActivity : FlutterFragmentActivity()
