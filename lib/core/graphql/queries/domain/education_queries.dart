const String kUniversities = r'''
query Universities($search: String, $universityType: String) {
  universities(search: $search, universityType: $universityType) {
    id name location universityType shortName description
  }
}
''';

const String kPrograms = r'''
query Programs($universityId: ID!) {
  programs(universityId: $universityId) {
    id name faculty durationYears
  }
}
''';

const String kPrimarySchools = r'''
query PrimarySchools($search: String) {
  primarySchools(search: $search) { id name district region }
}
''';

const String kSecondarySchools = r'''
query SecondarySchools($search: String) {
  secondarySchools(search: $search) { id name district region }
}
''';
