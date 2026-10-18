# Ironote - Professional Qarz Daftari & Boshqaruv Tizimi

Ironote — jismoniy shaxslar, tadbirkorlar va do'kon egalari uchun berilgan va olingan qarzlarni mukammal, xatosiz va qulay hisob-kitob qilish imkonini beruvchi zamonaviy web va PWA ilova.

## 🌟 Asosiy Xususiyatlar va Bajarilgan Talablar:

1. **Jadvallar Tuzilishi (Database Schema)**:
   - `users`: `id`, `full_name`, `phone`, `email`, `username`, `password`, `date_of_birth`, `avatar`, `google_id`, `apple_id`, `facebook_id`, `microsoft_id`.
   - `debts`: `id`, `user_id`, `debtor_name`, `amount`, `debt_date`, `deadline`, `phone`, `second_phone`, `address`, `images` (JSON/Base64), `type`, `notes`, `status`.
   - `repayments`: To'lovlar tarixi, qisman va to'liq to'lovlar auditi.

2. **So'ralgan Funksiyalar**:
   - ✅ **Qarzni tahrirlash (Edit Debt)**: Istalgan parametrni to'g'ridan-to'g'ri o'zgartirish.
   - ✅ **Raqamlarni 3 talikka ajratish**: `1 000 000` ko'rinishida yozish va ko'rsatish (minglik ajratgich).
   - ✅ **Search (Qidiruv) rangini o'zgartirish**: Ko'zni charchatmaydigan, premium yorqin qidiruv dizayni.
   - ✅ **Telefon orqali bir bosishda qo'ng'iroq qilish (`tel:`)**: Asosiy va qo'shimcha raqamlarga to'g'ridan-to'g'ri qo'ng'iroq.
   - ✅ **Telegram / SMS eslatma**: Qarzdorga bir bosishda chiroyli eslatma xabari jo'natish.
   - ✅ **Qo'shimcha telefon raqamini to'liq yozish**: `second_phone` to'liq kiritish va ko'rsatish.
   - ✅ **Ortiqcha summa hisob-kitobini to'g'irlash**: Aniq matematika, qoldiqdan ortiq to'lovni cheklash va to'liq audit.
   - ✅ **Dark Mode & Light Mode**: Input text fieldlar, modallar va kartalar har ikkala rejimda ideal moslashuv.
   - ✅ **To'liq Ko'p Tillilik (i18n)**: O'zbekcha (Lotin), Ўзбекча (Кирилл), Русский, English.
   - ✅ **Foydalanuvchi ma'lumotlarini tahrirlash**: Profilni to'liq yangilash, avatar yuklash, parolni o'zgartirish.
   - ✅ **Eksport & Chop etish**: Excel (CSV), PDF / Print hisoboti, JSON Zaxira nusxa (Backup & Restore).

## 🚀 Qanday ishga tushirish mumkin:
Fayllarni istalgan brauzerda ochish kifoya:
`index.html` faylini oching yoki mahalliy server orqali ishga tushiring.
