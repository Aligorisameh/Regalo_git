import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:regalofficial/app_localizations.dart';
import 'package:intl/intl.dart';

class AllAdsPage extends StatefulWidget {
  @override
  _AllAdsPageState createState() => _AllAdsPageState();
}

class _AllAdsPageState extends State<AllAdsPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  Map<String, TextEditingController> giftsControllers = {};
  Map<String, TextEditingController> numberOfWinnersControllers = {};
  Map<String, TextEditingController> endDateControllers = {};

  @override
  void dispose() {
    searchController.dispose();
    giftsControllers.forEach((key, controller) => controller.dispose());
    numberOfWinnersControllers
        .forEach((key, controller) => controller.dispose());
    endDateControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('all_ads')),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!
                    .translate('search_by_company_name'),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      searchQuery = '';
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('companies')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                        '${AppLocalizations.of(context)!.translate('error')}: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print("No ads found in 'companies' collection.");
                  return Center(
                    child: Text(AppLocalizations.of(context)!
                        .translate('no_ads_found')),
                  );
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var companyName = data['companyName'] ?? '';
                  return companyName
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());
                }).toList();

                print("Ads found: ${filteredDocs.length}");

                return ListView(
                  children: filteredDocs.map((companySnapshot) {
                    var data = companySnapshot.data() as Map<String, dynamic>?;
                    if (data == null) {
                      print(
                          'Invalid data for document ID: ${companySnapshot.id}');
                      return Center(
                        child: Text(AppLocalizations.of(context)!
                            .translate('invalid_data')),
                      );
                    }

                    String companyId = companySnapshot.id;
                    String companyName = data['companyName'] ??
                        AppLocalizations.of(context)!
                            .translate('unknown_company');
                    bool isPublished = data['isPublished'] ?? false;
                    bool isRejected = data['isRejected'] ?? false;
                    List<dynamic> imageUrls = data['imageUrls'] ?? [];
                    List<dynamic> questions = data['questions'] ?? [];
                    String selectedType = data['selectedType'] ??
                        AppLocalizations.of(context)!
                            .translate('unknown_company');
                    String videoUrl = data['videoUrl'] ?? '';
                    bool isNew = false;

                    if (data.containsKey('timestamp') &&
                        data['timestamp'] != null) {
                      Timestamp timestamp = data['timestamp'];
                      isNew =
                          DateTime.now().difference(timestamp.toDate()).inDays <
                              7;
                    }

                    if (!giftsControllers.containsKey(companyId)) {
                      giftsControllers[companyId] = TextEditingController(
                          text: data['gifts']?.toString() ?? '');
                    }
                    if (!numberOfWinnersControllers.containsKey(companyId)) {
                      numberOfWinnersControllers[companyId] =
                          TextEditingController(
                              text: data['numberOfWinners']?.toString() ?? '');
                    }
                    if (!endDateControllers.containsKey(companyId)) {
                      endDateControllers[companyId] = TextEditingController(
                        text: data.containsKey('endDate')
                            ? DateFormat('yyyy-MM-dd HH:mm')
                                .format((data['endDate'] as Timestamp).toDate())
                            : '',
                      );
                    }

                    print('Company Name: $companyName');
                    print('isPublished: $isPublished');
                    print('isRejected: $isRejected');
                    print('imageUrls: $imageUrls');
                    print('questions: $questions');
                    print('selectedType: $selectedType');
                    print('videoUrl: $videoUrl');

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green, Colors.blue, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    companyName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (isNew) ...[
                                    SizedBox(width: 8),
                                    BlinkingText(
                                      text: AppLocalizations.of(context)!
                                          .translate('new'),
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '${AppLocalizations.of(context)!.translate('type')}: $selectedType',
                                style: TextStyle(color: Colors.white),
                              ),
                              _buildImageDisplay(imageUrls),
                              if (videoUrl.isNotEmpty)
                                ChewieVideoPlayer(videoUrl: videoUrl),
                              _buildQuestionsTable(questions),
                              TextField(
                                controller: giftsControllers[companyId],
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!
                                      .translate('gifts'),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                              ),
                              TextField(
                                controller:
                                    numberOfWinnersControllers[companyId],
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!
                                      .translate('number_of_winners'),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              TextField(
                                controller: endDateControllers[companyId],
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!
                                      .translate('end_date'),
                                  hintText: 'yyyy-MM-dd HH:mm',
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                readOnly: true,
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedDate != null) {
                                    TimeOfDay? pickedTime =
                                        await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (pickedTime != null) {
                                      setState(() {
                                        DateTime finalDateTime = DateTime(
                                          pickedDate.year,
                                          pickedDate.month,
                                          pickedDate.day,
                                          pickedTime.hour,
                                          pickedTime.minute,
                                        );
                                        endDateControllers[companyId]!.text =
                                            DateFormat('yyyy-MM-dd HH:mm')
                                                .format(finalDateTime);
                                      });
                                    }
                                  }
                                },
                              ),
                              Row(
                                children: [
                                  FloatingActionButton(
                                    heroTag: 'publish-${companySnapshot.id}',
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection('companies')
                                          .doc(companySnapshot.id)
                                          .update({
                                            'isPublished': !isPublished,
                                          })
                                          .then((_) =>
                                              print("Ad updated successfully"))
                                          .catchError((error) => print(
                                              "Failed to update ad: $error"));
                                    },
                                    child: Icon(isPublished
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    tooltip: isPublished
                                        ? AppLocalizations.of(context)!
                                            .translate('unpublish')
                                        : AppLocalizations.of(context)!
                                            .translate('publish'),
                                  ),
                                  SizedBox(width: 8),
                                  FloatingActionButton(
                                    heroTag: 'delete-${companySnapshot.id}',
                                    onPressed: () =>
                                        _deleteAd(context, companySnapshot.id),
                                    child: Icon(Icons.delete),
                                    backgroundColor: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  FloatingActionButton(
                                    heroTag: 'save-${companySnapshot.id}',
                                    onPressed: () {
                                      String gifts =
                                          giftsControllers[companyId]!.text;
                                      int numberOfWinners = int.tryParse(
                                              numberOfWinnersControllers[
                                                      companyId]!
                                                  .text) ??
                                          0;
                                      DateTime? endDate;
                                      try {
                                        endDate = DateFormat('yyyy-MM-dd HH:mm')
                                            .parseStrict(
                                                endDateControllers[companyId]!
                                                    .text);
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(AppLocalizations.of(
                                                  context)!
                                              .translate('invalid_end_date')),
                                          backgroundColor: Colors.red,
                                        ));
                                        return;
                                      }

                                      FirebaseFirestore.instance
                                          .collection('companies')
                                          .doc(companySnapshot.id)
                                          .update({
                                            'gifts': gifts,
                                            'numberOfWinners': numberOfWinners,
                                            'endDate':
                                                Timestamp.fromDate(endDate),
                                          })
                                          .then((_) =>
                                              print("Ad updated successfully"))
                                          .catchError((error) => print(
                                              "Failed to update ad: $error"));
                                    },
                                    child: Icon(Icons.save),
                                    backgroundColor: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  FloatingActionButton(
                                    heroTag: 'reject-${companySnapshot.id}',
                                    onPressed: () =>
                                        _rejectAd(context, companySnapshot.id),
                                    child: Icon(Icons.thumb_down),
                                    backgroundColor: Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTable(List<dynamic> questions) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
              label: Text(AppLocalizations.of(context)!.translate('question'))),
          DataColumn(
              label: Text(AppLocalizations.of(context)!.translate('choices'))),
          DataColumn(
              label: Text(
                  AppLocalizations.of(context)!.translate('correct_answer'))),
          DataColumn(
              label:
                  Text(AppLocalizations.of(context)!.translate('explanation'))),
        ],
        rows: questions.map<DataRow>((question) {
          return DataRow(cells: [
            DataCell(Text(question['question'] ?? '')),
            DataCell(Text((question['choices'] as List<dynamic>).join(', '))),
            DataCell(Text(question['correctAnswer']?.toString() ?? '')),
            DataCell(Text(question['explanation'] ?? '')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildImageDisplay(List<dynamic> imageUrls) {
    return Wrap(
      children: imageUrls.map<Widget>((imageUrl) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network(
            imageUrl,
            width: 100,
            height: 100,
          ),
        );
      }).toList(),
    );
  }

  void _deleteAd(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context)!.translate('ad_deleted_successfully')),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${AppLocalizations.of(context)!.translate('failed_to_delete_ad')}: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _rejectAd(BuildContext context, String docId) {
    TextEditingController reasonController = TextEditingController();
    List<String> fields = [
      AppLocalizations.of(context)!.translate('company_name'),
      AppLocalizations.of(context)!.translate('type'),
      AppLocalizations.of(context)!.translate('image'),
      AppLocalizations.of(context)!.translate('video'),
      AppLocalizations.of(context)!.translate('questions'),
    ];
    List<String> selectedFields = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('reject_ad')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!
                      .translate('rejection_reason'),
                ),
              ),
              SizedBox(height: 10),
              Text(AppLocalizations.of(context)!
                  .translate('select_incorrect_fields')),
              Wrap(
                spacing: 10.0,
                children: fields.map((field) {
                  return ChoiceChip(
                    label: Text(field),
                    selected: selectedFields.contains(field),
                    onSelected: (selected) {
                      setState(() {
                        selected
                            ? selectedFields.add(field)
                            : selectedFields.remove(field);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('companies')
                    .doc(docId)
                    .update({
                      'isRejected': true,
                      'rejectionReason': reasonController.text,
                      'rejectedFields': selectedFields,
                    })
                    .then((_) => print("Ad rejected successfully"))
                    .catchError(
                        (error) => print("Failed to reject ad: $error"));
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.translate('submit')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
          ],
        );
      },
    );
  }
}

class ChewieVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const ChewieVideoPlayer({required this.videoUrl, Key? key}) : super(key: key);

  @override
  _ChewieVideoPlayerState createState() => _ChewieVideoPlayerState();
}

class _ChewieVideoPlayerState extends State<ChewieVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _videoPlayerController.value.aspectRatio,
      child: Chewie(
        controller: _chewieController,
      ),
    );
  }
}

class BlinkingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const BlinkingText({required this.text, required this.style});

  @override
  _BlinkingTextState createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}
