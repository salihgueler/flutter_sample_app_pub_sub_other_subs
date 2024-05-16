import 'dart:convert';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample_app_pub_sub_other_subs/amplifyconfiguration.dart';
import 'package:flutter_sample_app_pub_sub_other_subs/models/ModelProvider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Amplify.addPlugins(
      [
        AmplifyAPI(
          options: APIPluginOptions(
            modelProvider: ModelProvider.instance,
          ),
        )
      ],
    );
    await Amplify.configure(amplifyConfig);
  } on AmplifyException catch (e) {
    print(e);
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MessageShowingWidget());
  }
}

class MessageShowingWidget extends StatefulWidget {
  const MessageShowingWidget({super.key});

  @override
  State<MessageShowingWidget> createState() => _MessageShowingWidgetState();
}

class _MessageShowingWidgetState extends State<MessageShowingWidget> {
  String text = 'No Message Yet';
  @override
  void initState() {
    super.initState();
    const receiveMessage = 'receiveMessage';
    const graphQLDocument = '''subscription $receiveMessage {
  receive {
    content
    channelName
  }
}
''';

    Amplify.API
        .subscribe(
      GraphQLRequest<String>(document: graphQLDocument),
    )
        .listen((event) {
      safePrint(event);
      safePrint(event.data);
      if (event.data != null) {
        final myJson = json.decode(event.data!);
        final message = Message.fromJson(myJson['receive']);
        setState(() {
          text =
              '${message.content} is sent to ${message.channelName} channel.';
        });
      }
    }).onError((error) {
      safePrint('Error is: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(text),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          const createMessage = 'createMessage';
          const graphQLDocument = '''mutation $createMessage {
  publish(channelName: "world", content: "Amazing work") {
    content
  }
}
''';
          Amplify.API
              .mutate(
                request: GraphQLRequest(document: graphQLDocument),
              )
              .response
              .then((value) {
            print(value);
          }).onError((error, stackTrace) {
            print(error);
          });
        },
        label: const Text('Publish Message'),
      ),
    );
  }
}
