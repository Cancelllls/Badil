class AppStrings {
  final bool isAr;

  const AppStrings(this.isAr);

  // App & Common
  String get appName => isAr ? 'بَديل' : 'Badil';
  String get appTagline => isAr ? 'فحص المقاطعة واكتشاف البدائل' : 'Boycott Scanner & Alternatives';
  String get offlineBadge => isAr ? '١٠٠٪ بدون إنترنت' : '100% Offline';
  String get cancel => isAr ? 'إلغاء' : 'Cancel';
  String get close => isAr ? 'إغلاق' : 'Close';
  String get confirm => isAr ? 'تأكيد' : 'Confirm';
  String get search => isAr ? 'بحث' : 'Search';
  String get share => isAr ? 'مشاركة' : 'Share';

  // Navigation
  String get navScanner => isAr ? 'فحص الباركود' : 'Scanner';
  String get navSearch => isAr ? 'البحث' : 'Search';
  String get navCategories => isAr ? 'الأقسام' : 'Categories';
  String get navSupport => isAr ? 'الدعم والرسالة' : 'Support';

  // Scanner View
  String get scannerInstruction => isAr ? 'وجّه الكاميرا نحو باركود المنتج' : 'Align camera over product barcode';
  String get scannerQuickHint => isAr ? 'نتائج فورية في أقل من ١٠ ملي ثانية' : 'Instant offline results in < 10ms';
  String get manualBarcodeBtn => isAr ? 'إدخال يدوي' : 'Enter Manually';
  String get flashlight => isAr ? 'الكشاف' : 'Torch';
  String get manualBarcodeTitle => isAr ? 'إدخال الباركود يدوياً' : 'Enter Barcode Manually';
  String get manualBarcodeHint => isAr ? 'مثال: 6221010001011' : 'e.g. 6221010001011';
  String get barcodeNotFoundTitle => isAr ? 'منتج غير مسجل حالياً' : 'Product Not in Database';
  String get barcodeNotFoundDesc => isAr
      ? 'هذا الباركود غير مسجل في قاعدة البيانات المدمجة. يمكنك اقتراح إضافته لدعم مجتمع بديل!'
      : 'This barcode is not yet listed in the offline database. You can contribute it to help the community!';
  String get suggestProductBtn => isAr ? 'إضافة المنتج وقاعدته' : 'Suggest This Product';

  // Product Result Sheet
  String get statusBoycott => isAr ? 'منتج مقاطعة' : 'Boycott Product';
  String get statusSafeLocal => isAr ? 'منتج محلي / بديل آمن' : '100% Safe Local Alternative';
  String get statusUnderReview => isAr ? 'قيد المراجعة' : 'Under Review';
  String get boycottReasonTitle => isAr ? 'سبب المقاطعة والموقف' : 'Reason for Boycott';
  String get companyOwner => isAr ? 'الشركة المالكة' : 'Parent Company';
  String get countryOfOrigin => isAr ? 'بلد المنشأ' : 'Country of Origin';
  String get barcodeLabel => isAr ? 'الباركود' : 'Barcode';
  String get verifiedAlternativesTitle => isAr ? 'البدائل الوطنية المتاحة' : 'Verified Local Alternatives';
  String get verifiedAlternativesSubtitle => isAr ? 'منتجات مصرية وعربية موثوقة' : 'Verified domestic & Arab alternatives';
  String get noAlternativesFound => isAr ? 'جاري توفير بدائل موثوقة لهذا الصنف' : 'Working on adding verified alternatives for this item';
  String get suggestAlternativeBtn => isAr ? 'اقترح بديلاً آخر' : 'Suggest an Alternative';
  String get madeInEgypt => isAr ? 'صنع في مصر 🇪🇬' : 'Made in Egypt 🇪🇬';
  String get boycottWarningShort => isAr ? 'يُنصح بتجنب شرائه ودعم البدائل' : 'Avoid purchase — support ethical alternatives';
  String get safeLocalShort => isAr ? 'خيار وطني شريف يدعم الصناعة' : 'Trusted domestic brand supporting local economy';

  // Search View
  String get searchPlaceholder => isAr ? 'ابحث باسم المنتج أو العلامة أو الشركة...' : 'Search product, brand, or company...';
  String get filterAll => isAr ? 'الكل' : 'All';
  String get filterBoycott => isAr ? 'مقاطعة' : 'Boycott';
  String get filterSafeLocal => isAr ? 'بدائل محلية' : 'Safe Local';
  String searchResultsCount(int count) => isAr ? '$count منتج' : '$count products';
  String get noResultsTitle => isAr ? 'لم يتم العثور على نتائج' : 'No products found';
  String get noResultsDesc => isAr
      ? 'جرب البحث باسم آخر، أو استخدم ماسح الباركود لفحص المنتج مباشرة.'
      : 'Try searching with a different keyword, or scan the barcode directly.';
  String get popularBrandsTitle => isAr ? 'العلامات التجارية الأكثر بحثاً' : 'Popular Searches';

  // Categories View
  String get categoriesHeaderTitle => isAr ? 'أقسام المنتجات' : 'Browse Categories';
  String get categoriesHeaderSubtitle => isAr ? 'اكتشف البدائل الوطنية حسب تخصص المنتج' : 'Discover local alternatives by industry';
  String itemsCount(int count) => isAr ? '$count صنف' : '$count items';

  // Tip Jar & Support View
  String get supportHeaderTitle => isAr ? 'مشروع بَديل الحر' : 'Badil Open Project';
  String get missionCardTitle => isAr ? 'لماذا صممنا بَديل؟' : 'Why We Built Badil';
  String get missionCardBody => isAr
      ? 'بَديل هو تطبيق مجاني ومفتوح المصدر بنسبة 100%، صُمم ليعمل بالكامل بدون اتصال بالإنترنت، خالٍ من أي إعلانات تجارية أو تتبع، لحماية خصوصيتك ودعم الاقتصاد الوطني والاستهلاك الأخلاقي.'
      : 'Badil is a 100% free, offline-first, open-source application with zero tracking and zero telemetry. Built to empower ethical consumer choices and support national industries.';
  String get openSourceTitle => isAr ? 'كود مفتوح المصدر (GPL-3.0)' : 'Open Source (GPL-3.0)';
  String get openSourceDesc => isAr ? 'مستضاف بالكامل على GitHub مع دعم لمعايير F-Droid الحرة' : 'Fully hosted on GitHub, conforming to free software F-Droid standards';
  String get visitGithubBtn => isAr ? 'زيارة مستودع GitHub' : 'View on GitHub';
  String get sponsorCardTitle => isAr ? 'العلامة الوطنية الراعية' : 'Featured National Partner';
  String get promoCodeLabel => isAr ? 'كود الخصم الحصري:' : 'Exclusive Promo Code:';
  String get copyCode => isAr ? 'نسخ الكود' : 'Copy Code';
  String get codeCopied => isAr ? 'تم نسخ كود الخصم!' : 'Promo code copied!';

  // Suggest Form
  String get suggestFormTitle => isAr ? 'اقتراح منتج أو بديل' : 'Suggest Product or Alternative';
  String get productNameField => isAr ? 'اسم المنتج' : 'Product Name';
  String get brandNameField => isAr ? 'العلامة التجارية' : 'Brand Name';
  String get statusField => isAr ? 'تصنيف المنتج' : 'Product Status';
  String get altNameField => isAr ? 'البديل الوطني المقترح' : 'Suggested Alternative';
  String get notesField => isAr ? 'ملاحظات إضافية' : 'Additional Notes';
  String get submitBtn => isAr ? 'إرسال الاقتراح' : 'Submit Suggestion';
  String get fillRequiredFields => isAr ? 'يرجى إدخال اسم المنتج' : 'Please enter product name';
  String get suggestionSubmitted => isAr
      ? 'شكراً لمساهمتك! تم حفظ الاقتراح محلياً وسيتم مراجعته ومزامنته.'
      : 'Thank you! Saved locally and queued for verification.';
}
