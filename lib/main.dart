import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:gigflow/app/app.dart';
import 'package:gigflow/app/di/injection_container.dart';
import 'package:gigflow/app/router/app_router.dart';
import 'package:gigflow/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Must run before any other Firestore call.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await initDependencies();
  runApp(
    GigFlowApp(
      router: sl<AppRouter>().router,
      authBloc: sl(),
      themeCubit: sl(),
      filterCubit: sl(),
      connectivityCubit: sl(),
      taskRepository: sl(),
    ),
  );
}
