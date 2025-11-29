class Address {
  final int id;
  final String name;
  final String phone;
  final String address; // note: named 'address' to match UI
  final String city;
  final String state;
  final String pincode; // note: named 'pincode' to match UI
  final String country;
  final bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    this.isDefault = false,
  });

  /// Factory that tolerates multiple possible JSON keys (DB vs API)
  factory Address.fromJson(Map<String, dynamic> json) {
    // helpers to read various possible key names
    dynamic read(List<String> keys, [dynamic def = '']) {
      for (var k in keys) {
        if (json.containsKey(k) && json[k] != null) return json[k];
      }
      return def;
    }

    final idVal = read(['AddressID', 'id', 'ID', 'addressId'], 0);
    final nameVal = read(['Name', 'name', 'FullName'], '');
    final phoneVal = read(['Phone', 'phone', 'Mobile', 'mobile'], '');
    final addressVal = read(['Address', 'address', 'AddressLine', 'addressLine'], '');
    final cityVal = read(['City', 'city'], '');
    final stateVal = read(['State', 'state'], '');
    final pincodeVal = read(['Pincode', 'pincode', 'PostalCode', 'postalCode'], '');
    final countryVal = read(['Country', 'country'], '');
    final isDefaultVal = read(['IsDefault', 'isDefault', 'default'], false);

    // normalize types
    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) {
        final s = v.toLowerCase();
        return s == '1' || s == 'true' || s == 'yes';
      }
      return false;
    }

    return Address(
      id: idVal is int ? idVal : int.tryParse(idVal.toString()) ?? 0,
      name: nameVal.toString(),
      phone: phoneVal.toString(),
      address: addressVal.toString(),
      city: cityVal.toString(),
      state: stateVal.toString(),
      pincode: pincodeVal.toString(),
      country: countryVal.toString(),
      isDefault: parseBool(isDefaultVal),
    );
  }

  Map<String, dynamic> toJson() => {
        'AddressID': id,
        'Name': name,
        'Phone': phone,
        'Address': address,
        'City': city,
        'State': state,
        'Pincode': pincode,
        'Country': country,
        'IsDefault': isDefault ? 1 : 0,
      };
}
