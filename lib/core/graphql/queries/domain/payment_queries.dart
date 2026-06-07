const String kCreditPackages = r'''
query CreditPackages {
  creditPackages { code name amount credits label purchaseType badge }
  aiActionCatalog { code label cost description }
  me { profile { aiCredits } }
}
''';

const String kCreditLedger = r'''
query CreditLedger($limit: Int) {
  creditLedger(limit: $limit) { id entryType actionCode delta description createdAt }
}
''';

const String kPaymentHistory = r'''
query PaymentHistory {
  paymentHistory { id amount packageName status createdAt }
}
''';

const String kClaimDailyCredits = r'''
mutation ClaimDailyCredits {
  claimDailyCredits {
    awarded
    creditsGiven
    newBalance
  }
}
''';

const String kRegisterFcmToken = r'''
mutation RegisterFcmToken($token: String!) {
  registerFcmToken(token: $token) {
    success
  }
}
''';

const String kInitializePayment = r'''
mutation InitializePayment($packageCode: String!, $purchaseType: String!) {
  initializePayment(packageCode: $packageCode, purchaseType: $purchaseType) {
    success checkoutUrl transactionId errors
  }
}
''';
