
import 'package:flutter/material.dart';
import 'package:indie_spot/baseBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'concertDetails.dart';
class BuskingList extends StatefulWidget{
  const BuskingList({super.key});

  @override
  State<BuskingList> createState() => _BuskingListState();
}

class _BuskingListState extends State<BuskingList> with SingleTickerProviderStateMixin{
  final TextEditingController _search = TextEditingController();
  FocusNode _focusNode = FocusNode();
  late TextField sharedTextField;
  String selectRegions = "";
  String selectGenre = "";


  Widget _buskingList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("busking").snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snap) {
        if (!snap.hasData) {
          return Container();
        }
        return Expanded(
          child: ListView.builder(
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snap.data!.docs[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String spotId = data['spotId'];
              String artistId = data['artistId'];

              Future<QuerySnapshot> getGenreData() async {
                if (selectGenre == "") {
                  return FirebaseFirestore.instance.collection("artist")
                      .where(FieldPath.documentId, isEqualTo: artistId).get();
                } else {
                  return FirebaseFirestore.instance.collection("artist")
                      .where(FieldPath.documentId, isEqualTo: artistId)
                      .where("genre", isEqualTo: selectGenre)
                      .get();
                }
              }

              return FutureBuilder(
                  future: getGenreData(),
                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> artistSnapshot) {
                    if (!artistSnapshot.hasData) {
                      return Container();
                    }
                    if(artistSnapshot.connectionState == ConnectionState.waiting){
                      return Container();
                    }
                    if(artistSnapshot.hasError){
                      return ListTile(
                        title: Text('Error'),
                        subtitle: Text('Error'),
                      );
                    }
                    if(artistSnapshot.hasData && artistSnapshot.data!.docs.isNotEmpty) {
                      QueryDocumentSnapshot artistDoc = artistSnapshot.data!.docs.first;
                      Map<String, dynamic> artistData = artistDoc.data() as Map<String,dynamic>;
                      if(artistData['artistName'].contains(_search.text)){

                      Future<QuerySnapshot> getArtistData() async {
                        if (selectRegions == "") {
                          return FirebaseFirestore.instance.collection('busking_spot')
                              .where(FieldPath.documentId, isEqualTo: spotId)
                              .get();
                        } else {
                          return FirebaseFirestore.instance.collection('busking_spot')
                              .where(FieldPath.documentId, isEqualTo: spotId)
                              .where("regions", isEqualTo: selectRegions)
                              .get();
                        }
                      }
                      return FutureBuilder(
                        future: getArtistData(),
                        builder: (BuildContext context,
                            AsyncSnapshot<QuerySnapshot> spotSnapshot) {
                          if (spotSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(color:Colors.white,);
                          }
                          if (spotSnapshot.hasError) {
                            return ListTile(
                              title: Text('Error'),
                              subtitle: Text('Error'),
                            );
                          }
                          if (spotSnapshot.hasData&& spotSnapshot.data!.docs.isNotEmpty) {
                            QueryDocumentSnapshot spotDocument = spotSnapshot.data!.docs.first;
                            Map<String, dynamic> spotData = spotDocument.data() as Map<String, dynamic>;

                            return FutureBuilder(
                              future: FirebaseFirestore.instance.collection('busking').doc(doc.id).collection('image').get(),
                              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> imageSnapshot) {
                                if (imageSnapshot.connectionState == ConnectionState.waiting) {
                                  return Container();
                                }
                                if (imageSnapshot.hasError) {
                                  return ListTile(
                                    title: Text('Error'),
                                    subtitle: Text('Error'),
                                  );
                                }
                                if (imageSnapshot.hasData) {
                                  var firstImage = imageSnapshot.data!.docs.first ;
                                  return Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ListTile(
                                      title: Text(
                                          '${artistData['artistName']}'),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('일시 : ${data['buskingStart']}'),
                                          Text('장소: ${spotData['spotName']}')
                                        ],
                                      ),
                                      /*leading: Image.asset('assets/기본.jpg'),*/
                                      leading: Image.network(firstImage['path'],width: 100,),
                                      onTap: () {
                                        Navigator.push(context,
                                            MaterialPageRoute(
                                              builder: (context) =>ConcertDetails(document: doc),));
                                      },
                                    ),
                                  );
                                } else {
                                  return ListTile(
                                    title: Text('${data['artistId']}'),
                                    subtitle: Column(
                                      children: [
                                        Text('일시 : ${data['buskingStart']}'),
                                        Text('장소: ${spotData['spotName']}')
                                      ],
                                    ),
                                  );
                                }
                              },
                            );
                          } else {
                            return Container();
                          }
                        },
                      );
                    }
                    }
                    return Container();
                  },
              );
            },
          ),
        );
      },
    );
  }


  final List<String> _regions = ['서울', '부산', '인천', '강원', '경기', '경남', '경북', '광주', '대구', '대전', '울산', '전남', '전북', '제주', '충남', '충북'];

  Widget regiosWidget(){
    return Column(
        children: [
          Container(
            color: Colors.white,
            height: 50.0, // 높이 조절
            child: ListView(
              scrollDirection: Axis.horizontal, // 수평 스크롤
              children: [
                for (String region in _regions)
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[ TextButton(
                        onPressed: () {
                          setState(() {
                            selectRegions = region;
                          });
                        },
                        child: Text(region, style: TextStyle(
                            color: selectRegions == region? Colors.lightBlue : Colors.black),
                        ),
                      ),]
                  ),
              ],
            ),
          ),
          sharedTextField,
          _buskingList()
        ]
    );
  }
  final List<String> _genre = ["음악","댄스","퍼포먼스","마술"];
  Widget genreWidget(){
    return Column(
        children: [
          Container(
            color: Colors.white,
            height: 50.0, // 높이 조절
            child: ListView(
              scrollDirection: Axis.horizontal, // 수평 스크롤
              children: [
                for (String genre in _genre)
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children:[
                        Container(
                        margin: EdgeInsets.symmetric(horizontal: 17.0),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              selectGenre = genre;
                            });
                          },
                          child: Text(genre, style: TextStyle(
                              color: selectGenre == genre? Colors.lightBlue : Colors.black),
                          ),
                        ),
                      ),]
                  ),
              ],
            ),
          ),
          sharedTextField,
          _buskingList()
        ]
    );
  }

  @override
  Widget build(BuildContext context) {
    sharedTextField = TextField(
      controller: _search,
      focusNode: _focusNode,
      textInputAction: TextInputAction.go,
      onSubmitted: (value){
        setState(() {

        });
      },
      decoration: InputDecoration(

        hintText: "팀명으로 검색하기",
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          onPressed: () {
            _focusNode.unfocus();
            _search.clear();
          },
          icon: Icon(Icons.cancel_outlined),
        ),
        prefixIcon: Icon(Icons.search),
      ),
    );

    return DefaultTabController(
      length: 3,
      animationDuration: Duration.zero,
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
              builder: (context) {
                return IconButton(
                    color: Colors.black54,
                    onPressed: (){
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.arrow_back)
                );
              }
          ),
          title: Center(child: Text("공연 일정", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),)),
          actions: [
            Builder(
                builder: (context) {
                  return IconButton(
                      color: Colors.black54,
                      onPressed: (){
                        Scaffold.of(context).openDrawer();
                      },
                      icon: Icon(Icons.menu)

                  );
                }
            )
          ],
          backgroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50),
            child: TabBar(
              onTap: (int index) {
                if (index == 0) {
                  setState(() {
                    _search.clear();
                    selectRegions = "";
                    selectGenre = "";
                    _focusNode.unfocus();
                  });
                } else if (index == 1) {
                  setState(() {
                    _search.clear();
                    selectRegions = "서울";
                    selectGenre = "";
                    _focusNode.unfocus();
                  });
                } else if (index == 2) {
                  setState(() {
                    _search.clear();
                    selectRegions = "";
                    selectGenre = "음악";
                    _focusNode.unfocus();
                  });
                }
              },
              tabs: [
                Tab(text: '전체'),
                Tab(text: '지역'),
                Tab(text: '장르'),
              ],
              unselectedLabelColor: Colors.black, // 선택되지 않은 탭의 텍스트 색상
              labelColor: Colors.blue,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold, // 선택된 탭의 텍스트 굵기 설정
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.normal, // 선택되지 않은 탭의 텍스트 굵기 설정
              ),
            ),
          ),
          elevation: 1,
        ),
        drawer: MyDrawer(),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            Column(
              children: [
                sharedTextField,
                _buskingList()
              ],
            ),
            regiosWidget(),
            genreWidget(),
          ],
        ),
      ),
    );
  }
}