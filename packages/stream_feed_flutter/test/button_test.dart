import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stream_feed_flutter/src/widgets/buttons/buttons.dart';
import 'package:stream_feed_flutter/src/widgets/pages/reaction_list_view.dart';
import 'package:stream_feed_flutter/stream_feed_flutter.dart';

import 'mock.dart';

// ignore_for_file: cascade_invocations

void main() {
  testWidgets('ReactionListPage', (tester) async {
    final mockClient = MockStreamFeedClient();
    final mockReactions = MockReactions();
    final mockStreamAnalytics = MockStreamAnalytics();
    when(() => mockClient.reactions).thenReturn(mockReactions);
    const lookupAttr = LookupAttribute.activityId;
    const lookupValue = 'ed2837a6-0a3b-4679-adc1-778a1704852d';
    final filter =
        Filter().idGreaterThan('e561de8f-00f1-11e4-b400-0cc47a024be0');
    const kind = 'like';
    const limit = 5;
    const activityId = 'activityId';
    const userId = 'john-doe';
    const targetFeeds = <FeedId>[];
    const data = {'text': 'awesome post!'};
    const reactions = [
      Reaction(
        kind: kind,
        activityId: activityId,
        userId: userId,
        data: data,
        targetFeeds: targetFeeds,
      )
    ];
    when(() => mockReactions.filter(
          lookupAttr,
          lookupValue,
          filter: filter,
          limit: limit,
          kind: kind,
        )).thenAnswer((_) async => reactions);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return StreamFeed(
            bloc: FeedBloc(
              client: mockClient,
              analyticsClient: mockStreamAnalytics,
            ),
            child: child!,
          );
        },
        home: Scaffold(
          body: ReactionListView(
            activity: const GenericEnrichedActivity(id: 'id'),
            reactionBuilder: (context, reaction) => const Offstage(),
            lookupValue: lookupValue,
            filter: filter,
            limit: limit,
            kind: kind,
          ),
        ),
      ),
    );
    verify(() => mockReactions.filter(lookupAttr, lookupValue,
        filter: filter, limit: limit, kind: kind)).called(1);
  });

  testWidgets('LikeButton', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return StreamFeedTheme(
            data: StreamFeedThemeData.light(),
            child: child!,
          );
        },
        home: const Scaffold(
          body: LikeButton(
            activity:
                GenericEnrichedActivity(), //TODO: put actual fields in this, notes: look into checks in llc reactions
            // .add and .delete
            reaction: Reaction(kind: 'like', childrenCounts: {
              'like': 3
            }, ownChildren: {
              'like': [
                Reaction(
                  kind: 'like',
                )
              ]
            }),
          ),
        ),
      ),
    );

    final icon = find.byType(StreamSvgIcon);
    final activeIcon = tester.widget<StreamSvgIcon>(icon);
    final count = find.text('3');
    expect(count, findsOneWidget);
    expect(activeIcon.assetName, StreamSvgIcon.loveActive().assetName);
  });

  testWidgets('RepostButton', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return StreamFeedTheme(
            data: StreamFeedThemeData.light(),
            child: child!,
          );
        },
        home: const Scaffold(
          body: RepostButton(
            activity:
                GenericEnrichedActivity(), //TODO: put actual fields in this, notes: look into checks in llc reactions
            // .add and .delete
            reaction: Reaction(kind: 'repost', childrenCounts: {
              'repost': 3
            }, ownChildren: {
              'repost': [
                Reaction(
                  kind: 'repost',
                )
              ]
            }),
          ),
        ),
      ),
    );

    final icon = find.byType(StreamSvgIcon);
    final activeIcon = tester.widget<StreamSvgIcon>(icon);
    final count = find.text('3');
    expect(count, findsOneWidget);
    expect(activeIcon.color, Colors.blue);
  });

  group('ChildReactionToggleIcon', () {
    const kind = 'like';
    const count = 1300;
    final inactiveIcon = StreamSvgIcon.loveInactive();
    final activeIcon = StreamSvgIcon.loveActive();
    const foreignId = 'like:300';
    const activityId = 'activityId';
    const feedGroup = 'timeline:300';
    const activity = GenericEnrichedActivity(
      id: activityId,
      foreignId: foreignId,
    );
    const reaction = Reaction(id: 'id', kind: kind, parent: activityId);
    const userId = 'user:300';

    group('widget test', () {
      testWidgets('withoutOwnReactions: onAddChildReaction', (tester) async {
        final mockReactions = MockReactions();
        final mockStreamAnalytics = MockStreamAnalytics();
        final mockClient = MockStreamFeedClient();
        final controller = ReactionsManager();
        const parentId = 'parentId';
        const childId = 'childId';
        final now = DateTime.now();
        final reactedActivity =
            GenericEnrichedActivity<User, String, String, String>(
          id: 'id',
          time: now,
          actor: const User(data: {
            'name': 'Rosemary',
            'handle': '@rosemary',
            'subtitle': 'likes playing fresbee in the park',
            'profile_image': 'https://randomuser.me/api/portraits/women/20.jpg',
          }),
        );
        controller.init(reactedActivity.id!);
        final bloc = FeedBloc(
          analyticsClient: mockStreamAnalytics,
          client: mockClient,
        );
        bloc.reactionsManager = controller;
        expect(bloc.reactionsManager.hasValue(reactedActivity.id!), true);
        final parentReaction = Reaction(
            id: parentId, kind: 'comment', activityId: reactedActivity.id);
        final childReaction =
            Reaction(id: childId, kind: 'like', activityId: reactedActivity.id);
        when(() => mockClient.reactions).thenReturn(mockReactions);
        when(() => mockReactions.addChild('like', parentId))
            .thenAnswer((_) async => childReaction);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return StreamFeed(
                bloc: bloc,
                child: child!,
              );
            },
            home: Scaffold(
              body: ReactionToggleIcon(
                activity: reactedActivity,
                hoverColor: Colors.lightBlue,
                reaction: parentReaction,
                kind: kind,
                count: count,
                inactiveIcon: inactiveIcon,
                activeIcon: activeIcon,
              ),
            ),
          ),
        );
        final reactionIcon = find.byType(ReactionIcon);
        expect(reactionIcon, findsOneWidget);
        await tester.tap(reactionIcon);
        await tester.pumpAndSettle();
        verify(() => mockClient.reactions.addChild(
              'like',
              parentId,
            )).called(1);
        // await expectLater(
        //     bloc.getReactionsStream(reactedActivity.id!),
        //     emits([
        //       Reaction(
        //         id: parentId,
        //         kind: 'comment',
        //         activityId: reactedActivity.id,
        //         childrenCounts: const {'like': 1},
        //         latestChildren: {
        //           'like': [childReaction]
        //         },
        //         ownChildren: {
        //           'like': [childReaction]
        //         },
        //       )
        //     ]));

        //TODO: test reaction Stream
      });

      testWidgets('withOwnReactions: onRemoveChildReaction', (tester) async {
        final mockClient = MockStreamFeedClient();
        final mockReactions = MockReactions();
        final mockStreamAnalytics = MockStreamAnalytics();

        const label = kind;
        when(() => mockClient.reactions).thenReturn(mockReactions);
        final controller = ReactionsManager();
        final now = DateTime.now();
        const childId = 'childId';
        const parentId = 'parentId';
        final reactedActivity =
            GenericEnrichedActivity<User, String, String, String>(
          id: 'id',
          time: now,
          actor: const User(data: {
            'name': 'Rosemary',
            'handle': '@rosemary',
            'subtitle': 'likes playing fresbee in the park',
            'profile_image': 'https://randomuser.me/api/portraits/women/20.jpg',
          }),
        );
        final childReaction = Reaction(id: childId, kind: 'like');
        final parentReaction = Reaction(
          id: parentId,
          kind: 'comment',
          activityId: reactedActivity.id,
          childrenCounts: const {'like': 1},
          latestChildren: {
            'like': [childReaction]
          },
          ownChildren: {
            'like': [childReaction]
          },
        );

        controller.init(reactedActivity.id!);
        final bloc = FeedBloc(
          client: mockClient,
          analyticsClient: mockStreamAnalytics,
        );
        bloc.reactionsManager = controller;
        expect(bloc.reactionsManager.hasValue(reactedActivity.id!), true);

        when(() => mockReactions.delete(childId))
            .thenAnswer((_) async => Future.value());
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedProvider(
                bloc: bloc,
                child: ReactionToggleIcon(
                  ownReactions: [childReaction],
                  activity: reactedActivity,
                  hoverColor: Colors.lightBlue,
                  reaction: parentReaction,
                  kind: kind,
                  count: count,
                  // ownReactions: const [reaction],
                  inactiveIcon: inactiveIcon,
                  activeIcon: activeIcon,
                ),
              ),
            ),
          ),
        );
        final reactionIcon = find.byType(ReactionIcon);
        expect(reactionIcon, findsOneWidget);

        final expectedCount = find.text('1300');
        expect(expectedCount, findsOneWidget);

        await tester.tap(reactionIcon);
        await tester.pumpAndSettle();

        verify(() => mockClient.reactions.delete(childId)).called(1);
      });
    });
  });

  group('ReactionToggleIcon', () {
    late MockStreamFeedClient mockClient;
    late MockReactions mockReactions;
    late MockStreamAnalytics mockStreamAnalytics;
    late String kind;
    late List<Reaction> reactions;
    late String activityId;
    late FeedBloc bloc;
    late MockReactionsController mockReactionsController;
    late String feedGroup;
    late StreamSvgIcon inactiveIcon;
    late StreamSvgIcon activeIcon;

    tearDown(() => bloc.dispose());

    setUp(() {
      mockReactions = MockReactions();
      mockReactionsController = MockReactionsController();
      mockStreamAnalytics = MockStreamAnalytics();
      mockClient = MockStreamFeedClient();

      kind = 'like';
      activityId = 'activityId';
      feedGroup = 'user';
      inactiveIcon = StreamSvgIcon.loveInactive();
      activeIcon = StreamSvgIcon.loveActive();
      reactions = [
        Reaction(
          id: 'id',
          kind: 'like',
          activityId: activityId,
          childrenCounts: const {
            'like': 0,
          },
          latestChildren: const {'like': []},
          ownChildren: const {'like': []},
        )
      ];
      when(() => mockClient.reactions).thenReturn(mockReactions);

      bloc = FeedBloc(client: mockClient);
    });

    testGoldens('onAddReaction', (tester) async {
      const addedReaction = Reaction();
      bloc.reactionsManager = mockReactionsController;
      when(() => mockReactionsController.getReactions(activityId))
          .thenAnswer((_) => reactions);
      expect(bloc.reactionsManager.getReactions(activityId), reactions);
      when(() => mockReactions.add(
            kind,
            activityId,
          )).thenAnswer((_) async => addedReaction);
      await tester.pumpWidgetBuilder(
        StreamFeed(
          bloc: bloc,
          child: Scaffold(
            body: ReactionToggleIcon(
              activity: GenericEnrichedActivity(id: activityId),
              feedGroup: feedGroup,
              kind: kind,
              activeIcon: activeIcon,
              count: 1300,
              inactiveIcon: inactiveIcon,
            ),
          ),
        ),
        surfaceSize: const Size(125, 100),
      );
      await screenMatchesGolden(tester, 'reaction_toggle_onAddReaction');
      final reactionIcon = find.byType(InkWell);
      expect(reactionIcon, findsOneWidget);
      await tester.tap(reactionIcon);
      verify(() => mockReactions.add(
            kind,
            activityId,
          )).called(1);

      //TODO: test reaction Stream
    });
    testGoldens('onRemoveReaction', (tester) async {
      const reactionId = 'reactionId';
      const reaction = Reaction(id: reactionId);
      bloc.reactionsManager = mockReactionsController;
      when(() => mockReactionsController.getReactions(activityId))
          .thenAnswer((_) => reactions);
      when(() => mockReactions.delete(reactionId))
          .thenAnswer((invocation) => Future.value());

      await tester.pumpWidgetBuilder(
        MaterialApp(
          builder: (context, child) {
            return StreamFeed(
              bloc: bloc,
              child: child!,
            );
          },
          home: Scaffold(
            body: ReactionToggleIcon(
              ownReactions: const [reaction],
              activity: GenericEnrichedActivity(
                  id: activityId,
                  reactionCounts: const {
                    'like': 1300
                  },
                  ownReactions: const {
                    'like': [reaction]
                  },
                  latestReactions: const {
                    'like': [reaction]
                  }),
              feedGroup: feedGroup,
              kind: kind,
              activeIcon: activeIcon,
              count: 1300,
              inactiveIcon: inactiveIcon,
            ),
          ),
        ),
        surfaceSize: const Size(125, 100),
      );
      await screenMatchesGolden(tester, 'reaction_toggle_onRemoveReaction');
      final reactionIcon = find.byType(InkWell);
      expect(reactionIcon, findsOneWidget);
      await tester.tap(reactionIcon);
      await tester.pumpAndSettle();
      verify(() => mockReactions.delete(reactionId)).called(1);

      //TODO: test reaction Stream
    });
  });

  group('ReactionIcon', () {
    testWidgets('onTap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return StreamFeedTheme(
              data: StreamFeedThemeData(),
              child: child!,
            );
          },
          home: Scaffold(
            body: ReactionIcon(
              icon: StreamSvgIcon.repost(),
              count: 23,
              onTap: () => tapped++,
            ),
          ),
        ),
      );

      final icon = find.byType(StreamSvgIcon);
      final activeIcon = tester.widget<StreamSvgIcon>(icon);
      final count = find.text('23');
      expect(count, findsOneWidget);
      expect(activeIcon.assetName, StreamSvgIcon.repost().assetName);

      await tester.tap(find.byType(InkWell));
      expect(tapped, 1);
    });

    testGoldens('repost golden', (tester) async {
      await tester.pumpWidgetBuilder(
        StreamFeedTheme(
          data: StreamFeedThemeData(),
          child: Center(
            child: ReactionIcon(
              icon: StreamSvgIcon.repost(),
              count: 23,
            ),
          ),
        ),
        surfaceSize: const Size(100, 75),
      );
      await screenMatchesGolden(tester, 'repost');
    });
  });

  group('debugFillProperties tests', () {
    test('ChildReactionButton', () {
      final builder = DiagnosticPropertiesBuilder();
      final now = DateTime.now();
      final childReactionButton = ReactionButton(
        activity: const GenericEnrichedActivity(),
        reaction: Reaction(
          createdAt: now,
          kind: 'comment',
          data: const {
            'text': 'this is a piece of text',
          },
        ),
        kind: 'comment',
        activeIcon: const Icon(Icons.favorite),
        inactiveIcon: const Icon(Icons.favorite_border),
      );

      childReactionButton.debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) =>
              node.toJsonMap(const DiagnosticsSerializationDelegate()))
          .toList();

      expect(description[0]['description'],
          '''Reaction(null, comment, null, null, null, ${now.toString()}, null, null, null, null, {text: this is a piece of text}, null, null, null)''');
    });

    test('ChildReactionToggleIcon', () {
      final builder = DiagnosticPropertiesBuilder();
      final now = DateTime.now();
      final childReactionToggleIcon = ReactionToggleIcon(
        count: 1,
        ownReactions: const [],
        activity: const GenericEnrichedActivity(),
        reaction: Reaction(
          createdAt: now,
          kind: 'comment',
          data: const {
            'text': 'this is a piece of text',
          },
        ),
        kind: 'comment',
        activeIcon: const Icon(Icons.favorite),
        inactiveIcon: const Icon(Icons.favorite_border),
      );

      childReactionToggleIcon.debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) =>
              node.toJsonMap(const DiagnosticsSerializationDelegate()))
          .toList();

      expect(description[0]['description'], '[]');
    });

    test('Like button', () {
      final builder = DiagnosticPropertiesBuilder();
      final now = DateTime.now();
      final likeButton = LikeButton(
        activity: GenericEnrichedActivity(
          time: now,
          actor: const User(
            data: {
              'name': 'Rosemary',
              'handle': '@rosemary',
              'subtitle': 'likes playing frisbee in the park',
              'profile_image':
                  'https://randomuser.me/api/portraits/women/20.jpg',
            },
          ),
          extraData: const {
            'image':
                'https://handluggageonly.co.uk/wp-content/uploads/2017/08/IMG_0777.jpg',
          },
        ),
      );

      likeButton.debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) =>
              node.toJsonMap(const DiagnosticsSerializationDelegate()))
          .toList();

      expect(description[0]['description'], 'null');
    });

    test('ReactionButton', () {
      final builder = DiagnosticPropertiesBuilder();
      final now = DateTime.now();
      final reactionButton = ReactionButton(
        activity: GenericEnrichedActivity(
          time: now,
          actor: const User(
            data: {
              'name': 'Rosemary',
              'handle': '@rosemary',
              'subtitle': 'likes playing frisbee in the park',
              'profile_image':
                  'https://randomuser.me/api/portraits/women/20.jpg',
            },
          ),
          extraData: const {
            'image':
                'https://handluggageonly.co.uk/wp-content/uploads/2017/08/IMG_0777.jpg',
          },
        ),
        kind: 'comment',
        activeIcon: const Icon(Icons.favorite),
        inactiveIcon: const Icon(Icons.favorite_border),
      );

      reactionButton.debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) =>
              node.toJsonMap(const DiagnosticsSerializationDelegate()))
          .toList();

      expect(description[0]['description'], 'null');
    });

    test('ReactionToggleIcon', () {
      final builder = DiagnosticPropertiesBuilder();
      final now = DateTime.now();
      final reactionToggleIcon = ReactionToggleIcon(
        count: 1,
        activity: GenericEnrichedActivity(
          time: now,
          actor: const User(
            data: {
              'name': 'Rosemary',
              'handle': '@rosemary',
              'subtitle': 'likes playing frisbee in the park',
              'profile_image':
                  'https://randomuser.me/api/portraits/women/20.jpg',
            },
          ),
          extraData: const {
            'image':
                'https://handluggageonly.co.uk/wp-content/uploads/2017/08/IMG_0777.jpg',
          },
        ),
        kind: 'comment',
        activeIcon: const Icon(Icons.favorite),
        inactiveIcon: const Icon(Icons.favorite_border),
      );

      reactionToggleIcon.debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) =>
              node.toJsonMap(const DiagnosticsSerializationDelegate()))
          .toList();

      expect(description[0]['description'], 'null');
    });

    test('ReactionIcon', () {
      final builder = DiagnosticPropertiesBuilder();
      const reactionIcon = ReactionIcon(
        icon: Icon(Icons.favorite),
      );

      reactionIcon.debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) =>
              node.toJsonMap(const DiagnosticsSerializationDelegate()))
          .toList();

      expect(description[0]['description'], 'null');
    });

    test('ReplyButton', () {
      final builder = DiagnosticPropertiesBuilder();
      final now = DateTime.now();
      final replyButton = ReplyButton(
        activity: GenericEnrichedActivity(
          time: now,
          actor: const User(
            data: {
              'name': 'Rosemary',
              'handle': '@rosemary',
              'subtitle': 'likes playing frisbee in the park',
              'profile_image':
                  'https://randomuser.me/api/portraits/women/20.jpg',
            },
          ),
          extraData: const {
            'image':
                'https://handluggageonly.co.uk/wp-content/uploads/2017/08/IMG_0777.jpg',
          },
        ),
      );

      replyButton.debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) =>
              node.toJsonMap(const DiagnosticsSerializationDelegate()))
          .toList();

      expect(description[0]['description'], '"handle"');
    });

    test('RepostButton', () {
      final builder = DiagnosticPropertiesBuilder();
      final now = DateTime.now();
      final repostButton = RepostButton(
        activity: GenericEnrichedActivity(
          time: now,
          actor: const User(
            data: {
              'name': 'Rosemary',
              'handle': '@rosemary',
              'subtitle': 'likes playing frisbee in the park',
              'profile_image':
                  'https://randomuser.me/api/portraits/women/20.jpg',
            },
          ),
          extraData: const {
            'image':
                'https://handluggageonly.co.uk/wp-content/uploads/2017/08/IMG_0777.jpg',
          },
        ),
      );

      repostButton.debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) =>
              node.toJsonMap(const DiagnosticsSerializationDelegate()))
          .toList();

      expect(description[0]['description'], 'null');
    });
  });
}
