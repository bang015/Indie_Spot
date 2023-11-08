import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indie_spot/artistInfo.dart';
import 'package:indie_spot/login.dart';
import 'package:indie_spot/videoDetailed.dart';
import 'artistEdit.dart';
import 'artistMembers.dart';
import 'artistTeamJoin.dart';
import 'baseBar.dart';
import 'package:intl/intl.dart';
import 'donationList.dart';
import 'donationPage.dart';
import 'userModel.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class ArtistInfo extends StatefulWidget {
  final String docId;

  ArtistInfo(this.docId, {super.key});

  @override
  State<ArtistInfo> createState() => _ArtistInfoState();
}

class _ArtistInfoState extends State<ArtistInfo> {
  FirebaseFirestore fs = FirebaseFirestore.instance;

  bool _followerFlg = false; // 팔로우 했는지!
  bool scheduleFlg = true;
  int? folCnt; // 팔로워
  String? _artistId; // 리더
  String? _artistId2; // 맴버
  String? _userId;

  // 아티스트 정보
  String artistName = "";
  String artistInfo = "";
  String genre = "";
  String artistImg = "";

  //////////////세션 확인//////////
  bool isDataLoaded = false; // 데이터 로드 완료 여부를 확인하는 변수
  @override
  void initState() {
    _followerCount();
    artistLoad();
    final userModel = Provider.of<UserModel>(context, listen: false);
    if (!userModel.isLogin) {
    } else {
      _userId = userModel.userId;
      _loadData().then((_) {
        // 데이터 로딩이 완료된 경우 artistCheck 함수 호출
        _followCheck();
        artistCheck();
        isDataLoaded = true; // 데이터 로드 완료 표시
        setState(() {}); // 상태 업데이트
      });
    }
    super.initState();
  }

  Future<void> _loadData() async {
    LoadingScreen();

  }

  // 아티스트 권한 확인
  // 아티스트 멤버 권한이 리더 인 userId 가 _userId 와 같을때
  void artistCheck() async {
    final artistCheckSnap = await fs.collection('artist')
        .doc(widget.docId)
        .collection('team_members')
        .where('status', isEqualTo: 'Y')
        .where('userId', isEqualTo: _userId)
        .get();

    final artistMemberCheck = await fs.collection('artist')
        .doc(widget.docId)
        .collection('team_members')
        .where('userId', isEqualTo: _userId)
        .get();

    if (artistCheckSnap.docs.isNotEmpty) {
      setState(() {
        _artistId = _userId;
      });
    } else if (artistMemberCheck.docs.isNotEmpty) {
      setState(() {
        _artistId2 = _userId;
      });
    }
  }

  // 팔로우COUNT 불러오기
  void _followerCount() async {
    final CollectionReference artistCollection =
        FirebaseFirestore.instance.collection('artist');
    final DocumentReference artistDocument =
        artistCollection.doc(widget.docId);

    artistDocument.get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        // 문서가 존재하는 경우 필드 가져오기
        folCnt = documentSnapshot['followerCnt'];
      } else {
        folCnt = 0;
      }
    }).catchError((error) {
      print('데이터 가져오기 중 오류 발생: $error');
    });
  }

  //////////////팔로우 확인/////////////
  void _followCheck() async {
    final followYnSnapshot = await fs
        .collection('artist')
        .doc(widget.docId)
        .collection('follower')
        .where('userId', isEqualTo: _userId)
        .get(); // 데이터를 검색하기 위해 get()를 사용합니다.
    setState(() {
      if (followYnSnapshot.docs.isNotEmpty) {
        _followerFlg = true;
      } else {
        _followerFlg = false;
      }
      _followerCount(); // 팔로우count
    });
  }

  ///// 팔로우 하기
  void _followAdd() async {
    if (_userId == null) {
      _alertDialogWidget();
    } else {
      CollectionReference followAdd =
          fs.collection('artist').doc(widget.docId).collection('follower');


      await followAdd.add({'userId': _userId});
      DocumentReference artistDoc = fs.collection('artist').doc(widget.docId);
      artistDoc.update({
        'followerCnt': FieldValue.increment(1), // 1을 증가시킵니다.
      });
      // 유저
      var myFollowingRef = fs.collection('userList').doc(_userId);
      var myFollowing = await myFollowingRef.collection('following');
      await myFollowing.add({"artistId": widget.docId});
      myFollowingRef.update({
        'followingCnt': FieldValue.increment(1),
      });

      _followCheck();
    }
  }

  // 팔로우 취소
  void _followDelete() async {
    CollectionReference followDelete =
        fs.collection('artist').doc(widget.docId).collection('follower');

    var myFollowingRef = fs.collection('userList').doc(_userId);

    // 팔로우 관계를 삭제합니다.
    QuerySnapshot querySnapshot =
        await followDelete.where('userId', isEqualTo: _userId).get();
    if (querySnapshot.docs.isNotEmpty) {
      for (QueryDocumentSnapshot document in querySnapshot.docs) {
        // 해당 사용자와 관련된 문서를 삭제합니다.
        await document.reference.delete();

        DocumentReference artistDoc =
            fs.collection('artist').doc(widget.docId);
        artistDoc.update({
          'followerCnt': FieldValue.increment(-1), // 1을 감소시킵니다.
        });
      }

      await myFollowingRef
          .collection('following')
          .where('artistId', isEqualTo: widget.docId)
          .get()
          .then((querySnapshot) {
          querySnapshot.docs.forEach((doc) {
          doc.reference.delete();
        });
      });

      await myFollowingRef.update({
        'followingCnt': FieldValue.increment(-1),
      });
      _followCheck();
    }
  }

  // 아티스트정보 불러오기
  void artistLoad() async {
    final artistDoc = await fs.collection('artist').doc(widget.docId).get();
    if(artistDoc.exists){
      setState(() async {
        artistName = artistDoc['artistName'];
        artistInfo = artistDoc['artistInfo'];
        genre = artistDoc['genre'];
        // 이미지 데이터 로드
        final imageCollection = await fs.collection('artist').doc(widget.docId).collection('image').get();
        if (imageCollection.docs.isNotEmpty) {
          artistImg = imageCollection.docs.first['path'];
        }
      });

    } else {
      LoadingScreen();
    }



  }

  // 기본 엘럿 
  void inputDuplicateAlert(String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text("확인"),
              onPressed: () {
                Navigator.of(context).pop(); // 알림 창 닫기
              },
            ),
          ],
        );
      },
    );
  }

  // 로그인 해라
  _alertDialogWidget() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text("로그인이후 이용 가능합니다."),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  }, // 기능
                  child: Text("취소")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(),
                      ),
                    ).then((value) => Navigator.of(context).pop());
                  }, // 기능
                  child: Text("로그인")),
            ],
          );
        });
  }

  // 스피드 다이얼로그
  Widget? floatingButtons() {
    if (_artistId != null || _artistId2 != null) {
      return SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        visible: true,
        curve: Curves.bounceIn,
        backgroundColor: Color(0xFF56555B),
        children: [
          SpeedDialChild(
              child: const Icon(Icons.settings_sharp, color: Colors.white),
              label: "수정",
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 13.0),
              backgroundColor: Color(0xFF392F31),
              labelBackgroundColor: Color(0xFF392F31),
              onTap: () {

                if(_artistId != null){ // 리더가 맞다면
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(); // 현재 페이지를 제거
                  }
                  // Navigator.of(context).push(MaterialPageRoute(
                  //   builder: (context) {
                  //     return ArtistEdit(widget.doc, widget.artistImg); // 새 페이지로 이동
                  //   },
                  // ));
                } else{
                  inputDuplicateAlert("리더만 수정이 가능합니다");
                }


              }),
          SpeedDialChild(
            child: const Icon(
              Icons.add_chart_rounded,
              color: Colors.white,
            ),
            label: "내 후원기록",
            backgroundColor: Color(0xFF392F31),
            labelBackgroundColor: Color(0xFF392F31),
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 13.0),
            onTap: () {
              if(_artistId != null){
                Navigator.of(context)
                    .push(MaterialPageRoute(
                  builder: (context) => DonationList(artistId: widget.docId),
                ))
                    .then((value) => setState(() {}));
              } else {
                inputDuplicateAlert("리더만 확인이 가능합니다");
              }
              
            }),
            SpeedDialChild(
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                label: "팀 관리",
                backgroundColor: Color(0xFF392F31),
                labelBackgroundColor: Color(0xFF392F31),
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontSize: 13.0),
                onTap: () {
                  // Navigator.of(context)
                  //     .push(MaterialPageRoute(
                  //   builder: (context) => ArtistMembers(widget.doc, widget.artistImg, _artistId),
                  // ))
                  //     .then((value) => setState(() {}));
                }),
        ],
      );
    } else {
      return SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        visible: true,
        curve: Curves.bounceIn,
        backgroundColor: Color(0xFF233067),
        children: [
          SpeedDialChild(
              child: const Icon(Icons.settings_sharp, color: Colors.white),
              label: "후원하기",
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 13.0),
              backgroundColor: Color(0xFF392F31),
              labelBackgroundColor: Color(0xFF392F31),
              onTap: () {
                if (_userId != null) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        DonationPage(artistId: widget.docId),
                  ));
                } else {
                  _alertDialogWidget();
                }
              },
              ),
          SpeedDialChild(
              child: const Icon(
                Icons.add_chart_rounded,
                color: Colors.white,
              ),
              label: "팀 가입신청",
              backgroundColor: Color(0xFF392F31),
              labelBackgroundColor: Color(0xFF392F31),
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 13.0),
              onTap: () {
                if(_userId != null){
                  // Navigator.of(context)
                  //     .push(MaterialPageRoute(
                  //   builder: (context) => ArtistTeamJoin(widget.doc),
                  // )).then((value) => setState(() {}));
                } else{
                  _alertDialogWidget();
                }


              }),
        ],
      );
    }
  }

  /////////////////상세 타이틀///////////////
  Widget _infoTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: Image.network(
            artistImg,
            width: 100, // 원 모양 이미지의 너비
            height: 100, // 원 모양 이미지의 높이
            fit: BoxFit.cover, // 이미지를 화면에 맞게 조절
          ),
        ),
        Text(
          artistName, // artistName
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black),
        ),
        Text(
          artistInfo, // artistName
          style: TextStyle(
              fontSize: 15,
              color: Colors.black),
        ),
        Text(
          genre,
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
        Row(
          children: [
            Stack(
              children: [
                if (_followerFlg)
                  IconButton(
                      onPressed: () {
                        _followDelete();
                        setState(() {});
                      },
                      icon: Icon(Icons.person_add)),
                if (!_followerFlg)
                  IconButton(
                      onPressed: () {
                        _followAdd();
                        setState(() {});
                      },
                      icon: Icon(Icons.person_add_alt)),
                Positioned(
                    right: 1, top: 1, child: Text(folCnt.toString())),
              ],
            ),
            IconButton(
              onPressed: () {
                if (_userId != null) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        DonationPage(artistId: widget.docId),
                  ));
                } else {
                  _alertDialogWidget();
                }
              },
              icon: Icon(Icons.price_change),
            )
          ],
        ),
      ],
    );
  }

////////////////////////////////아이스트 소개/////////////////////////////////////////
  // 아티스트 소개 데이터호출 위젯
  Future<List<Widget>> _artistDetails() async {
    final membersQuerySnapshot = await fs
        .collection('artist')
        .doc(widget.docId)
        .collection('team_members')
        .get(); // 데이터를 검색하기 위해 get()를 사용합니다.

    List<Widget> memberWidgets = [];

    if (membersQuerySnapshot.docs.isNotEmpty) {
      for (QueryDocumentSnapshot membersDoc in membersQuerySnapshot.docs) {
        String memberPosition = membersDoc['position']; // 팀 포지션

        // userList 접근하는 쿼리문
        final userListJoin = await fs
            .collection("userList")
            .where(FieldPath.documentId, isEqualTo: membersDoc['userId'])
            .get();

        if (userListJoin.docs.isNotEmpty) {
          for (QueryDocumentSnapshot userDoc in userListJoin.docs) {
            String userName = userDoc['name']; // 이름
            final userImage = await fs
                .collection('userList')
                .doc(userDoc.id)
                .collection('image')
                .get();

            if (userImage.docs.isNotEmpty) {
              for (QueryDocumentSnapshot userImg in userImage.docs) {
                String userImage = userImg['PATH'];

                // 예시: ListTile을 사용하여 팀 멤버 정보를 보여주는 위젯을 만듭니다.
                Widget memberWidget = ListTile(
                  leading: Image.network(userImage),
                  title: Text(userName),
                  subtitle: Text(memberPosition),
                  // 다른 정보를 표시하려면 여기에 추가하세요.
                );

                memberWidgets.add(memberWidget);
              }
            }
          }
        }
      }
      return memberWidgets;
    } else {
      return [Container()];
    }
  }

  // 아티스트 소개 탭
  Widget tab1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(artistInfo), // artistInfo
        ),
        SizedBox(
          height: 50,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '기본공연비(공연시간 30분기준)',
                style: TextStyle(fontSize: 15),
              ),
              Text(
                //'${widget.doc['basicPrice']} 원', // baseicPrice
                '원',
                style: TextStyle(fontWeight: FontWeight.w600),
              )
            ],
          ),
        ),
        Divider(thickness: 1, height: 1, color: Colors.grey),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "멤버",
            style: TextStyle(fontSize: 20),
          ),
        ),
      ],
    );
  }

//////////////////////////////아티스트 공연 일정//////////////////////////////////

  // 버스킹 공연일정
  Future<List<Widget>> _buskingSchedule() async {
    List<Widget> buskingScheduleWidgets = []; // 출력한 위젯 담을 변수
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    // 버스킹 일정 확인
    final buskingScheduleSnapshot = await fs
        .collection('busking')
        .where('artistId', isEqualTo: widget.docId)
        .get();

    // 버스킹 일정
    if (buskingScheduleSnapshot.docs.isNotEmpty) {
      for (QueryDocumentSnapshot buskingSchedule
          in buskingScheduleSnapshot.docs) {
        String title = buskingSchedule['title'];
        // yyyy-MM-dd HH:mm:ss
        String date = DateFormat('MM-dd(EEEE) HH:mm', 'ko_KR')
            .format(buskingSchedule['buskingStart'].toDate());
        final buskingImage = await fs
            .collection('busking')
            .doc(buskingSchedule.id)
            .collection('image')
            .get();
        if (buskingImage.docs.isNotEmpty) {
          for (QueryDocumentSnapshot buskingImg in buskingImage.docs) {
            String img = buskingImg['path'];

            final buskingSpotSnapshot = await fs
                .collection('busking_spot')
                .where(FieldPath.documentId,
                    isEqualTo: buskingSchedule['spotId'])
                .get();
            for (QueryDocumentSnapshot buskingSpot
                in buskingSpotSnapshot.docs) {
              String addr = buskingSpot['spotName'];

              Widget buskingScheduleWidget = Card(
                child: Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(img,
                          width: screenWidth * 0.2,
                          height: screenHeight * 0.1,
                          fit: BoxFit.cover),
                      SizedBox(width: 10),
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                addr,
                                style: TextStyle(fontSize: 13),
                              ),
                              Text(
                                date,
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              buskingScheduleWidgets.add(buskingScheduleWidget);
            }
          }
        }
      }

      return buskingScheduleWidgets; // 출력할 위젯
    } else {
      return [
        Container(
          child: Text("공연일정이 없습니다."),
        )
      ];
    }
  }

  //상업공간 공연 일정
  Future<List<Widget>> _commerSchedule() async {
    List<Widget> buskingScheduleWidgets = []; // 출력한 위젯 담을 변수
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // 상업공간 컬렉션 접근
    final commerSnapshot = await fs.collection('commercial_space').get();
    if (commerSnapshot.docs.isNotEmpty) {
      for (QueryDocumentSnapshot commerDoc in commerSnapshot.docs) {
        final commerScheduleSnapshot = await fs
            .collection('commercial_space')
            .doc(commerDoc.id)
            .collection('rental')
            .where('artistId', isEqualTo: widget.docId)
            .get();

        if (commerScheduleSnapshot.docs.isNotEmpty) {
          for (QueryDocumentSnapshot commerScheduleDoc
              in commerScheduleSnapshot.docs) {
            if (commerScheduleDoc['acceptYn'] == "y") {
              String startDate = DateFormat('MM-dd(EEEE) HH:mm', 'ko_KR')
                  .format(commerScheduleDoc['startTime'].toDate());
              String endDate = DateFormat(' ~ HH:mm')
                  .format(commerScheduleDoc['endTime'].toDate());
              String spaceName = commerDoc['spaceName'];

              final commerImageSnapshot = await fs
                  .collection('commercial_space')
                  .doc(commerDoc.id)
                  .collection('image')
                  .get();

              if (commerImageSnapshot.docs.isNotEmpty) {
                for (QueryDocumentSnapshot commerImageDoc
                    in commerImageSnapshot.docs) {
                  final List<dynamic> cmmerImg = commerImageDoc['path'];

                  final commerAddrSnapshot = await fs
                      .collection('commercial_space')
                      .doc(commerDoc.id)
                      .collection('addr')
                      .get();
                  if (commerAddrSnapshot.docs.isNotEmpty) {
                    for (QueryDocumentSnapshot commerAddrDoc
                        in commerAddrSnapshot.docs) {
                      String addr = commerAddrDoc['addr'];

                      Widget buskingScheduleWidget = Card(
                        child: Container(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.network(cmmerImg[0],
                                  width: screenWidth * 0.2,
                                  height: screenHeight * 0.1,
                                  fit: BoxFit.cover),
                              SizedBox(width: 10),
                              Container(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        spaceName,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        addr,
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        startDate + endDate,
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      buskingScheduleWidgets.add(buskingScheduleWidget);
                    }
                  }
                }
              }

              return buskingScheduleWidgets;
            } else {
              return [Container()];
            }
          }
        }
      }
    }

    return [Container()];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        //extendBodyBehindAppBar: true, // AppBar를 바디 영역 뒤에 확장
        appBar: AppBar(
          backgroundColor: Colors.transparent, // AppBar 배경을 투명하게 설정
          elevation: 1,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: Color(0xFFffffff), // 원하는 배경 색상으로 변경
            ),
          ),
          leading: Builder(
            builder: (context) {
              return IconButton(
                color: Color(0xFF233067),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.arrow_back),
              );
            },
          ),
          title: Center(
            child: Text(
              artistName,
              style:
                  TextStyle(color: Color(0xFF233067), fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            Builder(
              builder: (context) {
                return IconButton(
                  color: Color(0xFF233067),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: Icon(Icons.menu),
                );
              },
            )
          ],
        ),
        drawer: MyDrawer(),
        body: Column(
          children: [
            Container(
              height: 250,
              child: Column(
                children: [
                  _infoTitle(),
                ],
              ),
            ),
            TabBar(
              tabs: [
                Tab(text: '소개',),
                Tab(text: '공연일정'),
                Tab(text: '클립'),
              ],
              indicatorColor:Color(0xFF233067),
              unselectedLabelColor: Colors.black,
              labelColor: Color(0xFF233067),
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    // 소개 탭
                    children: [
                      Container(
                        child: FutureBuilder(
                          future: _artistDetails(),
                          builder: (BuildContext context,
                              AsyncSnapshot<dynamic> snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              return Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(top: 10),
                                    margin: EdgeInsets.all(20),
                                    child: Column(
                                      children: snapshot.data ?? [Container()],
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      )
                    ],
                  ),
                  //////////////공연 일정 탭////////////
                  ListView(
                    //////////////공연 일정 탭////////////
                    children: [
                      Container(
                        child: FutureBuilder(
                          future:
                          scheduleFlg ? _buskingSchedule() : _commerSchedule(),
                          builder: (BuildContext context,
                              AsyncSnapshot<dynamic> scheduleSnap) {
                            if (scheduleSnap.connectionState ==
                                ConnectionState.waiting) {
                              return Container();
                            } else if (scheduleSnap.hasError) {
                              return Text('Error: ${scheduleSnap.error}');
                            } else {
                              return Column(
                                children: [
                                  Container(
                                    child: Row(
                                      children: [
                                        Container(
                                          child: Center(
                                            child: TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  scheduleFlg = true;
                                                });
                                              },
                                              child: Text(
                                                "버스킹",
                                                style: TextStyle(color: Color(0xFF233067)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          child: Center(
                                            child: TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  scheduleFlg = false;
                                                });
                                              },
                                              child: Text(
                                                "상업공간",
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(top: 10),
                                    margin: EdgeInsets.all(20),
                                    child: Column(
                                      children: scheduleSnap.data ?? [Container()],
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      )
                    ],
                  ),

                  ///////////클립 탭/////////////
                  StreamBuilder(
                      stream: fs
                          .collection('video')
                          .where('artistId', isEqualTo: widget.docId)
                          .orderBy('cnt', descending: true)
                          .snapshots(),
                      builder: (context, AsyncSnapshot<QuerySnapshot> videoSnap) {
                        if (!videoSnap.hasData) {
                          return Center();
                        }
                        return GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 2개의 열을 가진 그리드
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2),
                            itemCount: videoSnap.data!.docs.length,
                            itemBuilder: (context, index) {
                              DocumentSnapshot doc = videoSnap.data!.docs[index];
                              Map<String, dynamic> data =
                                  doc.data() as Map<String, dynamic>;
                              String url = data['url'];
                              return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (context) => VideoDetailed(
                                                data,
                                                doc.id,
                                                doc as DocumentSnapshot<
                                                    Map<String, dynamic>>?)))
                                        .then((value) => setState(() {}));
                                  },
                                  child: Image.network(
                                    'https://img.youtube.com/vi/$url/0.jpg',
                                    fit: BoxFit.cover,
                                  ));
                            });
                      }),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: floatingButtons(),
      ),
    );
  }
}
