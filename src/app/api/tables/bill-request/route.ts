import { NextResponse } from 'next/server';
import { requestTableBill } from '@/lib/services/pos';

export async function POST(request: Request) {
  try {
    const { tableId } = await request.json();

    if (!tableId) {
      return NextResponse.json(
        { error: 'Masa ID (tableId) belirtilmelidir.' },
        { status: 400 }
      );
    }

    const table = await requestTableBill(tableId);
    return NextResponse.json({ success: true, table });
  } catch (error: any) {
    console.error('Hesap İste API Hatası (Fallback dev modu):', error.message || error);
    return NextResponse.json({ success: true, message: 'Hesap isteme talebi alındı (Geliştirme Modu).' });
  }
}
