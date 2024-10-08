import 'package:browbeat/music.dart';
import 'package:browbeat/operation_io.dart';
import 'package:browbeat/setting.dart';
import 'package:browbeat/state.dart';
import 'package:browbeat/word.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'playground.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  await ioController.initialize();
  await audioController.initialize();
  await wordController.initialize();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    audioController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (AppLifecycleState.paused == state) {
      audioController.fadeOutMusic();
    }

    if (AppLifecycleState.resumed == state && audioController.isPlaying) {
      audioController.startMusic();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'BeatBrows',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: Color.fromRGBO(231, 204, 204, 1)),
        ),
        home: MainMenu(),
      ),
    );
  }
}

class MainMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text("Browbeat"),
        actions: [
          IconButton(
              onPressed: () => appState.switchMusic(),
              icon: audioController.musicIcon),
          IconButton(
              onPressed: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingPage(),
                      ),
                    )
                  },
              icon: Icon(Icons.settings)),
        ],
      ),
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DifficultyCard(appState: appState),
              Flexible(flex: 1, fit: FlexFit.tight, child: StartCard()),
            ],
          ),
        ),
      ),
    );
  }
}

class DifficultyCard extends StatelessWidget {
  const DifficultyCard({
    super.key,
    required this.appState,
  });

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 3,
      child: LayoutBuilder(
          builder: (BuildContext ctx, BoxConstraints constraints) {
        if (constraints.maxWidth >= 480) {
          return DifficultySelection(
              appState: appState, constraints: constraints, orientation: "Row");
        } else {
          return DifficultySelection(
              appState: appState,
              constraints: constraints,
              orientation: "Column");
        }
      }),
    );
  }
}

class DifficultySelection extends StatelessWidget {
  const DifficultySelection({
    super.key,
    required this.appState,
    required this.orientation,
    required this.constraints,
  });

  final AppState appState;
  final String orientation;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (orientation == "Row") {
      content =
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Difficulty(appState: appState, text: "Easy", difficulty: "easy"),
        Difficulty(appState: appState, text: "Normal", difficulty: "normal"),
        Difficulty(appState: appState, text: "Hard", difficulty: "hard"),
      ]);
    } else {
      content =
          Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Difficulty(appState: appState, text: "Easy", difficulty: "easy"),
        Difficulty(appState: appState, text: "Normal", difficulty: "normal"),
        Difficulty(appState: appState, text: "Hard", difficulty: "hard"),
      ]);
    }
    // Safer use of constraints
    return Container(
      margin: EdgeInsets.fromLTRB(0, 30, 0, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: appColorScheme.getColorSheme("secondary"),
      ),
      constraints: BoxConstraints(
          minHeight: constraints.maxHeight * 0.5,
          minWidth: constraints.maxWidth * 0.7,
          maxWidth: constraints.maxWidth * 0.7),
      child: content,
    );
  }
}

class Difficulty extends StatelessWidget {
  const Difficulty(
      {super.key,
      required this.appState,
      required this.text,
      required this.difficulty});
  final String difficulty;
  final String text;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onSecondary,
      fontSize: 20,
    );
    Color? color;
    if (wordController.difficulty == text.toLowerCase()) {
      color = appColorScheme.getColorSheme(difficulty);
    } else {
      color = appColorScheme.getColorSheme("unselected");
    }

    return Card(
      clipBehavior: Clip.hardEdge,
      color: color,
      child: InkWell(
        onTap: () {
          appState.setDifficulty(difficulty);
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 50,
            maxHeight: 50,
            minWidth: 100,
            maxWidth: 100,
          ),
          child: Center(child: Text(text, style: style)),
        ),
      ),
    );
  }
}

class StartCard extends StatelessWidget {
  const StartCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onSecondary,
      fontSize: 20,
    );

    return Container(
      alignment: Alignment.center,
      child: Card(
        color: theme.colorScheme.primary,
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          splashColor: theme.colorScheme.secondary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PlayGround(),
              ),
            );
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 50,
              maxHeight: 50,
              minWidth: 100,
              maxWidth: 100,
            ),
            child: Center(child: Text('Start', style: style)),
          ),
        ),
      ),
    );
  }
}
