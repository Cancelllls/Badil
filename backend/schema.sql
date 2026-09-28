-- Badil Cloudflare D1 Database Schema

CREATE TABLE IF NOT EXISTS submissions (
    id TEXT PRIMARY KEY,
    barcode TEXT NOT NULL,
    product_name TEXT NOT NULL,
    brand_name TEXT,
    suggested_status TEXT NOT NULL,
    suggested_alternative TEXT,
    notes TEXT,
    status TEXT DEFAULT 'pending', -- 'pending' | 'approved' | 'rejected'
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS delta_products (
    id TEXT PRIMARY KEY,
    barcode TEXT UNIQUE,
    name_ar TEXT NOT NULL,
    name_en TEXT,
    company_name TEXT NOT NULL,
    country_of_origin TEXT,
    category_id TEXT,
    status TEXT NOT NULL,
    reason_ar TEXT,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS delta_alternatives (
    product_id TEXT NOT NULL,
    alternative_product_id TEXT NOT NULL,
    note_ar TEXT,
    rating REAL DEFAULT 5.0,
    PRIMARY KEY (product_id, alternative_product_id)
);

CREATE TABLE IF NOT EXISTS sponsors (
    id TEXT PRIMARY KEY,
    brand_name TEXT NOT NULL,
    headline_ar TEXT NOT NULL,
    description_ar TEXT NOT NULL,
    promo_code TEXT,
    cta_url TEXT,
    category TEXT,
    is_active INTEGER DEFAULT 1,
    created_at INTEGER NOT NULL
);

-- Seed initial sponsor banner
INSERT OR REPLACE INTO sponsors (id, brand_name, headline_ar, description_ar, promo_code, cta_url, category, is_active, created_at)
VALUES (
    'spiro_official',
    'سبيرو سباتس (Spiro Spathis)',
    'مشروب الصودا المصري الأصيل منذ 1920',
    'ادعم الصناعة الوطنية واكتشف أحدث النكهات المنعشة في أقرب متجر إليك.',
    'EGYPT100',
    'https://cancellls.com',
    'beverages',
    1,
    strftime('%s', 'now')
);
