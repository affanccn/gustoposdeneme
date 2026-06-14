# Gusto POS - Proje Dökümantasyonu

Bu döküman, sistemde *gerçekten var olan* özellikleri baz alarak hazırlanmış, projeyi tüm yönleriyle anlatan, eksiksiz bir rehberdir. Geliştiriciler, tasarımcılar ve pazarlama uzmanları bu dökümanı kaynak olarak kullanabilir.

---

## 1. Proje Adı
**Gusto POS** (GustoPOS Restoran Yazılımı)

## 2. Projenin Amacı
Restoran, kafe ve benzeri yeme-içme işletmelerinin; sipariş alımından masa takibine, ödeme işlemlerinden (parçalı/kısmi ödemeler dahil) detaylı maliyet ve stok hesaplamalarına kadar tüm operasyonlarını tek bir merkezden, hızlı ve güvenli bir şekilde yönetmesini sağlayan modern bir adisyon sistemidir. Temel amaç işletme sahibine anlık, şeffaf ve detaylı finansal/operasyonel hakimiyet sunmaktır.

## 3. Hedef Kitle
* Kafeler ve Kahve Dükkanları (3. Nesil kahveciler vb.)
* Restoranlar
* Nargile Kafeler
* Pastaneler
* Hızlı ve esnek adisyon / masa takibi gerektiren her türlü yeme-içme işletmesi.

## 4. Teknoloji Altyapısı
Sistem, yüksek performans ve modern standartlara uygun olarak şu teknolojilerle inşa edilmiştir:
* **Frontend:** React, Next.js (App Router)
* **Stil / Arayüz:** Tailwind CSS, Glassmorphism konsepti, Sürükle-Bırak (DnD Kit)
* **Backend:** Next.js Serverless API Route'ları
* **Veritabanı ve ORM:** PostgreSQL veritabanı, Prisma ORM
* **Yazıcı Entegrasyonu:** Windows tabanlı yerel ağ yazıcılarıyla haberleşebilen özel Print Server mimarisi.

## 5. Mevcut Özellikler
*(Bu özellikler kaynak kodda ve veritabanında bizzat tespit edilmiş, aktif çalışan özelliklerdir.)*

* **Sipariş ve Adisyon Yönetimi:** Masalara ürün ekleme, ürüne not girme, adisyon içine "ikram" (complimentary) ekleme veya ürün iptal etme.
* **Opsiyon (Modifier) Desteği:** Ürünlere alt özellik ekleyebilme (Örn: Çift Lavaş, Buzlu, Şuruplu) ve bu özellikleri fiyata yansıtabilme.
* **Gelişmiş Ödeme Alma (Parçalı Ödeme):** Bir masanın hesabını farklı ödeme yöntemleriyle (Nakit, Kredi Kartı, Yemek Kartı, Cari/Veresiye) parça parça alabilme. Ödenen kısımların anında "Kapatılan Ciroya" yansıyıp masanın açık kalmaya devam edebilmesi.
* **Gün İşlemleri (Vardiya Yönetimi):** Sistemin "Gün Başı" ve "Gün Sonu" mantığıyla çalışması. Gece yarısı yapılan kapanışlarda bile bir günün (vardiyanın) diğerine karışmasını engelleyen tam izole Z Raporları.
* **Stok, Reçete ve Maliyet Analizi:** Ürünlerin içeriklerini gram/adet bazında reçetelendirme, fire payı ekleyebilme. Ürün satıldıkça stoğun otomatik düşmesi ve Satılan Malın Maliyeti (COGS) üzerinden **Net Kâr** hesaplanması.
* **Kritik Stok Uyarısı:** Stok seviyesi belirlenen limitin (örn: 15) altına düşen malzemelerin yönetim panelinde uyarı vermesi.
* **Tedarikçi ve Fatura Yönetimi:** Tedarikçilerden malzeme alımı faturalandırma, tedarikçiye borçlanma, borcu ödeme (Kasa, Kart, Havale) ve tedarikçi bakiyesi takibi.
* **Cari Müşteri Yönetimi:** Müşteri hesapları oluşturma, veresiye (cari) hesap yazdırma ve tahsilat işlemleri (müşteri ekstresi).
* **Masa ve Alan Yönetimi:** Farklı alanlar (Teras, Bahçe vb.) tanımlama. Aktif siparişleri olan masayı başka masaya taşıma (Table Transfer).
* **Mutfak ve Hesap Fişi Çıktısı:** Siparişlerin Windows yazıcılar üzerinden mutfak fişi olarak otomatik basılması. Kurumsal bilgiler ve alt notların eklenebildiği özelleştirilebilir müşteri hesap fişleri (Receipt Settings).
* **Güvenlik ve Denetim Logları (Audit Logs):** Sipariş iptalleri, ürün silinmesi veya indirim uygulanması gibi yetki gerektiren hareketlerin kim tarafından, ne zaman yapıldığının saniye saniye kaydedilmesi.
* **Detaylı Analizler (Admin Panel):**
  * Kapatılan Ciro, Açık Masa Cirosu, İptal ve İndirim Ciro kayıpları.
  * Ödeme Yöntemi dağılımı (Nakit, Kart vs.)
  * En Çok Satan Ürünler ve En Çok Tercih Edilen Masalar.
  * Saatlik Yoğunluk (Peak Hours) haritası.
  * Garson (Personel) satış performansı (Sipariş sayıları ve yaptıkları ciro tutarı).

## 6. Kullanıcı Rolleri
* **ADMIN (Yönetici):** Yönetim paneline, detaylı analizlere, ürün fiyat/reçete güncellemelerine, loglara ve ayar sayfalarına tam erişimi vardır. 
* **WAITER (Garson):** Sadece adisyon/POS arayüzüne PIN numarası ile erişebilir. Sipariş alabilir, masaları yönetebilir, (izin verilen sınırlar dahilinde) ödeme ve iptal işlemlerini yapabilir. 

*(Sistemde şu an aktif olarak iki ana rol hiyerarşisi tespit edilmiştir. Kasiyer ve Şef gibi ara yetkiler sistem altyapısında bulunsa da (AuditLog actorUser vb.) UI'da temel olarak bu iki rol yoğun kullanılmaktadır.)*

## 7. Sistemde Bulunan Ekranlar
* **Kilit / PIN Ekranı:** Personelin veya yöneticinin kendi şifresiyle giriş yaptığı hızlı ekran.
* **POS Arayüzü (Ana İşlem Ekranı):** Masa planlarının (renk kodlu: boş, aktif, yazdırıldı) görüldüğü, sol tarafta sipariş sepetinin, sağ tarafta kategoriler ve ürünlerin olduğu, parçalı ödeme, taşıma, ikram gibi araçların bulunduğu interaktif hızlı ekran.
* **Yönetim Paneli (Admin Paneli):** Sol menülü, detaylı bir "Dashboard" ekranı. Kendi içerisinde aşağıdaki sekmeleri (ekranları) barındırır:
  * Analiz Raporları (Ciro, Maliyet, İptal, İndirim sekmeleriyle)
  * Gün İşlemleri (Gün Başı/Sonu ve geçmiş Z raporları)
  * Menü Yönetimi (Kategoriler, Ürünler ve Sürükle-Bırak sıralama)
  * Opsiyonlar (Modifier'lar)
  * Masa Yönetimi
  * Cari (Müşteri)
  * Stok & Reçete (Malzemeler, Reçete oluşturma)
  * Tedarikçiler (Faturalar ve Ödemeler)
  * Kullanıcılar (Personel Yetkileri ve PIN)
  * Loglar (Güvenlik Denetim İzleri)
  * Yazıcılar (Cihaz eşleştirme ve Fiş Şablon Ayarları)

## 8. Tasarım Yapısı ve Kullanıcı Deneyimi
* **Premium Koyu Tema (Dark Mode):** Restoran/Kafe çalışanlarının gözünü yormamak için özel seçilmiş `zinc-900` ve `amber-500` odaklı şık renk paleti.
* **Glassmorphism Detayları:** Arka planı hafif buzlu cam efektiyle gösteren `glass-card` sınıfı ile premium ve derinlik hissi veren görünüm.
* **Akıcı Animasyonlar:** Ekran geçişleri, sepet güncellemeleri ve modal açılışlarında kullanıcıyı yormayan "fade-in" ve "slide" micro-animasyonlar.
* **Hız ve Minimum Tıklama:** Satış arayüzü dokunmatik ekranlar (Tablet, Kiosk, Dokunmatik Monitör) için optimize edilmiş, büyük tuşlu, sayfa yenilemeden çalışan Single-Page (SPA) mimarisindedir.

## 9. Güçlü Yönler
1. **Esnek Hesap Kapatma:** Rakiplerin aksine masayı tam kapatmadan alınan her bir "kısmi tahsilatı" anında ciroya yazabilen, hesap karışıklığını önleyen üst düzey "ödeme parçalama" mekanizması.
2. **Derin Maliyet Analizi:** Reçete içindeki fire payına kadar hesaba katarak işletme sahibine gerçek, anlık kârlılık bilgisini verebilmesi.
3. **Geçmişe Yönelik Bozulmayan Vardiya Raporları:** Günü saatsel veya spesifik tarihe göre değil, bizzat "Vardiya ID"si üzerinden takip ederek, gece kapanan mekanlarda (örn 03:00) ciroların 2 güne dağılması problemini sıfıra indirmesi.
4. **Denetlenebilirlik (Loglama):** Personelin yaptığı her kritik işlemin kaydedilmesi sayesinde kasada oluşan kaçak veya yanlış işlem riskinin minimuma inmesi.
5. **Modern Arayüz (Wow Etkisi):** İşletmenin imajına değer katan, kullanımı keyifli üst düzey UI/UX.

## 10. Eksik veya Gelecekte Eklenebilecek Özellikler
*(Bu özellikler sistemde **mevcut değildir**, projenin büyümesi için öngörülen eklentilerdir.)*
* Getir, Yemeksepeti, Trendyol Yemek vb. **Paket Servis Entegrasyonları**.
* Müşterilerin masadan kendi siparişlerini verebilmesi için **QR Menü Entegrasyonu**.
* Patronların mekan dışında telefonundan anlık ciro takibi yapabileceği native **Mobil Uygulama (iOS/Android)**.
* Kampanya/Promosyon motoru (Örn: "3 Kahve Alana 1 Tatlı Bedava").
* Çoklu şube / Franchise desteği (Şu an tek şube için mükemmel kurgulanmış durumda).
* Müşteri sadakat kartı (Loyalty points) sistemi.

---

## 11. Kısa Tanıtım Metni
**Gusto POS**; restoran ve kafelerin adisyon, stok, cari ve maliyet yönetimini tek çatı altında toplayan; şık tasarımı, reçete bazlı gerçek kâr analizi ve esnek parçalı ödeme sistemiyle işletmenize %100 kontrol sağlayan yeni nesil, hızlı ve güvenli akıllı restoran yazılımıdır.

## 12. Uzun Tanıtım Metni
Günümüzün hızlı tempolu yeme-içme sektöründe, işletmelerin sadece sipariş alan değil, tüm finansal ve operasyonel akışı analiz edebilen asistanlara ihtiyacı var. **Gusto POS** tam da bu ihtiyaçtan doğdu. 

Modern, göz yormayan karanlık teması ve dokunmatik ekranlara özel geliştirilmiş yüksek hızlı arayüzü sayesinde personeliniz saniyeler içinde sipariş alırken, siz işletme sahibi olarak arka planda nelerin olup bittiğine tam hakim olursunuz. Masaların hesaplarını esnek bir şekilde (Nakit, Kredi Kartı, Veresiye vb.) bölebilir, ödenen kısmı anında gün sonu cironuzda görebilirsiniz. 

Gusto POS sadece bir adisyon cihazı değildir. Fire oranına kadar girdiğiniz ürün reçeteleri sayesinde mutfaktaki stoğunuz sipariş satıldıkça gramı gramına otomatik düşer. Sistem, tedarikçi faturalarınızı hesaplayarak size günün sonunda sadece "Ne kadar ciro yaptım?" sorusunun değil, "Ne kadar net kâr ettim?" sorusunun cevabını verir. Vardiya (gün başı/sonu) sistemiyle gece uzayan mesailer diğer güne sarkmaz; iptal/indirim logları sayesinde ise güvenlikte açık verilmez. İşletmenizin dijital beyni Gusto POS ile her şey kontrolünüz altında.

## 13. Web Sitesi İçin Pazarlama Metni
**(Hero Section / Başlık)**
**İşletmenizin Dijital Şefi: Gusto POS ile Hızlanın, Denetleyin, Büyüyün.**

**(Alt Başlık)**
Eski nesil, karmaşık ekranları unutun. Hızlı sipariş alımı, reçete bazlı maliyet analizi, parçalı ödeme esnekliği ve anlık kâr raporları tek ekranda. 

**(Features Kısmı)**
* **Hesaplar Artık Çok Net:** Müşterileriniz hesabı bölmek mi istiyor? Gusto POS ile Nakit, Kart veya Yemek Kartı gibi ödemeleri aynı adisyonda parçalayın, cirolarınızı anlık takip edin.
* **Maliyetlerinizi Milimetrik Ölçün:** "Bu yemekten ne kadar kazanıyorum?" devri bitti. Reçetelerinize fire payını ekleyin, sistem satılan her ürün için stoğunuzu düşsün ve net kârınızı önüne çıkarsın.
* **Güvenlikten Ödün Vermeyin:** Kim, hangi adisyona indirim yaptı? Hangi ürün, hangi mazeretle iptal edildi? Tüm personelin kritik işlemleri kayıt altında.
* **Gece Yarılarına Sarkan Cirolara Son:** Gelişmiş "Vardiya" altyapısı sayesinde gece 02:00'da mekanınızı kapatsanız da raporlarınız iki farklı güne bölünmez, her şey ait olduğu günün Z Raporunda toplanır.
* **Göz Alıcı, Modern Arayüz:** İşletmenize yakışacak, öğrenmesi sadece 5 dakika süren premium dokunmatik arayüz ile hizmet hızınızı katlayın.

## 14. Görsel Tasarım İçin Gerekli Bilgiler
Tasarımcıların web sitesi, katalog veya uygulama sunumlarında kullanması gereken materyal bilgileri:
* **Tema ve Renk Paleti:** Dark Mode esastır. Zeminlerde Koyu Gri/Siyah (`#18181b` - Zinc 900), accent (vurgu) rengi olarak Altın/Amber (`#f59e0b` - Amber 500) kullanılmalıdır.
* **UI Stili:** "Glassmorphism" (buzlu cam arka plan, ince zarif borderlar) ön plandadır. Gölgelendirmeler derin, butonlar geniş ve dokunmatik ekrana uygundur.
* **Font Seçimi:** Modern, okunaklı "Sans-Serif" fontları (Inter, Roboto, Poppins) tercih edilmelidir. Başlıklarda kalın/black font ağırlığı, rakamlarda ise monospace veya tabular numaralar (hizalama için) önerilir.
* **Örnek Görsel İhtiyacı:** 
  1. Büyük bir tablet veya POS cihazı ekranında, koyu temalı ana satış arayüzü mockup'ı.
  2. Bir laptop ekranında detaylı, grafikleri (bar veya çizgi grafik) barındıran "Admin Analiz" paneli mockup'ı.
  3. Mutfakta fiş yazdıran küçük termal yazıcıdan çıkan bir sipariş fişi detayı.

## 15. Reklamlarda Kullanılabilecek Sloganlar
* "Siparişten net kâra, restoranınızın dijital pusulası."
* "Hesap karışıklığına son. Esnek ödeme, tam kontrol."
* "Kasanızda güven, mutfağınızda düzen: Gusto POS."
* "Eski nesil kasaları çöpe atın, Gusto ile yarına dokunun."
* "Ne sattığınızı değil, ne kazandığınızı bilin."
* "Saatler süren sayımlara veda; milimetrik reçeteler, anlık stoklar."
* "Siz sadece lezzete odaklanın, geri kalan her şey Gusto POS'ta."
