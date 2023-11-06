import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:indie_spot/artistList.dart';
import 'package:indie_spot/lsjMain.dart';
import 'donationList.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:indie_spot/userModel.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'buskingReservation.dart';
class ArtistEdit extends StatefulWidget {
  final DocumentSnapshot doc;
  final String artistImg;

  ArtistEdit(this.doc, this.artistImg, {super.key});

  @override
  State<ArtistEdit> createState() => _ArtistEditState();
}

class _ArtistEditState extends State<ArtistEdit> {
  bool _isNameChecked = false;
  File? _selectedImage;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final TextEditingController _basicPrice =
      TextEditingController(); // 기본공연비(30분기준)
  final TextEditingController _artistName = TextEditingController();
  final TextEditingController _artistInfo = TextEditingController();
  final TextEditingController _mainPlace = TextEditingController();
  final TextEditingController _genreCon =
      TextEditingController(); // 직접 입력할 상세 장르

  String? _genre; // 검색에 이용될 장르
  String? _genreCheck; // 체크한 상세 장르
  bool selfCon = false; // 직접입력선택시
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _artistName.text = widget.doc['artistName'];
    _basicPrice.text = widget.doc['basicPrice'].toString();
    _artistInfo.text = widget.doc['artistInfo'];
    _genre = widget.doc['genre'];
    _mainPlace.text = widget.doc['mainPlace'];
    if (_artistName.text == widget.doc['artistName']) {
      setState(() {
        _isNameChecked = true; //
      });
    }
    if(widget.doc['detailedGenre'] != null || widget.doc['detailedGenre'] != ""){
      setState(() {
        _genreCheck = widget.doc['detailedGenre'];
      });

    }
  }

  void _checkArtistName() async {
    // 활동명이 비어있는지 확인

    if (_artistName.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('아티스트 활동명을 입력해주세요.')),
      );
      return;
    }
    // Firestore에서 중복 닉네임 체크
    final checkArtistName = await _fs
        .collection('artist')
        .where('artistName', isEqualTo: _artistName.text)
        .get();

    if (_artistName.text == widget.doc['artistName']) {
      setState(() {
        _isNameChecked = true; //
      });
    } else if (checkArtistName.docs.isNotEmpty &&
        _artistName.text != widget.doc.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미 사용 중인 활동명 입니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용 가능한 활동명 입니다.')),
      );
      setState(() {
        _isNameChecked = true; //
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  void _change() {
    setState(() {
      _isNameChecked = false;
    });
  }

  Future<String> _uploadImage(File imageFile) async {
    try {
      String fileName = path.basename(imageFile.path);

      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child('image/$fileName');

      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  void _artistEdit() async {
    if (!_isNameChecked) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("중복 확인 필요"),
            content: Text("아티스트 활동명 중복을 확인해주세요."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("확인"),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LoadingScreen();
      },
      barrierDismissible: false, // 사용자가 화면을 탭해서 닫는 것을 막습니다.
    );



    print(_genre);
    print(_genreCheck);

    print(_artistName.text);
    print(_artistInfo.text);
    print(_mainPlace.text);
    print(_basicPrice.text);
    if (_artistName.text.isEmpty ||
        _artistInfo.text.isEmpty ||
        _mainPlace.text.isEmpty ||
        _genre == null ||
        _basicPrice.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("모든 정보를 입력해주세요.")));
      return;
    }
    final imageUrl = _selectedImage != null
        ? await _uploadImage(_selectedImage!)
        : widget.artistImg; // 이미지를 선택하지 않았을 때 widget.artistImg 사용

    if(_genreCheck == null){
      _genreCheck = "";
    }




      try {
        // URL에서 토큰을 추출
        final token = Uri.parse(widget.artistImg).queryParameters['token'];

        if (token != null) {
          // 스토리지 레퍼런스를 생성하고 파일을 삭제
          final Reference storageReference = FirebaseStorage.instance.refFromURL(widget.artistImg);
          await storageReference.delete();
          print('파일 삭제 완료');
        } else {
          print('토큰이 없는 URL로 파일을 삭제할 수 없습니다.');
        }
      } catch (e) {
        print('파일 삭제 중 오류 발생: $e');
      }


    try {
      //수정 처리
      _fs.collection('artist').doc(widget.doc.id).update({
        'artistName': _artistName.text,
        'artistInfo': _artistInfo.text,
        'genre': _genre,
        'mainPlace': _mainPlace.text,
        'udatetime': Timestamp.now(),
        'basicPrice': int.parse(_basicPrice.text),
        "detailedGenre" : _genreCheck == "직접입력" ? _genreCon.text : _genreCheck
      });

      final QuerySnapshot snapshot = await _fs
          .collection('artist')
          .doc(widget.doc.id)
          .collection('image')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final DocumentSnapshot document = snapshot.docs[0]; // 기존 문서 중 하나를 선택
        final String imageDocumentId = document.id;

        //서브 콜렉션에 이미지 추가
        await _fs
            .collection('artist')
            .doc(widget.doc.id)
            .collection('image')
            .doc(imageDocumentId)
            .update({
          'path': imageUrl,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정되었습니다.')),
      );

      setState(() {
        _artistName.clear();
        _artistInfo.clear();
        _mainPlace.clear();
        _selectedImage = null;
      });

      //등록 완료후 페이지 이동
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ArtistList()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      print('Error: $e');
    }
  }

  Widget? _buildSelectedImage() {
    if (_selectedImage != null) {
      // 이미지를 미리보기로 보여줄 수 있음
      return Center(
        child: Image.file(_selectedImage!, height: 150),
      );
    }
    return null; // 이미지가 없을 경우// null을 반환
  }

  // 검색에 사용될 장르 라디오 버튼
  Widget _customRadioBut() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton(
          onPressed: () {
            setState(() {
              _genreCheck = null;
              selfCon = false;
              _genre = '음악';
            });
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (_genre == '음악') {
                return Color(0xFF392F31); // 선택된 경우의 색상
              }
              return Colors.white; // 선택되지 않은 경우의 색상
            }),
          ),
          child: Text(
            '음악',
            style: TextStyle(
              color: _genre == '음악' ? Colors.white : Color(0xFF392F31),
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _genreCheck = null;
              selfCon = false;
              _genre = '댄스';
            });
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (_genre == '댄스') {
                return Color(0xFF392F31);
              }
              return Colors.white;
            }),
          ),
          child: Text(
            '댄스',
            style: TextStyle(
              color: _genre == '댄스' ? Colors.white : Color(0xFF392F31),
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () {
            setState(() {
              selfCon = false;
              _genreCheck = null;
              _genre = '퍼포먼스';
            });
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (_genre == '퍼포먼스') {
                return Color(0xFF392F31);
              }
              return Colors.white;
            }),
          ),
          child: Text(
            '퍼포먼스',
            style: TextStyle(
              color: _genre == '퍼포먼스' ? Colors.white : Color(0xFF392F31),
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () {
            setState(() {
              selfCon = false;
              _genreCheck = null;
              _genre = '마술';
            });
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (_genre == '마술') {
                selfCon = false;
                return Color(0xFF392F31);
              }
              return Colors.white;
            }),
          ),
          child: Text(
            '마술',
            style: TextStyle(
              color: _genre == '마술' ? Colors.white : Color(0xFF392F31),
            ),
          ),
        ),
      ],
    );
  }

  // 상세 장르 선택
  Widget? _wrapWidget(String genre) {
    Map<String, List<String>> genreButtonMap = {
      "음악": ["밴드", "발라드", "힙합", "클래식", "악기연주", "싱어송라이터", "직접입력"],
      "댄스": ["팝핀", "비보잉", "힙합", "하우스", "크럼프", "락킹", "왁킹", "직접입력"],
      "퍼포먼스": ["행위예술", "현대미술", "직접입력"],
    };

    if (genre.isEmpty) {
      return null;
    }

    final buttonList = genreButtonMap[genre];
    if (buttonList != null && buttonList.isNotEmpty) {
      return Wrap(
        spacing: 5.0,
        runSpacing: 0.1,
        children: buttonList.map((label) {
          return OutlinedButton(
            onPressed: () {
              setState(() {
                if (label == "직접입력") {
                  _genreCheck = label;
                  selfCon = true;
                } else {
                  _genreCheck = label;
                }
              });
            },
            style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25), // 둥근 모서리 반경 설정
                ),
              ),
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.all(8.0), // 버튼의 내부 여백 설정
              ),
              side: MaterialStateProperty.all<BorderSide>(
                BorderSide(
                  color: label == _genreCheck
                      ? Color(0xFF392F31)
                      : Colors.white, // 선택된 버튼인지 여부에 따라 테두리 색 변경
                  width: 2.0, // 테두리 두께 설정
                ),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(color: Color(0xFF392F31)),
            ),
          );
        }).toList(),
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            '수정',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              '아티스트 정보 수정',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            SizedBox(height: 40),
            Row(
              children: [
                Text(
                  '아티스트 이미지',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  onPressed: _pickImage,
                  child: Text('이미지 선택'),
                ),
              ],
            ),
            SizedBox(height: 14),
            _buildSelectedImage() ??
                Container(
                  alignment: Alignment.center,
                  child: Image.network(
                    widget.artistImg,
                    width: 360,
                    height: 200,
                  ),
                ),
            SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '아티스트 활동명(팀 or 솔로)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 10),
                if (_isNameChecked)
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                      onPressed: _change,
                      child: Text('수정'))
                else if (!_isNameChecked)
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                      onPressed: _checkArtistName,
                      child: Text('중복 확인')),
                SizedBox(width: 10),
              ],
            ),
            SizedBox(height: 14),
            TextField(
              controller: _artistName,
              decoration: InputDecoration(
                  hintText: widget.doc['artistName'],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6))),
              enabled: !_isNameChecked,
            ),
            SizedBox(height: 40),
            Text(
              '소개',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 14),
            TextField(
              maxLines: 4,
              controller: _artistInfo,
              decoration: InputDecoration(
                  hintText: widget.doc['artistInfo'],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6))),
            ),
            SizedBox(height: 40),
            Text(
              '주활동 지역',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 14),
            TextField(
              controller: _mainPlace,
              decoration: InputDecoration(
                  hintText: widget.doc['mainPlace'],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6))),
            ),
            Text(
              '기본공연비(30분 기중)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 14),
            TextField(
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              controller: _basicPrice,
              decoration: InputDecoration(
                  hintText: widget.doc['basicPrice'].toString(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6))),
            ),
            SizedBox(height: 40),
            Text(
              '장르',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 14),
            Column(
              children: [
                _customRadioBut(),
                _wrapWidget(_genre!)!,
                if (selfCon)
                  TextField(
                    controller: _genreCon,
                    decoration: InputDecoration(
                        hintText: "상세 장르를 입력하시오 ex)락",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6))
                    ),
                  ),
              ],
            ),
            SizedBox(height: 40),
            SizedBox(height: 40),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                // Add horizontal padding if needed
                child: ElevatedButton(
                  onPressed: _artistEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF392F31), // 392F31 색상
                    minimumSize: Size(
                        double.infinity, 48), // Set button width and height
                  ),
                  child: Text(
                    '등록하기',
                    style: TextStyle(fontSize: 18, letterSpacing: 3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}