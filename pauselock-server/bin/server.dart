import 'package:pauselock_server/server.dart' as pauselock;

Future<void> main(List<String> args) async {
  await pauselock.run(args);
}
