// 1. ADD THIS NEW STATEFUL WIDGET CLASS
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
// ADD THIS LINE
import '../../constants/colors.dart';
import '../../helper/size_config.dart';
class UrlMessage extends StatefulWidget {
  final String url;
  final bool fromFriend;

  const UrlMessage({Key? key, required this.url, required this.fromFriend})
      : super(key: key);

  @override
  _UrlMessageState createState() => _UrlMessageState();
}

class _UrlMessageState extends State<UrlMessage> {
  // Store the fetched preview data in the state
  LinkPreviewData? _previewData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment:
        widget.fromFriend ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(widget.fromFriend ? 0 : 40),
              topLeft: const Radius.circular(40),
              topRight: const Radius.circular(40),
              bottomRight: Radius.circular(widget.fromFriend ? 40 : 0),
            ),
            child: Container(
              width: SizeConfig.screenWidth * 0.5,
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                  blackColor(SizeConfig.cntxt).lightShade.withOpacity(0.18),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(widget.fromFriend ? 0 : 40),
                  topLeft: const Radius.circular(40),
                  topRight: const Radius.circular(40),
                  bottomRight: Radius.circular(widget.fromFriend ? 40 : 0),
                ),
              ),
              child: Column(
                children: [
                  // This widget is now invisible, it only fetches the data
                  LinkPreview(
                    enableAnimation: true,
                    // Use the new 'onLinkPreviewDataFetched' callback
                    onLinkPreviewDataFetched: (data) {
                      setState(() {
                        // Save the data to the state to trigger a rebuild
                        _previewData = data;
                      });
                    },
                    // Use the correct 'text' parameter
                    text: widget.url,
                    // We will build our own preview, so make this small
                    maxWidth: 0,
                    //height: 0,
                  ),

                  // Show a loading indicator until data is fetched
                  if (_previewData == null)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CupertinoActivityIndicator(),
                    ),

                  // Once data is available, build the custom preview
                  if (_previewData != null)
                    _buildPreview(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final String? imageUrl = _previewData!.image?.url;
    final String? title = _previewData!.title;
    final String? description = _previewData!.description;

    if (imageUrl == null || title == null) {
      // Return a simple text widget if data is missing
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(widget.url, style: const TextStyle(color: Colors.blue)),
      );
    }

    // This is your old UI, now rebuilt with the state data
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl.isNotEmpty)
          Container(
            height: SizeConfig.screenWidth * 0.25, // Give it a fixed height
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: blackColor(SizeConfig.cntxt).darkShade,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (description != null)
                Text(
                  description,
                  style: TextStyle(
                    color: blackColor(SizeConfig.cntxt).lightShade,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        )
      ],
    );
  }
}
