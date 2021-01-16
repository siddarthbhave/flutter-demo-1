import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: ImageCapture(),
    );
  }
}


class ImageCapture extends StatefulWidget {
  @override
  _ImageCaptureState createState() => _ImageCaptureState();
}

class _ImageCaptureState extends State<ImageCapture> {
  File _imageFile;

  Future<void> _pickImage(ImageSource source) async {
    File selected = await ImagePicker.pickImage(source: source);

    setState(() {
      _imageFile = selected;
    });

  }
  
  Future<void> _cropImage() async {
    File cropped = await ImageCropper.cropImage(
          sourcePath: _imageFile.path,
          cropStyle: CropStyle.rectangle,
          androidUiSettings: AndroidUiSettings(
            toolbarColor: Colors.purple,
            toolbarTitle: 'Crop!!!',
            statusBarColor: Colors.blueGrey
          ),
    );

    setState(() {
      _imageFile = cropped ?? _imageFile;
    });
  
  }
  
  void _clear(){
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        notchMargin: 10.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              iconSize: 45.0,
              color: Colors.purpleAccent,
              highlightColor: Colors.white,
              icon: Icon(Icons.camera),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            Container(
              color: Colors.white, 
              width: 2,
              height: 50,
            ),
            IconButton(
              iconSize: 45.0,
              color: Colors.orangeAccent,
              highlightColor: Colors.white,
              icon: Icon(Icons.photo_album),
              onPressed: ()=>_pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
      body: ListView(
        children: <Widget>[
          if (_imageFile != null) ...[
            Image.file(
              _imageFile,
              height: 300,
              width: 300,
            ),
            Divider(
              color: Colors.white,
              thickness: 1.0,
              indent: 10,
              endIndent: 10,
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                FlatButton(
                  colorBrightness: Brightness.dark,
                  color: Colors.blue,
                  child: Icon(Icons.crop),
                  onPressed: _cropImage,
                ),
                Container(
                  color: Colors.white, 
                  width: 2,
                  height: 50,
                ),
                FlatButton(
                  color: Colors.blue,
                  colorBrightness: Brightness.dark,
                  child: Icon(Icons.refresh),
                  onPressed: _clear,
                )
              ],
            ),
            Divider(
              color: Colors.white,
              thickness: 1.0,
              indent: 10,
              endIndent: 10,
              height: 20,
            ),
            SizedBox(height: 20,),
            Uploader(file: _imageFile),
          ]
        ],
      ),
    );
  }
}

class Uploader extends StatefulWidget {
  final File file;
  Uploader({Key key , this.file}) : super(key: key);
  @override
  _UploaderState createState() => _UploaderState();
}

class _UploaderState extends State<Uploader> {
  
  final FirebaseStorage _storage = FirebaseStorage(storageBucket: 'gs://uploader-696f5.appspot.com');
  StorageUploadTask _uploadTask;

  void _startUpload(){
    String filepath = 'images/${DateTime.now()}.png';
    setState(() {
      _uploadTask = _storage.ref().child(filepath).putFile(widget.file);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    
    if (_uploadTask != null) {
      return StreamBuilder<StorageTaskEvent>(
        stream: _uploadTask.events,
        builder: (context , snapshot){
          var event = snapshot?.data?.snapshot;
          double progressPercent = event != null ? event.bytesTransferred / event.totalByteCount : 0;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              if(_uploadTask.isComplete)
              Text('Compelete!'),

              if(_uploadTask.isPaused)
              FlatButton(
                child: Icon(Icons.play_circle_filled),
                onPressed: _uploadTask.resume,
              ),

              if(_uploadTask.isInProgress)
              FlatButton(
                child: Icon(Icons.pause_circle_filled),
                onPressed: _uploadTask.pause,
              ),
              SizedBox(height: 10,),
              CircularProgressIndicator(
                backgroundColor: Colors.pinkAccent,
                value: progressPercent,
                strokeWidth: 8,
              ),
              SizedBox(height: 10,),
              Text(
                '${(progressPercent * 100).toStringAsFixed(2)} % '
              ),
            ],
          );

        },
      );
      
    } else {
      return Container(
        height: 35,
        padding: EdgeInsets.fromLTRB(90, 0, 90, 0),
        child: FlatButton.icon(
        
          colorBrightness: Brightness.dark,
          color: Colors.lightGreen,
          onPressed: _startUpload, 
          icon: Icon(Icons.cloud_upload), 
          label: Text('Upload'),
        ),
      );
    
    
    }
    
    
  }
}