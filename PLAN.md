# Newborn Tracker → SwiftUI: Taşıma ve Öğrenme Planı

Amaç uygulamayı taşımak kadar **Swift, SwiftUI ve iOS mimarisini öğrenmek**. Kod temiz, test edilmiş ve portfolyo kalitesinde olacak; her faz mülakatta anlatılabilecek bir konu bırakacak.

## Çalışma kuralları

- Kodu **sen yazarsın** (Xcode'da elle). Ben 3-30 satırlık parçalar veririm; sadece sıkıcı toplu işleri (WHO tablosu, asset taşıma, çeviri sabitleri) hazır veririm.
- Her satırı ve "neden"ini Türkçe anlatırım, TS/React karşılığını yanında gösteririm. Kod ve yorumlar İngilizce.
- Her adımın sonunda ne çalıştıracağını söylerim (⌘B, ⌘R, ⌘U). "Bitti" deyince dosyalarını okur, derler, test eder, hataları anlatırım.
- Riskli/görsel işleri (grafik, animasyon, Live Activity, widget) önce scratchpad'de denerim, simülatörde doğrularım.
- Commit atmam; sana İngilizce kısa mesaj veririm.
- Her fazda birim test vardır. UI mantığı ekrandan bağımsızdır (ViewModel/servis).

## Hedef mimari

```
View ──► ViewModel ──► Model (SwiftData @Model + saf struct/enum)
 │            │
 └──► Store ◄─┘   (@Observable, ModelContext üzerinden okur/yazar)
          │
       Services (bildirim, fotoğraf dosyası, Live Activity) → protokol arkasında
```

| Katman | Sorumluluk | Örnekler |
|---|---|---|
| Model | Veri + iş kuralı. `@Model` sınıfları ve saf `struct/enum` | `Baby`, `BabyRecord`, `GrowthMeasurement`, `RecordType`, `Gender` |
| Store / servis | Paylaşılan durum, yan etkiler | `ActiveBabyStore`, `SleepTimerService`, `NotificationService`, `PhotoStorage` |
| ViewModel | Tek ekranın durumu ve mantığı; veriyi parametre olarak alır (test kolaylığı) | `HomeViewModel`, `RecordsViewModel`, `GrowthViewModel` |
| View | Durumdan UI tarif eder, iş mantığı yok | `HomeView`, `RecordsView`, bileşenler |
| Util | Saf fonksiyonlar | `WHOPercentiles`, `DayGrouper`, `TodayStats`, `TimeFormatting` |

Teknolojiler: SwiftUI, SwiftData, Observation (`@Observable`), Swift Charts, Swift Testing, String Catalog, UserNotifications, PhotosUI, ActivityKit, WidgetKit, App Intents. Üçüncü parti yok.

## RN uygulamasında gördüğüm zayıflıklar → Swift çözümleri

| RN'de | Sorun | Swift'te |
|---|---|---|
| `occurredAt: string` (ISO) | Tarih = string; her yerde `new Date(...)` parse, saat dilimi hatası riski | `Date` tipi; SwiftData doğrudan saklar |
| `recordsByBaby: Record<id, {records, activeSleep}>` + elle spread kopyalama | Her güncelleme tüm bucket'ı kopyalar, babyId her fonksiyona taşınır, bebek silince elle temizlik | `Baby` ↔ `BabyRecord` ilişkisi (`@Relationship(deleteRule: .cascade)`); bebek silinince kayıtlar otomatik gider |
| `generateId()` = `Date.now()+random` | Çakışabilir, anlamsız | `UUID` / SwiftData `persistentModelID` |
| Her mutasyondan sonra elle `syncWidget()` | Unutulursa widget bayat kalır; türetilmiş state elle senkron | Widget aynı SwiftData deposunu (App Group) okur; veriden türetilir, senkron çağrısı yok |
| Widget AsyncStorage'ı doğrudan okuyor | Widget'ın kendi veri biçimi, çift yazım | Paylaşılan `ModelContainer` + App Intent |
| `BabyRecord`'da 6 opsiyonel alan (feed/ateş/ilaç için) | Geçersiz kombinasyonlar mümkün (uyku + temperatureC) | `RecordType` enum + hesaplanan özellikler, ViewModel doğrulaması (SwiftData'da tek model pragmatik; ödünleşimi anlatırım) |
| `Gender` tipi store dosyasından import ediliyor | Katman karışıklığı | Modeller kendi dosyasında, store modele bağlı |
| Çeviri anahtarı + `useXxxLabels` hook'ları | Elle sözlük, runtime çözümleme | String Catalog + `LocalizedStringResource` |
| `hasHydrated` bayrakları | Asenkron AsyncStorage yüklemesi | SwiftData senkron, `@Query` otomatik günceller |
| Aktif bebek id'si store'da string | Silinen id'ye işaret edebilir | `@AppStorage` ile UUID + doğrulayan store |

## Klasör yapısı (hedef)

```
NewbornTracker/
  App/            NewbornTrackerApp.swift, AppContainer
  Models/         Baby, BabyRecord, GrowthMeasurement, MilestoneEntry, VaccineCompletion, Custom*, RecordType, FeedSubtype, Gender
  Stores/         ActiveBabyStore, SettingsStore
  Services/       SleepTimerService, NotificationService, PhotoStorage, WHOPercentiles, DayGrouper, TodayStats
  ViewModels/
  Views/          Home/, Records/, Growth/, Settings/, Onboarding/, Sleep/, Components/
  Theme/          AppColors, RecordTypeStyle, Color+Hex
  Resources/      Localizable.xcstrings, WHO data, schedules
NewbornTrackerTests/
NewbornTrackerWidgets/   (Faz 11-12)
```

## Veri modeli (özet)

- `Baby`: id, name, birthDate?, gender?, createdAt; ilişkiler: records, measurements, vaccines, milestones, customs.
- `BabyRecord`: type (`RecordType`, String raw), occurredAt: `Date`, createdAt, endedAt?, durationMinutes?, feedSubtypes: `[FeedSubtype]`, amountMl: `Int?`, temperatureC: `Double?`, note: `String?`.
- `ActiveSleep`: baby başına en fazla bir tane (`startedAt`, `notificationID`).
- `GrowthMeasurement`: date, weightKg/heightCm/headCircumferenceCm (`Double?`).
- `VaccineCompletion` (scheduleID), `MilestoneEntry` (scheduleID, achievedAt, note?, photoFileName?), `CustomVaccine`, `CustomMilestone`.
- Ayarlar (tema, dil, bildirim): `@AppStorage`/UserDefaults — küçük tercih verisi SwiftData'ya gitmez (nedenini anlatırım).
- Ölçü tipleri: ml → `Int`, °C/kg/cm → `Double`; `Measurement<UnitMass>` kullanma kararını Faz 1'de tartışırız. Hesaplanabilen değerler (yaş ay cinsinden, süre, persentil) computed property.

---

## Fazlar

### Faz 0 — Proje kurulumu, klasör yapısı, tema
**Kavramlar:** Xcode proje anatomisi (target, scheme, Info.plist, asset catalog), `@main` / `App` protokolü, `Scene`, varsayılan MainActor izolasyonu, `Color` genişletmeleri, asset catalog'daki renk setleri (açık/koyu) vs kod ile renk.
**RN karşılığı:** `app.json` + `_layout.tsx` + `tailwind.config.js` + `colors.ts`.
**Yapacaklar:** Xcode projesi (iOS App, SwiftUI, Swift Testing, **Storage: None** — SwiftData'yı kendimiz kuracağız), klasörler, `Color(hex:)`, `AppColors` (açık/koyu), `RecordTypeStyle`.
**Çıktı:** Boş `TabView` (Ana Sayfa / Kayıtlar / Büyüme) açık-koyu temada doğru renklerle.

### Faz 1 — Modeller, kayıt türleri, istatistik ve zaman yardımcıları + testler
**Kavramlar:** `enum` + raw value + `CaseIterable`, `Codable`, `Identifiable`, `Sendable`, value vs reference type, `Calendar`/`DateComponents`/`DateFormatter` (+ `FormatStyle`), saf fonksiyonlar, Swift Testing (`@Test`, `#expect`, parametrik testler), `@MainActor` test uyarısı.
**RN karşılığı:** `types/record.ts`, `recordTypes.ts`, `utils/stats.ts`, `time.ts`, `filters.ts`.
**Yapacaklar:** `RecordType`, `FeedSubtype`, `Gender`, geçici `RecordValue` struct'ı (Faz 2'de `@Model`'e dönüşür), `TodayStats`, `DayGrouper` (gün gruplama), `Period` filtresi, süre biçimleme.
**Çıktı:** Yeşil birim testleri (gün sınırı, saat dilimi, boş liste, çoklu tür).

### Faz 2 — SwiftData modelleri
**Kavramlar:** `@Model` makrosu, `ModelContainer`/`ModelContext`, `@Query` + `#Predicate` + `SortDescriptor`, `@Relationship` + delete rule, enum/array saklama (`Codable` raw), şema evrimi (`VersionedSchema` kısaca), `@Environment(\.modelContext)`, **bellek içi container ile test**, `ModelActor` / eşzamanlılık (context thread'e bağlıdır, `Sendable` değil), önizlemede örnek veri.
**RN karşılığı:** Zustand `persist` + AsyncStorage + `bootstrapStores`.
**Yapacaklar:** `Baby`, `BabyRecord`, `GrowthMeasurement`, `MilestoneEntry`, `VaccineCompletion`, `Custom*`; `ActiveBabyStore`; `PreviewData`.
**Çıktı:** Test: kaydet-getir, bebek silince cascade, sıralama; uygulama yeniden açılınca veri duruyor.

### Faz 3 — Home
**Kavramlar:** `@Query` ile view içinde canlı veri, `@Observable` ViewModel + `@State`, `LazyVGrid`, özel `ButtonStyle` (PressableScale karşılığı), `sheet(item:)`, `.sensoryFeedback` (haptik), `DatePicker`, `ViewBuilder`, zamanla yenilenen UI (`TimelineView`).
**RN karşılığı:** `(tabs)/index.tsx`, `AddEntryCard`, `TimePickerSheet`, `FeedDetailsSheet`, `HealthDetailsSheet`, `SecondaryStatRow`.
**Yapacaklar:** Hızlı ekleme kartları, zaman seçici sheet (şimdi / X dk önce / özel), mama alt türü + ml, sağlık seçici (ateş/ilaç/vitamin), bugünün özeti.
**Çıktı:** Kayıt ekle → özet anında güncellenir (elle senkron yok); ViewModel testleri.

### Faz 4 — Records
**Kavramlar:** `List` + `Section`, dinamik `@Query` (filtre değişince predicate yeniden kurma), `swipeActions`, `.alert` ile silme onayı (⚠ `role: .destructive` kullanma, `confirmationDialog` kullanma), `ScrollView` vs `List`, arama/filtre durumu ViewModel'de, düzenleme sheet'i, `ContentUnavailableView`, skeleton/placeholder (`.redacted`).
**RN karşılığı:** `records.tsx`, `RecordFilters`, `RecordListItem`, `RecordDetailsSheet`, `RecordTypeFilterSheet`.
**Yapacaklar:** Gün gruplu liste, tür filtresi (çoklu), tarih aralığı (bugün/hafta/ay/tümü/özel), düzenle, sil.
**Çıktı:** Filtre kombinasyonu testleri; silme/düzenleme çalışıyor.

### Faz 5 — Uyku zamanlayıcısı + yerel bildirim + deep link
**Kavramlar:** `UNUserNotificationCenter`, izin akışı (priming), `UNNotificationContent`, bildirim kategorisi + aksiyon, `UNUserNotificationCenterDelegate` (ön planda gösterme, tıklama), `onOpenURL` / URL scheme, `NavigationPath`/programatik sunum, protokol arkasında servis + sahte (fake) ile test, `Task`, `async/await`, `@MainActor`, geçen süreyi gösteren `TimelineView`/`Text(timerInterval:)`.
**RN karşılığı:** `services/notifications.ts`, `stop-sleep.tsx`, `useElapsedTime`.
**Yapacaklar:** `SleepTimerService`, `NotificationServicing` protokolü, uyku başlat/durdur, bildirime tıkla → stop-sleep ekranı.
**Çıktı:** Servis testleri (fake bildirim merkezi), simülatörde bildirimden açılış doğrulaması.

### Faz 6 — Records grafiği (Swift Charts)
**Kavramlar:** `Chart`, `BarMark`, `.foregroundStyle(by:)`, `chartXAxis`/`chartYAxis`, `chartForegroundStyleScale` (tür renkleri), `AxisMarks`, grafik verisini saf fonksiyonla hazırlama.
**RN karşılığı:** `RecordsChart.tsx`, `utils/chart.ts`.
**Çıktı:** Günlük grafik verisi testleri + grafik (simülatör ekran görüntüsü ile doğrulama).

### Faz 7 — Growth: ölçümler + WHO persentilleri + grafik
**Kavramlar:** LMS yöntemi (matematik), `Double` hassasiyeti ve `pow/exp`, doğrusal interpolasyon, sabit veri tablosu (hazır vereceğim), `LineMark` + `AreaMark` (persentil bantları) + `PointMark`, `chartOverlay`, ölçü birimleri (`Measurement`), `Picker` / segment kontrol, doğum tarihinden ay hesabı.
**RN karşılığı:** `growth.tsx`, `whoPercentiles.ts`, `whoGrowthStandards.ts`, `GrowthChart`, `GrowthEntrySheet`.
**Çıktı:** Persentil testleri (WHO bilinen değerleri, sınır ve ara değer), ölçüm ekle/düzenle/sil, grafik.

### Faz 8 — Aşı takvimi, kilometre taşları, fotoğraf
**Kavramlar:** Statik takvim verisi + kullanıcı verisi birleştirme (`ScheduleItem` + `VaccineCompletion`), `PhotosPicker` + `PhotosPickerItem.loadTransferable`, `Data` → dosya (`FileManager`, Documents), **dosya adı sakla, mutlak yol saklama** (RN'deki `file://` URI kırılganlığı), `Image(uiImage:)`, görsel boyutu küçültme, `async throws`.
**RN karşılığı:** `vaccineSchedule.ts`, `milestoneSchedule.ts`, `milestonePhotos.ts`, `CustomVaccineSheet`, `MilestoneEntrySheet`.
**Çıktı:** `PhotoStorage` testleri (geçici dizin), aşı işaretle/özel aşı, kilometre taşı + not + fotoğraf.

### Faz 9 — Çoklu bebek, onboarding, ayarlar, tema
**Kavramlar:** `@AppStorage`, `preferredColorScheme` (sheet/cover içinde ayrıca), ilk açılış akışı (`fullScreenCover` / koşullu kök view), `NavigationStack`, `Form`, `Toggle`, aktif bebek geçişi, bebek silme (cascade), "tüm verileri sil".
**RN karşılığı:** `onboarding.tsx`, `settings.tsx`, `AddBabySheet`, `useSettingsStore`, `useBabiesStore`.
**Çıktı:** `SettingsStore`/`ActiveBabyStore` testleri (silinen aktif bebek → geçerli bebeğe düşme).

### Faz 10 — Lokalizasyon (String Catalog)
**Kavramlar:** `Localizable.xcstrings`, `LocalizedStringKey` vs `String(localized:)`, çoğul (plural) varyasyonları, tarih/sayı biçimleri `Locale`'e göre, uygulama içi dil seçimi (`.environment(\.locale)`) ve sınırları, `String(localized:)` ile servis katmanında metin.
**RN karşılığı:** `i18n/translations.ts` (1000 satırlık sözlük).
**Çıktı:** TR/EN tam; eksik çeviri uyarısı yok; tür adları ve aşı/kilometre taşı adları katalogda.

### Faz 11 — Live Activity (uyku sayacı) *(ikinci tur olabilir)*
**Kavramlar:** ActivityKit, `ActivityAttributes`/`ContentState`, Widget Extension target, Dynamic Island düzenleri, `Text(timerInterval:)`, `Info.plist` (`NSSupportsLiveActivities`), app ↔ extension paylaşılan tipler.
**RN karşılığı:** Android'deki sabit bildirim (RN'de karşılığı yok, iOS'a özgü iyileştirme).

### Faz 12 — Etkileşimli widget *(ikinci tur olabilir)*
**Kavramlar:** WidgetKit (`TimelineProvider`, `reloadAllTimelines`), App Intents (`AppIntent` ile widget'tan kayıt ekle), **App Group + paylaşılan `ModelContainer`**, widget'ın aynı depoyu okuması.
**RN karşılığı:** `src/widgets/*` (AsyncStorage'a doğrudan erişim, elle `syncWidget`).

### Faz 13 — Cila, ikon, README, cihaza kurulum
Uygulama ikonu, erişilebilirlik (Dynamic Type, VoiceOver etiketleri), boş/hata durumları, performans, README (mimari + kararlar, SelfFinance örneğiyle), ücretli hesapla cihaza kurulum (signing, provisioning).

---

## Test stratejisi
- Saf mantık (istatistik, gruplama, persentil, filtre): parametrik Swift Testing.
- SwiftData: bellek içi `ModelContainer(isStoredInMemoryOnly: true)`.
- Servisler: protokol + fake (bildirim, dosya).
- ViewModel: veriyi parametre alır, ekran gerekmez.

## Sık hata listesi (önceki projeden)
- Test struct'larına `@MainActor`.
- `Category` gibi Foundation ile çakışan model adlarından kaçın (ör. `Record` yerine `BabyRecord`, `Measurement` yerine `GrowthMeasurement`).
- Sheet/cover içinde `preferredColorScheme` ayrıca.
- swipeActions'ta `role: .destructive` yok; onay `.alert`.
- Simülatör ilk input'ta gecikebilir.
