// ─── Site queries (TeamMembers + SitePages) ───────────────────────────────────

const String kTeamMembers = r'''
  query TeamMembers {
    teamMembers {
      id
      name
      role
      bio
      photoUrl
      twitter
      linkedin
      order
    }
  }
''';

const String kSitePage = r'''
  query SitePage($slug: String!) {
    sitePage(slug: $slug) {
      id
      slug
      title
      content
      version
      lastUpdated
    }
  }
''';
