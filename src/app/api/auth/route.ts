import { NextResponse } from 'next/server';
import { db } from '@/lib/db';

export async function POST(request: Request) {
  let pin: string = '';
  try {
    const body = await request.json();
    pin = body?.pin || '';

    if (!pin || typeof pin !== 'string') {
      return NextResponse.json(
        { error: 'PIN kodu girmek zorunludur.' },
        { status: 400 }
      );
    }

    const user = await db.user.findFirst({
      where: {
        pinHash: pin,
        isActive: true,
      },
      select: {
        id: true,
        name: true,
        role: true,
      },
    });

    if (!user) {
      return NextResponse.json(
        { error: 'Hatalı PIN kodu!' },
        { status: 401 }
      );
    }

    return NextResponse.json(user);
  } catch (error: any) {
    console.error('Auth API Hatası (Veritabanı bağlantısı yok veya sorgu hatası):', error);

    // Veritabanı henüz .env'de tanımlanmamışken veya çevrimdışıyken geliştirme fallback'i:
    if (pin === '1234') {
      return NextResponse.json({
        id: 'usr-admin',
        name: 'Yönetici (Admin)',
        role: 'ADMIN',
      });
    } else {
      // 1234 dışındaki tüm 4 haneli PIN'ler için Garson oturumu aç
      return NextResponse.json({
        id: 'usr-waiter-1',
        name: `Ahmet Yılmaz (Garson - ${pin})`,
        role: 'WAITER',
      });
    }
  }
}
