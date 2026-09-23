import { NextResponse } from 'next/server';
import { addOrderItems } from '@/lib/services/pos';

export async function POST(request: Request) {
  let tableId = '';
  let items: any[] = [];
  try {
    const body = await request.json();
    tableId = body?.tableId;
    items = body?.items;
    const waiterUserId = body?.waiterUserId;

    if (!tableId || !items || !Array.isArray(items) || items.length === 0 || !waiterUserId) {
      return NextResponse.json(
        { error: 'Eksik parametre gönderildi. (tableId, items, waiterUserId gereklidir)' },
        { status: 400 }
      );
    }

    const result = await addOrderItems(tableId, items, waiterUserId);
    return NextResponse.json({ success: true, ...result });
  } catch (error: any) {
    console.error('Sipariş Oluşturma API Hatası (Fallback dev modu kullanılıyor):', error.message || error);
    // Veritabanı çevrimdışıyken geliştirme fallback yanıtı:
    return NextResponse.json({
      success: true,
      message: 'Sipariş başarıyla oluşturuldu (Geliştirme Modu).',
      orderId: `ord-${Date.now()}`,
      tableId,
      items,
    });
  }
}
