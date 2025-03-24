import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_disease_detector/constants/constants.dart';
import 'package:plant_disease_detector/services/classify.dart';
import 'package:plant_disease_detector/services/disease_provider.dart';
import 'package:plant_disease_detector/services/hive_database.dart';
import 'package:plant_disease_detector/src/home_page/components/greeting.dart';
import 'package:plant_disease_detector/src/home_page/components/history.dart';
import 'package:plant_disease_detector/src/home_page/components/instructions.dart';
import 'package:plant_disease_detector/src/home_page/components/titlesection.dart';
import 'package:plant_disease_detector/src/home_page/models/disease_model.dart';
import 'package:plant_disease_detector/src/suggestions_page/suggestions.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  static const routeName = '/';

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isProcessing = false; // Loading state

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }

  // Function to process the image from camera or gallery
  Future<void> processImage(ImageSource source) async {
    try {
      setState(() {
        isProcessing = true;
      });

      final classifier = Classifier();
      final _diseaseService = Provider.of<DiseaseService>(context, listen: false);
      final _hiveService = HiveService();

      final List? result = await classifier.getDisease(source);

      if (result != null && result.isNotEmpty) {
        Disease _disease = Disease(
          name: result[0]["label"],
          imagePath: classifier.imageFile.path,
        );
        double _confidence = result[0]['confidence'];

        // Show confidence level in a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Confidence Level: ${(_confidence * 100).toStringAsFixed(2)}%'),
            duration: const Duration(seconds: 2),
          ),
        );

        if (_confidence > 0.8) {
          // Save and navigate to suggestions page
          _diseaseService.setDiseaseValue(_disease);
          _hiveService.addDisease(_disease);
          Navigator.restorablePushNamed(context, Suggestions.routeName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot confidently identify the disease. Try again with a clearer image.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No disease detected. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _diseaseService = Provider.of<DiseaseService>(context);
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SpeedDial(
        icon: isProcessing ? Icons.hourglass_empty : Icons.camera_alt,
        spacing: 10,
        children: [
          SpeedDialChild(
            child: const FaIcon(FontAwesomeIcons.file, color: kWhite),
            label: "Choose image",
            backgroundColor: kMain,
            onTap: isProcessing ? null : () => processImage(ImageSource.gallery),
          ),
          SpeedDialChild(
            child: const FaIcon(FontAwesomeIcons.camera, color: kWhite),
            label: "Take photo",
            backgroundColor: kMain,
            onTap: isProcessing ? null : () => processImage(ImageSource.camera),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: CustomScrollView(
              slivers: [
                GreetingSection(size.height * 0.2),
                TitleSection('Instructions', size.height * 0.066),
                InstructionsSection(size),
                TitleSection('Your History', size.height * 0.066),
                HistorySection(size, context, _diseaseService),
              ],
            ),
          ),
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
