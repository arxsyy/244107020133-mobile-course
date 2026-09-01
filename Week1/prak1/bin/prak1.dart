import 'package:prak1/prak1.dart' as prak1;

void main(List<String> arguments) {
  //print('Hello world: ${prak1.calculate()}!');
  var nama = 'Marsya';
  var umur = 20;
  var tinggi = "160";
  var alamat = "Jl. Raya No. 1";
  var iseng = umur + int.parse(tinggi);
  print("Nama: $nama");
  print("Umur: $umur");
  print("Tinggi: $tinggi");
  print("Alamat: $alamat");
  print("Hasil Iseng: $iseng");
}
