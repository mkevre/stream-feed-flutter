import 'package:flutter/material.dart';
import 'package:stream_feed_flutter_core/stream_feed_flutter_core.dart';

typedef OnActivities = Widget Function(
    BuildContext context, List<EnrichedActivity> activities, int idx);

typedef OnReactions = Widget Function(
    BuildContext context, List<Reaction> reactions, int idx);
typedef OnNotifications = Widget Function(
    BuildContext context, List<NotificationGroup<EnrichedActivity>> notifications, int idx);
