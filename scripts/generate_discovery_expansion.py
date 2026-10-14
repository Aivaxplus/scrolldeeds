#!/usr/bin/env python3
"""Build sourced Scroll cards: 200+ ayahs, 200+ sunnah/hadith, 200+ facts.

Ayahs and hadith texts come from published editions (AlQuran Cloud, hadith-api).
Facts are structural Quran/seerah items with citations — no viral word-counts.
"""
from __future__ import annotations

import hashlib
import json
import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "scrolldeeds"
SWIFT_OUT = APP / "DiscoveryExpansion.swift"
HADITH_PICKED = ROOT / "scripts" / "hadith_picked.json"
HADITH_I18N = ROOT / "scripts" / "hadith_i18n.json"
CACHE_DIR = ROOT / "scripts" / ".discovery_cache"
MARKER = "/* BEGIN DISCOVERY EXPANSION */"
MARKER_END = "/* END DISCOVERY EXPANSION */"

EDITIONS = {
    "ar": "quran-uthmani",
    "en": "en.sahih",
    "nl": "nl.leemhuis",
    "es": "es.garcia",
    "de": "de.bubenheim",
    "fr": "fr.hamidullah",
    "ru": "ru.kuliev",
}

# Famous, widely taught verses — skip ones already in DiscoveryCard.swift.
SKIP_AYAHS = {
    (1, 2), (2, 43), (2, 152), (2, 153), (2, 183), (2, 186), (2, 201), (2, 255),
    (2, 256), (2, 261), (2, 269), (2, 286), (3, 173), (4, 58), (4, 135), (14, 7),
    (16, 18), (17, 23), (18, 23), (20, 114), (21, 87), (24, 30), (24, 35),
    (30, 21), (31, 17), (36, 82), (39, 53), (49, 12), (49, 13), (50, 16),
    (55, 13), (57, 4), (64, 11), (65, 2), (65, 3), (67, 2), (93, 3), (93, 9),
    (94, 1), (94, 5), (97, 3), (98, 5), (103, 2), (108, 1), (109, 6), (112, 1),
    (113, 1), (114, 1),
}

AYAHS = [
    (1, 1), (1, 4), (1, 5), (1, 6), (1, 7),
    (2, 2), (2, 21), (2, 45), (2, 152), (2, 155), (2, 165), (2, 177), (2, 185),
    (2, 197), (2, 208), (2, 216), (2, 245), (2, 254), (2, 267), (2, 285),
    (3, 8), (3, 26), (3, 31), (3, 92), (3, 102), (3, 103), (3, 110), (3, 133),
    (3, 139), (3, 159), (3, 185), (3, 190), (3, 200),
    (4, 1), (4, 29), (4, 36), (4, 40), (4, 59), (4, 69), (4, 86), (4, 103),
    (4, 174),
    (5, 2), (5, 3), (5, 6), (5, 8), (5, 32), (5, 35), (5, 54), (5, 119),
    (6, 17), (6, 54), (6, 125), (6, 151), (6, 162),
    (7, 23), (7, 31), (7, 56), (7, 128), (7, 199), (7, 204),
    (8, 2), (8, 29), (8, 46), (8, 61),
    (9, 18), (9, 40), (9, 51), (9, 71), (9, 103), (9, 128),
    (10, 25), (10, 57), (10, 62), (10, 107),
    (11, 88), (11, 114),
    (12, 21), (12, 87), (12, 90),
    (13, 11), (13, 28),
    (14, 7), (14, 24),
    (15, 9), (15, 49),
    (16, 90), (16, 97), (16, 125),
    (17, 9), (17, 24), (17, 26), (17, 32), (17, 53), (17, 70), (17, 80), (17, 110),
    (18, 10), (18, 24), (18, 46), (18, 110),
    (19, 4), (19, 96),
    (20, 8), (20, 25), (20, 46), (20, 82),
    (21, 47), (21, 73), (21, 92),
    (22, 77), (22, 78),
    (23, 1), (23, 51), (23, 97),
    (24, 22), (24, 31), (24, 35), (24, 37),
    (25, 63), (25, 74),
    (26, 80), (26, 89),
    (27, 19), (27, 62),
    (28, 56), (28, 77),
    (29, 45), (29, 69),
    (31, 12), (31, 13), (31, 18), (31, 19),
    (32, 16), (32, 17),
    (33, 21), (33, 35), (33, 41), (33, 56), (33, 70),
    (35, 10), (35, 28),
    (36, 1), (36, 22), (36, 58),
    (37, 96),
    (38, 29),
    (39, 9), (39, 10), (39, 36), (39, 53),
    (40, 60), (40, 65),
    (41, 30), (41, 33), (41, 34),
    (42, 13), (42, 19), (42, 36),
    (43, 36),
    (44, 3),
    (45, 15),
    (46, 13), (46, 15),
    (47, 7), (47, 19),
    (48, 1), (48, 29),
    (49, 10), (49, 11), (49, 12),
    (51, 19), (51, 56),
    (52, 21),
    (53, 32), (53, 39),
    (54, 17),
    (55, 1), (55, 46),
    (56, 10),
    (57, 4), (57, 16), (57, 20), (57, 21),
    (58, 11),
    (59, 9), (59, 18), (59, 22),
    (61, 2), (61, 10), (61, 13),
    (62, 9), (62, 10),
    (63, 9),
    (64, 16),
    (65, 3), (65, 4),
    (66, 8),
    (67, 1), (67, 14), (67, 15),
    (68, 4),
    (70, 19),
    (73, 20),
    (74, 3),
    (76, 8), (76, 9),
    (87, 1), (87, 14),
    (89, 27), (89, 28),
    (90, 12), (90, 13),
    (91, 9),
    (92, 5), (92, 18),
    (93, 5), (93, 6), (93, 7), (93, 8), (93, 10), (93, 11),
    (94, 6), (94, 7), (94, 8),
    (95, 4),
    (96, 1), (96, 5),
    (97, 1), (97, 5),
    (99, 7), (99, 8),
    (102, 1), (102, 8),
    (103, 3),
    (107, 1), (107, 4),
    (110, 1), (110, 3),
    (112, 2), (112, 3), (112, 4),
]

# Extra sourced weetjes (not surah/juz templates). All 7 locales.
EXTRA_FACTS = [
    {
        "id": "ramadan_reveal",
        "source": "Qur’an 2:185",
        "title": {
            "en": "Sent down in Ramadan",
            "nl": "Neergezonden in Ramadan",
            "es": "Revelado en Ramadán",
            "de": "Im Ramadan herabgesandt",
            "fr": "Descendu en ramadan",
            "ru": "Ниспослан в Рамадан",
            "ar": "أُنزل في رمضان",
        },
        "meaning": {
            "en": "The Quran was sent down in the month of Ramadan, as guidance for people and clear proofs of the criterion.",
            "nl": "De Koran is neergezonden in de maand Ramadan, als leiding voor de mensen en duidelijke bewijzen van het onderscheid.",
            "es": "El Corán fue revelado en el mes de Ramadán, como guía para las personas y pruebas claras del criterio.",
            "de": "Der Koran wurde im Monat Ramadan herabgesandt, als Rechtleitung für die Menschen und klare Beweise des Unterscheidens.",
            "fr": "Le Coran a été descendu au mois de ramadan, comme guidance pour les gens et preuves claires du discernement.",
            "ru": "Коран был ниспослан в месяц Рамадан — как руководство для людей и ясные знамения различения.",
            "ar": "أُنزل القرآن في شهر رمضان هدى للناس وبينات من الهدى والفرقان.",
        },
    },
    {
        "id": "surah_count",
        "source": "Uthmani mushaf",
        "title": {
            "en": "114 surahs",
            "nl": "114 soera’s",
            "es": "114 suras",
            "de": "114 Suren",
            "fr": "114 sourates",
            "ru": "114 сур",
            "ar": "١١٤ سورة",
        },
        "meaning": {
            "en": "The Quran as compiled in the Uthmani mushaf is arranged in 114 surahs, from Al-Fatiha to An-Nas.",
            "nl": "De Koran in de Oethmaanse mushaf telt 114 soera’s, van Al-Fatiha tot An-Nas.",
            "es": "El Corán del mushaf utmaní está ordenado en 114 suras, de Al-Fatiha a An-Nas.",
            "de": "Der Koran im uthmanischen Mushaf umfasst 114 Suren, von Al-Fatiha bis An-Nas.",
            "fr": "Le Coran du mushaf othmanien compte 114 sourates, d’Al-Fatiha à An-Nas.",
            "ru": "Коран в османском мусхафе состоит из 114 сур — от «Аль-Фатиха» до «Ан-Нас».",
            "ar": "المصحف العثماني مرتب في ١١٤ سورة، من الفاتحة إلى الناس.",
        },
    },
    {
        "id": "juz_count",
        "source": "Uthmani mushaf",
        "title": {
            "en": "30 juz",
            "nl": "30 djoez",
            "es": "30 yuz",
            "de": "30 Dschuz",
            "fr": "30 jouz",
            "ru": "30 джузов",
            "ar": "٣٠ جزءًا",
        },
        "meaning": {
            "en": "For recitation, the Quran is divided into 30 juz — one for each night of a typical Ramadan khatm.",
            "nl": "Voor recitatie is de Koran verdeeld in 30 djoez — vaak één per nacht bij een khatm in Ramadan.",
            "es": "Para recitarlo, el Corán se divide en 30 yuz: uno por noche en un khatm típico de Ramadán.",
            "de": "Zum Rezitieren ist der Koran in 30 Dschuz geteilt — oft eines pro Nacht im Ramadan-Khatm.",
            "fr": "Pour la récitation, le Coran est divisé en 30 jouz — souvent un par nuit pour un khatm de ramadan.",
            "ru": "Для чтения Коран делят на 30 джузов — часто по одному за ночь в Рамадан.",
            "ar": "يُقسَّم القرآن إلى ٣٠ جزءًا للتلاوة، جزء في كل ليلة من ختمة رمضان المعتادة.",
        },
    },
    {
        "id": "iqra_first",
        "source": "Qur’an 96:1 · Sahih al-Bukhari 3",
        "title": {
            "en": "The first word: Iqra",
            "nl": "Het eerste woord: Iqra",
            "es": "La primera palabra: Iqra",
            "de": "Das erste Wort: Iqra",
            "fr": "Le premier mot : Iqra",
            "ru": "Первое слово: Икра",
            "ar": "أول كلمة: اقرأ",
        },
        "meaning": {
            "en": "The first revelation to the Prophet ﷺ in the cave of Hira began with: “Read, in the name of your Lord who created.”",
            "nl": "De eerste openbaring aan de Profeet ﷺ in de grot van Hira begon met: “Lees, in de naam van jouw Heer die schiep.”",
            "es": "La primera revelación al Profeta ﷺ en la cueva de Hira comenzó: “Lee, en el nombre de tu Señor que creó.”",
            "de": "Die erste Offenbarung an den Propheten ﷺ in der Höhle Hira begann: „Lies im Namen deines Herrn, der erschaffen hat.“",
            "fr": "La première révélation au Prophète ﷺ dans la grotte de Hira commença par : « Lis, au nom de ton Seigneur qui a créé. »",
            "ru": "Первое откровение Пророку ﷺ в пещере Хира началось словами: «Читай во имя Господа твоего, Который сотворил».",
            "ar": "أول ما نزل على النبي ﷺ في غار حراء: «اقرأ باسم ربك الذي خلق».",
        },
    },
    {
        "id": "longest_surah",
        "source": "Uthmani mushaf · Qur’an 2",
        "title": {
            "en": "The longest surah",
            "nl": "De langste soera",
            "es": "La sura más larga",
            "de": "Die längste Sure",
            "fr": "La plus longue sourate",
            "ru": "Самая длинная сура",
            "ar": "أطول سورة",
        },
        "meaning": {
            "en": "Al-Baqarah is the longest surah in the Quran, with 286 ayahs. It was revealed in Madinah.",
            "nl": "Al-Baqarah is de langste soera in de Koran, met 286 verzen. Ze is in Medina neergezonden.",
            "es": "Al-Baqarah es la sura más larga del Corán, con 286 aleyas. Se reveló en Medina.",
            "de": "Al-Baqara ist die längste Sure im Koran, mit 286 Versen. Sie wurde in Madina offenbart.",
            "fr": "Al-Baqara est la plus longue sourate du Coran, avec 286 versets. Elle fut descendue à Médine.",
            "ru": "«Аль-Бакара» — самая длинная сура Корана, 286 аятов. Она ниспослана в Медине.",
            "ar": "البقرة أطول سورة في القرآن، ٢٨٦ آية. نزلت في المدينة.",
        },
    },
    {
        "id": "shortest_surah",
        "source": "Uthmani mushaf · Qur’an 108",
        "title": {
            "en": "The shortest surah",
            "nl": "De kortste soera",
            "es": "La sura más corta",
            "de": "Die kürzeste Sure",
            "fr": "La plus courte sourate",
            "ru": "Самая короткая сура",
            "ar": "أقصر سورة",
        },
        "meaning": {
            "en": "Al-Kawthar is the shortest surah, with three ayahs.",
            "nl": "Al-Kawthar is de kortste soera, met drie verzen.",
            "es": "Al-Kawthar es la sura más corta, con tres aleyas.",
            "de": "Al-Kawthar ist die kürzeste Sure, mit drei Versen.",
            "fr": "Al-Kawthar est la plus courte sourate, avec trois versets.",
            "ru": "«Аль-Каусар» — самая короткая сура, три аята.",
            "ar": "الكوثر أقصر سورة، ثلاث آيات.",
        },
    },
    {
        "id": "first_house",
        "source": "Qur’an 3:96",
        "title": {
            "en": "The first House",
            "nl": "Het eerste Huis",
            "es": "La primera Casa",
            "de": "Das erste Haus",
            "fr": "La première Maison",
            "ru": "Первый Дом",
            "ar": "أول بيت",
        },
        "meaning": {
            "en": "The Quran says the first House set up for people is the one at Bakkah (Makkah), blessed and a guidance for the worlds.",
            "nl": "De Koran zegt dat het eerste Huis dat voor de mensen is ingesteld, dat in Bakka (Mekka) is: gezegend en leiding voor de werelden.",
            "es": "El Corán dice que la primera Casa erigida para las personas es la de Bakka (La Meca), bendita y guía para los mundos.",
            "de": "Der Koran sagt, das erste Haus, das für die Menschen errichtet wurde, sei das in Bakka (Mekka) — gesegnet und Rechtleitung für die Welten.",
            "fr": "Le Coran dit que la première Maison établie pour les gens est celle de Bakka (La Mecque), bénie et guidance pour les mondes.",
            "ru": "Коран говорит, что первый Дом, установленный для людей, — тот, что в Бакке (Мекке): благословенный и руководство для миров.",
            "ar": "إن أول بيت وُضع للناس للذي ببكة مباركًا وهدى للعالمين.",
        },
    },
    {
        "id": "qiblah_change",
        "source": "Qur’an 2:144",
        "title": {
            "en": "The qiblah was turned",
            "nl": "De qibla werd gedraaid",
            "es": "Se cambió la qibla",
            "de": "Die Qibla wurde gewendet",
            "fr": "La qibla fut tournée",
            "ru": "Киблу повернули",
            "ar": "تحويل القبلة",
        },
        "meaning": {
            "en": "Allah commanded the Prophet ﷺ to turn his face toward the Sacred Mosque. That became the qiblah of the Muslims.",
            "nl": "Allah gebood de Profeet ﷺ zijn gezicht naar de Heilige Moskee te keren. Dat werd de qibla van de moslims.",
            "es": "Allah ordenó al Profeta ﷺ volver el rostro hacia la Mezquita Sagrada. Esa pasó a ser la qibla de los musulmanes.",
            "de": "Allah gebot dem Propheten ﷺ, sein Gesicht zur Heiligen Moschee zu wenden. Das wurde die Qibla der Muslime.",
            "fr": "Allah ordonna au Prophète ﷺ de tourner son visage vers la Mosquée sacrée. Cela devint la qibla des musulmans.",
            "ru": "Аллах повелел Пророку ﷺ обратить лицо к Заповедной мечети. Так стала кибла мусульман.",
            "ar": "أمر الله النبي ﷺ أن يولي وجهه شطر المسجد الحرام، فصارت قبلة المسلمين.",
        },
    },
    {
        "id": "arabic_quran",
        "source": "Qur’an 12:2",
        "title": {
            "en": "An Arabic Quran",
            "nl": "Een Arabische Koran",
            "es": "Un Corán árabe",
            "de": "Ein arabischer Koran",
            "fr": "Un Coran arabe",
            "ru": "Арабский Коран",
            "ar": "قرآنًا عربيًا",
        },
        "meaning": {
            "en": "The Quran was sent down as an Arabic recitation so that its first audience could understand it.",
            "nl": "De Koran is neergezonden als een Arabische recitatie, zodat de eerste hoorders hem konden begrijpen.",
            "es": "El Corán fue revelado como recitación árabe para que su primer público lo entendiera.",
            "de": "Der Koran wurde als arabische Rezitation herabgesandt, damit die ersten Hörer ihn verstehen.",
            "fr": "Le Coran a été descendu comme une récitation arabe, pour que ses premiers auditeurs le comprennent.",
            "ru": "Коран ниспослан как арабское чтение, чтобы первые слушатели поняли его.",
            "ar": "أُنزل القرآن قرآنًا عربيًا لعل أول من سمعه يعقلونه.",
        },
    },
    {
        "id": "in_stages",
        "source": "Qur’an 17:106",
        "title": {
            "en": "Sent down in stages",
            "nl": "Neergezonden in etappes",
            "es": "Revelado por etapas",
            "de": "Stückweise herabgesandt",
            "fr": "Descendu par étapes",
            "ru": "Ниспослан постепенно",
            "ar": "نزّلناه تنزيلًا",
        },
        "meaning": {
            "en": "The Quran was not sent down all at once. It was recited in stages over the years of the Prophet’s ﷺ mission.",
            "nl": "De Koran is niet in één keer neergezonden. Hij werd in etappes gereciteerd tijdens de zending van de Profeet ﷺ.",
            "es": "El Corán no bajó de una sola vez. Se recitó por etapas a lo largo de la misión del Profeta ﷺ.",
            "de": "Der Koran wurde nicht auf einmal herabgesandt. Er wurde über die Jahre der Sendung des Propheten ﷺ stufenweise vorgetragen.",
            "fr": "Le Coran n’est pas descendu d’un seul coup. Il fut récité par étapes durant la mission du Prophète ﷺ.",
            "ru": "Коран не был ниспослан сразу целиком. Его читали этапами в годы пророческой миссии ﷺ.",
            "ar": "لم ينزل القرآن جملة واحدة، بل فُرّق على سنين بعثة النبي ﷺ.",
        },
    },
    {
        "id": "isra",
        "source": "Qur’an 17:1",
        "title": {
            "en": "The Night Journey",
            "nl": "De nachtreis",
            "es": "El viaje nocturno",
            "de": "Die Nachtreise",
            "fr": "Le voyage nocturne",
            "ru": "Ночное путешествие",
            "ar": "الإسراء",
        },
        "meaning": {
            "en": "Glory be to the One who took His servant by night from the Sacred Mosque to the Farthest Mosque, whose surroundings We blessed.",
            "nl": "Heilig is Hij die Zijn dienaar bij nacht voerde van de Heilige Moskee naar de Verste Moskee, waarvan Wij de omgeving hebben gezegend.",
            "es": "Gloria a Quien llevó a Su siervo de noche desde la Mezquita Sagrada hasta la Mezquita Más Lejana, cuyos alrededores bendijimos.",
            "de": "Gepriesen sei Der, der Seinen Diener bei Nacht von der Heiligen Moschee zur Fernsten Moschee führte, deren Umgebung Wir gesegnet haben.",
            "fr": "Gloire à Celui qui fit voyager Son serviteur de nuit de la Mosquée sacrée à la Mosquée la plus éloignée, dont Nous avons béni les alentours.",
            "ru": "Хвала Тому, Кто перенёс Своего раба ночью от Заповедной мечети до Отдалённейшей, окрестности которой Мы благословили.",
            "ar": "سبحان الذي أسرى بعبده ليلًا من المسجد الحرام إلى المسجد الأقصى الذي باركنا حوله.",
        },
    },
    {
        "id": "mercy_to_worlds",
        "source": "Qur’an 21:107",
        "title": {
            "en": "A mercy to the worlds",
            "nl": "Een genade voor de werelden",
            "es": "Misericordia para los mundos",
            "de": "Eine Barmherzigkeit für die Welten",
            "fr": "Une miséricorde pour les mondes",
            "ru": "Милость для миров",
            "ar": "رحمة للعالمين",
        },
        "meaning": {
            "en": "The Quran says the Prophet ﷺ was not sent except as a mercy to the worlds.",
            "nl": "De Koran zegt dat de Profeet ﷺ alleen is gezonden als een genade voor de werelden.",
            "es": "El Corán dice que el Profeta ﷺ no fue enviado sino como misericordia para los mundos.",
            "de": "Der Koran sagt, der Prophet ﷺ sei nur als Barmherzigkeit für die Welten gesandt.",
            "fr": "Le Coran dit que le Prophète ﷺ n’a été envoyé que comme une miséricorde pour les mondes.",
            "ru": "Коран говорит, что Пророк ﷺ послан только как милость для миров.",
            "ar": "وما أرسلناك إلا رحمة للعالمين.",
        },
    },
    {
        "id": "uswa_hasana",
        "source": "Qur’an 33:21",
        "title": {
            "en": "A beautiful example",
            "nl": "Een mooi voorbeeld",
            "es": "Un bello ejemplo",
            "de": "Ein schönes Vorbild",
            "fr": "Un bel exemple",
            "ru": "Прекрасный пример",
            "ar": "أسوة حسنة",
        },
        "meaning": {
            "en": "In the Messenger of Allah ﷺ you have a beautiful example for whoever hopes in Allah and the Last Day.",
            "nl": "In de Boodschapper van Allah ﷺ hebben jullie een mooi voorbeeld, voor wie hoopt op Allah en de Laatste Dag.",
            "es": "En el Mensajero de Allah ﷺ tenéis un bello ejemplo para quien espera en Allah y el Último Día.",
            "de": "Im Gesandten Allahs ﷺ habt ihr ein schönes Vorbild für den, der auf Allah und den Jüngsten Tag hofft.",
            "fr": "Vous avez dans le Messager d’Allah ﷺ un bel exemple pour qui espère en Allah et au Jour dernier.",
            "ru": "В Посланнике Аллаха ﷺ вам прекрасный пример для того, кто надеется на Аллаха и Последний день.",
            "ar": "لقد كان لكم في رسول الله أسوة حسنة لمن كان يرجو الله واليوم الآخر.",
        },
    },
    {
        "id": "great_character",
        "source": "Qur’an 68:4",
        "title": {
            "en": "A tremendous character",
            "nl": "Een geweldig karakter",
            "es": "Un carácter inmenso",
            "de": "Ein gewaltiger Charakter",
            "fr": "Un caractère immense",
            "ru": "Великий нрав",
            "ar": "خلق عظيم",
        },
        "meaning": {
            "en": "Allah said of the Prophet ﷺ: “And you are surely on a tremendous character.”",
            "nl": "Allah zei over de Profeet ﷺ: “En jij bent waarlijk van een geweldig karakter.”",
            "es": "Allah dijo del Profeta ﷺ: “Y eres de un carácter inmenso.”",
            "de": "Allah sagte über den Propheten ﷺ: „Und du bist wahrlich von großartigem Charakter.“",
            "fr": "Allah a dit du Prophète ﷺ : « Et tu es certes d’un caractère immense. »",
            "ru": "Аллах сказал о Пророке ﷺ: «Воистину, ты — нрава великого».",
            "ar": "قال تعالى عن النبي ﷺ: «وإنك لعلى خلق عظيم».",
        },
    },
    {
        "id": "salawat",
        "source": "Qur’an 33:56",
        "title": {
            "en": "Allah sends salah upon him",
            "nl": "Allah zendt salah over hem",
            "es": "Allah envía salah sobre él",
            "de": "Allah sendet Salah auf ihn",
            "fr": "Allah prie sur lui",
            "ru": "Аллах благословляет его",
            "ar": "إن الله وملائكته يصلون",
        },
        "meaning": {
            "en": "Allah and His angels send salah upon the Prophet ﷺ. Believers are commanded to send salah and greetings upon him too.",
            "nl": "Allah en Zijn engelen zenden salah over de Profeet ﷺ. Gelovigen wordt geboden ook salah en groet over hem te zenden.",
            "es": "Allah y Sus ángeles envían salah sobre el Profeta ﷺ. Se ordena a los creyentes enviar también salah y saludo sobre él.",
            "de": "Allah und Seine Engel senden Salah auf den Propheten ﷺ. Den Gläubigen ist geboten, ebenfalls Salah und Gruß auf ihn zu senden.",
            "fr": "Allah et Ses anges prient sur le Prophète ﷺ. Il est enjoint aux croyants de prier et de le saluer aussi.",
            "ru": "Аллах и Его ангелы благословляют Пророка ﷺ. Верующим велено также благословлять его и приветствовать.",
            "ar": "إن الله وملائكته يصلون على النبي، يا أيها الذين آمنوا صلوا عليه وسلموا تسليمًا.",
        },
    },
    {
        "id": "jumuah",
        "source": "Qur’an 62:9",
        "title": {
            "en": "When Friday is called",
            "nl": "Als de vrijdag wordt omgeroepen",
            "es": "Cuando se llama el viernes",
            "de": "Wenn der Freitag ausgerufen wird",
            "fr": "Quand on appelle le vendredi",
            "ru": "Когда зовут на пятницу",
            "ar": "إذا نودي للصلاة من يوم الجمعة",
        },
        "meaning": {
            "en": "When the call is made for Friday prayer, leave trade and hasten to the remembrance of Allah.",
            "nl": "Als de oproep tot het vrijdaggebed klinkt, laat handel achterwege en haast je naar de gedachtenis van Allah.",
            "es": "Cuando se llama a la oración del viernes, dejad el comercio y acudid al recuerdo de Allah.",
            "de": "Wenn zum Freitagsgebet gerufen wird, lasst den Handel und eilt zum Gedenken Allahs.",
            "fr": "Quand on appelle à la prière du vendredi, laissez le commerce et hâtez-vous vers le rappel d’Allah.",
            "ru": "Когда зовут на пятничную молитву, оставьте торговлю и спешите к поминанию Аллаха.",
            "ar": "إذا نودي للصلاة من يوم الجمعة فاسعوا إلى ذكر الله وذروا البيع.",
        },
    },
    {
        "id": "wudu_ayah",
        "source": "Qur’an 5:6",
        "title": {
            "en": "How wudu is in the Quran",
            "nl": "Hoe wudu in de Koran staat",
            "es": "El wudu en el Corán",
            "de": "Wudu im Koran",
            "fr": "Les ablutions dans le Coran",
            "ru": "Омовение в Коране",
            "ar": "الوضوء في القرآن",
        },
        "meaning": {
            "en": "The Quran names the wudu: wash the faces and arms to the elbows, wipe the heads, and wash the feet to the ankles.",
            "nl": "De Koran noemt de wudu: wast de gezichten en de armen tot de ellebogen, veegt over de hoofden en wast de voeten tot de enkels.",
            "es": "El Corán describe el wudu: lavad el rostro y los brazos hasta los codos, pasad la mano por la cabeza y lavad los pies hasta los tobillos.",
            "de": "Der Koran nennt das Wudu: wascht die Gesichter und die Arme bis zu den Ellbogen, streicht über die Köpfe und wascht die Füße bis zu den Knöcheln.",
            "fr": "Le Coran décrit les ablutions : lavez les visages et les bras jusqu’aux coudes, passez les mains sur les têtes, et lavez les pieds jusqu’aux chevilles.",
            "ru": "Коран называет омовение: умывайте лица и руки до локтей, протирайте головы и мойте ноги до щиколоток.",
            "ar": "ذكر القرآن الوضوء: فاغسلوا وجوهكم وأيديكم إلى المرافق وامسحوا برؤوسكم وأرجلكم إلى الكعبين.",
        },
    },
    {
        "id": "no_compulsion",
        "source": "Qur’an 2:256",
        "title": {
            "en": "No compulsion in the religion",
            "nl": "Geen dwang in de religie",
            "es": "No hay coacción en la religión",
            "de": "Kein Zwang im Glauben",
            "fr": "Nulle contrainte dans la religion",
            "ru": "Нет принуждения в религии",
            "ar": "لا إكراه في الدين",
        },
        "meaning": {
            "en": "There is no compulsion in the religion. Right guidance has become distinct from error.",
            "nl": "Er is geen dwang in de religie. Het juiste pad is duidelijk geworden, onderscheiden van dwaling.",
            "es": "No hay coacción en la religión. El camino recto se ha distinguido del error.",
            "de": "Es gibt keinen Zwang im Glauben. Der rechte Weg ist klar vom Irrtum unterschieden.",
            "fr": "Nulle contrainte dans la religion. Le bon chemin s’est distingué de l’égarement.",
            "ru": "Нет принуждения в религии. Прямой путь уже отличился от заблуждения.",
            "ar": "لا إكراه في الدين، قد تبين الرشد من الغي.",
        },
    },
    {
        "id": "quran_easy_remember",
        "source": "Qur’an 54:17",
        "title": {
            "en": "Made easy to remember",
            "nl": "Makkelijk gemaakt om te onthouden",
            "es": "Facilitado para recordar",
            "de": "Leicht gemacht zum Merken",
            "fr": "Rendu facile à retenir",
            "ru": "Облегчён для поминания",
            "ar": "يسرناه للذكر",
        },
        "meaning": {
            "en": "Allah said: “We have certainly made the Quran easy to remember. So is there any who will remember?” This wording is repeated in Surah Al-Qamar.",
            "nl": "Allah zei: “Voorwaar, Wij hebben de Koran makkelijk gemaakt om te onthouden. Is er dan iemand die zich laat vermanen?” Deze formulering keert terug in soera Al-Qamar.",
            "es": "Allah dijo: “Ciertamente hemos hecho el Corán fácil de recordar. ¿Hay quien recuerde?” Esta frase se repite en la sura Al-Qamar.",
            "de": "Allah sagte: „Wahrlich, Wir haben den Koran leicht zum Gedenken gemacht. Gibt es denn jemanden, der bedenkt?“ Dieser Wortlaut wiederholt sich in Sure Al-Qamar.",
            "fr": "Allah a dit : « Nous avons certes rendu le Coran facile à rappeler. Y a-t-il quelqu’un qui se rappelle ? » Cette formule revient dans la sourate Al-Qamar.",
            "ru": "Аллах сказал: «Воистину, Мы облегчили Коран для поминания. Есть ли поминающий?» Эти слова повторяются в суре «Аль-Камар».",
            "ar": "قال تعالى: «ولقد يسرنا القرآن للذكر فهل من مدكر». وتتكرر هذه الآية في سورة القمر.",
        },
    },
    {
        "id": "bismillah_tawbah",
        "source": "Uthmani mushaf · Qur’an 9",
        "title": {
            "en": "No Bismillah before At-Tawbah",
            "nl": "Geen Bismillah voor At-Tawbah",
            "es": "Sin Bismillah antes de At-Tawbah",
            "de": "Kein Bismillah vor At-Tauba",
            "fr": "Pas de Bismillah avant At-Tawba",
            "ru": "Без басмалы перед «Ат-Тауба»",
            "ar": "التوبة بلا بسملة",
        },
        "meaning": {
            "en": "In the Uthmani mushaf every surah begins with the Bismillah except At-Tawbah (surah 9).",
            "nl": "In de Oethmaanse mushaf begint elke soera met de Bismillah, behalve At-Tawbah (soera 9).",
            "es": "En el mushaf utmaní cada sura empieza con la Bismillah, excepto At-Tawbah (sura 9).",
            "de": "Im uthmanischen Mushaf beginnt jede Sure mit der Bismillah — außer At-Tauba (Sure 9).",
            "fr": "Dans le mushaf othmanien, chaque sourate commence par la Basmala, sauf At-Tawba (sourate 9).",
            "ru": "В османском мусхафе каждая сура начинается с басмалы, кроме «Ат-Тауба» (сура 9).",
            "ar": "في المصحف العثماني تبدأ كل سورة بالبسملة إلا سورة التوبة.",
        },
    },
    {
        "id": "fatiha_seven",
        "source": "Qur’an 15:87 · Qur’an 1",
        "title": {
            "en": "Seven oft-repeated",
            "nl": "Zeven vaak herhaalde",
            "es": "Siete reiterados",
            "de": "Sieben oft Wiederholte",
            "fr": "Les sept répétés",
            "ru": "Семь повторяемых",
            "ar": "سبعًا من المثاني",
        },
        "meaning": {
            "en": "Al-Fatiha has seven ayahs. Many scholars take “the seven oft-repeated” in 15:87 to refer to it — recited in every salah.",
            "nl": "Al-Fatiha telt zeven verzen. Veel geleerden zien in “de zeven vaak herhaalde” (15:87) deze soera — in elke salah gereciteerd.",
            "es": "Al-Fatiha tiene siete aleyas. Muchos eruditos entienden «los siete reiterados» (15:87) como esta sura, recitada en cada salah.",
            "de": "Al-Fatiha hat sieben Verse. Viele Gelehrte deuten „die sieben oft Wiederholten“ (15:87) auf sie — in jedem Salah rezitiert.",
            "fr": "Al-Fatiha compte sept versets. Beaucoup de savants voient en « les sept répétés » (15:87) cette sourate, récitée à chaque salat.",
            "ru": "В «Аль-Фатиха» семь аятов. Многие учёные относят «семь повторяемых» (15:87) к ней — её читают в каждом намазе.",
            "ar": "الفاتحة سبع آيات. وكثير من أهل العلم يجعلون «سبعًا من المثاني» في الحجر هي الفاتحة، تُقرأ في كل صلاة.",
        },
    },
    {
        "id": "ikhlas_third",
        "source": "Sahih al-Bukhari 5015",
        "title": {
            "en": "Ikhlas is a third of the Quran",
            "nl": "Ikhlas is een derde van de Koran",
            "es": "Ikhlas es un tercio del Corán",
            "de": "Ikhlas ist ein Drittel des Korans",
            "fr": "Al-Ikhlas est un tiers du Coran",
            "ru": "«Аль-Ихлас» — треть Корана",
            "ar": "الإخلاص ثلث القرآن",
        },
        "meaning": {
            "en": "The Prophet ﷺ said that “Qul Huwa Allahu Ahad” (Al-Ikhlas) is equal to a third of the Quran.",
            "nl": "De Profeet ﷺ zei dat “Qul Huwa Allahu Ahad” (Al-Ikhlas) gelijk is aan een derde van de Koran.",
            "es": "El Profeta ﷺ dijo que «Qul Huwa Allahu Ahad» (Al-Ikhlas) equivale a un tercio del Corán.",
            "de": "Der Prophet ﷺ sagte, „Qul Huwa Allahu Ahad“ (Al-Ikhlas) gleiche einem Drittel des Korans.",
            "fr": "Le Prophète ﷺ a dit que « Qul Huwa Allahu Ahad » (Al-Ikhlas) équivaut à un tiers du Coran.",
            "ru": "Пророк ﷺ сказал, что «Куль хува Аллаху ахад» («Аль-Ихлас») равна трети Корана.",
            "ar": "قال النبي ﷺ إن «قل هو الله أحد» تعدل ثلث القرآن.",
        },
    },
    {
        "id": "kursi_greatest",
        "source": "Sahih Muslim 810",
        "title": {
            "en": "The greatest ayah",
            "nl": "Het grootste vers",
            "es": "La aleya más grande",
            "de": "Der größte Vers",
            "fr": "Le plus grand verset",
            "ru": "Величайший аят",
            "ar": "أعظم آية",
        },
        "meaning": {
            "en": "The Prophet ﷺ asked Ubayy ibn Ka‘b which ayah in the Book of Allah is greatest. He answered Ayat al-Kursi, and the Prophet ﷺ confirmed it.",
            "nl": "De Profeet ﷺ vroeg Ubayy ibn Ka‘b welk vers in het Boek van Allah het grootst is. Hij antwoordde Ayat al-Kursi, en de Profeet ﷺ bevestigde dat.",
            "es": "El Profeta ﷺ preguntó a Ubayy ibn Ka‘b cuál era la aleya más grande del Libro de Allah. Respondió Ayat al-Kursi, y el Profeta ﷺ lo confirmó.",
            "de": "Der Prophet ﷺ fragte Ubayy ibn Ka‘b nach dem größten Vers im Buch Allahs. Er nannte Ayat al-Kursi, und der Prophet ﷺ bestätigte es.",
            "fr": "Le Prophète ﷺ demanda à Ubayy ibn Ka‘b quel verset du Livre d’Allah est le plus grand. Il cita le verset du Trône, et le Prophète ﷺ confirma.",
            "ru": "Пророк ﷺ спросил Убайя ибн Ка‘ба, какой аят в Книге Аллаха величайший. Он назвал аят аль-Курси, и Пророк ﷺ подтвердил.",
            "ar": "سأل النبي ﷺ أُبيّ بن كعب: أي آية في كتاب الله أعظم؟ فقال آية الكرسي، فأقرّه النبي ﷺ.",
        },
    },
    {
        "id": "muawwidhatayn",
        "source": "Sahih al-Bukhari 5016",
        "title": {
            "en": "The two protecting surahs",
            "nl": "De twee beschermende soera’s",
            "es": "Las dos suras de protección",
            "de": "Die zwei Schutzsuren",
            "fr": "Les deux sourates de protection",
            "ru": "Две защищающие суры",
            "ar": "المعوذتان",
        },
        "meaning": {
            "en": "Al-Falaq and An-Nas are called the Mu‘awwidhatayn. The Prophet ﷺ used them for protection and taught them.",
            "nl": "Al-Falaq en An-Nas heten de Mu‘awwidhatayn. De Profeet ﷺ gebruikte ze ter bescherming en onderwees ze.",
            "es": "Al-Falaq y An-Nas se llaman las Mu‘awwidhatayn. El Profeta ﷺ las usaba como protección y las enseñó.",
            "de": "Al-Falaq und An-Nas heißen die Mu‘awwidhatayn. Der Prophet ﷺ nutzte sie zum Schutz und lehrte sie.",
            "fr": "Al-Falaq et An-Nas sont les Mu‘awwidhatayn. Le Prophète ﷺ s’en servait comme protection et les enseigna.",
            "ru": "«Аль-Фалак» и «Ан-Нас» — му‘аввизатан. Пророк ﷺ читал их для защиты и учил им.",
            "ar": "الفلق والناس هما المعوذتان. كان النبي ﷺ يتعوذ بهما ويعلمهما.",
        },
    },
    {
        "id": "iman_six",
        "source": "Sahih Muslim 8 · Qur’an 4:136",
        "title": {
            "en": "Six articles of iman",
            "nl": "Zes zuilen van iman",
            "es": "Seis pilares del iman",
            "de": "Sechs Pfeiler des Iman",
            "fr": "Six piliers de la foi",
            "ru": "Шесть столпов имана",
            "ar": "أركان الإيمان الستة",
        },
        "meaning": {
            "en": "Iman is to believe in Allah, His angels, His books, His messengers, the Last Day, and divine decree — its good and its hard.",
            "nl": "Iman is geloven in Allah, Zijn engelen, Zijn boeken, Zijn boodschappers, de Laatste Dag en de goddelijke beschikking — het goede en het zware.",
            "es": "El iman es creer en Allah, Sus ángeles, Sus libros, Sus mensajeros, el Último Día y el decreto — lo bueno y lo duro.",
            "de": "Iman ist Glaube an Allah, Seine Engel, Seine Bücher, Seine Gesandten, den Jüngsten Tag und die Vorherbestimmung — das Gute und das Schwere.",
            "fr": "La foi est de croire en Allah, Ses anges, Ses livres, Ses messagers, le Jour dernier et le décret — le bon et l’épreuve.",
            "ru": "Иман — вера в Аллаха, Его ангелов, Его писания, Его посланников, Последний день и предопределение — его добро и тягость.",
            "ar": "الإيمان أن تؤمن بالله وملائكته وكتبه ورسله واليوم الآخر والقدر خيره وشره.",
        },
    },
    {
        "id": "revealed_books",
        "source": "Qur’an 3:3 · Qur’an 4:163 · Qur’an 5:46",
        "title": {
            "en": "Books named in the Quran",
            "nl": "Boeken die de Koran noemt",
            "es": "Libros nombrados en el Corán",
            "de": "Im Koran genannte Bücher",
            "fr": "Livres nommés dans le Coran",
            "ru": "Писания, названные в Коране",
            "ar": "كتب سماها القرآن",
        },
        "meaning": {
            "en": "Besides the Quran, the Book names the Tawrah, the Injil, and the Zabur — scriptures given to messengers before.",
            "nl": "Naast de Koran noemt het Boek de Tawrah, het Indjil en de Zabur — schriften die eerdere boodschappers ontvingen.",
            "es": "Además del Corán, el Libro nombra la Tora, el Evangelio y los Salmos: escrituras dadas a mensajeros anteriores.",
            "de": "Neben dem Koran nennt das Buch Tawrah, Indschil und Zabur — Schriften, die früheren Gesandten gegeben wurden.",
            "fr": "Outre le Coran, le Livre nomme la Torah, l’Évangile et les Psaumes — écritures données aux messagers d’avant.",
            "ru": "Помимо Корана Книга называет Тауру, Инджиль и Забур — писания, данные прежним посланникам.",
            "ar": "سمّى القرآن التوراة والإنجيل والزبور، كتبًا أُوتيها الرسل من قبل.",
        },
    },
    {
        "id": "twelve_months",
        "source": "Qur’an 9:36",
        "title": {
            "en": "Twelve months with Allah",
            "nl": "Twaalf maanden bij Allah",
            "es": "Doce meses ante Allah",
            "de": "Zwölf Monate bei Allah",
            "fr": "Douze mois auprès d’Allah",
            "ru": "Двенадцать месяцев у Аллаха",
            "ar": "اثنا عشر شهرًا",
        },
        "meaning": {
            "en": "The number of months with Allah is twelve, in the Book of Allah, the day He created the heavens and the earth — four of them sacred.",
            "nl": "Het aantal maanden bij Allah is twaalf, in het Boek van Allah, sinds Hij de hemelen en de aarde schiep — waarvan vier heilig.",
            "es": "El número de meses ante Allah es doce, en el Libro de Allah desde que creó los cielos y la tierra: cuatro de ellos sagrados.",
            "de": "Die Anzahl der Monate bei Allah ist zwölf, im Buch Allahs, seit Er Himmel und Erde erschuf — vier davon sind heilig.",
            "fr": "Le nombre de mois auprès d’Allah est de douze, dans le Livre d’Allah, le jour où Il créa les cieux et la terre — dont quatre sacrés.",
            "ru": "Число месяцев у Аллаха — двенадцать, в Книге Аллаха с того дня, как Он сотворил небеса и землю; четыре из них священны.",
            "ar": "إن عدة الشهور عند الله اثنا عشر شهرًا في كتاب الله يوم خلق السموات والأرض، منها أربعة حرم.",
        },
    },
    {
        "id": "maqam_ibrahim",
        "source": "Qur’an 2:125",
        "title": {
            "en": "The Station of Ibrahim",
            "nl": "De standplaats van Ibrahim",
            "es": "La estación de Ibrahim",
            "de": "Der Standort Ibrahims",
            "fr": "La station d’Ibrahim",
            "ru": "Стоянка Ибрахима",
            "ar": "مقام إبراهيم",
        },
        "meaning": {
            "en": "Take the Station of Ibrahim as a place of prayer. The Quran links it to the House that Ibrahim and Ismail were commanded to purify.",
            "nl": "Neem de standplaats van Ibrahim tot gebedsplaats. De Koran verbindt die met het Huis dat Ibrahim en Ismail moesten reinigen.",
            "es": "Tomad la estación de Ibrahim como lugar de oración. El Corán la une a la Casa que Ibrahim e Ismail debían purificar.",
            "de": "Nehmt den Standort Ibrahims zum Gebetsort. Der Koran verbindet ihn mit dem Haus, das Ibrahim und Ismail reinigen sollten.",
            "fr": "Prenez la station d’Ibrahim comme lieu de prière. Le Coran la lie à la Maison qu’Ibrahim et Ismail devaient purifier.",
            "ru": "Сделайте стоянку Ибрахима местом молитвы. Коран связывает её с Домом, который Ибрахим и Исмаил должны были очищать.",
            "ar": "واتخذوا من مقام إبراهيم مصلى. وربط القرآن ذلك بالبيت الذي أُمر إبراهيم وإسماعيل أن يطهراه.",
        },
    },
    {
        "id": "named_prophets",
        "source": "Qur’an · 25 named prophets",
        "title": {
            "en": "25 prophets named",
            "nl": "25 profeten bij naam",
            "es": "25 profetas nombrados",
            "de": "25 namentlich genannte Propheten",
            "fr": "25 prophètes nommés",
            "ru": "25 названных пророков",
            "ar": "٢٥ نبيًا مسمّى",
        },
        "meaning": {
            "en": "The Quran names twenty-five prophets, from Adam to Muhammad ﷺ. Other messengers are mentioned without being named.",
            "nl": "De Koran noemt vijfentwintig profeten, van Adam tot Mohammed ﷺ. Andere boodschappers worden genoemd zonder naam.",
            "es": "El Corán nombra veinticinco profetas, de Adán a Muhammad ﷺ. Otros mensajeros se mencionan sin nombre.",
            "de": "Der Koran nennt fünfundzwanzig Propheten, von Adam bis Muhammad ﷺ. Andere Gesandte werden ohne Namen erwähnt.",
            "fr": "Le Coran nomme vingt-cinq prophètes, d’Adam à Muhammad ﷺ. D’autres messagers sont cités sans être nommés.",
            "ru": "Коран называет двадцать пять пророков — от Адама до Мухаммада ﷺ. Другие посланники упомянуты без имён.",
            "ar": "سمّى القرآن خمسة وعشرين نبيًا، من آدم إلى محمد ﷺ. وذكر رسلًا آخرين بغير أسمائهم.",
        },
    },
    {
        "id": "ninety_nine_names",
        "source": "Sahih al-Bukhari 2736 · Sahih Muslim 2677",
        "title": {
            "en": "Ninety-nine names",
            "nl": "Negenennegentig namen",
            "es": "Noventa y nueve nombres",
            "de": "Neunundneunzig Namen",
            "fr": "Quatre-vingt-dix-neuf noms",
            "ru": "Девяносто девять имён",
            "ar": "تسعة وتسعون اسمًا",
        },
        "meaning": {
            "en": "The Prophet ﷺ said Allah has ninety-nine names, one hundred minus one; whoever enumerates them will enter Paradise.",
            "nl": "De Profeet ﷺ zei dat Allah negenennegentig namen heeft, honderd min één; wie ze opsomt, gaat het paradijs binnen.",
            "es": "El Profeta ﷺ dijo que Allah tiene noventa y nueve nombres, cien menos uno; quien los enumeré entrará en el Paraíso.",
            "de": "Der Prophet ﷺ sagte, Allah habe neunundneunzig Namen, hundert minus eins; wer sie aufzählt, kommt ins Paradies.",
            "fr": "Le Prophète ﷺ a dit qu’Allah a quatre-vingt-dix-neuf noms, cent moins un ; quiconque les énumère entre au Paradis.",
            "ru": "Пророк ﷺ сказал, что у Аллаха девяносто девять имён — сто без одного; кто их перечислит, войдёт в Рай.",
            "ar": "قال النبي ﷺ: إن لله تسعة وتسعين اسمًا، مائة إلا واحدًا، من أحصاها دخل الجنة.",
        },
    },
    {
        "id": "seven_mathani",
        "source": "Qur’an 15:87",
        "title": {
            "en": "Seven of the oft-repeated",
            "nl": "Zeven vaak herhaalde",
            "es": "Siete de las repetidas",
            "de": "Sieben oft Wiederholte",
            "fr": "Sept des souvent répétées",
            "ru": "Семь повторяемых",
            "ar": "سبعًا من المثاني",
        },
        "meaning": {
            "en": "Allah says He gave the Prophet ﷺ seven of the oft-repeated and the Great Quran. Many scholars take this as Al-Fatiha.",
            "nl": "Allah zegt dat Hij de Profeet ﷺ zeven van de vaak herhaalde gaf, en de Grote Koran. Veel geleerden nemen dit als Al-Fatiha.",
            "es": "Allah dice que dio al Profeta ﷺ siete de las a menudo repetidas y el Gran Corán. Muchos sabios lo entienden como Al-Fatiha.",
            "de": "Allah sagt, Er habe dem Propheten ﷺ sieben der oft Wiederholten und den großen Koran gegeben. Viele Gelehrte deuten das als Al-Fatiha.",
            "fr": "Allah dit qu’Il a donné au Prophète ﷺ sept des souvent répétées et le Grand Coran. Beaucoup de savants y voient Al-Fatiha.",
            "ru": "Аллах говорит, что дал Пророку ﷺ семь повторяемых и Великий Коран. Многие учёные относят это к «Аль-Фатиха».",
            "ar": "قال تعالى: «ولقد آتيناك سبعًا من المثاني والقرآن العظيم». وكثير من أهل العلم يرونها الفاتحة.",
        },
    },
    {
        "id": "safa_marwa",
        "source": "Qur’an 2:158",
        "title": {
            "en": "Safa and Marwah",
            "nl": "Safa en Marwa",
            "es": "Safa y Marwa",
            "de": "Safa und Marwa",
            "fr": "Safa et Marwa",
            "ru": "Сафа и Марва",
            "ar": "الصفا والمروة",
        },
        "meaning": {
            "en": "Safa and Marwah are among the rites of Allah. Whoever makes Hajj or Umrah to the House, there is no blame in walking between them.",
            "nl": "Safa en Marwa behoren tot de riten van Allah. Wie hadj of oemra naar het Huis verricht, daar is geen blaam in het lopen tussen beide.",
            "es": "Safa y Marwa son de los ritos de Allah. Quien haga Hayy o Umra a la Casa no peca al andar entre ambas.",
            "de": "Safa und Marwa gehören zu den Riten Allahs. Wer Haddsch oder Umra zum Haus verrichtet, dem ist kein Vorwurf, dazwischen zu gehen.",
            "fr": "Safa et Marwa font partie des rites d’Allah. Quiconque fait le hajj ou la umra vers la Maison n’encourt aucun blâme à circuler entre elles.",
            "ru": "Сафа и Марва — из обрядов Аллаха. Кто совершает хадж или умру к Дому, нет греха ходить между ними.",
            "ar": "إن الصفا والمروة من شعائر الله، فمن حج البيت أو اعتمر فلا جناح عليه أن يطوف بهما.",
        },
    },
    {
        "id": "four_sacred_named",
        "source": "Qur’an 9:36 · Sahih al-Bukhari 3197",
        "title": {
            "en": "Four sacred months",
            "nl": "Vier heilige maanden",
            "es": "Cuatro meses sagrados",
            "de": "Vier heilige Monate",
            "fr": "Quatre mois sacrés",
            "ru": "Четыре священных месяца",
            "ar": "أربعة أشهر حرم",
        },
        "meaning": {
            "en": "Of the twelve months, four are sacred: Dhul-Qa'dah, Dhul-Hijjah, Muharram, and Rajab — the one that stands between Jumada and Sha'ban.",
            "nl": "Van de twaalf maanden zijn er vier heilig: Dhoel-Qa’da, Dhoel-Hidjdja, Muharram en Radjab — die tussen Djoemada en Sja’ban valt.",
            "es": "De los doce meses, cuatro son sagrados: Dhul-Qa'da, Dhul-Hiyya, Muharram y Rayab, el que está entre Yumada y Sha'ban.",
            "de": "Von den zwölf Monaten sind vier heilig: Dhu l-Qaʿda, Dhu l-Hiddscha, Muharram und Radschab — der zwischen Dschumada und Schaʿban steht.",
            "fr": "Sur les douze mois, quatre sont sacrés : Dhou al-Qaʿda, Dhou al-Hijja, Muharram et Rajab — celui qui se tient entre Jumada et Shaʿban.",
            "ru": "Из двенадцати месяцев четыре священны: зу-ль-када, зу-ль-хиджа, мухаррам и раджаб — тот, что между джумада и шаабаном.",
            "ar": "منها أربعة حرم: ذو القعدة وذو الحجة والمحرم ورجب الذي بين جمادى وشعبان.",
        },
    },
    {
        "id": "three_mosques",
        "source": "Sahih al-Bukhari 1189 · Sahih Muslim 1397",
        "title": {
            "en": "Three mosques for a journey",
            "nl": "Drie moskeeën voor een reis",
            "es": "Tres mezquitas para un viaje",
            "de": "Drei Moscheen für eine Reise",
            "fr": "Trois mosquées pour un voyage",
            "ru": "Три мечети для путешествия",
            "ar": "ثلاثة مساجد تُشدّ إليها الرحال",
        },
        "meaning": {
            "en": "The Prophet ﷺ said: do not set out on a journey to visit a mosque except three: the Sacred Mosque, this mosque of mine, and Al-Aqsa.",
            "nl": "De Profeet ﷺ zei: onderneem geen reis naar een moskee behalve drie: de Heilige Moskee, deze moskee van mij, en Al-Aqsa.",
            "es": "El Profeta ﷺ dijo: no emprendáis viaje para visitar una mezquita salvo tres: la Sagrada, esta mía y Al-Aqsa.",
            "de": "Der Prophet ﷺ sagte: Reist zu keiner Moschee außer dreien: der Heiligen Moschee, dieser meiner Moskee und Al-Aqsa.",
            "fr": "Le Prophète ﷺ a dit : ne partez en voyage vers une mosquée que vers trois : la Mosquée sacrée, cette mosquée qui est la mienne, et Al-Aqsa.",
            "ru": "Пророк ﷺ сказал: не отправляйтесь в путь к мечети, кроме трёх: Заповедной, этой моей мечети и Аль-Акса.",
            "ar": "قال النبي ﷺ: لا تُشدّ الرحال إلا إلى ثلاثة مساجد: المسجد الحرام، ومسجدي هذا، والمسجد الأقصى.",
        },
    },
    {
        "id": "last_two_baqarah",
        "source": "Sahih al-Bukhari 5009 · Sahih Muslim 808",
        "title": {
            "en": "The last two ayahs of Al-Baqarah",
            "nl": "De laatste twee verzen van Al-Baqarah",
            "es": "Las dos últimas aleyas de Al-Baqarah",
            "de": "Die letzten zwei Verse von Al-Baqara",
            "fr": "Les deux derniers versets d’Al-Baqara",
            "ru": "Последние два аята «Аль-Бакара»",
            "ar": "آيتان من آخر البقرة",
        },
        "meaning": {
            "en": "The Prophet ﷺ said whoever recites the last two ayahs of Al-Baqarah at night, they will suffice him.",
            "nl": "De Profeet ﷺ zei dat wie de laatste twee verzen van Al-Baqarah ’s nachts reciteert, die hem zullen volstaan.",
            "es": "El Profeta ﷺ dijo que quien recita las dos últimas aleyas de Al-Baqarah por la noche, le bastarán.",
            "de": "Der Prophet ﷺ sagte, wer die letzten zwei Verse von Al-Baqara nachts rezitiert, dem genügen sie.",
            "fr": "Le Prophète ﷺ a dit que quiconque récite les deux derniers versets d’Al-Baqara la nuit, ils lui suffisent.",
            "ru": "Пророк ﷺ сказал: кто прочтёт ночью последние два аята «Аль-Бакара», они ему достаточны.",
            "ar": "قال النبي ﷺ: من قرأ بالآيتين من آخر سورة البقرة في ليلة كفتاه.",
        },
    },
    {
        "id": "best_days_dhulhijjah",
        "source": "Sahih al-Bukhari 969",
        "title": {
            "en": "The best days of the year",
            "nl": "De beste dagen van het jaar",
            "es": "Los mejores días del año",
            "de": "Die besten Tage des Jahres",
            "fr": "Les meilleurs jours de l’année",
            "ru": "Лучшие дни года",
            "ar": "أفضل أيام الدنيا",
        },
        "meaning": {
            "en": "The Prophet ﷺ said there are no days in which righteous deeds are more beloved to Allah than these ten days — the first ten of Dhul-Hijjah.",
            "nl": "De Profeet ﷺ zei dat er geen dagen zijn waarop rechtvaardige daden Allah meer bemind zijn dan deze tien — de eerste tien van Dhoel-Hidjdja.",
            "es": "El Profeta ﷺ dijo que no hay días en que las obras justas sean más amadas por Allah que estos diez: los primeros de Dhul-Hiyya.",
            "de": "Der Prophet ﷺ sagte, es gebe keine Tage, an denen rechtschaffene Taten Allah lieber seien als diese zehn — die ersten zehn des Dhu l-Hiddscha.",
            "fr": "Le Prophète ﷺ a dit qu’il n’est pas de jours où les œuvres pies soient plus aimées d’Allah que ces dix — les dix premiers de Dhou al-Hijja.",
            "ru": "Пророк ﷺ сказал, что нет дней, в которые праведные дела любимее Аллаху, чем эти десять — первые десять зу-ль-хиджи.",
            "ar": "قال النبي ﷺ: ما من أيام العمل الصالح فيها أحب إلى الله من هذه الأيام، يعني عشر ذي الحجة.",
        },
    },
]


def ar_plain(s: str) -> str:
    s = (s or "").replace("\ufeff", "")
    out = []
    for ch in s:
        o = ord(ch)
        if 0x064B <= o <= 0x065F:
            continue
        if 0x06D6 <= o <= 0x06ED:
            continue
        if ch in "\u0640\u06E5\u06E6":
            continue
        if ch == "\u0670":  # dagger alif → regular alif for counts
            out.append("ا")
            continue
        out.append("ا" if ch == "ٱ" else ch)
    return "".join(out)


def ar_tokens(s: str) -> list[str]:
    return re.findall(r"[^\s]+", ar_plain(s))


def count_ar_token(ar_map, token: str) -> int:
    needle = ar_plain(token)
    return sum(1 for text in ar_map.values() for w in ar_tokens(text) if ar_plain(w) == needle)


def count_ar_phrase(ar_map, phrase: str) -> int:
    needle = re.sub(r"\s+", "", ar_plain(phrase))
    total = 0
    for text in ar_map.values():
        hay = re.sub(r"\s+", "", ar_plain(text))
        total += hay.count(needle)
    return total


def count_identical_ayahs(ar_map, key, surah_only=None) -> int:
    sample = ar_plain(ar_map[key])
    n = 0
    for (s, _a), text in ar_map.items():
        if surah_only is not None and s != surah_only:
            continue
        if ar_plain(text) == sample:
            n += 1
    return n


def count_ar_token_any(ar_map, *tokens: str) -> int:
    return sum(count_ar_token(ar_map, t) for t in tokens)


def get_json(url: str):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    path = CACHE_DIR / f"{hashlib.sha1(url.encode()).hexdigest()}.json"
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    req = urllib.request.Request(url, headers={"User-Agent": "ScrollDeeds/1.0"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    path.write_text(json.dumps(data), encoding="utf-8")
    return data


def esc_strings(s: str) -> str:
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ").replace("\r", " ")
    s = re.sub(r"\s+", " ", s).strip()
    return s


def esc_swift(s: str) -> str:
    s = (s or "").replace("\ufeff", "")
    return s.replace("\\", "\\\\").replace('"', '\\"')


def polish_nl_quran(text: str) -> str:
    """Keep Allah (app voice) and strip OCR junk from Dutch Quran dumps."""
    text = re.sub(
        r"THIS TEXT HAS BEEN AUTOMATICALLY GENERATED[\s\S]*$",
        "",
        text,
        flags=re.I,
    )
    text = re.sub(r"\bGods\b", "Allahs", text)
    text = re.sub(r"\bGod\b", "Allah", text)
    fixes = (
        (r"\bboe\b", "hoe"),
        (r"\bKinderem\b", "Kinderen"),
        (r"\bkinderem\b", "kinderen"),
        (r"\barde\b", "aarde"),
        (r"\bdead\b", "deed"),
        (r"\bmetgezet\b", "metgezel"),
        (r"\bnasst\b", "naast"),
        (r"\bteokennen\b", "toekennen"),
        (r"\bven\b", "van"),
        (r"\bYolk\b", "Volk"),
        (r"\bverarderen\b", "veranderen"),
        (r"\bVoorwar\b", "Voorwaar"),
        (r"groEt", "groet"),
        (r"wanneerjullie", "wanneer jullie"),
        (r"aangeraakts", "aangeraakt"),
    )
    for pattern, repl in fixes:
        text = re.sub(pattern, repl, text)
    return re.sub(r"\s+", " ", text).strip()


def fetch_quran():
    quran = {}
    for lang, edition in EDITIONS.items():
        print("fetch quran", edition)
        data = get_json(f"https://api.alquran.cloud/v1/quran/{edition}")["data"]
        by_ayah = {}
        for surah in data["surahs"]:
            sn = surah["number"]
            for ayah in surah["ayahs"]:
                by_ayah[(sn, ayah["numberInSurah"])] = (
                    polish_nl_quran(ayah["text"]) if lang == "nl" else ayah["text"]
                )
        quran[lang] = by_ayah
    return quran


def fetch_surahs():
    print("fetch surah list")
    return get_json("https://api.alquran.cloud/v1/surah")["data"]


def fetch_juz_starts():
    starts = []
    for n in range(1, 31):
        print("fetch juz", n)
        data = get_json(f"https://api.alquran.cloud/v1/juz/{n}/en.sahih")["data"]
        ayahs = data["ayahs"]
        first = ayahs[0]
        surah = first["surah"]
        starts.append(
            {
                "juz": n,
                "surah": surah["number"],
                "ayah": first["numberInSurah"],
                "en_name": surah["englishName"],
                "ar_name": surah["name"],
            }
        )
    return starts


def fetch_hadiths():
    langs = {
        "en": "eng",
        "ar": "ara",
        "fr": "fra",
        "ru": "rus",
    }
    collections = {}
    for book in ("bukhari", "muslim"):
        collections[book] = {}
        for lang, prefix in langs.items():
            print("fetch hadith", prefix, book)
            url = f"https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/{prefix}-{book}.min.json"
            collections[book][lang] = get_json(url)["hadiths"]
    return collections


def extract_matn(ar: str) -> str | None:
    """Keep the quoted prophetic wording, not the isnad chain."""
    matches = re.findall(r'‏\s*"‏\s*(.+?)\s*‏"‏', ar, flags=re.DOTALL)
    if not matches:
        matches = re.findall(r'"‏\s*(.+?)\s*‏"', ar, flags=re.DOTALL)
    if not matches:
        return None
    text = max(matches, key=len)
    text = re.sub(r"\s+", " ", text).strip()
    return text if len(text) >= 8 else None


def pick_hadiths(collections, limit=220):
    picked = []
    seen_en = set()
    skip_sub = (
        "intentions",
        "reward of deeds depends",
        "smile in the face",
        "siwak",
        "half a date",
    )
    for book in ("bukhari", "muslim"):
        en_list = collections[book]["en"]
        by_num = {h["hadithnumber"]: h for h in en_list}
        others = {
            lang: {h["hadithnumber"]: h for h in collections[book][lang]}
            for lang in ("ar", "fr", "ru")
        }
        for h in en_list:
            text = (h.get("text") or "").strip()
            if not text or len(text) < 40 or len(text) > 280:
                continue
            low = text.lower()
            if any(s in low for s in skip_sub):
                continue
            key = re.sub(r"\s+", " ", low)[:80]
            if key in seen_en:
                continue
            num = h["hadithnumber"]
            ar = (others["ar"].get(num) or {}).get("text") or ""
            if len(ar.strip()) < 8:
                continue
            picked.append(
                {
                    "book": book,
                    "num": num,
                    "en": text,
                    "ar": ar.strip(),
                    "fr": ((others["fr"].get(num) or {}).get("text") or "").strip(),
                    "ru": ((others["ru"].get(num) or {}).get("text") or "").strip(),
                }
            )
            seen_en.add(key)
            if len(picked) >= limit:
                return picked
    return picked


def fact_surah_copy(lang, name, trans, place, n):
    if lang == "en":
        return (
            f"Surah {name}",
            f"Surah {name} ({trans}) was revealed in {place} and has {n} ayahs.",
        )
    if lang == "nl":
        return (
            f"Soera {name}",
            f"Soera {name} ({trans}) is in {place} neergezonden en telt {n} verzen.",
        )
    if lang == "es":
        return (
            f"Sura {name}",
            f"La sura {name} ({trans}) se reveló en {place} y tiene {n} aleyas.",
        )
    if lang == "de":
        return (
            f"Sure {name}",
            f"Die Sure {name} ({trans}) wurde in {place} offenbart und hat {n} Verse.",
        )
    if lang == "fr":
        return (
            f"Sourate {name}",
            f"La sourate {name} ({trans}) a été descendue à {place} et compte {n} versets.",
        )
    if lang == "ru":
        return (
            f"Сура {name}",
            f"Сура {name} ({trans}) ниспослана в городе {place} и содержит {n} аятов.",
        )
    return (
        name,
        f"{name} نزلت في {place} وعدد آياتها {n}.",
    )


def fact_juz_copy(lang, juz, name):
    if lang == "en":
        return (f"Juz {juz}", f"Juz {juz} of the Quran begins in Surah {name}.")
    if lang == "nl":
        return (f"Djoez {juz}", f"Djoez {juz} van de Koran begint in soera {name}.")
    if lang == "es":
        return (f"Yuz {juz}", f"El yuz {juz} del Corán empieza en la sura {name}.")
    if lang == "de":
        return (f"Dschuz {juz}", f"Dschuz {juz} des Korans beginnt in der Sure {name}.")
    if lang == "fr":
        return (f"Jouz {juz}", f"Le jouz {juz} du Coran commence dans la sourate {name}.")
    if lang == "ru":
        return (f"Джуз {juz}", f"Джуз {juz} Корана начинается в суре {name}.")
    return (f"الجزء {juz}", f"الجزء {juz} من القرآن يبدأ في {name}.")


def ayah_title(lang, surah_en, ayah_n):
    labels = {
        "en": f"{surah_en} {ayah_n}",
        "nl": f"{surah_en} {ayah_n}",
        "es": f"{surah_en} {ayah_n}",
        "de": f"{surah_en} {ayah_n}",
        "fr": f"{surah_en} {ayah_n}",
        "ru": f"{surah_en} {ayah_n}",
        "ar": f"{surah_en} {ayah_n}",
    }
    return labels[lang]


def hadith_title(lang, book, num):
    names = {
        "en": {"bukhari": "Sahih al-Bukhari", "muslim": "Sahih Muslim"},
        "nl": {"bukhari": "Sahih al-Boekhari", "muslim": "Sahih Moslim"},
        "es": {"bukhari": "Sahih al-Bujari", "muslim": "Sahih Muslim"},
        "de": {"bukhari": "Sahih al-Buchari", "muslim": "Sahih Muslim"},
        "fr": {"bukhari": "Sahih al-Bukhari", "muslim": "Sahih Muslim"},
        "ru": {"bukhari": "Сахих аль-Бухари", "muslim": "Сахих Муслим"},
        "ar": {"bukhari": "صحيح البخاري", "muslim": "صحيح مسلم"},
    }
    return f"{names[lang][book]} {num}"


def short_headline(meaning, max_len=42):
    """Clip the existing translation into a short topic title. Never invents wording."""
    text = (meaning or "").strip()
    if not text:
        return ""
    for a, b in {
        "“": '"', "”": '"', "„": '"', "«": '"', "»": '"',
        "‹": '"', "›": '"', "‘": "'", "’": "'",
    }.items():
        text = text.replace(a, b)

    quoted = re.findall(r'"([^"]{8,})"', text)
    if quoted:
        if len(quoted) >= 2 and quoted[0].rstrip().endswith(("?", "؟")):
            text = quoted[1]
        else:
            text = quoted[0]
    else:
        text = re.sub(
            r"^(?:Narrated|Overgeleverd|Relatado|Transmitido|Überliefert|Rapporté|Передано|روي)[^.!?\n]{0,160}[:：]\s*",
            "",
            text,
            flags=re.I,
        )
        said = re.search(
            r"(?:the (?:holy )?(?:prophet|messenger of allah|messenger)|allah'?s messenger|"
            r"de (?:profeet|boodschapper van allah)|el (?:profeta|mensajero de al[aá]h)|"
            r"der (?:prophet|gesandte allahs)|le (?:prophète|messager d['’]allah)|"
            r"пророк|посланник аллаха|النبي|رسول الله).{0,48}"
            r"(?:said|zei|dijo|sagte|dit|сказал|قال)\s*(?:\([^)]{0,12}\))?\s*[:：]\s*(.+)",
            text,
            flags=re.I | re.S,
        )
        if said:
            text = said.group(1)
        else:
            replied = re.search(
                r"(?:he|hij|él|er|il|он)\s+"
                r"(?:said|replied|answered|zei|antwoordde|dijo|respondió|sagte|antwortete|dit|répondit|сказал|قال)"
                r"\s*[:：]\s*(.+)",
                text,
                flags=re.I | re.S,
            )
            if replied:
                text = replied.group(1)
        text = text.strip(" \"'")

    vocative = re.sub(
        r"^(o (?:you who (?:have )?believed|mankind|people|believers)|o jullie die geloven|"
        r"o mensen|oh (?:vosotros )?los que (?:habéis )?creído|o ihr (?:die ihr glaubt|menschen)|"
        r"ô (?:vous qui (?:avez )?cru|hommes)|о (?:те,? кто уверовал|люди)|"
        r"يا أيها (?:الذين آمنوا|الناس|الإنسان))[,،:]?\s+",
        "",
        text,
        flags=re.I,
    )
    if len(vocative) >= 12:
        text = vocative

    sentence = re.split(r"(?<=[.!?؟۔])\s+", text, maxsplit=1)[0]
    clause = sentence
    if len(sentence) > max_len + 8:
        comma = re.split(r"[,;:،؛—–]\s+", sentence, maxsplit=1)[0]
        if 16 <= len(comma) <= max_len + 8:
            clause = comma
        else:
            conj = re.split(
                r"\s+(?:and|en|y|und|et|и|و|want|because|denn|car|pues)\s+",
                sentence,
                maxsplit=1,
                flags=re.I,
            )[0]
            clause = conj if len(conj) >= 16 else comma

    clause = clause.strip(" \"'.,;:")
    if clause and clause[0].isascii() and clause[0].islower():
        clause = clause[0].upper() + clause[1:]
    if len(clause) <= max_len:
        return clause
    cut = clause[:max_len].rsplit(" ", 1)[0]
    if len(cut) < 14:
        cut = clause[:max_len]
    return cut.strip(" \"'.,;:") + "…"


def hadith_source(book, num):
    if book == "bukhari":
        return f"Sahih al-Bukhari {num}"
    return f"Sahih Muslim {num}"


def load_hadith_i18n():
    if not HADITH_I18N.exists():
        return {}
    return json.loads(HADITH_I18N.read_text(encoding="utf-8"))


def hadith_meaning(lang, item, i18n):
    if lang == "ar":
        return item["ar"]
    if lang == "fr" and item["fr"]:
        return item["fr"]
    if lang == "ru" and item["ru"]:
        return item["ru"]
    key = f"{item['book']}_{item['num']}"
    if lang in i18n.get(key, {}) and i18n[key][lang].strip():
        return i18n[key][lang]
    return item["en"]


def write_strings(entries_by_lang):
    for lang, lines in entries_by_lang.items():
        path = APP / f"{lang}.lproj" / "Localizable.strings"
        text = path.read_text(encoding="utf-8")
        block = "\n".join(lines) + "\n"
        if MARKER in text:
            pre, rest = text.split(MARKER, 1)
            _, post = rest.split(MARKER_END, 1)
            text = pre + MARKER + "\n" + block + MARKER_END + post
        else:
            if not text.endswith("\n"):
                text += "\n"
            text += "\n" + MARKER + "\n" + block + MARKER_END + "\n"
        path.write_text(text, encoding="utf-8")


def main():
    quran = fetch_quran()
    surahs = fetch_surahs()
    juz_starts = fetch_juz_starts()
    collections = fetch_hadiths()
    hadiths = pick_hadiths(collections, 220)
    HADITH_PICKED.write_text(json.dumps(hadiths, ensure_ascii=False, indent=2), encoding="utf-8")
    hadith_i18n = load_hadith_i18n()
    surah_by_n = {s["number"]: s for s in surahs}

    ayahs = []
    for s, a in AYAHS:
        if (s, a) in SKIP_AYAHS:
            continue
        if (s, a) not in quran["en"]:
            continue
        ayahs.append((s, a))
    # Pad from remaining complete ayahs if under 200 — prefer short surahs.
    if len(ayahs) < 210:
        prefer = list(range(78, 115)) + list(range(1, 78))
        for s in prefer:
            count = surah_by_n[s]["numberOfAyahs"]
            for a in range(1, count + 1):
                if (s, a) in SKIP_AYAHS or (s, a) in ayahs:
                    continue
                text = quran["en"].get((s, a), "")
                if 40 <= len(text) <= 240:
                    ayahs.append((s, a))
                if len(ayahs) >= 220:
                    break
            if len(ayahs) >= 220:
                break

    swift_cards = []
    strings = {lang: [] for lang in EDITIONS}

    def add_strings(cid, titles, meanings, source):
        for lang in EDITIONS:
            strings[lang].append(f'"discovery.card.{cid}.title" = "{esc_strings(titles[lang])}";')
            strings[lang].append(f'"discovery.card.{cid}.meaning" = "{esc_strings(meanings[lang])}";')
            strings[lang].append(f'"discovery.card.{cid}.source" = "{esc_strings(source)}";')
            strings[lang].append("")

    # --- ayahs ---
    for s, a in ayahs:
        cid = f"ayah_{s}_{a}"
        ar = quran["ar"][(s, a)]
        swift_cards.append(f'        DiscoveryCard(id: "{cid}", kind: .ayah, arabic: "{esc_swift(ar)}"),')
        titles, meanings = {}, {}
        for lang in EDITIONS:
            meanings[lang] = quran[lang][(s, a)]
            titles[lang] = short_headline(meanings[lang]) or ayah_title(
                lang,
                surah_by_n[s]["name"] if lang == "ar" else surah_by_n[s]["englishName"],
                a,
            )
        add_strings(cid, titles, meanings, f"Qur’an {s}:{a}")

    # --- sunnah/hadith ---
    for item in hadiths:
        cid = f"sunnah_{item['book']}_{item['num']}"
        ar = extract_matn(item["ar"])
        ar_lit = f'"{esc_swift(ar)}"' if ar else "nil"
        swift_cards.append(f'        DiscoveryCard(id: "{cid}", kind: .sunnah, arabic: {ar_lit}),')
        titles, meanings = {}, {}
        for lang in EDITIONS:
            meanings[lang] = hadith_meaning(lang, item, hadith_i18n)
            titles[lang] = short_headline(meanings[lang]) or hadith_title(
                lang, item["book"], item["num"]
            )
        add_strings(cid, titles, meanings, hadith_source(item["book"], item["num"]))

    prophets = [
        ("adam", "Adam", "آدم", "Qur’an 2:31"),
        ("idris", "Idris", "إدريس", "Qur’an 19:56"),
        ("nuh", "Nuh", "نوح", "Qur’an 71:1"),
        ("hud", "Hud", "هود", "Qur’an 11:50"),
        ("salih", "Salih", "صالح", "Qur’an 11:61"),
        ("ibrahim", "Ibrahim", "إبراهيم", "Qur’an 2:124"),
        ("lut", "Lut", "لوط", "Qur’an 21:74"),
        ("ismail", "Ismail", "إسماعيل", "Qur’an 2:125"),
        ("ishaq", "Ishaq", "إسحاق", "Qur’an 11:71"),
        ("yaqub", "Yaqub", "يعقوب", "Qur’an 2:132"),
        ("yusuf", "Yusuf", "يوسف", "Qur’an 12:4"),
        ("ayyub", "Ayyub", "أيوب", "Qur’an 21:83"),
        ("shuayb", "Shuayb", "شعيب", "Qur’an 11:84"),
        ("musa", "Musa", "موسى", "Qur’an 20:9"),
        ("harun", "Harun", "هارون", "Qur’an 20:30"),
        ("dhulkifl", "Dhul-Kifl", "ذو الكفل", "Qur’an 21:85"),
        ("dawud", "Dawud", "داوود", "Qur’an 38:17"),
        ("sulayman", "Sulayman", "سليمان", "Qur’an 27:16"),
        ("ilyas", "Ilyas", "إلياس", "Qur’an 37:123"),
        ("alyasa", "Al-Yasa", "اليسع", "Qur’an 6:86"),
        ("yunus", "Yunus", "يونس", "Qur’an 37:139"),
        ("zakariyya", "Zakariyya", "زكريا", "Qur’an 19:2"),
        ("yahya", "Yahya", "يحيى", "Qur’an 19:7"),
        ("isa", "Isa", "عيسى", "Qur’an 3:45"),
        ("muhammad", "Muhammad ﷺ", "محمد ﷺ", "Qur’an 33:40"),
    ]
    prophet_mean = {
        "en": "The Quran names the prophet {n}. His story is part of the Book’s guidance, not a legend.",
        "nl": "De Koran noemt de profeet {n}. Zijn verhaal hoort bij de leiding van het Boek, geen sage.",
        "es": "El Corán nombra al profeta {n}. Su historia forma parte de la guía del Libro.",
        "de": "Der Koran nennt den Propheten {n}. Seine Geschichte gehört zur Rechtleitung des Buches.",
        "fr": "Le Coran nomme le prophète {n}. Son récit fait partie de la guidance du Livre.",
        "ru": "Коран называет пророка {n}. Его история — часть руководства Книги.",
        "ar": "يذكر القرآن النبي {n}. قصته من هداية الكتاب.",
    }
    prophet_title = {
        "en": "Prophet {n}",
        "nl": "Profeet {n}",
        "es": "Profeta {n}",
        "de": "Prophet {n}",
        "fr": "Prophète {n}",
        "ru": "Пророк {n}",
        "ar": "النبي {n}",
    }
    for pid, en_name, ar_name, src in prophets:
        cid = f"fact_prophet_{pid}"
        swift_cards.append(f'        DiscoveryCard(id: "{cid}", kind: .fact, arabic: nil),')
        titles, meanings = {}, {}
        for lang in EDITIONS:
            n = ar_name if lang == "ar" else en_name
            titles[lang] = prophet_title[lang].format(n=n)
            meanings[lang] = prophet_mean[lang].format(n=n)
        add_strings(cid, titles, meanings, src)

    extra_more = [
        (
            "five_prayers",
            "Sahih al-Bukhari 8 · Sahih Muslim 16",
            {
                "en": ("Five daily prayers", "Islam is built on five: the testimony of faith, salah, zakat, Hajj, and fasting Ramadan. Salah is five times every day."),
                "nl": ("Vijf dagelijkse gebeden", "De islam rust op vijf: de geloofsgetuigenis, salah, zakat, hadj en vasten in Ramadan. Salah is vijf keer per dag."),
                "es": ("Cinco oraciones diarias", "El islam se sostiene en cinco: el testimonio, el salah, el zakat, el Hayy y el ayuno de Ramadán. El salah es cinco veces al día."),
                "de": ("Fünf tägliche Gebete", "Der Islam steht auf fünf: Glaubensbekenntnis, Salah, Zakat, Haddsch und Fasten im Ramadan. Salah ist fünfmal täglich."),
                "fr": ("Cinq prières par jour", "L’islam est bâti sur cinq : le témoignage, la salat, la zakat, le hajj et le jeûne du ramadan. La salat est cinq fois par jour."),
                "ru": ("Пять молитв в день", "Ислам стоит на пяти: свидетельство, намаз, закят, хадж и пост в Рамадан. Намаз — пять раз каждый день."),
                "ar": ("خمس صلوات في اليوم", "بُني الإسلام على خمس: الشهادتين، والصلاة، والزكاة، والحج، وصوم رمضان. والصلاة خمس مرات كل يوم."),
            },
        ),
        (
            "night_qadr",
            "Qur’an 97:3",
            {
                "en": ("Better than a thousand months", "Laylat al-Qadr is better than a thousand months. It is in Ramadan; its exact night is not fixed in the Quran."),
                "nl": ("Beter dan duizend maanden", "Laylat al-Qadr is beter dan duizend maanden. Ze valt in Ramadan; de exacte nacht staat niet in de Koran vast."),
                "es": ("Mejor que mil meses", "Laylat al-Qadr es mejor que mil meses. Es en Ramadán; la noche exacta no está fijada en el Corán."),
                "de": ("Besser als tausend Monate", "Laylat al-Qadr ist besser als tausend Monate. Sie liegt im Ramadan; die genaue Nacht steht im Koran nicht fest."),
                "fr": ("Meilleure que mille mois", "Laylat al-Qadr est meilleure que mille mois. Elle est en ramadan ; la nuit exacte n’est pas fixée dans le Coran."),
                "ru": ("Лучше тысячи месяцев", "Ночь предопределения лучше тысячи месяцев. Она в Рамадан; точная ночь в Коране не названа."),
                "ar": ("خير من ألف شهر", "ليلة القدر خير من ألف شهر. هي في رمضان، ولم يُحدد القرآن ليلتها بعينها."),
            },
        ),
        (
            "hijrah",
            "Qur’an 9:40 · seerah of the Hijrah",
            {
                "en": ("The Hijrah", "The Prophet ﷺ migrated from Makkah to Madinah. The Quran mentions Allah’s help to him in the cave on that journey."),
                "nl": ("De hidjra", "De Profeet ﷺ emigreerde van Mekka naar Medina. De Koran noemt Allahs hulp aan hem in de grot op die reis."),
                "es": ("La Hégira", "El Profeta ﷺ emigró de La Meca a Medina. El Corán menciona la ayuda de Allah en la cueva de ese viaje."),
                "de": ("Die Hidschra", "Der Prophet ﷺ wanderte von Mekka nach Madina. Der Koran erwähnt Allahs Hilfe für ihn in der Höhle auf jener Reise."),
                "fr": ("L’hégire", "Le Prophète ﷺ émigra de La Mecque à Médine. Le Coran mentionne le secours d’Allah dans la grotte de ce voyage."),
                "ru": ("Хиджра", "Пророк ﷺ переселился из Мекки в Медину. Коран упоминает помощь Аллаха ему в пещере в том пути."),
                "ar": ("الهجرة", "هاجر النبي ﷺ من مكة إلى المدينة. وذكر القرآن نصر الله له في الغار في ذلك المسير."),
            },
        ),
        (
            "seal_prophets",
            "Qur’an 33:40",
            {
                "en": ("The Seal of the Prophets", "The Quran calls Muhammad ﷺ the Messenger of Allah and the seal of the prophets."),
                "nl": ("Het zegel der profeten", "De Koran noemt Mohammed ﷺ de Boodschapper van Allah en het zegel van de profeten."),
                "es": ("El sello de los profetas", "El Corán llama a Muhammad ﷺ Mensajero de Allah y sello de los profetas."),
                "de": ("Das Siegel der Propheten", "Der Koran nennt Muhammad ﷺ den Gesandten Allahs und das Siegel der Propheten."),
                "fr": ("Le sceau des prophètes", "Le Coran appelle Muhammad ﷺ le Messager d’Allah et le sceau des prophètes."),
                "ru": ("Печать пророков", "Коран называет Мухаммада ﷺ Посланником Аллаха и печатью пророков."),
                "ar": ("خاتم النبيين", "سمّى القرآن محمدًا ﷺ رسول الله وخاتم النبيين."),
            },
        ),
        (
            "two_testimonies",
            "Qur’an 47:19 · Sahih al-Bukhari 8",
            {
                "en": ("There is no god but Allah", "The first pillar is to witness that there is no god but Allah, and that Muhammad ﷺ is His messenger."),
                "nl": ("Er is geen god dan Allah", "De eerste pilaar is getuigen dat er geen god is dan Allah, en dat Mohammed ﷺ Zijn boodschapper is."),
                "es": ("No hay dios sino Allah", "El primer pilar es atestiguar que no hay dios sino Allah, y que Muhammad ﷺ es Su mensajero."),
                "de": ("Kein Gott außer Allah", "Die erste Säule ist zu bezeugen, dass es keinen Gott außer Allah gibt und Muhammad ﷺ Sein Gesandter ist."),
                "fr": ("Pas de dieu sinon Allah", "Le premier pilier est d’attester qu’il n’y a de dieu qu’Allah, et que Muhammad ﷺ est Son messager."),
                "ru": ("Нет бога, кроме Аллаха", "Первая опора — засвидетельствовать, что нет бога, кроме Аллаха, и что Мухаммад ﷺ — Его посланник."),
                "ar": ("لا إله إلا الله", "الركن الأول شهادة أن لا إله إلا الله وأن محمدًا ﷺ رسول الله."),
            },
        ),
        (
            "zakat_pillar",
            "Qur’an 2:43 · Sahih al-Bukhari 8",
            {
                "en": ("Zakat is a pillar", "The Quran pairs salah with zakat. Giving the due alms is one of the five pillars of Islam."),
                "nl": ("Zakat is een pilaar", "De Koran koppelt salah aan zakat. De verplichte aalmoes is een van de vijf pilaren van de islam."),
                "es": ("El zakat es un pilar", "El Corán une el salah con el zakat. La limosna debida es uno de los cinco pilares del islam."),
                "de": ("Zakat ist eine Säule", "Der Koran verbindet Salah mit Zakat. Die fällige Abgabe ist eine der fünf Säulen des Islam."),
                "fr": ("La zakat est un pilier", "Le Coran couple la salat et la zakat. L’aumône due est l’un des cinq piliers de l’islam."),
                "ru": ("Закят — опора", "Коран соединяет намаз и закят. Положенный закят — одна из пяти опор ислама."),
                "ar": ("الزكاة ركن", "قرن القرآن الصلاة بالزكاة. وإيتاء الزكاة ركن من أركان الإسلام الخمسة."),
            },
        ),
        (
            "hajj_pillar",
            "Qur’an 3:97 · Sahih al-Bukhari 8",
            {
                "en": ("Hajj to the House", "Hajj to the Kaaba is a duty for those who can find a way to it. It is one of the five pillars."),
                "nl": ("Hadj naar het Huis", "De hadj naar de Kaaba is een plicht voor wie er een weg naartoe vindt. Het is een van de vijf pilaren."),
                "es": ("Hayy a la Casa", "El Hayy a la Kaaba es un deber para quien pueda hallar un camino. Es uno de los cinco pilares."),
                "de": ("Haddsch zum Haus", "Der Haddsch zur Kaaba ist Pflicht für den, der einen Weg dorthin findet. Er ist eine der fünf Säulen."),
                "fr": ("Hajj vers la Maison", "Le hajj vers la Kaaba est un devoir pour qui en trouve le moyen. C’est l’un des cinq piliers."),
                "ru": ("Хадж к Дому", "Хадж к Каабе обязателен для того, кто найдёт к нему путь. Это одна из пяти опор."),
                "ar": ("الحج إلى البيت", "ولله على الناس حج البيت من استطاع إليه سبيلًا. وهو ركن من أركان الإسلام."),
            },
        ),
        (
            "fast_ramadan",
            "Qur’an 2:183 · Sahih al-Bukhari 8",
            {
                "en": ("Fasting was prescribed", "Fasting was prescribed for you as it was prescribed for those before you, so that you may become mindful of Allah."),
                "nl": ("Vasten is voorgeschreven", "Vasten is jullie voorgeschreven zoals het hen vóór jullie was voorgeschreven, opdat jullie taqwa zouden krijgen."),
                "es": ("Se os prescribió el ayuno", "Se os prescribió el ayuno como se prescribió a quienes os precedieron, para que alcancéis taqwa."),
                "de": ("Das Fasten wurde vorgeschrieben", "Das Fasten wurde euch vorgeschrieben, wie denen vor euch, damit ihr Gottesbewusstsein erlangt."),
                "fr": ("Le jeûne vous a été prescrit", "Le jeûne vous a été prescrit comme à ceux avant vous, afin que vous atteigniez la taqwa."),
                "ru": ("Пост предписан", "Вам предписан пост, как тем, кто был до вас, чтобы вы обрели такуа."),
                "ar": ("كُتب عليكم الصيام", "كُتب عليكم الصيام كما كُتب على الذين من قبلكم لعلكم تتقون."),
            },
        ),
        (
            "fatiha_every_salah",
            "Sahih al-Bukhari 756 · Sahih Muslim 394",
            {
                "en": ("No salah without Al-Fatiha", "The Prophet ﷺ said there is no salah for the one who does not recite the Opening of the Book."),
                "nl": ("Geen salah zonder Al-Fatiha", "De Profeet ﷺ zei dat er geen salah is voor wie de Opening van het Boek niet reciteert."),
                "es": ("No hay salah sin Al-Fatiha", "El Profeta ﷺ dijo que no hay salah para quien no recita la Apertura del Libro."),
                "de": ("Kein Salah ohne Al-Fatiha", "Der Prophet ﷺ sagte, es gebe kein Salah für den, der die Eröffnung des Buches nicht rezitiert."),
                "fr": ("Pas de salat sans Al-Fatiha", "Le Prophète ﷺ a dit qu’il n’y a pas de salat pour qui ne récite pas l’Ouverture du Livre."),
                "ru": ("Нет намаза без «Аль-Фатиха»", "Пророк ﷺ сказал, что нет намаза у того, кто не читает Открывающую Книгу."),
                "ar": ("لا صلاة إلا بفاتحة الكتاب", "قال النبي ﷺ: لا صلاة لمن لم يقرأ بفاتحة الكتاب."),
            },
        ),
        (
            "quran_preserved",
            "Qur’an 15:9",
            {
                "en": ("We will guard it", "Allah said of the Reminder: “It is We who sent down the Reminder, and We will surely guard it.”",),
                "nl": ("Wij zullen hem bewaren", "Allah zei over de Vermaning: “Voorwaar, Wij hebben de Vermaning neergezonden, en Wij zullen haar waarlijk bewaren.”"),
                "es": ("Nosotros lo guardaremos", "Allah dijo del Recuerdo: “Ciertamente, Nosotros hemos revelado el Recuerdo y Nosotros lo guardaremos.”"),
                "de": ("Wir werden ihn bewahren", "Allah sagte über die Erinnerung: „Wahrlich, Wir haben die Erinnerung herabgesandt, und wahrlich, Wir werden sie bewahren.“"),
                "fr": ("Nous le préserverons", "Allah a dit du Rappel : « C’est Nous qui avons fait descendre le Rappel, et c’est Nous qui le préservons. »"),
                "ru": ("Мы его охраним", "Аллах сказал о Напоминании: «Воистину, Мы ниспослали Напоминание, и Мы его охраняем»."),
                "ar": ("إنا له لحافظون", "قال تعالى: «إنا نحن نزلنا الذكر وإنا له لحافظون»."),
            },
        ),
    ]
    for fid, src, loc in extra_more:
        cid = f"fact_{fid}"
        swift_cards.append(f'        DiscoveryCard(id: "{cid}", kind: .fact, arabic: nil),')
        titles = {lang: loc[lang][0] for lang in EDITIONS}
        meanings = {lang: loc[lang][1] for lang in EDITIONS}
        add_strings(cid, titles, meanings, src)

    # --- facts: extra ---
    for fact in EXTRA_FACTS:
        cid = f"fact_{fact['id']}"
        swift_cards.append(f'        DiscoveryCard(id: "{cid}", kind: .fact, arabic: nil),')
        add_strings(cid, fact["title"], fact["meaning"], fact["source"])

    ar_map = quran["ar"]
    n_ayahs = len(ar_map)
    n_allah = count_ar_token(ar_map, "الله")
    n_rahman = count_ar_token_any(ar_map, "الرحمن", "الرحمان")
    n_rahim = count_ar_token(ar_map, "الرحيم")
    n_muhammad = count_ar_token(ar_map, "محمد")
    n_jannah = count_ar_token(ar_map, "الجنة")
    n_nar = count_ar_token(ar_map, "النار")
    n_salah = count_ar_token_any(ar_map, "الصلاة", "الصلوة", "الصلواة")
    n_rahman_refrain = count_identical_ayahs(ar_map, (55, 13), surah_only=55)
    n_mursalat = count_identical_ayahs(ar_map, (77, 15), surah_only=77)
    n_qamar = count_identical_ayahs(ar_map, (54, 17), surah_only=54)
    n_bismillah_open = sum(1 for s in surahs if s["number"] != 9)

    mushaf_src = "Uthmani Hafs mushaf count"
    computed_facts = [
        (
            "ayah_total",
            mushaf_src,
            {
                "en": (f"{n_ayahs} ayahs", f"The standard Uthmani Hafs mushaf contains {n_ayahs} ayahs across 114 surahs."),
                "nl": (f"{n_ayahs} verzen", f"De gebruikelijke Oethmaanse Hafs-mushaf telt {n_ayahs} verzen, verdeeld over 114 soera’s."),
                "es": (f"{n_ayahs} aleyas", f"El mushaf utmaní Hafs habitual contiene {n_ayahs} aleyas en 114 suras."),
                "de": (f"{n_ayahs} Verse", f"Der übliche uthmanische Hafs-Mushaf enthält {n_ayahs} Verse in 114 Suren."),
                "fr": (f"{n_ayahs} versets", f"Le mushaf othmanien Hafs usuel compte {n_ayahs} versets répartis en 114 sourates."),
                "ru": (f"{n_ayahs} аятов", f"В обычном османском мусхафе Хафса {n_ayahs} аятов в 114 сурах."),
                "ar": (f"{n_ayahs} آية", f"المصحف العثماني برواية حفص يضم {n_ayahs} آية في ١١٤ سورة."),
            },
        ),
        (
            "bismillah_openings",
            "Uthmani mushaf · Qur’an 27:30",
            {
                "en": (f"{n_bismillah_open} surahs open with Bismillah", f"{n_bismillah_open} surahs begin with Bismillah. At-Tawbah does not. An extra Bismillah appears in the letter of Sulayman (27:30)."),
                "nl": (f"{n_bismillah_open} soera’s beginnen met Bismillah", f"{n_bismillah_open} soera’s openen met Bismillah. At-Tawbah niet. Een extra Bismillah staat in de brief van Soelayman (27:30)."),
                "es": (f"{n_bismillah_open} suras empiezan con Bismillah", f"{n_bismillah_open} suras empiezan con Bismillah. At-Tawbah no. Hay otra Bismillah en la carta de Sulayman (27:30)."),
                "de": (f"{n_bismillah_open} Suren beginnen mit Bismillah", f"{n_bismillah_open} Suren beginnen mit Bismillah. At-Tawba nicht. Eine weitere Bismillah steht im Brief Sulaymans (27:30)."),
                "fr": (f"{n_bismillah_open} sourates s’ouvrent par Bismillah", f"{n_bismillah_open} sourates commencent par Bismillah. At-Tawba non. Une Bismillah de plus est dans la lettre de Sulayman (27:30)."),
                "ru": (f"{n_bismillah_open} сур начинаются с «Бисмиллях»", f"{n_bismillah_open} сур открываются «Бисмиллях». «Ат-Тауба» — нет. Ещё одно «Бисмиллях» в письме Сулеймана (27:30)."),
                "ar": (f"{n_bismillah_open} سورة تفتتح بالبسملة", f"تفتتح {n_bismillah_open} سورة بالبسملة، لا التوبة. وبسملة أخرى في كتاب سليمان (٢٧:٣٠)."),
            },
        ),
        (
            "word_allah",
            mushaf_src,
            {
                "en": (f"Allah is written {n_allah} times", f"In the Uthmani Hafs text, the name Allah (الله) appears {n_allah} times as a written word — not counting Allahumma."),
                "nl": (f"Allah staat {n_allah} keer geschreven", f"In de Oethmaanse Hafs-tekst komt de naam Allah (الله) {n_allah} keer voor als geschreven woord — zonder Allahumma."),
                "es": (f"Allah está escrito {n_allah} veces", f"En el texto utmaní Hafs, el nombre Allah (الله) aparece {n_allah} veces como palabra escrita, sin contar Allahumma."),
                "de": (f"Allah steht {n_allah}-mal geschrieben", f"Im uthmanischen Hafs-Text kommt der Name Allah (الله) {n_allah}-mal als geschriebenes Wort vor — ohne Allahumma."),
                "fr": (f"Allah est écrit {n_allah} fois", f"Dans le texte othmanien Hafs, le nom Allah (الله) apparaît {n_allah} fois comme mot écrit — hors Allahumma."),
                "ru": (f"«Аллах» написано {n_allah} раз", f"В османском тексте Хафса имя Аллах (الله) встречается {n_allah} раз как написанное слово — без «Аллахумма»."),
                "ar": (f"كُتب اسم الله {n_allah} مرة", f"في المصحف العثماني برواية حفص ورد اسم الله {n_allah} مرة كلمةً مكتوبة، دون اللهم."),
            },
        ),
        (
            "word_rahman",
            mushaf_src,
            {
                "en": (f"Ar-Rahman {n_rahman} times", f"In the Uthmani Hafs text, the word Ar-Rahman (الرحمن) appears {n_rahman} times as written."),
                "nl": (f"Ar-Rahman {n_rahman} keer", f"In de Oethmaanse Hafs-tekst komt het woord Ar-Rahman (الرحمن) {n_rahman} keer geschreven voor."),
                "es": (f"Ar-Rahman {n_rahman} veces", f"En el texto utmaní Hafs, la palabra Ar-Rahman (الرحمن) aparece {n_rahman} veces."),
                "de": (f"Ar-Rahman {n_rahman}-mal", f"Im uthmanischen Hafs-Text steht das Wort Ar-Rahman (الرحمن) {n_rahman}-mal geschrieben."),
                "fr": (f"Ar-Rahman {n_rahman} fois", f"Dans le texte othmanien Hafs, le mot Ar-Rahman (الرحمن) apparaît {n_rahman} fois."),
                "ru": (f"«Ар-Рахман» {n_rahman} раз", f"В османском тексте Хафса слово «Ар-Рахман» (الرحمن) встречается {n_rahman} раз."),
                "ar": (f"الرحمن {n_rahman} مرة", f"في المصحف العثماني برواية حفص وردت كلمة الرحمن {n_rahman} مرة."),
            },
        ),
        (
            "word_rahim",
            mushaf_src,
            {
                "en": (f"Ar-Raheem {n_rahim} times", f"In the Uthmani Hafs text, the word Ar-Raheem (الرحيم) appears {n_rahim} times as written."),
                "nl": (f"Ar-Rahiem {n_rahim} keer", f"In de Oethmaanse Hafs-tekst komt het woord Ar-Rahiem (الرحيم) {n_rahim} keer geschreven voor."),
                "es": (f"Ar-Rahim {n_rahim} veces", f"En el texto utmaní Hafs, la palabra Ar-Rahim (الرحيم) aparece {n_rahim} veces."),
                "de": (f"Ar-Rahim {n_rahim}-mal", f"Im uthmanischen Hafs-Text steht das Wort Ar-Rahim (الرحيم) {n_rahim}-mal geschrieben."),
                "fr": (f"Ar-Rahim {n_rahim} fois", f"Dans le texte othmanien Hafs, le mot Ar-Rahim (الرحيم) apparaît {n_rahim} fois."),
                "ru": (f"«Ар-Рахим» {n_rahim} раз", f"В османском тексте Хафса слово «Ар-Рахим» (الرحيم) встречается {n_rahim} раз."),
                "ar": (f"الرحيم {n_rahim} مرة", f"في المصحف العثماني برواية حفص وردت كلمة الرحيم {n_rahim} مرة."),
            },
        ),
        (
            "word_muhammad",
            mushaf_src + " · Qur’an 3:144 · 33:40 · 47:2 · 48:29",
            {
                "en": (f"Muhammad is named {n_muhammad} times", f"The name Muhammad ﷺ is written {n_muhammad} times in the Quran. He is also called Ahmad in 61:6."),
                "nl": (f"Mohammed wordt {n_muhammad} keer genoemd", f"De naam Mohammed ﷺ staat {n_muhammad} keer in de Koran. In 61:6 wordt hij ook Ahmad genoemd."),
                "es": (f"Muhammad se nombra {n_muhammad} veces", f"El nombre Muhammad ﷺ aparece {n_muhammad} veces en el Corán. En 61:6 también se le llama Ahmad."),
                "de": (f"Muhammad wird {n_muhammad}-mal genannt", f"Der Name Muhammad ﷺ steht {n_muhammad}-mal im Koran. In 61:6 wird er auch Ahmad genannt."),
                "fr": (f"Muhammad est nommé {n_muhammad} fois", f"Le nom Muhammad ﷺ est écrit {n_muhammad} fois dans le Coran. En 61:6 il est aussi appelé Ahmad."),
                "ru": (f"Мухаммад назван {n_muhammad} раза", f"Имя Мухаммад ﷺ написано в Коране {n_muhammad} раза. В 61:6 он также назван Ахмадом."),
                "ar": (f"ذُكر محمد {n_muhammad} مرات", f"كُتب اسم محمد ﷺ في القرآن {n_muhammad} مرات. وفي ٦١:٦ سُمّي أحمد."),
            },
        ),
        (
            "word_jannah",
            mushaf_src,
            {
                "en": (f"Al-jannah {n_jannah} times", f"In the Uthmani Hafs text, the word al-jannah (الجنة, the Garden) appears {n_jannah} times as written."),
                "nl": (f"Al-djannah {n_jannah} keer", f"In de Oethmaanse Hafs-tekst komt het woord al-djannah (الجنة, de Tuin) {n_jannah} keer geschreven voor."),
                "es": (f"Al-yanna {n_jannah} veces", f"En el texto utmaní Hafs, la palabra al-yanna (الجنة, el Jardín) aparece {n_jannah} veces."),
                "de": (f"Al-Dschanna {n_jannah}-mal", f"Im uthmanischen Hafs-Text steht das Wort al-Dschanna (الجنة, der Garten) {n_jannah}-mal geschrieben."),
                "fr": (f"Al-janna {n_jannah} fois", f"Dans le texte othmanien Hafs, le mot al-janna (الجنة, le Jardin) apparaît {n_jannah} fois."),
                "ru": (f"«Аль-джанна» {n_jannah} раз", f"В османском тексте Хафса слово «аль-джанна» (الجنة, Сад) встречается {n_jannah} раз."),
                "ar": (f"الجنة {n_jannah} مرة", f"في المصحف العثماني برواية حفص وردت كلمة الجنة {n_jannah} مرة."),
            },
        ),
        (
            "word_nar",
            mushaf_src,
            {
                "en": (f"An-nar {n_nar} times", f"In the Uthmani Hafs text, the word an-nar (النار, the Fire) appears {n_nar} times as written."),
                "nl": (f"An-naar {n_nar} keer", f"In de Oethmaanse Hafs-tekst komt het woord an-naar (النار, het Vuur) {n_nar} keer geschreven voor."),
                "es": (f"An-nar {n_nar} veces", f"En el texto utmaní Hafs, la palabra an-nar (النار, el Fuego) aparece {n_nar} veces."),
                "de": (f"An-Nar {n_nar}-mal", f"Im uthmanischen Hafs-Text steht das Wort an-Nar (النار, das Feuer) {n_nar}-mal geschrieben."),
                "fr": (f"An-nar {n_nar} fois", f"Dans le texte othmanien Hafs, le mot an-nar (النار, le Feu) apparaît {n_nar} fois."),
                "ru": (f"«Ан-нар» {n_nar} раз", f"В османском тексте Хафса слово «ан-нар» (النار, Огонь) встречается {n_nar} раз."),
                "ar": (f"النار {n_nar} مرة", f"في المصحف العثماني برواية حفص وردت كلمة النار {n_nar} مرة."),
            },
        ),
        (
            "rahman_refrain",
            "Qur’an 55",
            {
                "en": (f"Which of the favors — {n_rahman_refrain} times", f"The ayah “So which of the favors of your Lord will you both deny?” is written {n_rahman_refrain} times in Surah Ar-Rahman."),
                "nl": (f"Welke gunsten — {n_rahman_refrain} keer", f"Het vers “Welke van de gunsten van jullie Heer loochenen jullie beiden dan?” staat {n_rahman_refrain} keer in soera Ar-Rahman."),
                "es": (f"¿Cuál de los favores? {n_rahman_refrain} veces", f"La aleya “¿Cuál de los favores de vuestro Señor negaréis?” está escrita {n_rahman_refrain} veces en la sura Ar-Rahman."),
                "de": (f"Welche Wohltaten — {n_rahman_refrain}-mal", f"Der Vers „Welche der Wohltaten eures Herrn wollt ihr beide denn leugnen?“ steht {n_rahman_refrain}-mal in Sure Ar-Rahman."),
                "fr": (f"Lequel des bienfaits — {n_rahman_refrain} fois", f"Le verset « Lequel donc des bienfaits de votre Seigneur nierez-vous ? » est écrit {n_rahman_refrain} fois dans la sourate Ar-Rahman."),
                "ru": (f"Какую из милостей — {n_rahman_refrain} раз", f"Аят «Какую же из милостей Господа вашего вы сочтёте ложью?» написан {n_rahman_refrain} раз в суре «Ар-Рахман»."),
                "ar": (f"فبأي آلاء ربكما تكذبان {n_rahman_refrain} مرة", f"تكررت آية «فبأي آلاء ربكما تكذبان» {n_rahman_refrain} مرة في سورة الرحمن."),
            },
        ),
        (
            "mursalat_refrain",
            "Qur’an 77",
            {
                "en": (f"Woe that Day — {n_mursalat} times", f"The ayah “Woe that Day to the deniers” is written {n_mursalat} times in Surah Al-Mursalat."),
                "nl": (f"Wee die Dag — {n_mursalat} keer", f"Het vers “Wee die Dag de loochenaars” staat {n_mursalat} keer in soera Al-Moersalat."),
                "es": (f"¡Ay aquel Día! {n_mursalat} veces", f"La aleya “¡Ay aquel Día de los desmentidores!” está escrita {n_mursalat} veces en la sura Al-Mursalat."),
                "de": (f"Wehe an jenem Tag — {n_mursalat}-mal", f"Der Vers „Wehe an jenem Tag den Leugnern“ steht {n_mursalat}-mal in Sure Al-Mursalat."),
                "fr": (f"Malheur ce jour-là — {n_mursalat} fois", f"Le verset « Malheur ce jour-là aux négateurs » est écrit {n_mursalat} fois dans la sourate Al-Mursalat."),
                "ru": (f"Горе в тот день — {n_mursalat} раз", f"Аят «Горе в тот день обвиняющим во лжи» написан {n_mursalat} раз в суре «Аль-Мурсалят»."),
                "ar": (f"ويل يومئذ للمكذبين {n_mursalat} مرة", f"تكررت آية «ويل يومئذ للمكذبين» {n_mursalat} مرة في سورة المرسلات."),
            },
        ),
        (
            "qamar_easy_repeat",
            "Qur’an 54:17 · 54:22 · 54:32 · 54:40",
            {
                "en": (f"Made easy to remember — {n_qamar} times", f"The wording “We have certainly made the Quran easy to remember; so is there any who will remember?” appears {n_qamar} times in Surah Al-Qamar."),
                "nl": (f"Makkelijk om te onthouden — {n_qamar} keer", f"De formulering “Voorwaar, Wij hebben de Koran makkelijk gemaakt om te onthouden; is er dan iemand die zich laat vermanen?” staat {n_qamar} keer in soera Al-Qamar."),
                "es": (f"Fácil de recordar — {n_qamar} veces", f"La frase “Ciertamente hemos hecho el Corán fácil de recordar; ¿hay quien recuerde?” aparece {n_qamar} veces en la sura Al-Qamar."),
                "de": (f"Leicht zum Merken — {n_qamar}-mal", f"Der Wortlaut „Wahrlich, Wir haben den Koran leicht zum Gedenken gemacht; gibt es denn jemanden, der bedenkt?“ steht {n_qamar}-mal in Sure Al-Qamar."),
                "fr": (f"Facile à retenir — {n_qamar} fois", f"La formule « Nous avons certes rendu le Coran facile à retenir ; y a-t-il quelqu’un qui se rappelle ? » apparaît {n_qamar} fois dans la sourate Al-Qamar."),
                "ru": (f"Облегчён для поминания — {n_qamar} раза", f"Слова «Мы облегчили Коран для поминания. Но есть ли поминающие?» встречаются {n_qamar} раза в суре «Аль-Камар»."),
                "ar": (f"يسرناه للذكر {n_qamar} مرات", f"تكرر قوله «ولقد يسرنا القرآن للذكر فهل من مدكر» {n_qamar} مرات في سورة القمر."),
            },
        ),
    ]
    if n_salah > 0:
        computed_facts.append(
            (
                "word_salah",
                mushaf_src,
                {
                    "en": (f"As-salah {n_salah} times", f"In the Uthmani Hafs text, the word as-salah (the prayer) appears {n_salah} times as written."),
                    "nl": (f"As-salah {n_salah} keer", f"In de Oethmaanse Hafs-tekst komt het woord as-salah (het gebed) {n_salah} keer geschreven voor."),
                    "es": (f"As-salah {n_salah} veces", f"En el texto utmaní Hafs, la palabra as-salah (la oración) aparece {n_salah} veces."),
                    "de": (f"As-Salah {n_salah}-mal", f"Im uthmanischen Hafs-Text steht das Wort as-Salah (das Gebet) {n_salah}-mal geschrieben."),
                    "fr": (f"As-salat {n_salah} fois", f"Dans le texte othmanien Hafs, le mot as-salat (la prière) apparaît {n_salah} fois."),
                    "ru": (f"«Ас-салят» {n_salah} раз", f"В османском тексте Хафса слово «ас-салят» (молитва) встречается {n_salah} раз."),
                    "ar": (f"الصلاة {n_salah} مرة", f"في المصحف العثماني برواية حفص وردت كلمة الصلاة {n_salah} مرة."),
                },
            )
        )
    computed_facts = [
        item
        for item in computed_facts
        if " 0 times" not in item[2]["en"][0] and "— 0" not in item[2]["en"][0]
    ]
    print(
        "counts",
        {
            "ayahs": n_ayahs,
            "allah": n_allah,
            "rahman": n_rahman,
            "rahim": n_rahim,
            "muhammad": n_muhammad,
            "jannah": n_jannah,
            "nar": n_nar,
            "salah": n_salah,
            "rahman_refrain": n_rahman_refrain,
            "mursalat": n_mursalat,
            "qamar": n_qamar,
        },
    )
    for fid, src, loc in computed_facts:
        cid = f"fact_{fid}"
        swift_cards.append(f'        DiscoveryCard(id: "{cid}", kind: .fact, arabic: nil),')
        titles = {lang: loc[lang][0] for lang in EDITIONS}
        meanings = {lang: loc[lang][1] for lang in EDITIONS}
        add_strings(cid, titles, meanings, src)

    meccan = sum(1 for s in surahs if s["revelationType"] == "Meccan")
    medinan = sum(1 for s in surahs if s["revelationType"] == "Medinan")
    count_facts = [
        (
            "meccan_count",
            "Uthmani mushaf classification",
            {
                "en": (f"{meccan} Makkan surahs", f"In the standard mushaf classification, {meccan} surahs were revealed in Makkah."),
                "nl": (f"{meccan} Mekkaanse soera’s", f"In de gebruikelijke mushaf-indeling zijn {meccan} soera’s in Mekka neergezonden."),
                "es": (f"{meccan} suras mecanas", f"En la clasificación habitual del mushaf, {meccan} suras se revelaron en La Meca."),
                "de": (f"{meccan} mekkanische Suren", f"In der üblichen Mushaf-Einteilung wurden {meccan} Suren in Mekka offenbart."),
                "fr": (f"{meccan} sourates mecquoises", f"Dans la classification habituelle du mushaf, {meccan} sourates furent descendues à La Mecque."),
                "ru": (f"{meccan} мекканских сур", f"В обычной классификации мусхафа {meccan} сур ниспосланы в Мекке."),
                "ar": (f"{meccan} سورة مكية", f"في تصنيف المصحف المعتاد نزلت {meccan} سورة في مكة."),
            },
        ),
        (
            "medinan_count",
            "Uthmani mushaf classification",
            {
                "en": (f"{medinan} Madinan surahs", f"In the standard mushaf classification, {medinan} surahs were revealed in Madinah."),
                "nl": (f"{medinan} Medinese soera’s", f"In de gebruikelijke mushaf-indeling zijn {medinan} soera’s in Medina neergezonden."),
                "es": (f"{medinan} suras medinesas", f"En la clasificación habitual del mushaf, {medinan} suras se revelaron en Medina."),
                "de": (f"{medinan} medinensische Suren", f"In der üblichen Mushaf-Einteilung wurden {medinan} Suren in Madina offenbart."),
                "fr": (f"{medinan} sourates médinoises", f"Dans la classification habituelle du mushaf, {medinan} sourates furent descendues à Médine."),
                "ru": (f"{medinan} мединских сур", f"В обычной классификации мусхафа {medinan} сур ниспосланы в Медине."),
                "ar": (f"{medinan} سورة مدنية", f"في تصنيف المصحف المعتاد نزلت {medinan} سورة في المدينة."),
            },
        ),
    ]
    for fid, src, loc in count_facts:
        cid = f"fact_{fid}"
        swift_cards.append(f'        DiscoveryCard(id: "{cid}", kind: .fact, arabic: nil),')
        titles = {lang: loc[lang][0] for lang in EDITIONS}
        meanings = {lang: loc[lang][1] for lang in EDITIONS}
        add_strings(cid, titles, meanings, src)

    # --- facts: one per surah ---
    place = {
        "en": {"Meccan": "Makkah", "Medinan": "Madinah"},
        "nl": {"Meccan": "Mekka", "Medinan": "Medina"},
        "es": {"Meccan": "La Meca", "Medinan": "Medina"},
        "de": {"Meccan": "Mekka", "Medinan": "Madina"},
        "fr": {"Meccan": "La Mecque", "Medinan": "Médine"},
        "ru": {"Meccan": "Мекке", "Medinan": "Медине"},
        "ar": {"Meccan": "مكة", "Medinan": "المدينة"},
    }
    for s in surahs:
        cid = f"fact_surah_{s['number']}"
        swift_cards.append(f'        DiscoveryCard(id: "{cid}", kind: .fact, arabic: nil),')
        titles, meanings = {}, {}
        for lang in EDITIONS:
            p = place[lang][s["revelationType"]]
            name = s["name"] if lang == "ar" else s["englishName"]
            trans = s["englishNameTranslation"]
            t, m = fact_surah_copy(lang, name, trans, p, s["numberOfAyahs"])
            titles[lang], meanings[lang] = t, m
        add_strings(cid, titles, meanings, f"Qur’an {s['number']} · {s['revelationType']}")

    # --- facts: one per juz ---
    for j in juz_starts:
        cid = f"fact_juz_{j['juz']}"
        swift_cards.append(f'        DiscoveryCard(id: "{cid}", kind: .fact, arabic: nil),')
        titles, meanings = {}, {}
        for lang in EDITIONS:
            name = j["ar_name"] if lang == "ar" else j["en_name"]
            t, m = fact_juz_copy(lang, j["juz"], name)
            titles[lang], meanings[lang] = t, m
        add_strings(
            cid,
            titles,
            meanings,
            f"Qur’an {j['surah']}:{j['ayah']} · Juz {j['juz']}",
        )

    swift = """//
//  DiscoveryExpansion.swift
//  scrolldeeds
//
//  Generated sourced cards (ayahs, sunnah, facts). Do not edit by hand.
//  Regenerated by scripts/generate_discovery_expansion.py
//

import Foundation

enum DiscoveryExpansion {
    static let cards: [DiscoveryCard] = [
"""
    swift += "\n".join(swift_cards) + "\n    ]\n}\n"
    SWIFT_OUT.write_text(swift, encoding="utf-8")
    write_strings(strings)

    kinds = {
        "en": "Fact",
        "nl": "Weetje",
        "es": "Dato",
        "de": "Wissen",
        "fr": "Info",
        "ru": "Факт",
        "ar": "معلومة",
    }
    for lang, label in kinds.items():
        path = APP / f"{lang}.lproj" / "Localizable.strings"
        text = path.read_text(encoding="utf-8")
        line = f'"discovery.kind.fact" = "{label}";\n'
        if "discovery.kind.fact" not in text:
            text = text.replace(
                '"discovery.kind.hadith"',
                f'"discovery.kind.fact" = "{label}";\n"discovery.kind.hadith"',
                1,
            )
            path.write_text(text, encoding="utf-8")

    n_ayah = sum(1 for c in swift_cards if "kind: .ayah" in c)
    n_sun = sum(1 for c in swift_cards if "kind: .sunnah" in c)
    n_fact = sum(1 for c in swift_cards if "kind: .fact" in c)
    print(f"wrote {n_ayah} ayahs, {n_sun} sunnahs, {n_fact} facts")


if __name__ == "__main__":
    main()
