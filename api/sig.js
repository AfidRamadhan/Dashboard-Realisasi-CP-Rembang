// Vercel Serverless Function Proxy for SIG Intransit API
// Endpoint: /api/sig

export default async function handler(req, res) {
  // Set universal CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    let comp = '5000';
    let plant = '5401';

    if (req.body) {
      if (typeof req.body === 'object') {
        comp = req.body.comp || comp;
        plant = req.body.plant || plant;
      } else if (typeof req.body === 'string') {
        const params = new URLSearchParams(req.body);
        comp = params.get('comp') || comp;
        plant = params.get('plant') || plant;
      }
    }

    if (req.query) {
      comp = req.query.comp || comp;
      plant = req.query.plant || plant;
    }

    const targetUrl = 'https://app.sig.id/sgg/sd/intransit/index.php/dashboard/get_data_all';
    const formBody = new URLSearchParams({ comp, plant }).toString();

    const response = await fetch(targetUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'X-Requested-With': 'XMLHttpRequest',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      },
      body: formBody
    });

    if (!response.ok) {
      return res.status(response.status).json({
        error: `Gagal menghubungi SIG (HTTP ${response.status})`
      });
    }

    const data = await response.json();
    return res.status(200).json(data);
  } catch (error) {
    return res.status(502).json({
      error: 'Proxy Error: ' + error.message
    });
  }
}
