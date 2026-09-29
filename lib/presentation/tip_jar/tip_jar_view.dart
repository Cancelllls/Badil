import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_controller.dart';

class TipJarView extends StatelessWidget {
  const TipJarView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final strings = LocaleController.instance.strings;
        final isAr = LocaleController.instance.isArabic;
        final textDir = LocaleController.instance.textDirection;

        return Directionality(
          textDirection: textDir,
          child: Scaffold(
            appBar: AppBar(
              title: Text(strings.supportHeaderTitle),
              centerTitle: true,
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              children: [
                // 1. Mission Hero Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGreen.withValues(alpha: 0.18),
                        AppTheme.primaryGreen.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text("🇪🇬", style: TextStyle(fontSize: 38)),
                      const SizedBox(height: 10),
                      Text(
                        strings.missionCardTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.missionCardBody,
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

                // 2. Open Source / F-Droid Card
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.amberGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.code_rounded, color: AppTheme.amberGold, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.openSourceTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                strings.openSourceDesc,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  isAr ? "طرق الدعم والمساهمة:" : "Ways to Support the Project:",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // 1. InstaPay
                _buildDonationTile(
                  context,
                  title: isAr ? "إنستاباي (InstaPay)" : "InstaPay (Egypt)",
                  subtitle: isAr ? "الدعم المباشر الفوري داخل مصر" : "Direct instant domestic transfer",
                  value: "cancellls@instapay",
                  icon: Icons.account_balance_wallet_rounded,
                  badge: isAr ? "الأسهل بمصر" : "Instant",
                  isDark: isDark,
                  strings: strings,
                ),

                // 2. Vodafone Cash
                _buildDonationTile(
                  context,
                  title: isAr ? "فودافون كاش (Vodafone Cash)" : "Vodafone Cash Wallet",
                  subtitle: isAr ? "تحويل مباشر للمحفظة الإلكترونية" : "Mobile wallet transfer",
                  value: "01023456789",
                  icon: Icons.phone_android_rounded,
                  badge: "Wallet",
                  isDark: isDark,
                  strings: strings,
                ),

                // 3. Crypto USDT (TRC-20)
                _buildDonationTile(
                  context,
                  title: "USDT (TRC-20)",
                  subtitle: isAr ? "للدعم الدولي السريع" : "Global cryptocurrency support",
                  value: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
                  icon: Icons.currency_bitcoin_rounded,
                  badge: "TRC-20",
                  isDark: isDark,
                  strings: strings,
                ),

                const SizedBox(height: 20),

                // 3. Brand Sponsorship Partnership Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.amberGold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign_rounded, color: AppTheme.amberGold, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? "أصحاب المصانع والعلامات الوطنية 📢" : "For Domestic Brand Partners 📢",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? "هل تملك علامة تجارية مصرية أو عربية وترغب في إبرازها كبديل معتمد أمام آلاف المتسوقين يومياً؟"
                            : "Do you own a verified domestic brand and wish to feature it as a recommended alternative to thousands of daily shoppers?",
                        style: TextStyle(
                          fontSize: 12,
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Clipboard.setData(const ClipboardData(text: "contact@cancellls.com"));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isAr ? "تم نسخ البريد: contact@cancellls.com" : "Email copied: contact@cancellls.com"),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text("contact@cancellls.com"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    required dynamic strings,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
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
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy_rounded, size: 18),
          tooltip: "Copy",
          onPressed: () {
            HapticFeedback.lightImpact();
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${LocaleController.instance.isArabic ? 'تم نسخ' : 'Copied'}: $value"),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }
}
