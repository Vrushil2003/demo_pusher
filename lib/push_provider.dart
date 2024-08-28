import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'services.dart';

class PusherProvider extends ChangeNotifier {
  late PusherChannelsFlutter pusher;
  late String _log;
  late TextEditingController _apiKey;
  late TextEditingController _cluster;
  late TextEditingController _channelName;
  late TextEditingController _eventName;
  late TextEditingController _data;
  final _channelFormKey = GlobalKey<FormState>();
  final _eventFormKey = GlobalKey<FormState>();
  final _listViewController = ScrollController();

  PusherProvider() {
    pusher = PusherChannelsFlutter.getInstance();
    _log = 'output:\n';
    _apiKey = TextEditingController();
    _cluster = TextEditingController();
    _channelName = TextEditingController();
    _eventName = TextEditingController();
    _data = TextEditingController();
    initPlatformState();
  }

  TextEditingController get apiKey => _apiKey;
  TextEditingController get cluster => _cluster;
  TextEditingController get channelName => _channelName;
  TextEditingController get eventName => _eventName;
  TextEditingController get data => _data;
  GlobalKey<FormState> get channelFormKey => _channelFormKey;
  GlobalKey<FormState> get eventFormKey => _eventFormKey;
  ScrollController get listViewController => _listViewController;

  void log(String text) {
    print("LOG: $text");
    _log += text + "\n";
    notifyListeners();
  }

  Future<void> initPlatformState() async {
    final preferences = await PusherService.getPreferences();
    _apiKey.text = preferences["apiKey"]!;
    _cluster.text = preferences["cluster"]!;
    _channelName.text = preferences["channelName"]!;
    _eventName.text = preferences["eventName"]!;
    _data.text = preferences["data"]!;
    notifyListeners();
  }

  void onConnectPressed() async {
    if (!_channelFormKey.currentState!.validate()) {
      return;
    }

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
    log("onEvent: $event");
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

    print(" V : ${jsonDecode(_data.text)}");

    pusher.trigger(PusherEvent(channelName: _channelName.text, eventName: _eventName.text, data: _data.text));
  }
}
