import { NextResponse } from 'next/server';
import { db } from '@/lib/db';

export async function GET() {
  try {
    const tables = await db.table.findMany({
      orderBy: [
        { area: 'asc' },
        { sortOrder: 'asc' }
      ]
    });

    // Masalara bağlı aktif siparişleri topluca veya ilişkisel olarak çekelim.
    // SQLite'ta activeOrderId üzerinden doğrudan Order'ı eşleştirebiliriz.
    const activeOrderIds = tables
      .map((t) => t.activeOrderId)
      .filter((id): id is string => !!id);

    const activeOrders = await db.order.findMany({
      where: {
        id: { in: activeOrderIds },
        status: 'ACTIVE',
      },
      include: {
        items: {
          where: { status: { in: ['ACTIVE', 'COMPLIMENTARY'] } },
        },
        payments: true,
      },
    });

    const ordersMap = new Map(activeOrders.map((o) => [o.id, o]));

    const tablesWithOrders = tables.map((table) => {
      const activeOrder = table.activeOrderId ? ordersMap.get(table.activeOrderId) : null;
      return {
        ...table,
        activeOrder: activeOrder ? {
          id: activeOrder.id,
          totalAmount: activeOrder.totalAmount,
          discountAmount: activeOrder.discountAmount,
          paidAmount: activeOrder.paidAmount,
          createdAt: activeOrder.createdAt,
          updatedAt: activeOrder.updatedAt,
          items: activeOrder.items.map((item) => ({
            id: item.id,
            productId: item.productId,
            productName: item.productName,
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            note: item.note,
            status: item.status,
            selectedModifiers: item.selectedModifiers,
            createdAt: item.createdAt,
          })),
          payments: activeOrder.payments,
        } : null,
      };
    });

    return NextResponse.json(tablesWithOrders);
  } catch (error: any) {
    console.error('Masalar API Hatası (Veritabanı offline):', error);
    // Veritabanı bağlı değilken geliştirme fallback masaları
    return NextResponse.json([
      { id: 't-1', name: 'Masa 1', area: 'Salon', status: 'EMPTY', sortOrder: 1, activeOrder: null },
      {
        id: 't-2',
        name: 'Masa 2',
        area: 'Salon',
        status: 'OCCUPIED',
        sortOrder: 2,
        activeOrder: {
          id: 'ord-2',
          totalAmount: 340.0,
          discountAmount: 0.0,
          paidAmount: 0.0,
          createdAt: new Date(Date.now() - 38 * 60000).toISOString(),
          items: [
            { id: 'item-1', productName: 'Caffe Latte', unitPrice: 95.0, quantity: 2, status: 'ACTIVE', note: 'Biri vanilyalı' },
            { id: 'item-2', productName: 'San Sebastian Cheesecake', unitPrice: 150.0, quantity: 1, status: 'ACTIVE' },
          ],
          payments: [],
        },
      },
      { id: 't-3', name: 'Masa 3', area: 'Salon', status: 'BILL_REQUESTED', sortOrder: 3, activeOrder: { id: 'ord-3', totalAmount: 480.0, discountAmount: 0.0, paidAmount: 0.0, createdAt: new Date(Date.now() - 45 * 60000).toISOString(), items: [{ id: 'item-3', productName: 'Gusto Burger', unitPrice: 240.0, quantity: 2, status: 'ACTIVE' }], payments: [] } },
      { id: 't-4', name: 'Masa 4', area: 'Salon', status: 'EMPTY', sortOrder: 4, activeOrder: null },
      { id: 't-5', name: 'Teras 1', area: 'Teras', status: 'OCCUPIED', sortOrder: 5, activeOrder: { id: 'ord-5', totalAmount: 220.0, discountAmount: 0.0, paidAmount: 0.0, createdAt: new Date(Date.now() - 20 * 60000).toISOString(), items: [{ id: 'item-5', productName: 'Penne Arrabbiata', unitPrice: 220.0, quantity: 1, status: 'ACTIVE' }], payments: [] } },
      { id: 't-6', name: 'Teras 2', area: 'Teras', status: 'EMPTY', sortOrder: 6, activeOrder: null },
      { id: 't-7', name: 'Bahçe 1', area: 'Bahçe', status: 'EMPTY', sortOrder: 7, activeOrder: null },
      { id: 't-8', name: 'Bahçe 2', area: 'Bahçe', status: 'EMPTY', sortOrder: 8, activeOrder: null },
    ]);
  }
}
