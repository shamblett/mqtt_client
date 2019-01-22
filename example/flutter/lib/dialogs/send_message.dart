import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;

class SendMessageDialog extends StatefulWidget {
  final mqtt.MqttClient client;

  const SendMessageDialog({Key key, @required this.client}) : super(key: key);

  @override
  _SendMessageDialogState createState() => _SendMessageDialogState();
}

class _SendMessageDialogState extends State<SendMessageDialog> {
  bool _hasMessage = false;
  bool _hasTopic = false;
  bool _retainValue = false;
  bool _saveNeeded = false;
  int _qosValue = 0;
  String _messageContent;
  String _topicContent;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('New message'), actions: <Widget>[
        FlatButton(
            child: Text('SEND',
                style: theme.textTheme.body1.copyWith(color: Colors.white)),
            onPressed: () {
              if (_formKey.currentState.validate()) {
                _formKey.currentState.save();
                _sendMessage();
              }
            })
      ]),
      body: Form(
        key: _formKey,
        onWillPop: _onWillPop,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              alignment: Alignment.bottomLeft,
              child: TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Message', filled: true),
                style: theme.textTheme.headline,
                maxLines: 2,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter some text';
                  }
                },
                onSaved: (String value) {
                  setState(() {
                    _hasMessage = value.isNotEmpty;
                    if (_hasMessage) {
                      _messageContent = value;
                    }
                  });
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              alignment: Alignment.bottomLeft,
              child: TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Topic', filled: true),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter some text';
                  }
                },
                onSaved: (String value) {
                  setState(() {
                    _hasTopic = value.isNotEmpty;
                  });
                  if (_hasTopic) {
                    _topicContent = value;
                  }
                },
              ),
            ),
            _buildQosChoiceChips(),
            Container(
              decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: theme.dividerColor))),
              child: Row(
                children: <Widget>[
                  Checkbox(
                      value: _retainValue,
                      onChanged: (bool value) {
                        setState(() {
                          _retainValue = value;
                          _saveNeeded = true;
                        });
                      }),
                  const Text('Retained'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Wrap _buildQosChoiceChips() {
    return Wrap(
      spacing: 4.0,
      children: List<Widget>.generate(
        3,
        (int index) {
          return ChoiceChip(
            label: Text('QoS level $index'),
            selected: _qosValue == index,
            onSelected: (bool selected) {
              setState(() {
                _qosValue = selected ? index : null;
              });
            },
          );
        },
      ).toList(),
    );
  }

  Future<bool> _onWillPop() async {
    _saveNeeded = _hasTopic || _hasMessage || _saveNeeded;

    if (!_saveNeeded) return true;

    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text('Discard message?', style: dialogTextStyle),
              actions: <Widget>[
                FlatButton(
                    child: const Text('CANCEL'),
                    onPressed: () {
                      Navigator.of(context).pop(
                          false); // Pops the confirmation dialog but not the page.
                    }),
                FlatButton(
                    child: const Text('DISCARD'),
                    onPressed: () {
                      Navigator.of(context).pop(
                          true); // Returning true to _onWillPop will pop again.
                    })
              ],
            );
          },
        ) ??
        false;
  }

  void _sendMessage() {
    final mqtt.MqttClientPayloadBuilder builder =
        mqtt.MqttClientPayloadBuilder();

    builder.addString(_messageContent);
    widget.client.publishMessage(
      _topicContent,
      mqtt.MqttQos.values[_qosValue],
      builder.payload,
      retain: _retainValue,
    );
    Navigator.pop(context);
  }
}
