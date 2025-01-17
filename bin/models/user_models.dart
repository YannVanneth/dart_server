// ignore_for_file: public_member_api_docs, sort_constructors_first
class UserModel {
  late int id;
  late String firstName;
  late String lastName;
  late String gender;
  late String email;

  // UserModel({
  //   required this.id,
  //   required this.firstName,
  //   required this.lastName,
  //   required this.gender,
  //   required this.email,
  // });

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int;
    firstName = json['firstName'] as String;
    lastName = json['lastName'] as String;
    gender = json['gender'] as String;
    email = json['email'] as String;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'email': email,
    };
  }
}
