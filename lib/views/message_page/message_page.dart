import 'package:flutter/material.dart';
// import 'package:giphy_api_client/giphy_api_client.dart'; // REMOVED
import 'package:line_icons/line_icons.dart';
import '../../constants/colors.dart';
import '../../helper/size_config.dart';
import '../../models/user.dart';
import 'message_page_widgets.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({Key? key, required this.user}) : super(key: key);

  final User user;

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  // --- All Giphy related state variables have been removed ---
  // bool isGifClicked = false; // REMOVED
  TextEditingController messageController = TextEditingController();
  // TextEditingController gifController = TextEditingController(); // REMOVED
  // final client = GiphyClient(...); // REMOVED
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    // ?. is no longer needed as WidgetsBinding.instance is non-nullable now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor(context),
      body: Column(
        children: [
          headerSection(context, widget.user),
          Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(top: 20),
                  children: [
                    circularMessage(
                        fromFriend: true,
                        messageType: MessageType.text,
                        message: "Whatcha doing bro? 🤔"),
                    circularMessage(
                        fromFriend: false,
                        messageType: MessageType.text,
                        message:
                        "nah! bro, nothing much but I found a great channel on YouTube"),
                    // --- The circularMessage that displayed a GIF has been removed ---
                    circularMessage(
                        fromFriend: false,
                        messageType: MessageType.url,
                        url: "https://www.youtube.com/watch?v=yqsb3gKP_N4"),
                    circularMessage(
                        fromFriend: false,
                        messageType: MessageType.text,
                        message:
                        "Yeah! You can watch this video where he is explaining about a whatsapp clone!"),
                    circularMessage(
                        fromFriend: true,
                        messageType: MessageType.text,
                        message: "Wowww! That does sound cool"),
                    circularMessage(
                        fromFriend: true,
                        messageType: MessageType.text,
                        message:
                        "I am going to subscribe the channel right NOW!!!"),
                  ],
                ),
              )),
          // --- All logic for showing the GIF search bar or message bar is gone. ---
          // --- Replaced with a single, permanent message input bar. ---
          SizedBox(
            width: SizeConfig.screenWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  // --- The GIF button is now a generic attachments button ---
                  circularIconButton(LineIcons.paperclip, () {
                    // TODO: Implement attachment logic (e.g., images, files)
                  }),
                  const SizedBox(
                    width: 8.0,
                  ),
                  Expanded(
                      child: circularTextField(
                          controller: messageController,
                          hintText: "Respond...")),
                  const SizedBox(
                    width: 8.0,
                  ),
                  circularIconButton(LineIcons.microphone, () {
                    // TODO: Implement voice message logic
                  }),
                  const SizedBox(
                    width: 8.0,
                  ),
                  circularIconButton(LineIcons.horizontalEllipsis, () {
                    // TODO: Implement "more options" logic
                  })
                ],
              ),
            ),
          ),
          // --- The entire GridView for displaying GIFs has been removed ---
        ],
      ),
    );
  }
}
