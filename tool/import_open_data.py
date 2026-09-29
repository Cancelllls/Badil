#!/usr/bin/env python3
"""
Open Data Ingestion & Database Compiler for Badil (بَديل)
Pulls the TechForPalestine golden-source dataset and merges it with curated
Egyptian & Arab alternatives, GS1 barcode country prefixes, and bilingual metadata (AR/EN).
Compiles into `assets/database/badil_seed.db` with SQLite FTS5 enabled.
"""

import os
import sys
import json
import time
import sqlite3
import urllib.request
import re

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_DIR = os.path.join(PROJECT_ROOT, "assets", "data")
DB_PATH = os.path.join(PROJECT_ROOT, "assets", "database", "badil_seed.db")
TFP_DATASET_URL = "https://raw.githubusercontent.com/TechForPalestine/boycott-israeli-consumer-goods-dataset/main/output/json/data.json"
LOCAL_CACHE_JSON = os.path.join(DATA_DIR, "tech_for_palestine.json")

# Category mapping from TechForPalestine to Badil categories
CATEGORY_MAP = {
    'drinks': 'beverages',
    'coffee': 'beverages',
    'food': 'snacks',
    'dates': 'snacks',
    'cosmetics': 'personal_care',
    'household': 'detergents',
    'dairy': 'dairy',
    'supermarket': 'retail',
    'restaurants': 'restaurants',
    'clothing': 'fashion',
    'fashion': 'fashion',
    'technology': 'electronics',
    'hardware': 'electronics',
    'semiconductors': 'electronics',
}

# Arabic transliteration mapping for common international brands
ARABIC_BRAND_NAMES = {
    'pepsi': 'بيبسي',
    'coca-cola': 'كوكاكولا',
    '7up': 'سفن أب',
    'mirinda': 'ميرندا',
    'sprite': 'سبرايت',
    'fanta': 'فانتا',
    'schweppes': 'شويبس',
    'nestle': 'نستله',
    'lipton': 'ليبتون',
    'nescafe': 'نسكافيه',
    'starbucks': 'ستاربكس',
    'costa': 'كوستا كافيه',
    'mcdonalds': 'ماكدونالدز',
    'kfc': 'كنتاكي (KFC)',
    'burger-king': 'برجر كنج',
    'pizza-hut': 'بيتزا هت',
    'dominos': 'دومينوز بيتزا',
    'subway': 'صَب واي',
    'hardees': 'هارديز',
    'chipsy': 'شيبسي',
    'lays': 'ليز',
    'doritos': 'دوريتوس',
    'cheetos': 'شيتوس',
    'pringles': 'برينجلز',
    'oreo': 'أوريو',
    'cadbury': 'كادبوري',
    'kitkat': 'كيت كات',
    'galaxy': 'جالكسي',
    'twix': 'تويكس',
    'mars': 'مارس',
    'snickers': 'سنيكرز',
    'bounty': 'باونتي',
    'milka': 'ميلكا',
    'toblerone': 'توبليرون',
    'danone': 'دانون',
    'activia': 'أكتيفيا',
    'president': 'بريزيدون',
    'kiri': 'كيري',
    'la-vache-qui-rit': 'البقرة الضاحكة',
    'ariel': 'أريال',
    'tide': 'تايد',
    'persil': 'برسيل',
    'fairy': 'فيري',
    'pril': 'بريل',
    'downy': 'داوني',
    'comfort': 'كمفورت',
    'head-and-shoulders': 'هيد آند شولدرز',
    'pantene': 'بانتين',
    'dove': 'دوف',
    'sunsilk': 'صانسيلك',
    'clear': 'كلير',
    'lux': 'لوكس',
    'colgate': 'كولجيت',
    'signal': 'سيجنال',
    'oral-b': 'أورال-بي',
    'gillette': 'جيليت',
    'nivea': 'نيفيا',
    'johnson-and-johnson': 'جونسون آند جونسون',
    'loreal': 'لوريال',
    'garnier': 'غارنييه',
    'maybelline': 'ميبيلين',
    'puma': 'بوما',
    'nike': 'نايكي',
    'adidas': 'أديداس',
    'zara': 'زارا',
    'h-and-m': 'إتش آند إم',
    'carrefour': 'كارفور',
    'hp': 'إتش بي (HP)',
    'siemens': 'سيمنز',
    'intel': 'إنتل',
    'sodastream': 'صودا ستريم',
    'ahava': 'أهافا',
    'strauss': 'مجموعة شتراوس',
    'osem': 'أوسم',
    'waze': 'ويز',
}

def clean_markdown(text):
    if not text:
        return ""
    text = re.sub(r'\[\^.*?\]:?.*', '', text)
    text = re.sub(r'\*\*(.*?)\*\*', r'\1', text)
    text = re.sub(r'\[(.*?)\]\(.*?\)', r'\1', text)
    return text.strip()

def fetch_tech_for_palestine():
    os.makedirs(DATA_DIR, exist_ok=True)
    if os.path.exists(LOCAL_CACHE_JSON):
        # Refresh if older than 7 days
        mtime = os.path.getmtime(LOCAL_CACHE_JSON)
        if time.time() - mtime < 7 * 86400:
            print("Using cached TechForPalestine dataset...")
            with open(LOCAL_CACHE_JSON, "r", encoding="utf-8") as f:
                return json.load(f)

    print("Fetching latest TechForPalestine dataset from GitHub...")
    try:
        req = urllib.request.Request(
            TFP_DATASET_URL,
            headers={'User-Agent': 'Badil-OpenData-Compiler/1.0'}
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            content = resp.read().decode('utf-8')
            data = json.loads(content)
            with open(LOCAL_CACHE_JSON, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"Successfully fetched and cached {len(data.get('brands', {}))} brands.")
            return data
    except Exception as e:
        print(f"Failed to fetch live dataset: {e}. Falling back to cached file if present.")
        if os.path.exists(LOCAL_CACHE_JSON):
            with open(LOCAL_CACHE_JSON, "r", encoding="utf-8") as f:
                return json.load(f)
        return {"brands": {}, "companies": {}}

def build_database():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
        print(f"Removed previous {DB_PATH}")

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("PRAGMA journal_mode = WAL;")
    cur.execute("PRAGMA foreign_keys = ON;")

    # 1. Schema
    cur.execute("""
    CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        icon TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0
    );
    """)

    cur.execute("""
    CREATE TABLE products (
        id TEXT PRIMARY KEY,
        barcode TEXT UNIQUE,
        name_ar TEXT NOT NULL,
        name_en TEXT,
        company_name TEXT NOT NULL,
        country_of_origin TEXT,
        category_id TEXT REFERENCES categories(id),
        status TEXT NOT NULL,           -- 'boycott' | 'safe_local'
        reason_ar TEXT,
        reason_en TEXT,
        image_url TEXT,
        is_featured INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
    );
    """)

    cur.execute("""
    CREATE TABLE product_alternatives (
        product_id TEXT NOT NULL REFERENCES products(id),
        alternative_product_id TEXT NOT NULL REFERENCES products(id),
        note_ar TEXT,
        note_en TEXT,
        rating REAL DEFAULT 5.0,
        PRIMARY KEY (product_id, alternative_product_id)
    );
    """)

    cur.execute("""
    CREATE TABLE country_prefixes (
        prefix TEXT PRIMARY KEY,
        country_code TEXT NOT NULL,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        flag_emoji TEXT NOT NULL,
        default_status TEXT NOT NULL   -- 'safe_local' | 'boycott' | 'neutral'
    );
    """)

    cur.execute("""
    CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
    );
    """)

    cur.execute("""
    CREATE TABLE pending_submissions (
        id TEXT PRIMARY KEY,
        barcode TEXT NOT NULL,
        product_name TEXT NOT NULL,
        brand_name TEXT,
        suggested_status TEXT NOT NULL,
        suggested_alternative TEXT,
        notes TEXT,
        status TEXT DEFAULT 'pending',
        created_at INTEGER NOT NULL
    );
    """)

    cur.execute("""
    CREATE VIRTUAL TABLE products_fts USING fts5(
        name_ar,
        name_en,
        company_name,
        content='products',
        content_rowid='rowid',
        tokenize='unicode61'
    );
    """)

    now = int(time.time())

    # 2. Categories
    categories = [
        ("beverages", "مشروبات ومياه", "Beverages & Drinks", "coffee", 1),
        ("snacks", "شيبسي وحلويات وبسكويت", "Snacks & Confectionery", "cookie", 2),
        ("personal_care", "عناية شخصية وصابون", "Personal Care & Soap", "sparkles", 3),
        ("detergents", "منظفات وعناية منزلية", "Detergents & Home Care", "droplet", 4),
        ("dairy", "ألبان وأجبان", "Dairy & Cheese", "milk", 5),
        ("restaurants", "مطاعم وسلاسل وجبات", "Restaurants & Chains", "utensils", 6),
        ("fashion", "ملابس وأحذية", "Fashion & Apparel", "shirt", 7),
        ("electronics", "إلكترونيات وتقنية", "Electronics & Tech", "laptop", 8),
        ("retail", "سوبرماركت ومتاجر", "Supermarkets & Retail", "store", 9),
    ]
    cur.executemany("INSERT INTO categories VALUES (?, ?, ?, ?, ?)", categories)

    # 3. GS1 Country Prefixes Table
    country_prefixes = [
        ("622", "EG", "مصر", "Egypt", "🇪🇬", "safe_local"),
        ("628", "SA", "المملكة العربية السعودية", "Saudi Arabia", "🇸🇦", "safe_local"),
        ("629", "AE", "الإمارات العربية المتحدة", "United Arab Emirates", "🇦🇪", "safe_local"),
        ("621", "SY", "سوريا", "Syria", "🇸🇾", "safe_local"),
        ("625", "JO", "الأردن", "Jordan", "🇯🇴", "safe_local"),
        ("611", "MA", "المغرب", "Morocco", "🇲🇦", "safe_local"),
        ("619", "TN", "تونس", "Tunisia", "🇹🇳", "safe_local"),
        ("613", "DZ", "الجزائر", "Algeria", "🇩🇿", "safe_local"),
        ("627", "KW", "الكويت", "Kuwait", "🇰🇼", "safe_local"),
        ("624", "YE", "اليمن", "Yemen", "🇾🇪", "safe_local"),
        ("608", "BH", "البحرين", "Bahrain", "🇧🇭", "safe_local"),
        ("630", "QA", "قطر", "Qatar", "🇶🇦", "safe_local"),
        ("612", "OM", "عُمان", "Oman", "🇴🇲", "safe_local"),
        ("616", "LY", "ليبيا", "Libya", "🇱🇾", "safe_local"),
        ("626", "IR", "إيران", "Iran", "🇮🇷", "safe_local"),
        ("868", "TR", "تركيا", "Turkey", "🇹🇷", "safe_local"),
        ("869", "TR", "تركيا", "Turkey", "🇹🇷", "safe_local"),
        ("729", "IL", "إسرائيل (مقاطعة مؤكدة)", "Israel (Strict Boycott)", "🇮🇱", "boycott"),
        ("000", "US", "الولايات المتحدة", "United States", "🇺🇸", "neutral"),
        ("001", "US", "الولايات المتحدة", "United States", "🇺🇸", "neutral"),
        ("002", "US", "الولايات المتحدة", "United States", "🇺🇸", "neutral"),
        ("003", "US", "الولايات المتحدة", "United States", "🇺🇸", "neutral"),
        ("004", "US", "الولايات المتحدة", "United States", "🇺🇸", "neutral"),
        ("005", "US", "الولايات المتحدة", "United States", "🇺🇸", "neutral"),
        ("006", "US", "الولايات المتحدة", "United States", "🇺🇸", "neutral"),
        ("007", "US", "الولايات المتحدة", "United States", "🇺🇸", "neutral"),
        ("008", "US", "الولايات المتحدة", "United States", "🇺🇸", "neutral"),
        ("009", "US", "الولايات المتحدة", "United States", "🇺🇸", "neutral"),
        ("500", "GB", "المملكة المتحدة", "United Kingdom", "🇬🇧", "neutral"),
        ("760", "CH", "سويسرا", "Switzerland", "🇨🇭", "neutral"),
        ("400", "DE", "ألمانيا", "Germany", "🇩🇪", "neutral"),
        ("300", "FR", "فرنسا", "France", "🇫🇷", "neutral"),
    ]
    cur.executemany("INSERT INTO country_prefixes VALUES (?, ?, ?, ?, ?, ?)", country_prefixes)

    # 4. Ingest Curated High-Priority Products (Egyptian Market & Core Targets)
    # (id, barcode, name_ar, name_en, company, origin, category, status, reason_ar, reason_en, is_featured)
    curated_products = [
        # --- BEVERAGES: BOYCOTT ---
        ("pepsi_can_330", "6221010001011", "بيبسي كانز 330 مل", "Pepsi Can 330ml", "PepsiCo", "US", "beverages", "boycott",
         "شركة بيبسيكو الأمريكية تملك شراكات استثمارية ومصانع وتدعم الاحتلال الإسرائيلي.",
         "PepsiCo owns strategic investments, manufacturing facilities and directly supports Israeli ventures.", 0),
        ("coca_cola_can_330", "5449000000996", "كوكاكولا كانز 330 مل", "Coca-Cola Can 330ml", "The Coca-Cola Company", "US", "beverages", "boycott",
         "تملك مصانع ومراكز توزيع في المستوطنات غير الشرعية وتدعم الاحتلال.",
         "Operates facilities in illegal settlements and actively backs Israeli expansion.", 0),
        ("seven_up_can_330", "6221010001028", "سفن أب كانز 330 مل", "7Up Can 330ml", "PepsiCo", "US", "beverages", "boycott",
         "مملوكة لشركة بيبسيكو الأمريكية الداعمة للاحتلال.",
         "Subsidiary of PepsiCo, active corporate backer of the Israeli economy.", 0),
        ("mirinda_orange_can", "6221010001035", "ميرندا برتقال كانز", "Mirinda Orange Can", "PepsiCo", "US", "beverages", "boycott",
         "مملوكة لشركة بيبسيكو الأمريكية.",
         "Owned by US-based PepsiCo.", 0),
        ("sprite_can_330", "5449000001009", "سبرايت كانز 330 مل", "Sprite Can 330ml", "The Coca-Cola Company", "US", "beverages", "boycott",
         "تابعة لشركة كوكاكولا الأمريكية.",
         "Subsidiary of The Coca-Cola Company.", 0),
        ("schweppes_gold", "5449000054321", "شويبس جولد أناناس", "Schweppes Gold Pineapple", "The Coca-Cola Company", "US", "beverages", "boycott",
         "مملوكة لشركة كوكاكولا بالمنطقة.",
         "Distributed by Coca-Cola holding.", 0),
        ("nestle_pure_life_15", "6223000520015", "مياه نستله بيور لايف 1.5 لتر", "Nestle Pure Life 1.5L", "Nestle", "CH", "beverages", "boycott",
         "نستله تمتلك حصة مسيطرة بأكثر من 50% في شركة أوسم الإسرائيلية لصناعات الأغذية.",
         "Nestle owns a controlling stake of over 50% in Israeli food giant Osem.", 0),
        ("baraka_water_15", "6221053001015", "مياه بركة 1.5 لتر", "Baraka Water 1.5L", "Nestle", "CH", "beverages", "boycott",
         "تابعة لمجموعة نستله السويسرية.",
         "Subsidiary of Swiss conglomerate Nestle.", 0),
        ("dasani_water_15", "5449000012345", "مياه داساني 1.5 لتر", "Dasani Water 1.5L", "The Coca-Cola Company", "US", "beverages", "boycott",
         "مملوكة لشركة كوكاكولا الأمريكية.",
         "Bottled water brand of Coca-Cola.", 0),
        ("nescafe_classic", "7613035380012", "نسكافيه كلاسيك 100 جم", "Nescafe Classic 100g", "Nestle", "CH", "beverages", "boycott",
         "تابعة لمجموعة نستله السويسرية الداعمة للاحتلال.",
         "Flagship instant coffee brand of Nestle.", 0),
        ("lipton_yellow_label", "6221155001010", "شاي ليبتون العلامة الصفراء", "Lipton Yellow Label Tea", "Unilever / CVC", "UK", "beverages", "boycott",
         "مملوكة لشركات استثمارية دولية تدعم الأنشطة الاقتصادية للاحتلال.",
         "Invested by multinational holding backing Israeli commercial hubs.", 0),

        # --- BEVERAGES: LOCAL ALTERNATIVES ---
        ("spiro_spathis_apple", "6224000111011", "سبيرو سباتس تفاح 330 مل", "Spiro Spathis Apple 330ml", "Spiro Spathis", "EG", "beverages", "safe_local",
         None, None, 1),
        ("spiro_spathis_lemon", "6224000111028", "سبيرو سباتس ليمون 330 مل", "Spiro Spathis Lemon 330ml", "Spiro Spathis", "EG", "beverages", "safe_local",
         None, None, 1),
        ("spiro_spathis_grapes", "6224000111035", "سبيرو سباتس عنب 330 مل", "Spiro Spathis Grapes 330ml", "Spiro Spathis", "EG", "beverages", "safe_local",
         None, None, 1),
        ("v7_cola_can", "6225000123015", "في سفن كولا كانز 330 مل", "V7 Cola Can 330ml", "V7 Egypt", "EG", "beverages", "safe_local",
         None, None, 1),
        ("v7_lemon_can", "6225000123022", "في سفن ليمون كانز 330 مل", "V7 Lemon Can 330ml", "V7 Egypt", "EG", "beverages", "safe_local",
         None, None, 0),
        ("dash_soda", "6224008880012", "داش صودا فواكه مشكلة", "Dash Fruit Soda", "Dash Egypt", "EG", "beverages", "safe_local",
         None, None, 0),
        ("sina_cola_can", "6223001234567", "سينا كولا كانز 330 مل", "Sina Cola Can", "Sina Cola", "EG", "beverages", "safe_local",
         None, None, 0),
        ("siwa_water_15", "6223000101015", "مياه سيوة الطبيعية 1.5 لتر", "Siwa Natural Water 1.5L", "Siwa", "EG", "beverages", "safe_local",
         None, None, 0),
        ("flo_water_15", "6224000202015", "مياه فلو الطبيعية 1.5 لتر", "Flo Natural Water 1.5L", "Flo Egypt", "EG", "beverages", "safe_local",
         None, None, 0),
        ("hayat_water_15", "6223000303015", "مياه حياة الطبيعية 1.5 لتر", "Hayat Water 1.5L", "Hayat Egypt", "EG", "beverages", "safe_local",
         None, None, 0),
        ("safi_water_15", "6224000404015", "مياه صافي الطبيعية 1.5 لتر", "Safi Natural Water 1.5L", "Safi", "EG", "beverages", "safe_local",
         None, None, 0),
        ("misr_cafe_classic", "6221111222019", "مصر كافيه قهوة سريعة التحضير", "Misr Cafe Instant Coffee", "Misr Cafe", "EG", "beverages", "safe_local",
         None, None, 1),
        ("abu_auf_coffee", "6224000555018", "بن أبو عوف تركي محوج", "Abu Auf Turkish Coffee", "Abu Auf", "EG", "beverages", "safe_local",
         None, None, 0),
        ("el_arosa_tea", "6221022001012", "شاي العروسة أسود فاخر", "El Arosa Black Tea", "El Arosa", "EG", "beverages", "safe_local",
         None, None, 1),

        # --- SNACKS & CHIPS: BOYCOTT ---
        ("chipsy_chili_lemon", "6221010111111", "شيبسي شطة وليمون عائلي", "Chipsy Chili & Lemon", "PepsiCo", "US", "snacks", "boycott",
         "مملوكة بالكامل لشركة بيبسيكو الأمريكية الداعمة للاحتلال.",
         "Fully owned subsidiary of US PepsiCo.", 0),
        ("doritos_sweet_chili", "6221010222222", "دوريتوس فلفل حلو", "Doritos Sweet Chili", "PepsiCo", "US", "snacks", "boycott",
         "مملوكة لشركة فريتو لاي التابعة لبيبسيكو.",
         "Frito-Lay / PepsiCo consumer brand.", 0),
        ("cheetos_crunchy_cheese", "6221010333333", "شيتوس جبنة كرانشي", "Cheetos Crunchy Cheese", "PepsiCo", "US", "snacks", "boycott",
         "تابعة لشركة بيبسيكو الأمريكية.",
         "PepsiCo snack line.", 0),
        ("pringles_original", "5053990101511", "برينجلز بطاطس أوريجينال", "Pringles Original", "Kellanova (Kellogg's)", "US", "snacks", "boycott",
         "شركة كيلوجز الأمريكية تملك استثمارات وشراكات تقنية إسرائيلية.",
         "Kellanova / Kellogg's maintains major corporate partnerships in Israel.", 0),
        ("oreo_original_biscuit", "7622210101012", "بسكويت أوريو الأصلي", "Oreo Original Biscuit", "Mondelez International", "US", "snacks", "boycott",
         "موندليز الأمريكية تستثمر في حاضنات الأغذية والشركات الناشئة في إسرائيل.",
         "Mondelez invests in Israeli FoodTech hubs and tech incubators.", 0),
        ("cadbury_dairy_milk", "7622210202022", "كادبوري ديري ميلك سادة", "Cadbury Dairy Milk Chocolate", "Mondelez International", "US", "snacks", "boycott",
         "مملوكة لشركة موندليز الأمريكية الداعمة للاحتلال.",
         "Owned by Mondelez International.", 0),
        ("kitkat_4_finger", "7613035111111", "كيت كات أصابع شوكولاتة", "KitKat 4 Finger", "Nestle", "CH", "snacks", "boycott",
         "تابعة لمجموعة نستله السويسرية الشريكة في شركة أوسم الإسرائيلية.",
         "Produced by Nestle.", 0),
        ("galaxy_smooth_milk", "5000159404011", "جالكسي شوكولاتة بالحليب", "Galaxy Smooth Milk", "Mars Inc.", "US", "snacks", "boycott",
         "مارس الأمريكية تدعم وتستثمر في أكاديميات الأغذية الإسرائيلية.",
         "Mars Inc. funds Israeli food science initiatives.", 0),

        # --- SNACKS: LOCAL ALTERNATIVES ---
        ("tiger_chili_lemon", "6223000777011", "تايجر شيبس شطة وليمون", "Tiger Chips Chili Lemon", "Egypt Foods", "EG", "snacks", "safe_local",
         None, None, 1),
        ("big_chips_cheese", "6223000888012", "بيج شيبس جبنة متبلة", "Big Chips Cheese", "Egypt Foods", "EG", "snacks", "safe_local",
         None, None, 0),
        ("fox_potatoes", "6224000999013", "فوكس بطاطس مقرمشة بالجبنة", "Fox Potato Chips", "Fox Egypt", "EG", "snacks", "safe_local",
         None, None, 0),
        ("bake_rolz_pizza", "6221155333011", "بيك رولز بيتزا فاخر", "Bake Rolz Pizza", "Edita", "EG", "snacks", "safe_local",
         None, None, 1),
        ("corona_classic_chocolate", "6221000111019", "كورونا شوكولاتة مصرية كلاسيك", "Corona Egyptian Classic Chocolate", "Corona", "EG", "snacks", "safe_local",
         None, None, 1),
        ("bimbo_biscuit_chocolate", "6221155444018", "بيمبو بسكويت مغطى بالشوكولاتة", "Bimbo Chocolate Biscuit", "Bisco Misr", "EG", "snacks", "safe_local",
         None, None, 1),
        ("freska_bites", "6221155555015", "فريسكا بايتس شوكولاتة وبندق", "Freska Bites Hazelnut", "Edita", "EG", "snacks", "safe_local",
         None, None, 1),
        ("molto_chocolate_croissant", "6221155666012", "مولتو كرواسون شوكولاتة", "Molto Chocolate Croissant", "Edita", "EG", "snacks", "safe_local",
         None, None, 0),

        # --- DETERGENTS: BOYCOTT ---
        ("ariel_automatic_powder", "4015600101011", "مسحوق أريال أوتوماتيك 4 كجم", "Ariel Automatic Powder 4kg", "Procter & Gamble (P&G)", "US", "detergents", "boycott",
         "بي آند جي الأمريكية تستثمر مئات الملايين بمراكز الأبحاث في إسرائيل.",
         "P&G maintains massive R&D facilities and joint ventures in Israel.", 0),
        ("tide_automatic_powder", "4015600202022", "مسحوق تايد أوتوماتيك 4 كجم", "Tide Automatic Powder 4kg", "Procter & Gamble (P&G)", "US", "detergents", "boycott",
         "مملوكة لشركة بروكتر آند جامبل الأمريكية.",
         "P&G flagship laundry brand.", 0),
        ("persil_deep_clean", "6221155999015", "برسيل ديب كلين جل 3 لتر", "Persil Deep Clean Gel 3L", "Henkel", "DE", "detergents", "boycott",
         "هنكل الألمانية تمتلك شراكات واستثمارات تكنولوجية مباشرة في إسرائيل.",
         "Henkel holds direct corporate equity in Israeli tech firms.", 0),
        ("fairy_dishwashing_liquid", "4015600303033", "فيري سائل غسيل الأطباق بالليمون", "Fairy Dishwashing Liquid", "Procter & Gamble (P&G)", "US", "detergents", "boycott",
         "تابعة لشركة بروكتر آند جامبل الأمريكية.",
         "P&G dishwashing product.", 0),

        # --- DETERGENTS: LOCAL ALTERNATIVES ---
        ("oxi_automatic_powder", "6224000777019", "أوكسي مسحوق غسيل أوتوماتيك باللافندر", "Oxi Automatic Powder Lavender", "Arma", "EG", "detergents", "safe_local",
         None, None, 1),
        ("oxi_gel_detergent", "6224000777026", "أوكسي جل غسيل منظف ومطهر", "Oxi Gel Detergent", "Arma", "EG", "detergents", "safe_local",
         None, None, 1),
        ("feba_dishwashing_liquid", "6223000666018", "فيبا سائل غسيل الصحون بالليمون 2 لتر", "Feba Dishwashing Liquid 2L", "Feba Egypt", "EG", "detergents", "safe_local",
         None, None, 1),
        ("bahar_automatic_powder", "6224000333017", "بحر مسحوق غسيل اقتصادي فائق النظافة", "Bahar Automatic Powder", "Bahar", "EG", "detergents", "safe_local",
         None, None, 0),

        # --- PERSONAL CARE: BOYCOTT ---
        ("head_and_shoulders_shampoo", "4015600505055", "شامبو هيد آند شولدرز ضد القشرة", "Head & Shoulders Shampoo", "Procter & Gamble (P&G)", "US", "personal_care", "boycott",
         "تابعة لشركة بروكتر آند جامبل الأمريكية.",
         "Produced by P&G.", 0),
        ("dove_beauty_soap", "8717163001011", "صابون دوف للجمال قالب 100 جم", "Dove Beauty Soap 100g", "Unilever", "UK", "personal_care", "boycott",
         "يونيليفر العالمية تدعم وتستثمر في السوق الإسرائيلي.",
         "Unilever global consumer brand.", 0),
        ("colgate_total_toothpaste", "8718951001011", "معجون أسنان كولجيت توتال", "Colgate Total Toothpaste", "Colgate-Palmolive", "US", "personal_care", "boycott",
         "كولجيت بالموليف تستثمر وتدعم حاضنات تقنية إسرائيلية.",
         "Colgate-Palmolive funds Israeli tech hubs.", 0),

        # --- PERSONAL CARE: LOCAL ALTERNATIVES ---
        ("eva_cosmetics_shampoo", "6221044001012", "إيفا هير كلينيك شامبو كيراتين", "Eva Hair Clinic Keratin Shampoo", "Eva Cosmetics", "EG", "personal_care", "safe_local",
         None, None, 1),
        ("bobana_marine_collagen", "6224000888019", "بوبانا ماسك لتغذية الشعر", "Bobana Hair Collagen Treatment", "Bobana", "EG", "personal_care", "safe_local",
         None, None, 1),
        ("penduline_kids_shampoo", "6224000999020", "بندولين شامبو أطفال طبيعي 100%", "Penduline Natural Kids Shampoo", "Penduline", "EG", "personal_care", "safe_local",
         None, None, 1),
        ("starville_cleanser", "6224000333024", "ستارفيل غسول للبشرة الدهنية", "Starville Facial Cleanser", "Parkville", "EG", "personal_care", "safe_local",
         None, None, 1),
        ("depurdent_toothpaste", "6221044002029", "معجون أسنان إيفا سموكرز بالمسواك", "Eva Smokers Miswak Toothpaste", "Eva Cosmetics", "EG", "personal_care", "safe_local",
         None, None, 1),

        # --- DAIRY: BOYCOTT ---
        ("danone_danette_chocolate", "3033490001011", "دانون دانيت شوكولاتة كراميل", "Danone Danette Chocolate", "Danone", "FR", "dairy", "boycott",
         "دانون الفرنسية تملك استثمارات استراتيجية وشراكات تقنية مع الاحتلال.",
         "Danone invested directly in Israeli venture capital funds.", 0),
        ("president_feta_cheese", "3155250001012", "جبنة بريزيدون فيتا بيضاء 500 جم", "President Feta Cheese 500g", "Lactalis", "FR", "dairy", "boycott",
         "مجموعة لاكتاليس الفرنسية تدعم التعاون التجاري مع إسرائيل.",
         "Lactalis Group commercial partner in Israel.", 0),

        # --- DAIRY: LOCAL ALTERNATIVES ---
        ("lamar_full_cream_milk", "6223000444018", "حليب لمار كامل الدسم طبيعي 1 لتر", "Lamar Full Cream Natural Milk 1L", "Lamar Egypt", "EG", "dairy", "safe_local",
         None, None, 1),
        ("juhayna_pure_milk", "6221020001014", "حليب جهينة كامل الدسم معبأ 1 لتر", "Juhayna Full Cream Milk 1L", "Juhayna", "EG", "dairy", "safe_local",
         None, None, 1),
        ("domty_plus_feta", "6221050001018", "جبنة دومتي بلس فيتا طازجة 500 جم", "Domty Plus Feta Fresh 500g", "Domty", "EG", "dairy", "safe_local",
         None, None, 1),
        ("katilo_white_cheese", "6221070001012", "جبنة قتيلو دمياطي براميلي فاخرة", "Katilo Traditional White Cheese", "Katilo", "EG", "dairy", "safe_local",
         None, None, 0),

        # --- RESTAURANTS: BOYCOTT ---
        ("mcdonalds_chain", "REST_MCDONALDS", "ماكدونالدز مصر والوجبات السريعة", "McDonald's Fast Food", "McDonald's Corp", "US", "restaurants", "boycott",
         "ماكدونالدز قدمت وجبات وتبرعات لجنود جيش الاحتلال الإسرائيلي.",
         "McDonald's provided complimentary meals and support to Israeli military units.", 0),
        ("kfc_chain", "REST_KFC", "كنتاكي دجاج مقلي (KFC)", "KFC Fried Chicken", "Yum! Brands", "US", "restaurants", "boycott",
         "مجموعة يم براندز تملك وتستثمر في شركات ناشئة إسرائيلية.",
         "Yum! Brands backs and acquires Israeli food-tech companies.", 0),
        ("starbucks_chain", "REST_STARBUCKS", "ستاربكس كافيه للمشروبات والقهوة", "Starbucks Coffee", "Starbucks Corp", "US", "restaurants", "boycott",
         "ستاربكس قاضت نقابتها العمالية بسبب دعم غزة والتضامن الإنساني.",
         "Starbucks aggressively sued its workers union over Palestine solidarity.", 0),
        ("hardees_chain", "REST_HARDEES", "هارديز برجر وبطاطس", "Hardee's Burgers", "CKE Restaurants", "US", "restaurants", "boycott",
         "شركة أمريكية تابعة لمجموعات استثمارية داعمة للاحتلال.",
         "US corporate chain owned by pro-Israel equity groups.", 0),

        # --- RESTAURANTS: LOCAL ALTERNATIVES ---
        ("buffalo_burger", "REST_BUFFALO", "بافلو برجر مشوي على الفحم", "Buffalo Burger", "Buffalo Burger", "EG", "restaurants", "safe_local",
         None, None, 1),
        ("bazooka_chicken", "REST_BAZOOKA", "بازوكا فرايد تشيكن مصرية", "Bazooka Fried Chicken", "Bazooka Egypt", "EG", "restaurants", "safe_local",
         None, None, 1),
        ("heart_attack_chicken", "REST_HEART_ATTACK", "هارت أタック دجاج مقرمش", "Heart Attack Chicken", "Heart Attack", "EG", "restaurants", "safe_local",
         None, None, 0),
        ("blaban_desserts", "REST_BLABAN", "ب لبن قشطوطة وأم علي وحلويات", "B.Laban Oriental Desserts", "B.Laban", "EG", "restaurants", "safe_local",
         None, None, 1),

        # --- STRATEGIC BDS TARGETS (TECH / APPAREL) ---
        ("puma_sports", "BDS_PUMA", "بوما للملابس والأحذية الرياضية", "Puma Sports & Apparel", "Puma SE", "DE", "fashion", "boycott",
         "الراعي الرسمي لاتحاد كرة القدم الإسرائيلي الذي يضم أندية بالمستوطنات غير القانونية.",
         "Main sponsor of the Israel Football Association, which governs teams in illegal West Bank settlements.", 1),
        ("hp_inc", "BDS_HP", "إتش بي للحواسيب والطابعات", "HP Inc. Computers & Printers", "HP Inc.", "US", "electronics", "boycott",
         "توفر الخوادم والتكنولوجيا لقواعد بيانات ونقاط التفتيش التابعة للاحتلال.",
         "Provides servers and biometric tracking technologies used across Israeli military checkpoints.", 1),
        ("carrefour_supermarkets", "BDS_CARREFOUR", "متاجر وسوبرماركت كارفور", "Carrefour Supermarkets", "Carrefour Group", "FR", "retail", "boycott",
         "وقعت شراكة مع شركات إسرائيلية وافتتحت فروعاً في المستوطنات المحتلة.",
         "Partnered with Israeli firms and expanded supermarket branches into occupied Palestinian territories.", 1),
        ("sodastream_devices", "7290001112223", "صودا ستريم ماكينات المياه الغازية", "SodaStream Machines", "PepsiCo", "IL", "beverages", "boycott",
         "مصنعة مباشرة في إسرائيل وتاريخ من الاستيطان ومملوكة لبيبسيكو.",
         "Direct Israeli manufacturer with deep ties to settlement industries; owned by PepsiCo.", 1),
        ("ahava_cosmetics", "7290002223334", "أهافا مستحضرات البحر الميت", "Ahava Dead Sea Cosmetics", "Fosun Group", "IL", "personal_care", "boycott",
         "تنهب الموارد الطبيعية الفلسطينية من شواطئ البحر الميت المحتلة.",
         "Manufactures products using stolen minerals from the occupied Palestinian Dead Sea shores.", 1),
    ]

    for p in curated_products:
        cur.execute("""
        INSERT INTO products (id, barcode, name_ar, name_en, company_name, country_of_origin, category_id, status, reason_ar, reason_en, is_featured, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], now))

    # 5. Ingest TechForPalestine Dataset Brands
    tfp_data = fetch_tech_for_palestine()
    brands = tfp_data.get('brands', {})
    print(f"Processing {len(brands)} TechForPalestine brands into SQLite...")

    inserted_tfp_count = 0
    curated_ids = {p[0] for p in curated_products}

    for b_id, b in brands.items():
        clean_id = f"tfp_{b_id.replace('-', '_')}"
        if clean_id in curated_ids:
            continue

        raw_name = b.get('name') or b_id
        # Derive Arabic name
        slug = b_id.lower()
        name_ar = ARABIC_BRAND_NAMES.get(slug, raw_name)

        desc = clean_markdown(b.get('description', ''))
        # Map category
        cat_id = 'snacks'  # default fallback
        for c in b.get('categories', []):
            if c in CATEGORY_MAP:
                cat_id = CATEGORY_MAP[c]
                break

        # Company owner
        company = "Unknown"
        for s in b.get('stakeholders', []):
            if s.get('type') == 'owner':
                company = s.get('id', '').replace('-', ' ').title()
                break

        # Default boycott reason
        reason_en = desc if desc else "Identified as a company supporting the Israeli military occupation."
        reason_ar = f"علامة تجارية تابعة لشركة {company} وتدعم الاستثمار في إسرائيل."

        try:
            cur.execute("""
            INSERT OR IGNORE INTO products (
                id, barcode, name_ar, name_en, company_name, country_of_origin,
                category_id, status, reason_ar, reason_en, image_url, is_featured, created_at
            )
            VALUES (?, NULL, ?, ?, ?, ?, ?, 'boycott', ?, ?, ?, 0, ?)
            """, (clean_id, name_ar, raw_name, company, "Global", cat_id, reason_ar, reason_en, b.get('logo_url'), now))
            inserted_tfp_count += 1
        except Exception as err:
            pass

    print(f"Added {inserted_tfp_count} brands from TechForPalestine.")

    # 6. Alternatives Mapping (Junction Table)
    alternatives_map = [
        # Pepsi / Coke -> Spiro Spathis, V7, Dash, Sina Cola
        ("pepsi_can_330", "spiro_spathis_apple", "العلامة المصرية التاريخية الأفضل طعماً والأعلى انتشاراً", "Historic Egyptian national brand, premium taste & wide availability", 5.0),
        ("pepsi_can_330", "v7_cola_can", "طعم كولا مصري أصيل غازي وقوي", "Authentic Egyptian sparkling cola taste", 4.9),
        ("pepsi_can_330", "sina_cola_can", "بديل مصري قديم واقتصادي", "Classic economical Egyptian cola alternative", 4.5),
        ("coca_cola_can_330", "v7_cola_can", "طعم كولا طبيعي بدون مقاطعة", "Natural Egyptian cola alternative, zero boycott ties", 5.0),
        ("coca_cola_can_330", "spiro_spathis_lemon", "مشروب ليمون منعش بجودة فائقة", "Refreshing sparkling lemon soda of high quality", 4.9),
        ("seven_up_can_330", "spiro_spathis_lemon", "نفس الانتعاش ونكهة الليمون الصودا النقية", "Equal crispness and natural lemon soda flavor", 5.0),
        ("seven_up_can_330", "v7_lemon_can", "صودا ليمون مصرية نقية بدون مواد حافظة ضارة", "Pure Egyptian lemon soda without artificial additives", 4.8),
        ("mirinda_orange_can", "dash_soda", "صودا برتقال وفواكه مصرية طبيعية وغنية بالغازات", "Egyptian natural fruit soda with rich carbonation", 4.8),
        ("sprite_can_330", "spiro_spathis_lemon", "ليمون صودا مصري منعش للغاية", "Ultra refreshing Egyptian lemon soda", 5.0),
        ("schweppes_gold", "dash_soda", "بديل مصري بنكهة الفواكه الطبيعية", "Egyptian sparkling beverage with natural fruit essence", 4.7),

        # Water: Nestle / Dasani / Baraka -> Siwa, Flo, Hayat, Safi
        ("nestle_pure_life_15", "siwa_water_15", "مياه آبار سيوة الجوفية النقية من قلب الصحراء الغربية", "Pure natural underground spring water from Siwa Oasis", 5.0),
        ("nestle_pure_life_15", "flo_water_15", "مياه مصرية طبيعية نقية متوازنة الأملاح", "Balanced mineral Egyptian spring water", 4.8),
        ("baraka_water_15", "hayat_water_15", "مياه طبيعية 100% مستخرجة من أنقى الآبار", "100% natural Egyptian spring water", 4.8),
        ("dasani_water_15", "safi_water_15", "مياه جوفية طبيعية عالية الجودة والنقاء", "High purity natural Egyptian bottled water", 4.9),

        # Coffee & Tea: Nescafe / Lipton -> Misr Cafe, Abu Auf, El Arosa
        ("nescafe_classic", "misr_cafe_classic", "أول مصنع قهوة سريعة التحضير في مصر والشرق الأوسط", "The pioneer instant coffee manufacturer in Egypt & Middle East", 5.0),
        ("nescafe_classic", "abu_auf_coffee", "بن تركي فاخر ومحبوب في كل بيت", "Premium roasted coffee beans & blends", 4.9),
        ("lipton_yellow_label", "el_arosa_tea", "شاي مصر الأول ذو النكهة القوية والمذاق الأصيل", "Egypt's #1 traditional black tea with bold authentic flavor", 5.0),

        # Chips: Chipsy / Doritos / Cheetos / Pringles -> Tiger, Big Chips, Fox, Bake Rolz
        ("chipsy_chili_lemon", "tiger_chili_lemon", "بطاطس طبيعية 100% مصرية مقرمشة بنكهات غنية", "100% natural Egyptian crispy potatoes with rich seasoning", 5.0),
        ("chipsy_chili_lemon", "big_chips_cheese", "رقائق بطاطس كبيرة ومقرمشة بأعلى جودة", "Extra-large crispy potato chips of high quality", 4.7),
        ("doritos_sweet_chili", "tiger_chili_lemon", "قرمشة حقيقية وتتبيلة لذيذة بديلة لدوريتوس", "Great crunchy substitute with flavorful seasoning", 4.8),
        ("cheetos_crunchy_cheese", "fox_potatoes", "مقرمشات مصرية عالية الجودة بطعم الجبنة الغنية", "Crispy cheese corn snack made locally", 4.6),
        ("pringles_original", "bake_rolz_pizza", "مقرمشات مخبوزة صحية وغير مقلية بنكهات متعددة", "Healthy oven-baked wheat snacks, delicious and non-fried", 4.9),

        # Chocolate: Oreo / Cadbury / KitKat / Galaxy -> Corona, Bimbo, Freska, Molto
        ("oreo_original_biscuit", "bimbo_biscuit_chocolate", "البسكويت المصري الأصيل المغطى بالشوكولاتة الفاخرة", "Authentic Egyptian chocolate-coated heritage biscuit", 5.0),
        ("cadbury_dairy_milk", "corona_classic_chocolate", "أعرق مصنع شوكولاتة في الشرق الأوسط منذ 1919", "Historic Egyptian confectioner crafting fine chocolate since 1919", 5.0),
        ("kitkat_4_finger", "freska_bites", "ويفر فريسكا المقرمش المحشو بأشهى أنواع الشوكولاتة والبندق", "Crispy wafer bites loaded with premium chocolate & hazelnut", 5.0),
        ("galaxy_smooth_milk", "corona_classic_chocolate", "شوكولاتة ناعمة غنية بالحليب المحلي الطبيعي", "Smooth melt-in-your-mouth milk chocolate bar", 4.9),

        # Detergents: Ariel / Tide / Persil / Fairy -> Oxi, Feba, Bahar
        ("ariel_automatic_powder", "oxi_automatic_powder", "مسحوق الغسيل المصري رقم 1 بقوة أكسجين فائقة ورائحة منعشة", "Egypt's #1 laundry detergent powered by active oxygen", 5.0),
        ("tide_automatic_powder", "oxi_automatic_powder", "نظافة ناصعة وبياض فائق بدون بهتان للألوان", "Superior brightness and color protection", 5.0),
        ("persil_deep_clean", "oxi_gel_detergent", "جل مركز فائق القوة يزيل أصعب البقع بسهولة", "Concentrated stain-lifting gel with long-lasting freshness", 4.9),
        ("fairy_dishwashing_liquid", "feba_dishwashing_liquid", "سائل غسيل صحون مصري اقتصادي قاهر للدهون", "Grease-cutting concentrated dishwashing liquid", 4.9),

        # Personal Care: Head & Shoulders / Dove / Colgate -> Eva, Bobana, Penduline, Starville
        ("head_and_shoulders_shampoo", "eva_cosmetics_shampoo", "شامبو كيراتين وصبار طبيعي خالي من السلفات من إيفا", "Sulfate-free keratin & aloe vera hair clinic shampoo", 5.0),
        ("dove_beauty_soap", "bobana_marine_collagen", "منتجات عناية مصرية مصنعة بمواصفات طبية عالمية", "Dermatologically tested Egyptian skin & hair care formulas", 4.9),
        ("colgate_total_toothpaste", "depurdent_toothpaste", "معجون أسنان مصري بالمسواك الطبيعي لحماية اللثة والأسنان", "Natural Miswak antibacterial formula for strong gums & teeth", 5.0),

        # Dairy: Danone / President -> Lamar, Juhayna, Domty, Katilo
        ("danone_danette_chocolate", "juhayna_pure_milk", "حليب مصري نقي 100% من مزارع جهينة الطبيعية", "100% pure Egyptian fresh milk from farm to table", 5.0),
        ("president_feta_cheese", "domty_plus_feta", "جبنة فيتا طبيعية طازجة من أكبر مصانع الأجبان بمصر", "Fresh natural feta cheese from Egypt's leading dairy brand", 5.0),

        # Restaurants: McDonald's / KFC / Starbucks -> Buffalo, Bazooka, B.Laban
        ("mcdonalds_chain", "buffalo_burger", "برجر مصري 100% لحم بقري صافي مشوي على اللهب", "100% pure flame-grilled premium beef burgers", 5.0),
        ("kfc_chain", "bazooka_chicken", "دجاج مقلي مصري طازج ومقرمش بخلطات سرية لذيذة", "Crispy fresh fried chicken prepared with authentic spices", 5.0),
        ("hardees_chain", "heart_attack_chicken", "وجبات برجر ودجاج ضخمة وسريعة التحضير بجودة مصرية", "Generous burgers and crispy chicken meals", 4.7),
        ("starbucks_chain", "abu_auf_coffee", "قهوة ومشروبات تركي ومختصة من أجود الحبوب بالعالم", "Specialty coffee beans and artisan espresso blends", 4.9),
    ]

    for alt in alternatives_map:
        cur.execute("""
        INSERT OR REPLACE INTO product_alternatives (product_id, alternative_product_id, note_ar, note_en, rating)
        VALUES (?, ?, ?, ?, ?)
        """, alt)

    # 7. Initial App Settings (e.g. language)
    cur.execute("INSERT OR REPLACE INTO app_settings (key, value) VALUES ('locale', 'ar');")
    cur.execute("INSERT OR REPLACE INTO app_settings (key, value) VALUES ('db_version', '2');")

    conn.commit()

    # 8. Rebuild FTS5 Index
    print("Building full-text search index...")
    cur.execute("INSERT INTO products_fts(products_fts) VALUES('rebuild');")
    conn.commit()

    # Counts
    cur.execute("SELECT count(*) FROM products;")
    total_p = cur.fetchone()[0]
    cur.execute("SELECT count(*) FROM products WHERE status = 'boycott';")
    total_boycott = cur.fetchone()[0]
    cur.execute("SELECT count(*) FROM products WHERE status = 'safe_local';")
    total_local = cur.fetchone()[0]
    cur.execute("SELECT count(*) FROM product_alternatives;")
    total_alts = cur.fetchone()[0]

    print("\n✅ Badil Seed Database Compilation Complete!")
    print(f"Total Products:     {total_p}")
    print(f"  - Boycott Brands: {total_boycott}")
    print(f"  - Local Brands:   {total_local}")
    print(f"Alternative Links:  {total_alts}")
    print(f"Database File:      {DB_PATH} ({os.path.getsize(DB_PATH) // 1024} KB)")

    conn.close()

if __name__ == "__main__":
    build_database()
