const String kUniversities = r'''
query Universities {
  universities { id name location universityType shortName }
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
query PrimarySchools {
  primarySchools { id name district region }
}
''';

const String kSecondarySchools = r'''
query SecondarySchools {
  secondarySchools { id name district region }
}
''';
