# Gusto POS Flutter Mobil Uygulaması

Gusto POS restoran otomasyon sisteminin iOS ve Android için geliştirilmiş resmi Flutter mobil uygulamasıdır.

---

## 📱 Ekran Mimarisi

### 1. Garson Ekranı (Varsayılan İlk Sayfa)
* **Kat Planı ve Masalar (`FloorPlanScreen`):**
  * Uygulama açıldığında personel doğrudan masaların yer aldığı kat planı ekranıyla karşılaşır.
  * Salon, Teras, Bahçe, Bar gibi alanlar arasında tek dokunuşla geçiş yapılabilir.
  * Masalar durumlarına göre renk kodludur:
    * ⚪ **Boş Masa:** Gri çerçeve, yeni sipariş için hazır.
    * 🟡 **Dolu Masa:** Amber/Altın vurgulu, masanın toplam açık tutarı, sipariş süresi ve ürün adedi gösterilir.
    * 🔵 **Hesap İstendi:** Mavi vurgulu, hesap bekleyen masa.
* **Hızlı Sipariş ve Adisyon (`PosOrderScreen`):**
  * Masaya dokunulduğunda doğrudan sipariş alma ekranı açılır.
  * Kategorilere göre menü filtreleme (Kahveler, Burgerler, Tatlılar vb.).
  * Ürüne özel opsiyonlar (Modifier'lar) (Örn: Çift köfte, ekstra cheddar, şurup).
  * Adisyon sepetinde adet artırma/azaltma, mutfak sipariş notu ekleme.
  * Tek tuşla **"Mutfağa Gönder"** işlemi.
* **Parçalı & Hızlı Ödeme (`CheckoutDialog`):**
  * Masanın hesabını tek seferde veya parçalı olarak (Nakit, Kredi Kartı, Yemek Kartı, Cari) tahsil etme.
  * Hızlı bölme tuşları: *Tamamı, 1/2, 1/3, ₺100, ₺200*.
* **Masa Taşıma & Birleştirme (`TransferTableDialog`):**
  * Masayı başka bir masaya taşıma veya iki masanın hesabını birleştirme.

---

### 2. Yönetici Paneli (`AdminDashboardScreen`)
Garson ekranının sağ üst köşesindeki **"Yönetici"** butonuna basılıp PIN girilerek (Varsayılan PIN: `1234`) erişilir:
1. **Raporlar:** Kapatılan ciro, açık masa cirosu, indirimler, saatlik satış çubuk grafiği (Peak Hours), ödeme yöntemi dağılımları ve en çok satan ürünler.
2. **Vardiya & Z Raporu:** Gün başı açılışı, gün sonu kapanışı ve resmi Z Raporu dökümü.
3. **Menü Yönetimi:** Menüdeki kategorileri ve ürünleri listeleme, ürün fiyatlarını anlık güncelleme ve yeni ürün ekleme.
4. **Masa Yönetimi & Denetim Logları:** Yeni masa ekleme ve personel tarafından yapılan tüm indirim, iptal ve taşıma hareketlerinin güvenlik denetim izleri.
5. **Sunucu Ayarları:** Next.js backend API adresini (`http://192.168.1.X:3000`) tanımlama veya internetsiz bağımsız test için Çevrimdışı/Demo modunu açıp kapatma.

---

## 🛠️ Yerel Çalıştırma (Local Development)

```bash
cd mobile
flutter pub get
flutter run
```

---

## ☁️ GitHub Actions ile Ücretsiz iOS & Android Çıktısı Alma

Windows kullandığınız için macOS işletim sistemine ihtiyaç duymadan **GitHub Actions**'ın sağladığı ücretsiz bulut macOS ve Ubuntu makineleri üzerinden iOS IPA ve Android APK çıktılarınızı alabilirsiniz:

### 1. Değişiklikleri GitHub'a Gönderin
```bash
git add .
git commit -m "feat: add GitHub Actions iOS and Android workflows"
git push origin main
```

### 2. GitHub Üzerinden Derlemeyi Başlatma (Elle veya Otomatik)
1. GitHub reponuza gidin: `https://github.com/affanccn/gustoposdeneme`
2. Üst menüdeki **"Actions"** sekmesine tıklayın.
3. Sol tarafta iki iş akışı göreceksiniz:
   * **`Build GustoPOS iOS (IPA)`**
   * **`Build GustoPOS Android (APK)`**
4. İstediğiniz iş akışını seçin ve sağdaki **"Run workflow"** butonuna basarak derlemeyi başlatın. (Ayrıca `mobile/` klasörüne push yaptığınızda da otomatik başlar).

### 3. Çıktıyı İndirme (Artifacts)
* Derleme tamamlandığında (macOS üzerinde yaklaşık 4-6 dakika sürer), çalışan iş akışına tıklayın.
* Sayfanın altındaki **Artifacts** bölümünden:
  * **`GustoPOS-iOS-IPA`** (veya `GustoPOS-Android-APK`) paketini tek tıkla bilgisayarınıza indirin!
* İndirdiğiniz `.ipa` dosyasını AltStore, Sideloadly veya Apple Developer hesabınızla iPhone'unuza doğrudan yükleyebilirsiniz.
