import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class TipJarView extends StatelessWidget {
  const TipJarView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("دعم استمرار التطبيق ☕"),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            // Mission Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.18),
                    AppTheme.primaryGreen.withOpacity(0.04),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  const Text("🇪🇬", style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 10),
                  const Text(
                    "تطبيق بَديل مجاني ومفتوح المصدر 100%",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "صُنع هذا التطبيق بدون أي إعلانات مزعجة وبأعلى معايير الخصوصية لتمكين كل مواطن عربي من دعم المنتجات الوطنية والبدائل الشريفة.\nمساهمتك الرمزية تساعد في تغطية تكاليف الخوادم وتحديث الباركود والبدائل يومياً.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "طرق الدعم والمساهمة:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // 1. InstaPay
            _buildDonationTile(
              context,
              title: "إنستاباي (InstaPay)",
              subtitle: "الدعم المباشر الفوري داخل مصر",
              value: "cancellls@instapay",
              icon: Icons.account_balance_wallet_rounded,
              badge: "الأسهل بمصر",
              isDark: isDark,
            ),

            // 2. Vodafone Cash
            _buildDonationTile(
              context,
              title: "فودافون كاش (Vodafone Cash)",
              subtitle: "تحويل مباشر للمحفظة الإلكترونية",
              value: "01023456789",
              icon: Icons.phone_android_rounded,
              badge: "فودافون كاش",
              isDark: isDark,
            ),

            // 3. Crypto USDT (TRC-20)
            _buildDonationTile(
              context,
              title: "العملات الرقمية (USDT TRC-20)",
              subtitle: "للدعم الدولي السريع",
              value: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
              icon: Icons.currency_bitcoin_rounded,
              badge: "USDT",
              isDark: isDark,
            ),

            // 4. Crypto TON
            _buildDonationTile(
              context,
              title: "شبكة تيليجرام (TON)",
              subtitle: "تحويل سريع عبر محفظة تلجرام",
              value: "EQCD39VS5jcptHL8vMjEXrzGaRcCVYto7HUn4bpAOg8xqB2N",
              icon: Icons.send_rounded,
              badge: "TON",
              isDark: isDark,
            ),

            const SizedBox(height: 20),

            // For Brands / Sponsors Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.amberGold.withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.campaign_rounded, color: AppTheme.amberGold, size: 24),
                      SizedBox(width: 8),
                      Text(
                        "أصحاب المصانع والعلامات المصرية 📢",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "هل تملك علامة تجارية مصرية أو منتجاً بديلاً وترغب في إبرازه في بانر 'بديل الأسبوع المعتمد' أمام آلاف المستخدمين يومياً؟",
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.amberGold,
                        side: const BorderSide(color: AppTheme.amberGold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: "contact@cancellls.com"));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("تم نسخ البريد الإلكتروني للتواصل: contact@cancellls.com")),
                        );
                      },
                      icon: const Icon(Icons.email_outlined, size: 18),
                      label: const Text("تواصل لرعاية البدائل: contact@cancellls.com"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required String badge,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy_rounded, size: 20),
          tooltip: "نسخ",
          onPressed: () {
            HapticFeedback.lightImpact();
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("تم نسخ: $value"),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
