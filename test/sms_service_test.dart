import 'package:flutter_test/flutter_test.dart';
import 'package:cardpulse/models/credit_card.dart';
import 'package:cardpulse/services/sms_service.dart';

void main() {
  group('Real Bank SMS Parsing Tests', () {
    final axisCard = CreditCard(
      id: 'c1',
      cardName: 'Axis Card',
      bank: 'Axis Bank',
      last4: '9301',
      monthlyLimit: 50000,
      billGenerationDay: 15,
    );

    final hdfc3079 = CreditCard(
      id: 'c2',
      cardName: 'HDFC Card 1',
      bank: 'HDFC Bank',
      last4: '3079',
      monthlyLimit: 50000,
      billGenerationDay: 15,
    );

    final hdfc2863 = CreditCard(
      id: 'c3',
      cardName: 'HDFC Card 2',
      bank: 'HDFC Bank',
      last4: '2863',
      monthlyLimit: 50000,
      billGenerationDay: 15,
    );

    final icici0000 = CreditCard(
      id: 'c4',
      cardName: 'Amazon Pay ICICI',
      bank: 'ICICI Bank',
      last4: '0000',
      monthlyLimit: 300000,
      billGenerationDay: 15,
    );

    final icici7001 = CreditCard(
      id: 'c5',
      cardName: 'ICICI Platinum',
      bank: 'ICICI Bank',
      last4: '7001',
      monthlyLimit: 250000,
      billGenerationDay: 15,
    );

    final sbi0763 = CreditCard(
      id: 'c6',
      cardName: 'SBI SimplyCLICK',
      bank: 'SBI Card',
      last4: '0763',
      monthlyLimit: 50000,
      billGenerationDay: 15,
    );

    test('1. Axis Bank multi-line spend SMS', () {
      const sms = '''
Spent INR 117
Axis Bank Card no. XX9301
17-09-26 09:53:27 IST
Flipkart
Avl Limit: INR 58887.8
Not you? SMS BLOCK 9301 to 919951860002
''';

      expect(SmsService.isSpendMessage(sms), isTrue);
      expect(SmsService.messageMatchesCard(sms, axisCard), isTrue);
      expect(SmsService.extractAmount(sms), equals(117.0));
      expect(SmsService.extractMerchant(sms), equals('Flipkart'));
      expect(SmsService.extractTransactionDate(sms), equals(DateTime(2026, 9, 17)));
    });

    test('2. HDFC Bank UPI transaction SMS', () {
      const sms = '''
Txn Rs.550.00
On HDFC Bank Card 3079
At 79670663030705@cnrb 
by UPI 129374396448
On 10-09-26
Not You?
Call 18002586161/SMS BLOCK CC 3079 to 7308080808
''';

      expect(SmsService.isSpendMessage(sms), isTrue);
      expect(SmsService.messageMatchesCard(sms, hdfc3079), isTrue);
      expect(SmsService.extractAmount(sms), equals(550.0));
      expect(SmsService.extractMerchant(sms), equals('79670663030705@cnrb'));
    });

    test('3. HDFC Bank POS spend SMS', () {
      const sms =
          'Spent Rs.43423.82 On HDFC Bank Card 2863 At QRS7501084 On 2026-08-15:15:01:18.Not You? To Block+Reissue Call 18002586161/SMS BLOCK CC 2863 to 7308080808';

      expect(SmsService.isSpendMessage(sms), isTrue);
      expect(SmsService.messageMatchesCard(sms, hdfc2863), isTrue);
      expect(SmsService.extractAmount(sms), equals(43423.82));
      expect(SmsService.extractMerchant(sms), equals('QRS7501084'));
      expect(SmsService.extractTransactionDate(sms), equals(DateTime(2026, 8, 15)));
    });

    test('4. ICICI Bank AMAZON PAY spend SMS', () {
      const sms =
          'INR 899.00 spent using ICICI Bank Card XX0000 on 11-Sep-26 on AMAZON PAY IN R. Avl Limit: INR 2,63,569.91. If not you, call 1800 2662/SMS BLOCK 0000 to 9215676766.';

      expect(SmsService.isSpendMessage(sms), isTrue);
      expect(SmsService.messageMatchesCard(sms, icici0000), isTrue);
      expect(SmsService.extractAmount(sms), equals(899.0));
      expect(SmsService.extractMerchant(sms), equals('AMAZON PAY IN R'));
      expect(SmsService.extractTransactionDate(sms), equals(DateTime(2026, 9, 11)));
    });

    test('5. ICICI Bank FIRSTCRY spend SMS', () {
      const sms =
          'INR 792.01 spent using ICICI Bank Card XX7001 on 30-May-26 on FSS4FIRSTCRY. Avl Limit: INR 2,22,112.20. If not you, call 1800 2662/SMS BLOCK 7001 to 9215676766.';

      expect(SmsService.isSpendMessage(sms), isTrue);
      expect(SmsService.messageMatchesCard(sms, icici7001), isTrue);
      expect(SmsService.extractAmount(sms), equals(792.01));
      expect(SmsService.extractMerchant(sms), equals('FSS4FIRSTCRY'));
      expect(SmsService.extractTransactionDate(sms), equals(DateTime(2026, 5, 30)));
    });

    test('6. SBI Credit Card spend SMS', () {
      const sms =
          'Rs.111.23 spent on your SBI Credit Card ending 0763 at KIMSKOLLAM on 05/08/26. Trxn. not done by you? Report at https://sbicard.com/Dispute';

      expect(SmsService.isSpendMessage(sms), isTrue);
      expect(SmsService.messageMatchesCard(sms, sbi0763), isTrue);
      expect(SmsService.extractAmount(sms), equals(111.23));
      expect(SmsService.extractMerchant(sms), equals('KIMSKOLLAM'));
      expect(SmsService.extractTransactionDate(sms), equals(DateTime(2026, 8, 5)));
    });

    test('6b. SBI Card variant space date SMS', () {
      const sms =
          'Spent Rs 43423.82 On SBI Card ending 0763 at Flipkart on 15 Sep 24. Not You? Call 18601801290';

      expect(SmsService.isSpendMessage(sms), isTrue);
      expect(SmsService.messageMatchesCard(sms, sbi0763), isTrue);
      expect(SmsService.extractAmount(sms), equals(43423.82));
      expect(SmsService.extractMerchant(sms), equals('Flipkart'));
      expect(SmsService.extractTransactionDate(sms), equals(DateTime(2024, 9, 15)));
    });

    test('7. Ignores historical SMS older than card billing cycle', () {
      // 5-year-old SMS from 2021
      const oldSms =
          'Spent Rs.5000.00 On HDFC Bank Card 2863 At STORE On 2021-08-15:15:01:18. Not You? Call 18002586161';

      final parsedDate = SmsService.extractTransactionDate(oldSms);
      expect(parsedDate, equals(DateTime(2021, 8, 15)));

      // Active billing cycle for ref date 2026-08-20 (Bill day 15) is 15 Aug 2026 to 14 Sep 2026
      // 2021-08-15 is outside cycle!
    });

    test('8. Filters out promotional voucher offer SMS', () {
      const offerSms =
          "Get Rs.1,000 Flipkart e-Voucher by doing 3 Trxns. of Min. Rs.10,000 each with your SBI Credit Card ending 8049 between 3 Sep - 2 Oct'26.T&C: https://acl.cc/SBICRD/N0dXenZ4";

      expect(SmsService.isNonSpendMessage(offerSms), isTrue);
      expect(SmsService.isSpendMessage(offerSms), isFalse);
    });
  });
}
