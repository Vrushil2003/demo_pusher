import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PusherChannelsFlutter pusher;
  String _log = 'output:\n';
  final _apiKey = TextEditingController();
  final _cluster = TextEditingController();
  final _channelName = TextEditingController();
  final _eventName = TextEditingController();
  final _channelFormKey = GlobalKey<FormState>();
  final _eventFormKey = GlobalKey<FormState>();
  final _listViewController = ScrollController();
  final _data = TextEditingController();
  final _eventDataController = TextEditingController();
  String eventData = '';
  String imageName = '';
  String points = '';

  @override
  void initState() {
    super.initState();
    pusher = PusherChannelsFlutter.getInstance();
    initPlatformState();
  }

  void log(String text) {
    // print("LOG: $text");
    setState(() {
      _log += "$text\n";
      Timer(const Duration(milliseconds: 100), () => _listViewController.jumpTo(_listViewController.position.maxScrollExtent));
    });
  }

  void onConnectPressed() async {
    if (!_channelFormKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).requestFocus(FocusNode());

    try {
      await pusher.init(
        apiKey: _apiKey.text,
        cluster: _cluster.text,
        onConnectionStateChange: onConnectionStateChange,
        onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onEvent: onEvent,
        onSubscriptionError: onSubscriptionError,
        onDecryptionFailure: onDecryptionFailure,
        onMemberAdded: onMemberAdded,
        onMemberRemoved: onMemberRemoved,
        onSubscriptionCount: onSubscriptionCount,
        // authEndpoint: "",
        // onAuthorizer: onAuthorizer
      );
      await pusher.subscribe(channelName: _channelName.text);
      await pusher.connect();

      await PusherService.savePreferences(
        apiKey: _apiKey.text,
        cluster: _cluster.text,
        channelName: _channelName.text,
        eventName: _eventName.text,
        data: _data.text,
      );

      // print(" V : ${jsonDecode(_data.text)}");
    } catch (e) {
      log("ERROR: $e");
    }
  }

  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    log("Connection: $currentState");
  }

  void onError(String message, int? code, dynamic e) {
    log("onError: $message code: $code exception: $e");
  }

  void onEvent(PusherEvent event) {
    final data = json.decode(event.data);
    setState(() {
      eventData = data['img'];
      imageName = data['name'];
      points = data['points'];
      _eventDataController.text = eventData;
    });
    log("onEvent: ${jsonDecode(event.data)}");
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    log("onSubscriptionSucceeded: $channelName data: $data");
    final me = pusher.getChannel(channelName)?.me;
    log("Me: $me");
  }

  void onSubscriptionError(String message, dynamic e) {
    log("onSubscriptionError: $message Exception: $e");
  }

  void onDecryptionFailure(String event, String reason) {
    log("onDecryptionFailure: $event reason: $reason");
  }

  void onMemberAdded(String channelName, PusherMember member) {
    log("onMemberAdded: $channelName user: $member");
  }

  void onMemberRemoved(String channelName, PusherMember member) {
    log("onMemberRemoved: $channelName user: $member");
  }

  void onSubscriptionCount(String channelName, int subscriptionCount) {
    log("onSubscriptionCount: $channelName subscriptionCount: $subscriptionCount");
  }

  dynamic onAuthorizer(String channelName, String socketId, dynamic options) {
    return {"auth": "foo:bar", "channel_data": '{"user_id": 1}', "shared_secret": "foobar"};
  }

  void onTriggerEventPressed() async {
    var eventFormValidated = _eventFormKey.currentState!.validate();

    if (!eventFormValidated) {
      return;
    }

    PusherService.savePreferences(
      apiKey: _apiKey.text,
      cluster: _cluster.text,
      channelName: _channelName.text,
      eventName: _eventName.text,
      data: _data.text,
    );

    pusher.trigger(PusherEvent(channelName: _channelName.text, eventName: _eventName.text, data: _data.text));
  }

  @override
  void dispose() {
    pusher.disconnect();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    if (!mounted) return;
    final preferences = await PusherService.getPreferences();
    setState(() {
      _apiKey.text = preferences["apiKey"]!;
      _cluster.text = preferences["cluster"]!;
      _channelName.text = preferences["channelName"]!;
      _eventName.text = preferences["eventName"]!;
      _data.text = preferences["data"]!;
    });

    if (_apiKey.text.isNotEmpty && _cluster.text.isNotEmpty && _channelName.text.isNotEmpty && _eventName.text.isNotEmpty && _data.text.isNotEmpty) {
      onConnectPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pusher.connectionState == 'DISCONNECTED' ? 'Pusher Channels Example' : _channelName.text),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          controller: _listViewController,
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: <Widget>[
            if (pusher.connectionState != 'CONNECTED')
              Form(
                key: _channelFormKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _apiKey,
                      validator: (String? value) {
                        return (value != null && value.isEmpty) ? 'Please enter your API key.' : null;
                      },
                      decoration: const InputDecoration(labelText: 'API Key'),
                    ),
                    TextFormField(
                      controller: _cluster,
                      validator: (String? value) {
                        return (value != null && value.isEmpty) ? 'Please enter your cluster.' : null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Cluster',
                      ),
                    ),
                    TextFormField(
                      controller: _channelName,
                      validator: (String? value) {
                        return (value != null && value.isEmpty) ? 'Please enter your channel name.' : null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Channel',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onConnectPressed,
                      child: const Text('Connect'),
                    )
                  ],
                ),
              )
            else
              Form(
                key: _eventFormKey,
                child: Column(
                  children: <Widget>[
                    ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: pusher.channels[_channelName.text]?.members.length,
                        itemBuilder: (context, index) {
                          final member = pusher.channels[_channelName.text]!.members.values.elementAt(index);
                          return ListTile(title: Text(member.userInfo.toString()), subtitle: Text(member.userId));
                        }),
                    TextFormField(
                      controller: _eventName,
                      validator: (String? value) {
                        return (value != null && value.isEmpty) ? 'Please enter your event name.' : null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Event',
                      ),
                    ),
                    TextFormField(
                      controller: _eventDataController,
                      onChanged: (value) {
                        setState(() {
                          eventData = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Event Data',
                      ),
                    ),
                    // ElevatedButton(
                    //   onPressed: onTriggerEventPressed,
                    //   child: const Text('Trigger Event'),
                    // ),
                  ],
                ),
              ),
            const SizedBox(height: 30),
            Column(
              children: [
                eventData.isNotEmpty
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(eventData.toString()),
                      )
                    : const CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage('https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png'),
                      ),
                const SizedBox(height: 8),
                Text(
                  imageName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  points,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SingleChildScrollView(scrollDirection: Axis.vertical, child: Text(_log)),
          ],
        ),
      ),
    );
  }
}
