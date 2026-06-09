import 'package:pauselock_server/src/endpoints/build_endpoint.dart';
import 'package:pauselock_server/src/endpoints/hero_endpoint.dart';
import 'package:pauselock_server/src/endpoints/player_endpoint.dart';
import 'package:pauselock_server/src/endpoints/stats_endpoint.dart';

class Endpoints {
  PlayerEndpoint player = PlayerEndpoint();
  HeroEndpoint hero = HeroEndpoint();
  BuildEndpoint build = BuildEndpoint();
  StatsEndpoint stats = StatsEndpoint();
}
