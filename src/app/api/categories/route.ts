import { NextResponse } from 'next/server';
import { getCachedMenu } from '@/lib/cache';

export async function GET() {
  try {
    const categories = await getCachedMenu();
    return NextResponse.json(categories);
  } catch (error: unknown) {
    const err = error as Error;
    console.error('Kategoriler API Hatası (Fallback kullanılıyor):', err.message);
    return NextResponse.json([
      {
        id: 'cat-1',
        name: 'Sıcak Kahveler',
        sortOrder: 1,
        products: [
          { id: 'p-1', name: 'Espresso', price: 65, isFavorite: true, modifiers: [{ id: 'm-1', name: 'Double Shot', price: 25 }] },
          { id: 'p-2', name: 'Caffe Latte', price: 95, isFavorite: true, modifiers: [{ id: 'm-2', name: 'Vanilya Şurup', price: 15 }] },
          { id: 'p-3', name: 'Türk Kahvesi', price: 60, isFavorite: true, modifiers: [] },
        ],
      },
      {
        id: 'cat-2',
        name: 'Soğuk İçecekler',
        sortOrder: 2,
        products: [
          { id: 'p-4', name: 'Iced Americano', price: 85, isFavorite: true, modifiers: [] },
          { id: 'p-5', name: 'Limonata', price: 80, isFavorite: false, modifiers: [] },
        ],
      },
      {
        id: 'cat-3',
        name: 'Burger & Yemek',
        sortOrder: 3,
        products: [
          { id: 'p-6', name: 'Gusto Burger', price: 260, isFavorite: true, modifiers: [{ id: 'm-3', name: 'Ekstra Cheddar', price: 30 }] },
          { id: 'p-7', name: 'Tavuk Şnitzel', price: 220, isFavorite: false, modifiers: [] },
        ],
      },
      {
        id: 'cat-4',
        name: 'Tatlılar',
        sortOrder: 4,
        products: [
          { id: 'p-8', name: 'San Sebastian Cheesecake', price: 150, isFavorite: true, modifiers: [] },
          { id: 'p-9', name: 'Sufle', price: 130, isFavorite: false, modifiers: [] },
        ],
      },
    ]);
  }
}
