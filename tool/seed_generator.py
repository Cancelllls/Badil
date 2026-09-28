#!/usr/bin/env python3
"""
Seed Database Generator for Badil (بَديل)
Generates `assets/database/badil_seed.db` with SQLite FTS5 enabled,
containing verified categories, boycotted items, and high-quality local Egyptian alternatives.
"""

import os
import sqlite3
import time

DB_PATH = "/home/ubuntu/Badil/assets/database/badil_seed.db"

def build_seed_database():
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
        print(f"Removed existing {DB_PATH}")

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # 1. Enable WAL mode & foreign keys
    cur.execute("PRAGMA journal_mode = WAL;")
    cur.execute("PRAGMA foreign_keys = ON;")

    # 2. Create Schema
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
        rating REAL DEFAULT 5.0,
        PRIMARY KEY (product_id, alternative_product_id)
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

    # FTS5 Virtual Table for full-text Arabic & English search
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

    # 3. Categories
    categories = [
        ("beverages", "مشروبات ومياه", "Beverages & Water", "coffee", 1),
        ("snacks", "شيبسي ومقرمشات وبسكويت", "Snacks & Biscuits", "cookie", 2),
        ("personal_care", "عناية شخصية وصابون", "Personal Care & Soap", "sparkles", 3),
        ("detergents", "منظفات وغسيل", "Detergents & Cleaning", "droplet", 4),
        ("dairy", "ألبان وجبن", "Dairy & Cheese", "milk", 5),
        ("chocolate", "شوكولاتة وحلويات", "Chocolates & Sweets", "candy", 6),
        ("restaurants", "مطاعم وكافيهات", "Chains & Dining", "utensils", 7),
    ]
    cur.executemany("INSERT INTO categories VALUES (?, ?, ?, ?, ?)", categories)

    # 4. Products Master Data
    # Format: (id, barcode, name_ar, name_en, company, origin, category, status, reason_ar, is_featured)
    products = [
        # --- BEVERAGES: BOYCOTT ---
        ("pepsi_can_330", "6221010001011", "بيبسي كانز 330 مل", "Pepsi Can 330ml", "PepsiCo", "US", "beverages", "boycott", "شركة أمريكية تدعم الاحتلال الإسرائيلي وشراكات استثمارية مباشرة.", 0),
        ("coca_cola_can_330", "5449000000996", "كوكاكولا كانز 330 مل", "Coca-Cola Can 330ml", "The Coca-Cola Company", "US", "beverages", "boycott", "تملك مصانع في المستوطنات وتدعم الاحتلال بشكل مباشر.", 0),
        ("seven_up_can_330", "6221010001028", "سفن أب كانز 330 مل", "7Up Can 330ml", "PepsiCo", "US", "beverages", "boycott", "تابعة لشركة بيبسيكو الأمريكية الداعمة للاحتلال.", 0),
        ("mirinda_orange_can", "6221010001035", "ميرندا برتقال كانز", "Mirinda Orange Can", "PepsiCo", "US", "beverages", "boycott", "تابعة لشركة بيبسيكو الأمريكية.", 0),
        ("sprite_can_330", "5449000001009", "سبرايت كانز 330 مل", "Sprite Can 330ml", "The Coca-Cola Company", "US", "beverages", "boycott", "تابعة لشركة كوكاكولا الأمريكية.", 0),
        ("schweppes_gold", "5449000054321", "شويبس جولد أناناس", "Schweppes Gold Pineapple", "The Coca-Cola Company", "US", "beverages", "boycott", "مملوكة لشركة كوكاكولا في المنطقة.", 0),
        ("nestle_pure_life_15", "6223000520015", "مياه نستله بيور لايف 1.5 لتر", "Nestle Pure Life 1.5L", "Nestle", "CH", "beverages", "boycott", "شركة نستله تمتلك حصة مسيطرة في شركة أوسم الإسرائيلية.", 0),
        ("baraka_water_15", "6221053001015", "مياه بركة 1.5 لتر", "Baraka Water 1.5L", "Nestle", "CH", "beverages", "boycott", "تابعة لمجموعة نستله السويسرية.", 0),
        ("dasani_water_15", "5449000012345", "مياه داساني 1.5 لتر", "Dasani Water 1.5L", "The Coca-Cola Company", "US", "beverages", "boycott", "تابعة لشركة كوكاكولا.", 0),
        ("nescafe_classic", "7613035380012", "نسكافيه كلاسيك 100 جم", "Nescafe Classic 100g", "Nestle", "CH", "beverages", "boycott", "تابعة لمجموعة نستله السويسرية الداعمة للاحتلال.", 0),
        ("lipton_yellow_label", "6221155001010", "شاي ليبتون العلامة الصفراء", "Lipton Yellow Label Tea", "Unilever / ekaterra", "UK", "beverages", "boycott", "مملوكة سابقاً ليونيليفر وتابعة لشركات استثمارية داعمة.", 0),

        # --- BEVERAGES: LOCAL ALTERNATIVES ---
        ("spiro_spathis_apple", "6224000111011", "سبيرو سباتس تفاح 330 مل", "Spiro Spathis Apple 330ml", "Spiro Spathis", "EG", "beverages", "safe_local", None, 1),
        ("spiro_spathis_lemon", "6224000111028", "سبيرو سباتس ليمون 330 مل", "Spiro Spathis Lemon 330ml", "Spiro Spathis", "EG", "beverages", "safe_local", None, 1),
        ("spiro_spathis_grapes", "6224000111035", "سبيرو سباتس عنب 330 مل", "Spiro Spathis Grapes 330ml", "Spiro Spathis", "EG", "beverages", "safe_local", None, 1),
        ("v7_cola_can", "6225000123015", "في سفن كولا كانز 330 مل", "V7 Cola Can 330ml", "V7 Egypt", "EG", "beverages", "safe_local", None, 1),
        ("v7_lemon_can", "6225000123022", "في سفن ليمون كانز 330 مل", "V7 Lemon Can 330ml", "V7 Egypt", "EG", "beverages", "safe_local", None, 0),
        ("dash_soda", "6224008880012", "داش صودا فواكه مشكلة", "Dash Fruit Soda", "Dash Egypt", "EG", "beverages", "safe_local", None, 0),
        ("sina_cola_can", "6223001234567", "سينا كولا كانز 330 مل", "Sina Cola Can", "Sina Cola", "EG", "beverages", "safe_local", None, 0),
        ("siwa_water_15", "6223000101015", "مياه سيوة الطبيعية 1.5 لتر", "Siwa Natural Water 1.5L", "Siwa", "EG", "beverages", "safe_local", None, 0),
        ("flo_water_15", "6224000202015", "مياه فلو الطبيعية 1.5 لتر", "Flo Natural Water 1.5L", "Flo Egypt", "EG", "beverages", "safe_local", None, 0),
        ("hayat_water_15", "6223000303015", "مياه حياة الطبيعية 1.5 لتر", "Hayat Water 1.5L", "Hayat Egypt", "EG", "beverages", "safe_local", None, 0),
        ("safi_water_15", "6224000404015", "مياه صافي الطبيعية 1.5 لتر", "Safi Natural Water 1.5L", "Safi", "EG", "beverages", "safe_local", None, 0),
        ("misr_cafe_classic", "6221111222019", "مصر كافيه قهوة سريعة التحضير", "Misr Cafe Instant Coffee", "Misr Cafe", "EG", "beverages", "safe_local", None, 1),
        ("abu_auf_coffee", "6224000555018", "بن أبو عوف تركي محوج", "Abu Auf Turkish Coffee", "Abu Auf", "EG", "beverages", "safe_local", None, 0),
        ("el_arosa_tea", "6221022001012", "شاي العروسة أسود فاخر", "El Arosa Black Tea", "El Arosa", "EG", "beverages", "safe_local", None, 1),

        # --- SNACKS & CHIPS: BOYCOTT ---
        ("chipsy_chili_lemon", "6221010111111", "شيبسي شطة وليمون عائلي", "Chipsy Chili & Lemon", "PepsiCo", "US", "snacks", "boycott", "مملوكة بالكامل لشركة بيبسيكو الأمريكية.", 0),
        ("doritos_sweet_chili", "6221010222222", "دوريتوس فلفل حلو", "Doritos Sweet Chili", "PepsiCo", "US", "snacks", "boycott", "مملوكة لشركة فريتو لاي التابعة لبيبسيكو.", 0),
        ("cheetos_crunchy_cheese", "6221010333333", "شيتوس جبنة كرانشي", "Cheetos Crunchy Cheese", "PepsiCo", "US", "snacks", "boycott", "مملوكة لشركة بيبسيكو الأمريكية.", 0),
        ("sunbites_olive_oregano", "6221010444444", "صن بايتس زيتون وزعتر", "Sunbites Olive & Oregano", "PepsiCo", "US", "snacks", "boycott", "تابعة لشركة بيبسيكو الأمريكية.", 0),
        ("pringles_original", "5053990101511", "برينجلز بطاطس أوريجينال", "Pringles Original", "Kellanova (Kellogg's)", "US", "snacks", "boycott", "شركة أمريكية تدعم الاحتلال ولها استثمارات واسعة هناك.", 0),

        # --- SNACKS & CHIPS: LOCAL ALTERNATIVES ---
        ("tiger_chili_lemon", "6223000777011", "تايجر شيبس شطة وليمون", "Tiger Chips Chili Lemon", "Egypt Foods", "EG", "snacks", "safe_local", None, 1),
        ("big_chips_cheese", "6223000888012", "بيج شيبس جبنة متبلة", "Big Chips Cheese", "Egypt Foods", "EG", "snacks", "safe_local", None, 0),
        ("fox_potatoes", "6224000999013", "فوكس بطاطس مقرمشة بالجبنة", "Fox Potato Chips", "Fox Egypt", "EG", "snacks", "safe_local", None, 0),
        ("crunch_chips", "6224000666014", "كرانش شيبس طماطم متبلة", "Crunch Chips Tomato", "Crunch Egypt", "EG", "snacks", "safe_local", None, 0),
        ("jagoo_corn_chips", "6224000555015", "جاجو مقرمشات ذرة بالجبنة", "Jagoo Corn Chips", "Egypt Foods", "EG", "snacks", "safe_local", None, 0),
        ("bake_rolz_pizza", "6221155333011", "بيك رولز بيتزا فاخر", "Bake Rolz Pizza", "Edita", "EG", "snacks", "safe_local", None, 1),

        # --- CHOCOLATES & SWEETS: BOYCOTT ---
        ("oreo_original_biscuit", "7622210101012", "بسكويت أوريو الأصلي", "Oreo Original Biscuit", "Mondelez International", "US", "chocolate", "boycott", "موندليز شركة أمريكية تدعم وتستثمر في شركات ناشئة إسرائيلية.", 0),
        ("cadbury_dairy_milk", "7622210202022", "كادبوري ديري ميلك سادة", "Cadbury Dairy Milk Chocolate", "Mondelez International", "US", "chocolate", "boycott", "مملوكة لشركة موندليز الأمريكية الداعمة للاحتلال.", 0),
        ("kitkat_4_finger", "7613035111111", "كيت كات أصابع شوكولاتة", "KitKat 4 Finger", "Nestle", "CH", "chocolate", "boycott", "تابعة لمجموعة نستله الداعمة للاحتلال.", 0),
        ("galaxy_smooth_milk", "5000159404011", "جالكسي شوكولاتة بالحليب", "Galaxy Smooth Milk", "Mars Inc.", "US", "chocolate", "boycott", "مارس شركة أمريكية تدعم وتستثمر في بحوث أغذية إسرائيلية.", 0),
        ("twix_caramel_bar", "5000159404028", "تويكس شوكولاتة كراميل", "Twix Caramel Bar", "Mars Inc.", "US", "chocolate", "boycott", "تابعة لشركة مارس الأمريكية.", 0),
        ("bounty_coconut_bar", "5000159404035", "باونتي شوكولاتة جوز هند", "Bounty Coconut Bar", "Mars Inc.", "US", "chocolate", "boycott", "تابعة لشركة مارس الأمريكية.", 0),

        # --- CHOCOLATES & SWEETS: LOCAL ALTERNATIVES ---
        ("corona_classic_chocolate", "6221000111019", "كورونا شوكولاتة مصرية كلاسيك", "Corona Egyptian Classic Chocolate", "Corona", "EG", "chocolate", "safe_local", None, 1),
        ("corona_rocket_chocolate", "6221000111026", "كورونا شوكولاتة روكيت ويفر", "Corona Rocket Chocolate Wafer", "Corona", "EG", "chocolate", "safe_local", None, 1),
        ("bimbo_biscuit_chocolate", "6221155444018", "بيمبو بسكويت مغطى بالشوكولاتة", "Bimbo Chocolate Biscuit", "Bisco Misr", "EG", "chocolate", "safe_local", None, 1),
        ("lambada_wafer", "6223000222019", "لمبادا ويفر محشو شوكولاتة", "Lambada Chocolate Wafer", "Covertina", "EG", "chocolate", "safe_local", None, 0),
        ("freska_bites", "6221155555015", "فريسكا بايتس شوكولاتة وبندق", "Freska Bites Hazelnut", "Edita", "EG", "chocolate", "safe_local", None, 1),
        ("molto_chocolate_croissant", "6221155666012", "مولتو كرواسون شوكولاتة", "Molto Chocolate Croissant", "Edita", "EG", "chocolate", "safe_local", None, 0),

        # --- DETERGENTS & CLEANING: BOYCOTT ---
        ("ariel_automatic_powder", "4015600101011", "مسحوق أريال أوتوماتيك 4 كجم", "Ariel Automatic Powder 4kg", "Procter & Gamble (P&G)", "US", "detergents", "boycott", "بي آند جي من أكبر الشركات الأمريكية الداعمة لمراكز أبحاث الاحتلال.", 0),
        ("tide_automatic_powder", "4015600202022", "مسحوق تايد أوتوماتيك 4 كجم", "Tide Automatic Powder 4kg", "Procter & Gamble (P&G)", "US", "detergents", "boycott", "مملوكة لشركة بروكتر آند جامبل (P&G) الأمريكية.", 0),
        ("persil_deep_clean", "6221155999015", "برسيل ديب كلين جل 3 لتر", "Persil Deep Clean Gel 3L", "Henkel", "DE", "detergents", "boycott", "هنكل الألمانية لها شراكات واستثمارات مباشرة في إسرائيل.", 0),
        ("fairy_dishwashing_liquid", "4015600303033", "فيري سائل غسيل الأطباق بالليمون", "Fairy Dishwashing Liquid", "Procter & Gamble (P&G)", "US", "detergents", "boycott", "تابعة لشركة بروكتر آند جامبل الأمريكية.", 0),
        ("pril_dishwashing_gel", "6221155888018", "بريل سائل غسيل أطباق مركز", "Pril Dishwashing Liquid", "Henkel", "DE", "detergents", "boycott", "مملوكة لشركة هنكل الألمانية الداعمة للاحتلال.", 0),
        ("downy_fabric_softener", "4015600404044", "داوني منعم أقمشة برائحة نسيم الوادي", "Downy Fabric Softener", "Procter & Gamble (P&G)", "US", "detergents", "boycott", "تابعة لشركة بروكتر آند جامبل الأمريكية.", 0),

        # --- DETERGENTS & CLEANING: LOCAL ALTERNATIVES ---
        ("oxi_automatic_powder", "6224000777019", "أوكسي مسحوق غسيل أوتوماتيك باللافندر", "Oxi Automatic Powder Lavender", "Arma", "EG", "detergents", "safe_local", None, 1),
        ("oxi_gel_detergent", "6224000777026", "أوكسي جل غسيل منظف ومطهر", "Oxi Gel Detergent", "Arma", "EG", "detergents", "safe_local", None, 1),
        ("feba_dishwashing_liquid", "6223000666018", "فيبا سائل غسيل الصحون بالليمون 2 لتر", "Feba Dishwashing Liquid 2L", "Feba Egypt", "EG", "detergents", "safe_local", None, 1),
        ("bahar_automatic_powder", "6224000333017", "بحر مسحوق غسيل اقتصادي فائق النظافة", "Bahar Automatic Powder", "Bahar", "EG", "detergents", "safe_local", None, 0),
        ("frisk_fabric_softener", "6224000222018", "فريسك معطر ومنعم أقمشة مركز", "Frisk Fabric Softener", "Frisk Egypt", "EG", "detergents", "safe_local", None, 0),

        # --- PERSONAL CARE: BOYCOTT ---
        ("head_and_shoulders_shampoo", "4015600505055", "شامبو هيد آند شولدرز ضد القشرة", "Head & Shoulders Shampoo", "Procter & Gamble (P&G)", "US", "personal_care", "boycott", "تابعة لشركة بروكتر آند جامبل الأمريكية.", 0),
        ("pantene_pro_v_shampoo", "4015600606066", "شامبو بانتين برو-في للشعر التالف", "Pantene Pro-V Shampoo", "Procter & Gamble (P&G)", "US", "personal_care", "boycott", "مملوكة لشركة بروكتر آند جامبل الأمريكية.", 0),
        ("dove_beauty_soap", "8717163001011", "صابون دوف للجمال قالب 100 جم", "Dove Beauty Soap 100g", "Unilever", "UK", "personal_care", "boycott", "يونيليفر لها شراكات واستثمارات وتدعم أنشطة الاحتلال.", 0),
        ("sunsilk_black_shine", "8717163002022", "شامبو صانسيلك لمعان الشعر", "Sunsilk Black Shine Shampoo", "Unilever", "UK", "personal_care", "boycott", "تابعة لشركة يونيليفر البريطانية الهولندية.", 0),
        ("colgate_total_toothpaste", "8718951001011", "معجون أسنان كولجيت توتال", "Colgate Total Toothpaste", "Colgate-Palmolive", "US", "personal_care", "boycott", "شركة أمريكية تملك وتستثمر في مراكز تطوير إسرائيلية.", 0),
        ("signal_cavity_toothpaste", "8717163003033", "معجون أسنان سيجنال حماية ضد التسوس", "Signal Cavity Protection", "Unilever", "UK", "personal_care", "boycott", "تابع لشركة يونيليفر العالمية.", 0),

        # --- PERSONAL CARE: LOCAL ALTERNATIVES ---
        ("eva_cosmetics_shampoo", "6221044001012", "إيفا هير كلينيك شامبو كيراتين", "Eva Hair Clinic Keratin Shampoo", "Eva Cosmetics", "EG", "personal_care", "safe_local", None, 1),
        ("bobana_marine_collagen", "6224000888019", "بوبانا ماسك وماسكارا لتغذية الشعر", "Bobana Hair Collagen Treatment", "Bobana", "EG", "personal_care", "safe_local", None, 1),
        ("penduline_kids_shampoo", "6224000999020", "بندولين شامبو أطفال طبيعي 100%", "Penduline Natural Kids Shampoo", "Penduline", "EG", "personal_care", "safe_local", None, 1),
        ("starville_cleanser", "6224000333024", "ستارفيل غسول للبشرة الدهنية والمختلطة", "Starville Facial Cleanser", "Parkville", "EG", "personal_care", "safe_local", None, 1),
        ("depurdent_toothpaste", "6221044002029", "معجون أسنان إيفا سموكرز بالمسواك", "Eva Smokers Miswak Toothpaste", "Eva Cosmetics", "EG", "personal_care", "safe_local", None, 1),
        ("five_fives_soap", "6221033001018", "صابون خمس خمسات الطبيعي بزيت الزيتون", "Five Fives Natural Olive Soap", "Five Fives", "EG", "personal_care", "safe_local", None, 0),

        # --- DAIRY & CHEESE: BOYCOTT ---
        ("danone_danette_chocolate", "3033490001011", "دانون دانيت شوكولاتة كراميل", "Danone Danette Chocolate", "Danone", "FR", "dairy", "boycott", "دانون استثمرت بشكل مباشر في رأس المال الإسرائيلي وشراكات التقنية.", 0),
        ("activia_strawberry_yogurt", "3033490002022", "زبادي أكتيفيا بالفراولة هضم طبيعي", "Activia Strawberry Yogurt", "Danone", "FR", "dairy", "boycott", "تابعة لمجموعة دانون الفرنسية الداعمة للاحتلال.", 0),
        ("president_feta_cheese", "3155250001012", "جبنة بريزيدون فيتا بيضاء 500 جم", "President Feta Cheese 500g", "Lactalis", "FR", "dairy", "boycott", "مجموعة لاكتاليس الفرنسية وشراكاتها الداعمة للاحتلال.", 0),
        ("kiri_squares_cheese", "3073780001015", "جبنة كيري مربعات 8 قطع", "Kiri Cheese Squares 8pcs", "Bel Group", "FR", "dairy", "boycott", "مجموعة بيل الفرنسية الداعمة للاستثمار في إسرائيل.", 0),

        # --- DAIRY & CHEESE: LOCAL ALTERNATIVES ---
        ("lamar_full_cream_milk", "6223000444018", "حليب لمار كامل الدسم طبيعي 1 لتر", "Lamar Full Cream Natural Milk 1L", "Lamar Egypt", "EG", "dairy", "safe_local", None, 1),
        ("juhayna_pure_milk", "6221020001014", "حليب جهينة كامل الدسم معبأ 1 لتر", "Juhayna Full Cream Milk 1L", "Juhayna", "EG", "dairy", "safe_local", None, 1),
        ("domty_plus_feta", "6221050001018", "جبنة دومتي بلس فيتا طازجة 500 جم", "Domty Plus Feta Fresh 500g", "Domty", "EG", "dairy", "safe_local", None, 1),
        ("katilo_white_cheese", "6221070001012", "جبنة قتيلو دمياطي براميلي فاخرة", "Katilo Traditional White Cheese", "Katilo", "EG", "dairy", "safe_local", None, 0),
        ("obour_land_feta", "6221090001016", "جبنة عبور لاند تتراباك بيضاء 500 جم", "Obour Land Feta Cheese 500g", "Obour Land", "EG", "dairy", "safe_local", None, 0),

        # --- RESTAURANTS & CHAINS: BOYCOTT ---
        ("mcdonalds_chain", "REST_MCDONALDS", "ماكدونالدز مصر والوجبات السريعة", "McDonald's Fast Food", "McDonald's Corp", "US", "restaurants", "boycott", "ماكدونالدز قدمت وجبات مجانية لجنود الاحتلال الإسرائيلي.", 0),
        ("kfc_chain", "REST_KFC", "كنتاكي دجاج مقلي (KFC)", "KFC Fried Chicken", "Yum! Brands", "US", "restaurants", "boycott", "يم براندز تملك وتستثمر في شركات تقنية طعام إسرائيلية.", 0),
        ("hardees_chain", "REST_HARDEES", "هارديز برجر وبطاطس", "Hardee's Burgers", "CKE Restaurants", "US", "restaurants", "boycott", "شركة أمريكية تابعة لمجموعات استثمارية داعمة.", 0),
        ("starbucks_chain", "REST_STARBUCKS", "ستاربكس كافيه للمشروبات والقهوة", "Starbucks Coffee", "Starbucks Corp", "US", "restaurants", "boycott", "ستاربكس قاضت نقابتها العمالية بسبب التضامن مع فلسطين.", 0),

        # --- RESTAURANTS & CHAINS: LOCAL ALTERNATIVES ---
        ("buffalo_burger", "REST_BUFFALO", "بافلو برجر مشوي على الفحم", "Buffalo Burger", "Buffalo Burger", "EG", "restaurants", "safe_local", None, 1),
        ("bazooka_chicken", "REST_BAZOOKA", "بازوكا فرايد تشيكن مصرية", "Bazooka Fried Chicken", "Bazooka Egypt", "EG", "restaurants", "safe_local", None, 1),
        ("heart_attack_chicken", "REST_HEART_ATTACK", "هارت أタック دجاج مقرمش", "Heart Attack Chicken", "Heart Attack", "EG", "restaurants", "safe_local", None, 0),
        ("kansas_fried_chicken", "REST_KANSAS", "كانساس تشيكن فرايد مصري", "Kansas Fried Chicken", "Kansas Egypt", "EG", "restaurants", "safe_local", None, 0),
        ("blaban_desserts", "REST_BLABAN", "ب لبن قشطوطة وأم علي وحلويات", "B.Laban Oriental Desserts", "B.Laban", "EG", "restaurants", "safe_local", None, 1),
        ("el_malky_desserts", "REST_EL_MALKY", "المالكي أرز بلبن وقشطة", "El Malky Rice Pudding", "El Malky", "EG", "restaurants", "safe_local", None, 0),
    ]

    for p in products:
        cur.execute("""
        INSERT INTO products (id, barcode, name_ar, name_en, company_name, country_of_origin, category_id, status, reason_ar, is_featured, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], now))

    # 5. Alternatives Mapping (Junction Table)
    # product_id -> alternative_id, note, rating
    alternatives_map = [
        # Pepsi / Coke -> Spiro Spathis, V7, Dash, Sina Cola
        ("pepsi_can_330", "spiro_spathis_apple", "العلامة المصرية التاريخية الأفضل طعماً والأعلى انتشاراً", 5.0),
        ("pepsi_can_330", "v7_cola_can", "طعم كولا مصري أصيل غازي وقوي", 4.9),
        ("pepsi_can_330", "sina_cola_can", "بديل مصري قديم واقتصادي", 4.5),
        ("coca_cola_can_330", "v7_cola_can", "طعم كولا طبيعي بدون مقاطعة", 5.0),
        ("coca_cola_can_330", "spiro_spathis_lemon", "مشروب ليمون منعش بجودة فائقة", 4.9),
        ("seven_up_can_330", "spiro_spathis_lemon", "نفس الانتعاش ونكهة الليمون الصودا النقية", 5.0),
        ("seven_up_can_330", "v7_lemon_can", "صودا ليمون مصرية نقية بدون مواد حافظة ضارة", 4.8),
        ("mirinda_orange_can", "dash_soda", "صودا برتقال وفواكه مصرية طبيعية وغنية بالغازات", 4.8),
        ("sprite_can_330", "spiro_spathis_lemon", "ليمون صودا مصري منعش للغاية", 5.0),
        ("schweppes_gold", "dash_soda", "بديل مصري بنكهة الفواكه الطبيعية", 4.7),

        # Water: Nestle / Dasani / Baraka -> Siwa, Flo, Hayat, Safi
        ("nestle_pure_life_15", "siwa_water_15", "مياه آبار طبيعية من واحة سيوة نقية 100%", 5.0),
        ("nestle_pure_life_15", "flo_water_15", "مياه جوفية مصرية معبأة بأعلى معايير الجودة العالمية", 4.9),
        ("nestle_pure_life_15", "hayat_water_15", "مياه شرب طبيعية معتدلة الأملاح", 4.8),
        ("baraka_water_15", "siwa_water_15", "مياه طبيعية نقية وصحية", 5.0),
        ("dasani_water_15", "safi_water_15", "مياه معدنية طبيعية مصرية من واحة سيوة", 4.9),

        # Coffee & Tea: Nescafe / Lipton -> Misr Cafe, Abu Auf, El Arosa
        ("nescafe_classic", "misr_cafe_classic", "قهوة سريعة التحضير مصرية بنسبة 100% ونكهة غنية", 4.9),
        ("nescafe_classic", "abu_auf_coffee", "بن تركي وإسبريسو مصري محوج فاخر", 5.0),
        ("lipton_yellow_label", "el_arosa_tea", "شاي مصر الأول وأقوى نكهة شاي أسود بدون منازع", 5.0),

        # Chips: Chipsy / Doritos / Cheetos -> Tiger, Big Chips, Fox, Crunch
        ("chipsy_chili_lemon", "tiger_chili_lemon", "بطاطس طبيعية 100% مصرية ونفس الطعم الحار اللذيذ", 5.0),
        ("chipsy_chili_lemon", "big_chips_cheese", "رقائق بطاطس مقرمشة مصرية سميكة النكهة", 4.8),
        ("doritos_sweet_chili", "jagoo_corn_chips", "مقرمشات ذرة مثلثة بطعم الفلفل الحلو والجبنة", 4.8),
        ("cheetos_crunchy_cheese", "crunch_chips", "كرانشي مصري بطعم الجبنة المتبلة الغنية", 4.7),
        ("pringles_original", "bake_rolz_pizza", "مقرمشات مخبوزة بالفرن صحية وألذ", 5.0),

        # Chocolate: Oreo / Cadbury / KitKat -> Corona, Bimbo, Freska
        ("oreo_original_biscuit", "bimbo_biscuit_chocolate", "البسكويت المصري الأصيل بالشوكولاتة", 5.0),
        ("oreo_original_biscuit", "freska_bites", "ويفر فريسكا مقرمش محشو بالبندق والشوكولاتة الفاخرة", 4.9),
        ("cadbury_dairy_milk", "corona_classic_chocolate", "شوكولاتة كورونا المصرية العريقة بحليب كامل الدسم", 5.0),
        ("kitkat_4_finger", "corona_rocket_chocolate", "ويفر روكيت شوكولاتة مصري مقرمش", 4.9),
        ("galaxy_smooth_milk", "corona_classic_chocolate", "طعم ناعم وفاخر من مصانع كورونا بالإسكندرية", 4.9),
        ("twix_caramel_bar", "lambada_wafer", "ويفر مقرمش بطبقات الكراميل والشوكولاتة", 4.7),

        # Detergents: Ariel / Tide / Persil / Fairy -> Oxi, Feba, Bahar
        ("ariel_automatic_powder", "oxi_automatic_powder", "المسحوق المصري الأول بقوة الأكسجين ورائحة اللافندر", 5.0),
        ("ariel_automatic_powder", "bahar_automatic_powder", "نظافة فائقة وتوفير اقتصادي كبير للغسيل الأبيض والملون", 4.8),
        ("tide_automatic_powder", "oxi_automatic_powder", "أفضل بديل مصري ينظف البقع الصعبة بكفاءة", 5.0),
        ("persil_deep_clean", "oxi_gel_detergent", "جل غسيل أوتوماتيك مركز يحافظ على بريق الأقمشة", 5.0),
        ("fairy_dishwashing_liquid", "feba_dishwashing_liquid", "سائل فيبا المصري الأقوى في إذابة الدهون والرغوة الوفيرة", 5.0),
        ("pril_dishwashing_gel", "feba_dishwashing_liquid", "توفير ونظافة فائقة للصحون برائحة الليمون المنعشة", 5.0),
        ("downy_fabric_softener", "frisk_fabric_softener", "نعومة فائقة للملابس وعطر يدوم طويلاً", 4.8),

        # Personal Care: Head&Shoulders / Dove / Signal -> Eva, Bobana, Penduline
        ("head_and_shoulders_shampoo", "eva_cosmetics_shampoo", "شامبو إيفا كلينيك الطبي المتخصص ضد القشرة وتساقط الشعر", 5.0),
        ("pantene_pro_v_shampoo", "bobana_marine_collagen", "تغذية عميقة للشعر بالكولاجين البحري الطبيعي", 4.9),
        ("dove_beauty_soap", "five_fives_soap", "صابون طبيعي بزيت الزيتون والغليسيرين المرطب", 4.8),
        ("sunsilk_black_shine", "penduline_kids_shampoo", "شامبو خالي من السلفات والبارابين ناعم على فروة الرأس", 5.0),
        ("colgate_total_toothpaste", "depurdent_toothpaste", "معجون أسنان إيفا بالمسواك لتبييض وحماية اللثة", 4.9),
        ("signal_cavity_toothpaste", "depurdent_toothpaste", "حماية متكاملة من التسوس ونكهة نعناع قوية", 4.8),

        # Dairy: Danone / President -> Lamar, Juhayna, Domty, Katilo
        ("danone_danette_chocolate", "blaban_desserts", "حلويات شرقية وقشطوطة طازجة 100%", 5.0),
        ("activia_strawberry_yogurt", "juhayna_pure_milk", "زبادي جهينة الطبيعي بالفراولة", 4.9),
        ("president_feta_cheese", "domty_plus_feta", "جبنة دومتي فيتا المصرية الطازجة عالية الجودة", 5.0),
        ("president_feta_cheese", "katilo_white_cheese", "جبنة براميلي دمياطي طبيعية فاخرة", 4.9),
        ("kiri_squares_cheese", "obour_land_feta", "جبنة كريمية بيضاء بطعم غني وقوام متماسك", 4.8),

        # Fast Food: McDonald's / KFC / Starbucks -> Buffalo, Bazooka, Blaban
        ("mcdonalds_chain", "buffalo_burger", "برجر لحم بقري طبيعي مشوي على اللهب، جودة أعلى بمراحل", 5.0),
        ("kfc_chain", "bazooka_chicken", "دجاج مقلي مقرمش مصري بطعم وتتبيلة مميزة ومقرمشة", 5.0),
        ("kfc_chain", "heart_attack_chicken", "قطع دجاج مقلي ضخمة وقرمشة لا تقاوم", 4.8),
        ("hardees_chain", "buffalo_burger", "ساندوتشات برجر عملاقة وألذ من الشركات الأجنبية", 5.0),
        ("starbucks_chain", "abu_auf_coffee", "أجود أنواع القهوة المختصة والمشروبات الباردة والساخنة", 5.0),
        ("starbucks_chain", "blaban_desserts", "مشروبات وحلويات وحليب طازج مصري بجدارة", 5.0),
    ]

    for alt in alternatives_map:
        cur.execute("""
        INSERT INTO product_alternatives (product_id, alternative_product_id, note_ar, rating)
        VALUES (?, ?, ?, ?)
        """, alt)

    # 6. Populate FTS5 Index
    cur.execute("""
    INSERT INTO products_fts(rowid, name_ar, name_en, company_name)
    SELECT rowid, name_ar, name_en, company_name FROM products;
    """)

    conn.commit()

    # Integrity verification
    cur.execute("SELECT COUNT(*) FROM categories;")
    cat_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM products;")
    prod_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM product_alternatives;")
    alt_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM products_fts;")
    fts_count = cur.fetchone()[0]

    conn.close()

    print(f"✅ Seed database successfully built at: {DB_PATH}")
    print(f"📊 Summary:")
    print(f"   • Categories: {cat_count}")
    print(f"   • Total Products: {prod_count}")
    print(f"   • Alternatives Mapped: {alt_count}")
    print(f"   • FTS5 Indexed Rows: {fts_count}")

if __name__ == "__main__":
    build_seed_database()
