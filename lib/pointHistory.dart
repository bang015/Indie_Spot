import 'package:flutter/material.dart';
import 'package:indie_spot/baseBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indie_spot/userModel.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PointHistory extends StatefulWidget {
  const PointHistory({super.key});

  @override
  State<PointHistory> createState() => _PointHistoryState();
}

class _PointHistoryState extends State<PointHistory> {
  String? _userId;
  int? _pointBalance = 0;
  FirebaseFirestore fs = FirebaseFirestore.instance;
  int _totalRecharge = 0;
  List<Widget> _pointsDetailsList = [];
  int _num = 30;

  Future<void> pointBalanceSearch() async {
    QuerySnapshot pointSnapshot = await fs.collection('userList').doc(_userId)
        .collection('point').limit(1)
        .get();

    if (pointSnapshot.docs.isNotEmpty) {
      QueryDocumentSnapshot firstPointDocument = pointSnapshot.docs.first;
      Map<String, dynamic> data = firstPointDocument.data() as Map<
          String,
          dynamic>;
      setState(() {
        _pointBalance = data!['pointBalance'];
      });
    } else {}
  }

  @override
  void initState() {
    super.initState();
    final userModel = Provider.of<UserModel>(context, listen: false);
    if (!userModel.isLogin) {
      Navigator.pop(context);
    } else {
      _userId = userModel.userId;
      pointBalanceSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              // 아이콘 클릭 시 수행할 작업 추가
            },
            icon: Icon(Icons.person),
            color: Colors.black54,
          ),
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: Icon(Icons.menu),
                color: Colors.black54,
              );
            },
          ),
        ],
        elevation: 1,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black54,
          ),
          onPressed: () {
            // 뒤로가기 버튼을 눌렀을 때 수행할 작업
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          '포인트 내역',
          style: TextStyle(color: Colors.black,),
        ),
      ),
      body: ListView(
        children: [
          // 포인트 내역 섹션
          Container(
            color: Colors.white,
            child: Container(
              child: FutureBuilder<List<Widget>>(
                future: _pointsDetails(_num),
                builder: (context, snapshot) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _container() ,
                      Container(
                        padding: EdgeInsets.only(left: 20, top: 30),
                        child: Text(_num == 30 ? '최근 1개월' : '최근 3개월', style: TextStyle(fontSize: 17,)),
                      ),
                      Container(color: Colors.black12, height: 15,),
                      Container(
                        padding: EdgeInsets.only(top: 10),
                        margin: EdgeInsets.all(20),
                        child: Column(
                          children: snapshot.data ?? [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('해당 기간에 충전한 내역이 없습니다.'),
                              ],
                            )
                          ],
                        ),
                      )
                    ]
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MyBottomBar(),
    );
  }

  Container _container() {
    return Container(
      color: Color(0xFF392F31),
      height: 200,
      child: Container(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Expanded(child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/point2.png', height: 30, width: 30,),
                    Text(' 총 충전 포인트', style: TextStyle(color: Colors.white, fontSize: 15),),
                  ],
                ),
                Row(
                  children: [
                    Text('$_totalRecharge', style: TextStyle(color: Colors.white, fontSize: 25),),
                    Text('P', style: TextStyle(color: Colors.white, fontSize: 17),)
                  ],
                )
              ],
            )),
            Expanded(child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 5),
                      child: Text('기간별 조회', style: TextStyle(color: Colors.white, fontSize: 15),)
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 15),
                          child: ElevatedButton(
                            onPressed: (){
                              setState(() {
                                _num = 30;
                              });
                            },
                            style: ButtonStyle(
                              shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.zero), side: _num == 30 ? BorderSide(color: Colors.white, width: 1) : BorderSide())),
                              backgroundColor: MaterialStatePropertyAll(Color(0xFF634F52))
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 13, bottom: 13),
                              child: Text('최근 1개월'),
                            )
                          ),
                        ),
                        ElevatedButton(
                            onPressed: (){
                              setState(() {
                                _num = 90;
                              });
                            },
                            style: ButtonStyle(
                                shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.zero), side: _num == 90 ? BorderSide(color: Colors.white, width: 1) : BorderSide())),
                                backgroundColor: MaterialStatePropertyAll(Color(0xFF634F52))
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 13, bottom: 13),
                              child: Text('최근 3개월'),
                            )
                        ),
                      ],
                    ),
                  ],
                )
              ],
            )),
          ],
        ),
      ),
    );
  }

  Future<List<Widget>> _pointsDetails(int day) async {
    var userDocRef = fs.collection('userList').doc(_userId);
    var querySnapshot = await userDocRef.collection('point').limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      var firstPointDocument = querySnapshot.docs.first;
      var list = <Widget>[];
      // 현재 날짜를 가져옵니다.
      final DateTime now = DateTime.now();
      // 1개월 전의 날짜를 계산합니다.
      final DateTime oneMonthAgo = now.subtract(Duration(days: day));

      var pointsDetailsRef = firstPointDocument.reference.collection('points_details');
      var pointsDetailsQuerySnapshot = await pointsDetailsRef.orderBy('date', descending: true)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(oneMonthAgo))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      if(pointsDetailsQuerySnapshot.docs.isEmpty){
        list.add( Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('해당 기간에 충전한 내역이 없습니다.'),
          ],
        ));
        return list;
      }
      _totalRecharge = 0;
      pointsDetailsQuerySnapshot.docs.forEach((pointDetailDocument) {
        var pointDetailData = pointDetailDocument.data();
        var type = pointDetailData['type'];
        int amount = pointDetailData['amount'].toInt();
        var date = pointDetailData['date'];

        if(type == '충전') {
          _totalRecharge += amount;
        }

        var listItem = Container(
          margin: EdgeInsets.only(bottom: 20),
          child: ListTile(
            title: Text(type, style: TextStyle(color: Colors.black54, fontFamily: 'Noto_Serif_KR',),),
            subtitle: Text(NumberFormat.decimalPattern().format(amount), style: TextStyle(fontSize: 20, color: Colors.black),),
            trailing: Text(DateFormat('yyyy-MM-dd').format(date.toDate())),
            // 다른 필드 및 스타일을 추가할 수 있습니다.
          )
        );
        list.add(listItem);
      });
      return list;
    } else {
      var list = <Widget>[];
      return list;
    }
  }
}
