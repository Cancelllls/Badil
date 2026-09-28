import { Hono } from 'hono';
import { cors } from 'hono/cors';

type Bindings = {
  DB: D1Database;
  ADMIN_PASSWORD?: string;
};

const app = new Hono<{ Bindings: Bindings }>();

app.use('*', cors());

// Health Check
app.get('/', (c) => {
  return c.json({
    service: 'badil-api',
    status: 'healthy',
    message: 'بَديل - منصة توثيق المنتجات والبدائل المصرية 🇪🇬',
  });
});

// 1. Ingest crowdsourced barcode submissions
app.post('/api/v1/submissions', async (c) => {
  try {
    const body = await c.req.json();
    const { id, barcode, product_name, brand_name, suggested_status, suggested_alternative, notes } = body;

    if (!barcode || !product_name || !suggested_status) {
      return c.json({ error: 'Missing required fields: barcode, product_name, suggested_status' }, 400);
    }

    const submissionId = id || `${Date.now()}_${barcode}`;
    const createdAt = Math.floor(Date.now() / 1000);

    await c.env.DB.prepare(
      `INSERT INTO submissions (id, barcode, product_name, brand_name, suggested_status, suggested_alternative, notes, status, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?)`
    )
      .bind(submissionId, barcode, product_name, brand_name || null, suggested_status, suggested_alternative || null, notes || null, createdAt)
      .run();

    return c.json({ success: true, id: submissionId }, 201);
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// 2. Fetch active sponsor spotlight banner
app.get('/api/v1/sponsors', async (c) => {
  try {
    const sponsor = await c.env.DB.prepare(
      `SELECT * FROM sponsors WHERE is_active = 1 ORDER BY created_at DESC LIMIT 1`
    ).first();

    if (sponsor) {
      return c.json(sponsor);
    }
  } catch (_) {}

  // Default fallback
  return c.json({
    id: 'spiro_official',
    brand_name: 'سبيرو سباتس (Spiro Spathis)',
    headline_ar: 'مشروب الصودا المصري الأصيل منذ 1920',
    description_ar: 'ادعم الصناعة الوطنية واكتشف أحدث النكهات المنعشة في أقرب متجر إليك.',
    promo_code: 'EGYPT100',
    cta_url: 'https://cancellls.com',
    category: 'beverages',
  });
});

// 3. Delta Updates for mobile clients
app.get('/api/v1/updates', async (c) => {
  const since = parseInt(c.req.query('since') || '0', 10);

  try {
    const products = await c.env.DB.prepare(
      `SELECT * FROM delta_products WHERE created_at > ? ORDER BY created_at ASC`
    )
      .bind(since)
      .all();

    const alternatives = await c.env.DB.prepare(
      `SELECT * FROM delta_alternatives`
    ).all();

    return c.json({
      timestamp: Math.floor(Date.now() / 1000),
      products: products.results || [],
      alternatives: alternatives.results || [],
    });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

// 4. Web Admin Dashboard (Clean, responsive HTML)
app.get('/admin', async (c) => {
  const key = c.req.query('key');
  const expectedPassword = c.env.ADMIN_PASSWORD || 'badil-secure-admin-pass';

  if (key !== expectedPassword) {
    return c.html(`
      <!DOCTYPE html>
      <html dir="rtl" lang="ar">
      <head>
        <meta charset="utf-8">
        <title>تسجيل دخول الإدارة | بَديل</title>
        <script src="https://cdn.tailwindcss.com"></script>
      </head>
      <body class="bg-slate-900 text-white flex items-center justify-center min-h-screen p-4">
        <div class="bg-slate-800 p-8 rounded-2xl max-w-sm w-full border border-slate-700 shadow-2xl">
          <h1 class="text-2xl font-bold mb-4 text-emerald-400 text-center">لوحة إدارة بَديل 🇪🇬</h1>
          <form method="GET" action="/admin">
            <label class="block text-sm mb-2 text-slate-300">أدخل كلمة المرور:</label>
            <input type="password" name="key" required class="w-full px-4 py-2.5 rounded-xl bg-slate-900 border border-slate-700 mb-4 focus:outline-none focus:border-emerald-500">
            <button type="submit" class="w-full bg-emerald-500 hover:bg-emerald-600 font-bold py-2.5 rounded-xl transition">دخول</button>
          </form>
        </div>
      </body>
      </html>
    `, 401);
  }

  // Fetch pending submissions and sponsors
  const pendingSubmissions = await c.env.DB.prepare(
    `SELECT * FROM submissions WHERE status = 'pending' ORDER BY created_at DESC LIMIT 50`
  ).all();

  const sponsors = await c.env.DB.prepare(
    `SELECT * FROM sponsors ORDER BY created_at DESC LIMIT 5`
  ).all();

  return c.html(`
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>لوحة إدارة بَديل 🇪🇬</title>
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-slate-900 text-slate-100 min-h-screen p-6">
      <div class="max-w-6xl mx-auto">
        <header class="flex flex-wrap justify-between items-center pb-6 mb-8 border-b border-slate-800 gap-4">
          <div>
            <h1 class="text-3xl font-extrabold text-emerald-400 flex items-center gap-2">
              <span>🇪🇬</span> لوحة إدارة بَديل (Badil)
            </h1>
            <p class="text-slate-400 text-sm mt-1">مراجعة اقتراحات المستخدمين وإدارة رعايات البدائل الوطنية</p>
          </div>
          <div class="bg-slate-800 px-4 py-2 rounded-xl border border-slate-700 text-sm">
            اقتراحات قيد المراجعة: <span class="font-bold text-emerald-400">${(pendingSubmissions.results || []).length}</span>
          </div>
        </header>

        <!-- Submissions Table -->
        <section class="bg-slate-800 rounded-2xl border border-slate-700 overflow-hidden shadow-xl mb-10">
          <div class="p-5 border-b border-slate-700 flex justify-between items-center">
            <h2 class="text-xl font-bold text-white flex items-center gap-2">
              <span>📦</span> اقتراحات المنتجات الجديدة المعلقة
            </h2>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-right text-sm">
              <thead class="bg-slate-900/60 text-slate-400 border-b border-slate-700">
                <tr>
                  <th class="p-4">الباركود</th>
                  <th class="p-4">اسم المنتج</th>
                  <th class="p-4">الحالة المقترحة</th>
                  <th class="p-4">البديل المقترح</th>
                  <th class="p-4">ملاحظات</th>
                  <th class="p-4">إجراء</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-700/60">
                ${
                  (pendingSubmissions.results || []).length === 0
                    ? `<tr><td colspan="6" class="p-8 text-center text-slate-500">لا توجد اقتراحات معلقة حالياً 🎉</td></tr>`
                    : (pendingSubmissions.results || [])
                        .map(
                          (item: any) => `
                    <tr class="hover:bg-slate-750 transition">
                      <td class="p-4 font-mono text-emerald-400 font-bold">${item.barcode}</td>
                      <td class="p-4 font-bold text-white">${item.product_name} <span class="text-xs text-slate-400 block">${item.brand_name || ''}</span></td>
                      <td class="p-4">
                        <span class="px-2.5 py-1 rounded-full text-xs font-bold ${
                          item.suggested_status === 'boycott' ? 'bg-red-500/20 text-red-400 border border-red-500/40' : 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/40'
                        }">
                          ${item.suggested_status === 'boycott' ? 'مقاطعة 🛑' : 'بديل محلي 🟢'}
                        </span>
                      </td>
                      <td class="p-4 text-emerald-300 font-medium">${item.suggested_alternative || '—'}</td>
                      <td class="p-4 text-slate-400 text-xs">${item.notes || '—'}</td>
                      <td class="p-4 flex gap-2">
                        <form method="POST" action="/admin/action?key=${key}">
                          <input type="hidden" name="id" value="${item.id}">
                          <input type="hidden" name="action" value="approve">
                          <button type="submit" class="bg-emerald-600 hover:bg-emerald-500 text-white px-3 py-1.5 rounded-lg text-xs font-bold transition">اعتماد</button>
                        </form>
                        <form method="POST" action="/admin/action?key=${key}">
                          <input type="hidden" name="id" value="${item.id}">
                          <input type="hidden" name="action" value="reject">
                          <button type="submit" class="bg-rose-600 hover:bg-rose-500 text-white px-3 py-1.5 rounded-lg text-xs font-bold transition">رفض</button>
                        </form>
                      </td>
                    </tr>
                  `
                        )
                        .join('')
                }
              </tbody>
            </table>
          </div>
        </section>

        <!-- Sponsors Management -->
        <section class="bg-slate-800 rounded-2xl border border-slate-700 p-6 shadow-xl">
          <h2 class="text-xl font-bold text-white mb-4 flex items-center gap-2">
            <span>📢</span> إعلانات ورعايات البدائل الوطنية
          </h2>
          <div class="grid md:grid-cols-2 gap-4">
            ${(sponsors.results || [])
              .map(
                (s: any) => `
              <div class="p-4 rounded-xl bg-slate-900 border border-amber-500/30">
                <div class="flex justify-between items-center mb-2">
                  <span class="text-amber-400 font-bold">${s.brand_name}</span>
                  <span class="text-xs bg-amber-500/10 text-amber-300 px-2 py-0.5 rounded border border-amber-500/20">${s.promo_code || 'كود خصم'}</span>
                </div>
                <p class="text-sm font-semibold text-white">${s.headline_ar}</p>
                <p class="text-xs text-slate-400 mt-1">${s.description_ar}</p>
              </div>
            `
              )
              .join('')}
          </div>
        </section>
      </div>
    </body>
    </html>
  `);
});

// 5. Admin Actions (Approve / Reject)
app.post('/admin/action', async (c) => {
  const key = c.req.query('key');
  const expectedPassword = c.env.ADMIN_PASSWORD || 'badil-secure-admin-pass';

  if (key !== expectedPassword) {
    return c.text('Unauthorized', 401);
  }

  const body = await c.req.parseBody();
  const id = body['id'] as string;
  const action = body['action'] as string;

  if (action === 'approve') {
    const submission: any = await c.env.DB.prepare(
      `SELECT * FROM submissions WHERE id = ?`
    ).bind(id).first();

    if (submission) {
      const now = Math.floor(Date.now() / 1000);
      const prodId = `delta_${submission.barcode}`;

      // Insert into delta_products
      await c.env.DB.prepare(
        `INSERT OR REPLACE INTO delta_products (id, barcode, name_ar, company_name, status, created_at)
         VALUES (?, ?, ?, ?, ?, ?)`
      )
        .bind(prodId, submission.barcode, submission.product_name, submission.brand_name || 'شركة غير محددة', submission.suggested_status, now)
        .run();

      await c.env.DB.prepare(
        `UPDATE submissions SET status = 'approved' WHERE id = ?`
      ).bind(id).run();
    }
  } else if (action === 'reject') {
    await c.env.DB.prepare(
      `UPDATE submissions SET status = 'rejected' WHERE id = ?`
    ).bind(id).run();
  }

  return c.redirect(`/admin?key=${key}`);
});

export default app;
