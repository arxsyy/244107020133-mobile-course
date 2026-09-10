import 'package:prak2/prak2.dart' as prak2;

late int a;
void main(List<String> arguments) {
  int a = 10;
  double b = 3.14;
  String c = "Hello, Dart!";
  bool d = true;
  print(a);
  print(b);
  print(c);
  print(d);
  String e = '12';
  int f = a +int.parse(e);
  print(f);
  List<String> names = ['Alice', 'Bob', 'Charlie'];
  List<int> numbers = [1, 2, 3, 4, 5];
  print(names);
  print('nama yang ke 1 adalah : ${names[0]}');
  print(numbers);
  print('jumlah elemen dalam list numbers adalah : ${numbers.length}');
  Map<String, int> umur = {
    'Alice': 25,
    'Bob': 30,
    'Charlie': 35,
  };
  print(umur);
  print ('umur Alice adalah : ${umur['Alice']}');
  dynamic g = 'Hello';
  print(g);
  g = 42;
  print(g);
  g = true;
  print(g);
  g = {'name': 'Alice', 'age': 25};
  print(g);
  var h = 'Dart';
  print(h);
}
