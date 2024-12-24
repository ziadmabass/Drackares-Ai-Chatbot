import 'package:dash_chat_2/dash_chat_2.dart'; // Chat UI package
import 'package:flutter/material.dart'; // Flutter material package
import 'package:flutter_gemini/flutter_gemini.dart'; // Gemini AI integration
import 'package:image_picker/image_picker.dart'; // Image picker for media selection
import 'package:google_ml_kit/google_ml_kit.dart'; // For face detection
import 'package:translator/translator.dart'; // For text translation
import 'package:flutter_tts/flutter_tts.dart'; // For Text-to-Speech functionality
import 'package:googleapis/language/v1.dart'
    as language; // For sentiment analysis
import 'package:speech_to_text/speech_to_text.dart'; // Speech-to-Text functionality

// Define Homescreen widget
class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  String? image = "images/70eb0b53eb57c91db403928c5d02a19a.gif";
  final Gemini gemini = Gemini.instance;
  final GoogleTranslator translator = GoogleTranslator(); // Translator instance
  FlutterTts flutterTts = FlutterTts(); // Text-to-Speech instance
  SpeechToText _speechToText = SpeechToText(); // Speech-to-Text instance
  bool _isListening = false; // Track the listening state

  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(
    id: "0",
    firstName: "User",
  );

  ChatUser geminiuser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage:
        'https://th.bing.com/th/id/R.eb30bf977ffb1a405f675470b65f5456?rik=t51iC6s8lsLCJA&pid=ImgRaw&r=0',
  );

  @override
  void initState() {
    super.initState();
    _initSpeechRecognition(); // Initialize speech recognition
  }

  // Initialize Speech-to-Text
  void _initSpeechRecognition() async {
    bool available = await _speechToText.initialize();
    if (!available) {
      print("Speech recognition is not available");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set the background to black
      appBar: AppBar(
        leading: Image.network(
            'https://th.bing.com/th/id/R.eb30bf977ffb1a405f675470b65f5456?rik=t51iC6s8lsLCJA&pid=ImgRaw&r=0'),
        title: Text(
          "Drackares",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black, // Set appBar background to black
      ),
      body: _buildUi(),
    );
  }

  // Builds the UI with DashChat widget
  Widget _buildUi() {
    return DashChat(
      inputOptions: InputOptions(
        inputToolbarStyle: BoxDecoration(color: Colors.black),
        trailing: [
          IconButton(
            icon: Icon(
              Icons.camera_alt,
              color: Colors.white,
            ),
            onPressed: _sendCameraImage,
          ),
          IconButton(
            icon: Icon(Icons.image, color: Colors.white),
            onPressed: _sendGalleryImage,
          ),
        ],
      ),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      messageOptions: MessageOptions(
          currentUserContainerColor: Colors.black,
          currentUserTextColor: Colors.white,
          containerColor: Colors.deepOrange,
          currentUserTimeTextColor: Colors.white,
          textColor: Colors.white),
    );
  }

  // Send text messages
  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    try {
      String question = chatMessage.text;
      gemini.streamGenerateContent(question).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiuser) {
          lastMessage = messages.removeAt(0);
          String response = event.content?.parts?.fold(
                  "", (previous, current) => '$previous ${current.text}') ??
              '';
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          String response = event.content?.parts?.fold(
                  "", (previous, current) => '$previous ${current.text}') ??
              '';
          ChatMessage message = ChatMessage(
            user: geminiuser,
            text: response,
            createdAt: DateTime.now(),
          );
          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  // Send media (images) from the camera
  void _sendCameraImage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.camera);

    if (file != null) {
      _recognizeImage(file); // Call the image recognition function
      _detectFaces(file); // Detect faces in the image

      // Send the image to AI for description
      ChatMessage message = ChatMessage(
        user: currentUser,
        text: 'What is this image of?', // Ask AI to describe the image
        createdAt: DateTime.now(),
        medias: [
          ChatMedia(
            fileName: '',
            type: MediaType.image,
            url: file.path,
          ),
        ],
      );
      _sendMessage(message);

      gemini.streamGenerateContent('What is in this image?').listen((event) {
        String response = event.content?.parts?.fold(
                "", (previous, current) => '$previous ${current.text}') ??
            '';
        ChatMessage descriptionMessage = ChatMessage(
          user: geminiuser,
          text: 'AI Description: $response',
          createdAt: DateTime.now(),
        );
        setState(() {
          messages = [descriptionMessage, ...messages];
        });
      });
    }
  }

  // Send media (images) from the gallery
  void _sendGalleryImage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      _recognizeImage(file); // Call the image recognition function
      _detectFaces(file); // Detect faces in the image

      // Send the image to AI for description
      ChatMessage message = ChatMessage(
        user: currentUser,
        text: 'What is this image of?', // Ask AI to describe the image
        createdAt: DateTime.now(),
        medias: [
          ChatMedia(
            fileName: '',
            type: MediaType.image,
            url: file.path,
          ),
        ],
      );
      _sendMessage(message);

      gemini.streamGenerateContent('').listen((event) {
        String response = event.content?.parts?.fold(
                "", (previous, current) => '$previous ${current.text}') ??
            '';
        ChatMessage descriptionMessage = ChatMessage(
          user: geminiuser,
          text: 'AI Description: $response',
          createdAt: DateTime.now(),
        );
        setState(() {
          messages = [descriptionMessage, ...messages];
        });
      });
    }
  }

  // Image recognition using Google Vision API (ML Kit)
  void _recognizeImage(XFile file) async {
    final InputImage inputImage = InputImage.fromFilePath(file.path);
    final imageLabeler = GoogleMlKit.vision.imageLabeler();
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);

    if (labels.isNotEmpty) {
      String description = 'I detected the following objects:';
      for (var label in labels) {
        description += '\n- ${label.label}';
      }
      setState(() {
        messages.insert(
          0,
          ChatMessage(
            user: geminiuser,
            text: description,
            createdAt: DateTime.now(),
          ),
        );
      });
    }
  }

  // Detect faces in the image using Google ML Kit
  void _detectFaces(XFile file) async {
    final InputImage inputImage = InputImage.fromFilePath(file.path);

    final faceDetector = GoogleMlKit.vision.faceDetector();
    final faces = await faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      setState(() {
        messages.insert(
          0,
          ChatMessage(
            user: geminiuser,
            text: 'Detected ${faces.length} face(s) in the image!',
            createdAt: DateTime.now(),
          ),
        );
      });
    }
  }
}
